import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../lib_currency.dart';
import 'sheet_engine.dart';
import 'sheet_model.dart';
import 'sheet_store.dart';

/// Where the latest ECB table comes from (the region provider in the app, a
/// fake in tests).
abstract class LatestRatesSource implements Listenable {
  /// The latest `from=USD` table — live, or the last one cached — or null.
  RatesResult? get latestTable;

  /// True once a refresh has failed and no live table is available.
  bool get latestOffline;

  /// Tries to fetch a fresh table. Completes either way.
  Future<void> refreshRates();
}

/// What happened when the user tapped Re-price.
class RepriceResult {
  final bool ok;

  /// ECB date the sheet is priced at afterwards, `YYYY-MM-DD`.
  final String? asOf;
  const RepriceResult({required this.ok, this.asOf});
}

/// Owns every sheet: editing, autosave (≈500 ms after the last change and on
/// app pause), the Sheets list operations, and fetching the ECB rates the
/// sheets ask for.
class SheetsController extends ChangeNotifier with WidgetsBindingObserver {
  SheetsController({
    required this.rates,
    RateClient? rateClient,
    DateTime Function()? now,
    this.saveDelay = const Duration(milliseconds: 500),
  })  : _now = now ?? DateTime.now,
        rateClient = rateClient ?? RateClient(today: now) {
    rates.addListener(_onRatesChanged);
    WidgetsBinding.instance.addObserver(this);
  }

  final LatestRatesSource rates;
  final RateClient rateClient;
  final DateTime Function() _now;
  final Duration saveDelay;

  SheetStore? _store;
  final List<Sheet> _sheets = [];
  String? _currentId;
  bool _ready = false;
  Timer? _saveTimer;
  bool _disposed = false;

  final Map<String, RateFailure> _datedFailures = {};
  final Set<String> _inflight = {};
  bool _latestAttempted = false;
  final Map<String, SheetEvaluation> _evals = {};
  int _seq = 0;

  bool get ready => _ready;

  /// Loads sheets, runs the one-time Notes migration, and opens the last
  /// edited sheet (or a new empty one on first launch).
  Future<void> init({SharedPreferences? prefs}) async {
    final p = prefs ?? await SharedPreferences.getInstance();
    final store = SheetStore(p);
    _store = store;
    await store.migrateNotes();
    _sheets
      ..clear()
      ..addAll(store.loadSheets());
    rateClient.cache.addAll(store.loadRateCache());
    final last = store.lastSheetId;
    if (last != null && _sheets.any((s) => s.id == last)) {
      _currentId = last;
    } else if (_sheets.isNotEmpty) {
      _currentId = _sorted(_sheets).first.id;
    } else {
      _currentId = _blank().id;
    }
    _ready = true;
    _notify();
  }

  // ---- reading ------------------------------------------------------------

  Sheet get current =>
      _sheets.firstWhere((s) => s.id == _currentId, orElse: () => _blank());

  Sheet? byId(String id) {
    for (final s in _sheets) {
      if (s.id == id) return s;
    }
    return null;
  }

  /// Saved sheets, newest edit first, filtered by [query] across titles and
  /// line text.
  List<Sheet> savedSheets({String query = ''}) {
    final q = query.trim().toLowerCase();
    return _sorted(_sheets.where((s) => !s.isBlank)).where((s) {
      if (q.isEmpty) return true;
      if (s.displayTitle.toLowerCase().contains(q)) return true;
      return s.lines.any((l) => l.text.toLowerCase().contains(q));
    }).toList();
  }

  List<Sheet> _sorted(Iterable<Sheet> sheets) =>
      sheets.toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  RateBook get _book => RateBook(
        dated: rateClient.cache,
        datedFailures: _datedFailures,
        latest: rates.latestTable,
        latestOffline: rates.latestOffline,
      );

  /// The worked-out sheet. Pins new undated rates onto their lines and starts
  /// fetching any rate the sheet still needs.
  SheetEvaluation evaluation([String? sheetId]) {
    final sheet = sheetId == null ? current : (byId(sheetId) ?? current);
    final cached = _evals[sheet.id];
    if (cached != null) return cached;
    final eval = evaluateSheet(sheet.lines, rates: _book, today: _now());
    _evals[sheet.id] = eval;

    final pins = eval.newPins;
    if (pins.isNotEmpty) {
      final lines = [...sheet.lines];
      pins.forEach((i, pin) => lines[i] = lines[i].withPin(pin));
      _replace(sheet.copyWith(lines: lines), touch: false, invalidate: false);
      _scheduleSave();
    }
    if (eval.needs.isNotEmpty) {
      scheduleMicrotask(() => _fetch(eval.needs));
    }
    return eval;
  }

  int get cachedRateCount => rateClient.cache.length;

  // ---- editing ------------------------------------------------------------

  void setLineText(int index, String text) {
    final s = current;
    if (index < 0 || index >= s.lines.length) return;
    if (s.lines[index].text == text) return;
    final lines = [...s.lines];
    lines[index] = lines[index].withText(text);
    _replace(s.copyWith(lines: lines));
  }

  void insertLine(int at, [String text = '']) {
    final s = current;
    final lines = [...s.lines]..insert(at.clamp(0, s.lines.length), SheetLine(text));
    _replace(s.copyWith(lines: lines));
  }

  void removeLine(int index) {
    final s = current;
    if (index < 0 || index >= s.lines.length) return;
    final lines = [...s.lines]..removeAt(index);
    _replace(s.copyWith(lines: lines.isEmpty ? [const SheetLine('')] : lines));
  }

  /// Appends [text] to the current sheet (into its last line when that line
  /// is empty). Returns the sheet's title, for "Added to …".
  String appendLine(String text) {
    final s = current;
    final lines = [...s.lines];
    if (lines.isNotEmpty && lines.last.text.trim().isEmpty) {
      lines[lines.length - 1] = SheetLine(text);
    } else {
      lines.add(SheetLine(text));
    }
    _replace(s.copyWith(lines: lines));
    return current.displayTitle;
  }

  Sheet newSheet() {
    final s = _blank(force: true);
    _currentId = s.id;
    _notify();
    return s;
  }

  void open(String id) {
    if (byId(id) == null) return;
    _currentId = id;
    _store?.setLastSheetId(id);
    _notify();
  }

  void rename(String id, String title) {
    final s = byId(id);
    if (s == null) return;
    _replace(s.copyWith(title: title.trim()));
  }

  Sheet? duplicate(String id) {
    final s = byId(id);
    if (s == null) return null;
    final now = _now().millisecondsSinceEpoch;
    final copy = s.copyWith(
      id: _newId(),
      title: '${s.displayTitle} (copy)',
      createdAt: now,
      updatedAt: now,
    );
    _sheets.add(copy);
    _scheduleSave();
    _notify();
    return copy;
  }

  /// Deletes a sheet. Returns what [restore] needs to undo it.
  Sheet? delete(String id) {
    final s = byId(id);
    if (s == null) return null;
    _sheets.removeWhere((x) => x.id == id);
    _evals.remove(id);
    if (_currentId == id) {
      final rest = _sorted(_sheets.where((x) => !x.isBlank));
      _currentId = rest.isNotEmpty ? rest.first.id : _blank().id;
    }
    _scheduleSave();
    _notify();
    return s;
  }

  void restore(Sheet sheet) {
    if (byId(sheet.id) != null) return;
    _sheets.add(sheet);
    _scheduleSave();
    _notify();
  }

  // ---- rates --------------------------------------------------------------

  /// Re-prices every undated currency line of the current sheet at today's
  /// ECB rate. Only ever called from an explicit tap.
  Future<RepriceResult> reprice() async {
    final before = evaluation().pinnedAsOf;
    _latestAttempted = true;
    await rates.refreshRates();
    final table = rates.latestTable;
    if (table == null || !table.live) {
      return RepriceResult(ok: false, asOf: before ?? table?.date);
    }
    final s = current;
    final lines = [for (final l in s.lines) l.withPin(null)];
    _datedFailures.clear();
    _replace(s.copyWith(lines: lines));
    return RepriceResult(ok: true, asOf: table.date);
  }

  /// Forgets cached dated rates (Settings → Rates). Pinned lines keep their
  /// pins; dated lines are fetched again.
  Future<void> clearRateCache() async {
    rateClient.cache.clear();
    await _store?.clearRateCache();
    _evals.clear();
    _notify();
  }

  Future<void> _fetch(Set<RateNeed> needs) async {
    var changed = false;
    final jobs = <Future<void>>[];
    for (final need in needs) {
      if (need.date == null) {
        // The first load is already under way when there is no table yet and
        // no failure: wait for it rather than asking twice.
        if (rates.latestTable == null && !rates.latestOffline) continue;
        if (_latestAttempted) continue;
        _latestAttempted = true;
        jobs.add(rates.refreshRates());
        continue;
      }
      final key = need.key;
      if (_inflight.contains(key) || _datedFailures.containsKey(key)) continue;
      if (rateClient.cache.containsKey(key)) continue;
      _inflight.add(key);
      jobs.add(rateClient
          .fetchRateOn(DateTime.parse(need.date!), need.base, need.quote)
          .then((lookup) {
        _inflight.remove(key);
        if (lookup.ok) {
          _datedFailures.remove(key);
        } else {
          _datedFailures[key] = lookup.failure!;
        }
        changed = true;
      }));
    }
    if (jobs.isEmpty) return;
    await Future.wait(jobs);
    if (_disposed) return;
    if (changed) await _store?.saveRateCache(rateClient.cache);
    _evals.clear();
    _notify();
  }

  void _onRatesChanged() {
    _evals.clear();
    _notify();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      flush();
    } else if (state == AppLifecycleState.resumed) {
      // Back from the background, perhaps with a connection again: retry the
      // lines that could not get a rate.
      _datedFailures.removeWhere((_, f) => f == RateFailure.offline);
      _latestAttempted = false;
      _evals.clear();
      _notify();
    }
  }

  // ---- persistence --------------------------------------------------------

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(saveDelay, flush);
  }

  /// Saves now (also called on app pause).
  Future<void> flush() async {
    _saveTimer?.cancel();
    _saveTimer = null;
    final store = _store;
    if (store == null) return;
    await store.saveSheets(_sheets);
    final cur = byId(_currentId ?? '');
    if (cur != null && !cur.isBlank) await store.setLastSheetId(cur.id);
  }

  // ---- internals ----------------------------------------------------------

  String _newId() =>
      '${_now().microsecondsSinceEpoch.toRadixString(36)}-${_seq++}';

  Sheet _blank({bool force = false}) {
    if (!force) {
      for (final s in _sheets) {
        if (s.isBlank) return s;
      }
    }
    final now = _now().millisecondsSinceEpoch;
    final s = Sheet(
        id: _newId(),
        title: '',
        createdAt: now,
        updatedAt: now,
        lines: const [SheetLine('')]);
    _sheets.removeWhere((x) => x.isBlank);
    _sheets.add(s);
    return s;
  }

  void _replace(Sheet s, {bool touch = true, bool invalidate = true}) {
    final i = _sheets.indexWhere((x) => x.id == s.id);
    final next =
        touch ? s.copyWith(updatedAt: _now().millisecondsSinceEpoch) : s;
    if (i < 0) {
      _sheets.add(next);
    } else {
      _sheets[i] = next;
    }
    if (invalidate) {
      _evals.remove(s.id);
      _scheduleSave();
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _saveTimer?.cancel();
    rates.removeListener(_onRatesChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
