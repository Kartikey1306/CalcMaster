/// The sheet's line grammar. Pure Dart — no Flutter import — so every rule is
/// unit-tested without a widget tree.
///
/// A line is one of:
///   * blank;
///   * a heading — text with no number (`Trip to Lisbon`);
///   * `label: expr` — the label sits left of the result;
///   * arithmetic through `lib_calc` (`12 * (3 + 4)`, `sqrt(2)`);
///   * a reference: `#3` is line 3's result, `prev` the line above;
///   * a percentage: `expr + 18%`, `expr - 10%`, `18% of expr`;
///   * an amount tagged with a currency (`38.50 EUR`, `€38.50`) or a unit
///     (`12 ft`, `3'`);
///   * a unit conversion: `12 ft in m`;
///   * a currency conversion: `38.50 EUR [on 14 Sep] in USD`, converted at the
///     European Central Bank reference rate (for that date, when one is given);
///   * `total` — the sum of the results above in the sheet's main currency or
///     unit.
library;

import '../lib_calc.dart';
import '../lib_currency.dart';
import '../lib_format.dart';
import '../lib_units.dart';
import 'sheet_model.dart';

// ---------------------------------------------------------------------------
// Tags
// ---------------------------------------------------------------------------

/// What an amount is measured in: a currency code or a unit. Plain numbers
/// carry no tag.
class Tag {
  final String? currency;
  final UnitRef? unit;
  const Tag.currency(String this.currency) : unit = null;
  const Tag.unit(UnitRef this.unit) : currency = null;

  bool get isCurrency => currency != null;

  /// Stable identity: `USD`, or `u:ft`.
  String get key => currency ?? 'u:${unit!.unit.id}';

  /// What is printed after a number: `USD`, `m`, `°C`.
  String get label => currency ?? unit!.unit.symbol;

  @override
  bool operator ==(Object other) => other is Tag && other.key == key;

  @override
  int get hashCode => key.hashCode;

  @override
  String toString() => label;
}

const Map<String, String> _symbolCurrency = {
  '€': 'EUR',
  '£': 'GBP',
  r'$': 'USD',
  '¥': 'JPY',
  '₹': 'INR',
  '₩': 'KRW',
};

/// A currency tag, a unit tag, a specific "the ECB publishes no rate" error,
/// or null when [token] names neither.
({Tag? tag, String? error})? _tagFor(String token) {
  final sym = _symbolCurrency[token];
  if (sym != null) return (tag: Tag.currency(sym), error: null);
  final upper = token.toUpperCase();
  if (token.length == 3 && isEcbCurrency(upper)) {
    return (tag: Tag.currency(upper), error: null);
  }
  if (token.length == 3 && nonEcbCurrencies.contains(upper)) {
    return (tag: null, error: noEcbRateMessage(upper));
  }
  final unit = unitForToken(token);
  if (unit != null) return (tag: Tag.unit(unit), error: null);
  return null;
}

String noEcbRateMessage(String code) =>
    'The ECB publishes no reference rate for $code';

// ---------------------------------------------------------------------------
// Rates the evaluator may use (it never fetches anything itself)
// ---------------------------------------------------------------------------

/// A dated or latest rate the evaluator needs and does not have yet.
class RateNeed {
  /// `YYYY-MM-DD`, or null for "today's rate" (the latest table).
  final String? date;
  final String base;
  final String quote;
  const RateNeed({this.date, required this.base, required this.quote});

  String get key => date == null ? 'latest' : datedRateKey(date!, base, quote);

  @override
  bool operator ==(Object other) => other is RateNeed && other.key == key;

  @override
  int get hashCode => key.hashCode;
}

/// Everything the evaluator knows about rates at this moment.
class RateBook {
  /// Dated ECB rates, keyed by [datedRateKey] on the *requested* date.
  final Map<String, EcbRate> dated;

  /// Dated lookups that failed this session, keyed the same way.
  final Map<String, RateFailure> datedFailures;

  /// The latest `from=USD` table (live or the last cached one), if any.
  final RatesResult? latest;

  /// True when the last attempt to refresh [latest] failed for lack of a
  /// connection.
  final bool latestOffline;

  const RateBook({
    this.dated = const {},
    this.datedFailures = const {},
    this.latest,
    this.latestOffline = false,
  });
}

/// How a currency line's rate was obtained — printed under the result and
/// carried into exports.
class RateUse {
  final EcbRate rate;

  /// The date the line asked for (`YYYY-MM-DD`), or null for an undated line.
  final String? requestedDate;

  /// An undated line using the rate it was pinned to.
  final bool pinned;

  /// An undated line priced from a cached table while offline.
  final bool cachedOffline;

  const RateUse({
    required this.rate,
    this.requestedDate,
    this.pinned = false,
    this.cachedOffline = false,
  });

  bool get dated => requestedDate != null;

  /// e.g. "ECB 1.1551 · 14 Sep 2026", or for a weekend
  /// "ECB 1.1206 · Fri 9 Oct (no rate on Sat 10 Oct)".
  String get caption {
    final r = 'ECB ${formatRate(rate.rate)}';
    final used = DateTime.tryParse(rate.ecbDate);
    if (used == null) return r;
    if (dated && requestedDate != rate.ecbDate) {
      final asked = DateTime.tryParse(requestedDate!);
      return '$r · ${weekdayDayMonth(used)}'
          '${asked == null ? '' : ' (no rate on ${weekdayDayMonth(asked)})'}';
    }
    if (cachedOffline) {
      return '$r (offline · cached ECB rate of ${dayMonth(used)})';
    }
    return '$r · ${dayMonthYear(used)}${pinned ? ' · pinned' : ''}';
  }
}

// ---------------------------------------------------------------------------
// Results
// ---------------------------------------------------------------------------

enum LineKind {
  blank,
  heading,
  value,
  error,

  /// A currency line waiting for, or unable to get, its ECB rate. Shown with
  /// a reason and left out of the total.
  needsRate,
}

class LineResult {
  final int index;
  final LineKind kind;
  final String? label;
  final double? value;
  final Tag? tag;

  /// Reason shown in place of the result for [LineKind.error] and
  /// [LineKind.needsRate].
  final String? message;
  final RateUse? rate;
  final bool isTotal;

  /// The name this line defines (`rent = 1200`), or null.
  final String? variable;

  /// A rate this undated line should be pinned to from now on.
  final RatePin? newPin;

  const LineResult({
    required this.index,
    required this.kind,
    this.label,
    this.value,
    this.tag,
    this.message,
    this.rate,
    this.isTotal = false,
    this.variable,
    this.newPin,
  });

  /// A plain-number variable (`nights = 3`) is a setting, not an amount:
  /// never summed, never reported as left out.
  bool get isSetting => variable != null && tag == null;

  /// 1-based line number, as shown in the gutter.
  int get number => index + 1;

  bool get hasValue => kind == LineKind.value && value != null;

  /// The result as displayed: `44.47 USD`, `3.6576 m`, `12`.
  String? get display => hasValue ? formatTagged(value!, tag) : null;

  /// The result for exports: no thousands separators.
  String? get plain => hasValue ? formatPlain(value!, tag) : null;
}

class SheetEvaluation {
  final List<LineResult> lines;

  /// The footer's currency or unit; null means plain numbers.
  final Tag? mainTag;
  final double total;

  /// How many results the total leaves out, and why.
  final int excludedCount;
  final String? excludedNote;

  /// Rates still to fetch.
  final Set<RateNeed> needs;

  /// Earliest ECB date among pinned undated lines, `YYYY-MM-DD`; null when
  /// the sheet has none (then there is nothing to re-price).
  final String? pinnedAsOf;

  /// Sums of the counted lines stamped PAID and PENDING (same rule as the
  /// total: only lines in [mainTag]).
  final double paid;
  final double pending;

  /// How many counted lines carry a stamp; 0 hides the paid/owed split.
  final int stampedCount;

  const SheetEvaluation({
    required this.lines,
    required this.mainTag,
    required this.total,
    required this.excludedCount,
    required this.excludedNote,
    required this.needs,
    required this.pinnedAsOf,
    this.paid = 0,
    this.pending = 0,
    this.stampedCount = 0,
  });

  bool get hasStamps => stampedCount > 0;
  String get paidDisplay => formatTagged(paid, mainTag);
  String get pendingDisplay => formatTagged(pending, mainTag);

  bool get hasValues => lines.any((l) => l.hasValue && !l.isTotal);

  String get totalDisplay => formatTagged(total, mainTag);
  String get totalPlain => formatPlain(total, mainTag);

  /// Pins to write back onto lines (index → pin).
  Map<int, RatePin> get newPins => {
        for (final l in lines)
          if (l.newPin != null) l.index: l.newPin!,
      };
}

// ---------------------------------------------------------------------------
// Formatting
// ---------------------------------------------------------------------------

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];
const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

String dayMonth(DateTime d) => '${d.day} ${_months[d.month - 1]}';
String dayMonthYear(DateTime d) => '${dayMonth(d)} ${d.year}';
String weekdayDayMonth(DateTime d) =>
    '${_weekdays[d.weekday - 1]} ${dayMonth(d)}';

/// A rate to five significant figures: 1.1551, 0.85598, 162.39.
String formatRate(double r) {
  var s = r.toStringAsPrecision(5);
  if (s.contains('e')) return r.toString();
  if (s.contains('.')) {
    s = s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }
  return s;
}

int _digitsFor(Tag? tag) => tag == null ? 6 : (tag.isCurrency ? 2 : 4);

/// The number part of [formatTagged]: `1,580.17`, `3.6576`, `12`.
String formatAmount(double v, Tag? tag) => tag != null && tag.isCurrency
    ? formatNumber(v, maxDigits: 2, minDigits: 2)
    : formatNumber(v, maxDigits: _digitsFor(tag));

/// `1,580.17 USD`, `3.6576 m`, `12`.
String formatTagged(double v, Tag? tag) {
  final n = formatAmount(v, tag);
  return tag == null ? n : '$n ${tag.label}';
}

/// [formatTagged] without thousands separators, for CSV.
String formatPlain(double v, Tag? tag) =>
    formatTagged(v, tag).replaceAll(',', '');

// ---------------------------------------------------------------------------
// Dates
// ---------------------------------------------------------------------------

const _monthNames = {
  'jan': 1, 'january': 1, 'feb': 2, 'february': 2, 'mar': 3, 'march': 3,
  'apr': 4, 'april': 4, 'may': 5, 'jun': 6, 'june': 6, 'jul': 7, 'july': 7,
  'aug': 8, 'august': 8, 'sep': 9, 'sept': 9, 'september': 9, 'oct': 10,
  'october': 10, 'nov': 11, 'november': 11, 'dec': 12, 'december': 12,
};

/// Reads `2026-09-14`, `14 Sep`, `14 Sep 2026`, `Sep 14`, `Sep 14, 2026`,
/// `today` or `yesterday`. A day and month with no year means the most recent
/// such day that is not in the future. Returns null when [s] is not a date.
DateTime? parseSheetDate(String s, DateTime today) {
  final t = s.trim().toLowerCase();
  final day0 = DateTime.utc(today.year, today.month, today.day);
  if (t == 'today') return day0;
  if (t == 'yesterday') return day0.subtract(const Duration(days: 1));

  DateTime? build(int y, int m, int d) {
    if (m < 1 || m > 12 || d < 1) return null;
    final dt = DateTime.utc(y, m, d);
    if (dt.month != m || dt.day != d) return null; // 31 Feb
    return dt;
  }

  DateTime? noYear(int m, int d) {
    final thisYear = build(day0.year, m, d);
    if (thisYear == null) {
      // 29 Feb: the most recent leap year.
      for (var y = day0.year - 1; y > day0.year - 8; y--) {
        final dt = build(y, m, d);
        if (dt != null) return dt;
      }
      return null;
    }
    return thisYear.isAfter(day0) ? build(day0.year - 1, m, d) : thisYear;
  }

  var m = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})$').firstMatch(t);
  if (m != null) {
    return build(
        int.parse(m.group(1)!), int.parse(m.group(2)!), int.parse(m.group(3)!));
  }
  m = RegExp(r'^(\d{1,2})(?:st|nd|rd|th)?\s+([a-z]+)\.?,?(?:\s+(\d{4}))?$')
      .firstMatch(t);
  if (m != null) {
    final month = _monthNames[m.group(2)!];
    if (month == null) return null;
    final d = int.parse(m.group(1)!);
    return m.group(3) == null
        ? noYear(month, d)
        : build(int.parse(m.group(3)!), month, d);
  }
  m = RegExp(r'^([a-z]+)\.?\s+(\d{1,2})(?:st|nd|rd|th)?,?(?:\s+(\d{4}))?$')
      .firstMatch(t);
  if (m != null) {
    final month = _monthNames[m.group(1)!];
    if (month == null) return null;
    final d = int.parse(m.group(2)!);
    return m.group(3) == null
        ? noYear(month, d)
        : build(int.parse(m.group(3)!), month, d);
  }
  return null;
}

// ---------------------------------------------------------------------------
// Evaluation
// ---------------------------------------------------------------------------

class _LineError implements Exception {
  final String message;
  const _LineError(this.message);
}

class _Tagged {
  final double value;
  final Tag? tag;
  const _Tagged(this.value, this.tag);
}

final _digit = RegExp(r'\d');
final _refWord = RegExp(r'#\d|\bprev\b', caseSensitive: false);
final _conversion = RegExp(
    r'^(.*?)\s+(?:on\s+(.+?)\s+)?(?:in|to)\s+(\S+)$',
    caseSensitive: false);
final _dateOnly = RegExp(r'^(.*?)\s+on\s+(.+)$', caseSensitive: false);
final _pctAdd = RegExp(r'^(.+?)\s*([+\-−])\s*(\d+(?:\.\d+)?)\s*%$');
final _pctOf =
    RegExp(r'^(\d+(?:\.\d+)?)\s*%\s+of\s+(.+)$', caseSensitive: false);
final _number = r'\d[\d,]*(?:\.\d+)?|\.\d+';

/// `rent = 1200`, `per_month = total_cost / 12`.
final _assignment = RegExp(r'^([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.+)$');
final _identifier = RegExp(r'\b[A-Za-z_][A-Za-z0-9_]*\b');

/// Words a variable may not be called: the sheet's own keywords and every
/// function or constant the evaluator understands.
const _reservedNames = {
  'prev', 'total', 'sum', 'of', 'in', 'on', 'to', 'x',
  'pi', 'e', 'sin', 'cos', 'tan', 'asin', 'acos', 'atan', 'sinh', 'cosh',
  'tanh', 'asinh', 'acosh', 'atanh', 'cbrt', 'log', 'ln', 'sqrt', 'exp',
  'abs', 'ceil', 'floor', 'round',
};

/// Why [name] can't be a variable, or null when it can.
String? variableNameProblem(String name) {
  final lower = name.toLowerCase();
  if (_reservedNames.contains(lower)) return '"$name" is a reserved word';
  if (_tagFor(name) != null) {
    return '"$name" is a unit or currency — pick another name';
  }
  return null;
}

/// Works out every line of a sheet.
///
/// [today] decides what "14 Sep" (no year) and "in the future" mean.
SheetEvaluation evaluateSheet(
  List<SheetLine> lines, {
  RateBook rates = const RateBook(),
  required DateTime today,
}) {
  var pass = _Pass(lines, rates, today, null).run();
  final main = _mainTag(pass);
  // A `total` line sums the lines that carry the footer's tag. The footer's
  // tag depends on every line, so a sheet with a total is worked out twice:
  // once to learn the tag, once with it.
  if (pass.any((r) => r.isTotal && r.tag != main)) {
    pass = _Pass(lines, rates, today, main).run(forced: true);
  }
  final summary = _summarise(pass, main);
  var paid = 0.0, pending = 0.0, stamped = 0;
  for (final r in pass) {
    if (r.isTotal || r.isSetting || !r.hasValue || r.tag != main) continue;
    switch (lines[r.index].stamp) {
      case LineStamp.paid:
        paid += r.value!;
        stamped++;
      case LineStamp.pending:
        pending += r.value!;
        stamped++;
      case null:
        break;
    }
  }
  if (stamped == 0) return summary;
  return SheetEvaluation(
    lines: summary.lines,
    mainTag: summary.mainTag,
    total: summary.total,
    excludedCount: summary.excludedCount,
    excludedNote: summary.excludedNote,
    needs: summary.needs,
    pinnedAsOf: summary.pinnedAsOf,
    paid: paid,
    pending: pending,
    stampedCount: stamped,
  );
}

Tag? _mainTag(List<LineResult> results) {
  final counts = <Tag, int>{};
  for (final r in results) {
    if (!r.hasValue || r.isTotal || r.tag == null) continue;
    counts[r.tag!] = (counts[r.tag!] ?? 0) + 1;
  }
  Tag? best;
  var bestCount = 0;
  // First occurrence wins a tie: iteration follows insertion order.
  counts.forEach((tag, n) {
    if (n > bestCount) {
      best = tag;
      bestCount = n;
    }
  });
  return best;
}

SheetEvaluation _summarise(List<LineResult> results, Tag? main) {
  var total = 0.0;
  var otherTag = 0;
  var waiting = 0;
  var untagged = 0;
  final otherTags = <Tag>{};
  final needs = <RateNeed>{};
  String? asOf;
  for (final r in results) {
    if (r.isTotal || r.isSetting) continue;
    if (r.kind == LineKind.needsRate) waiting++;
    if (r.hasValue) {
      // Only lines in the footer's currency or unit are added. A plain number
      // on a sheet of metres (a count of boxes, say) is left out and named,
      // never silently summed.
      if (r.tag == main) {
        total += r.value!;
      } else {
        otherTag++;
        if (r.tag != null) otherTags.add(r.tag!);
        if (r.tag == null) untagged++;
      }
    }
    final rate = r.rate;
    if (rate != null && !rate.dated) {
      final d = rate.rate.ecbDate;
      if (asOf == null || d.compareTo(asOf) < 0) asOf = d;
    }
  }
  for (final r in results) {
    final n = _needOf[r];
    if (n != null) needs.add(n);
  }
  final excluded = otherTag + waiting;
  String? note;
  if (excluded > 0) {
    final lines = excluded == 1 ? '1 line' : '$excluded lines';
    note = waiting == 0 && untagged == 0 && otherTags.length == 1
        ? 'Total excludes $lines in ${otherTags.single.label}'
        : waiting == 0 && otherTags.isEmpty
            ? 'Total excludes $lines with no ${main!.isCurrency ? 'currency' : 'unit'}'
            : 'Total excludes $lines';
  }
  return SheetEvaluation(
    lines: results,
    mainTag: main,
    total: total,
    excludedCount: excluded,
    excludedNote: note,
    needs: needs,
    pinnedAsOf: asOf,
  );
}

/// Rate needs, attached to results without widening their public shape.
final Expando<RateNeed> _needOf = Expando<RateNeed>('rateNeed');

class _Pass {
  _Pass(this.lines, this.rates, this.today, this.totalTag);

  final List<SheetLine> lines;
  final RateBook rates;
  final DateTime today;
  final Tag? totalTag;
  bool _forced = false;
  final List<LineResult> out = [];

  /// Variables defined so far (lower-case name → its line's result). A later
  /// definition of the same name takes over from that line on.
  final Map<String, LineResult> _vars = {};

  /// Names whose defining line has no value (an error, a rate still loading).
  final Map<String, int> _brokenVars = {};

  bool _mentionsVariable(String s) => _identifier
      .allMatches(s)
      .any((m) {
        final w = m.group(0)!.toLowerCase();
        return _vars.containsKey(w) || _brokenVars.containsKey(w);
      });

  List<LineResult> run({bool forced = false}) {
    _forced = forced;
    for (var i = 0; i < lines.length; i++) {
      out.add(_line(i));
    }
    return out;
  }

  LineResult _line(int i) {
    final t = lines[i].text.trim();
    if (t.isEmpty) return LineResult(index: i, kind: LineKind.blank);

    String? label;
    var body = t;
    final colon = t.indexOf(': ');
    if (colon > 0) {
      label = t.substring(0, colon).trim();
      body = t.substring(colon + 2).trim();
    } else if (t.endsWith(':')) {
      return LineResult(index: i, kind: LineKind.heading, label: t);
    }
    if (body.isEmpty) {
      return LineResult(index: i, kind: LineKind.heading, label: label ?? t);
    }

    final lower = body.toLowerCase();
    if (lower == 'total' || lower == 'sum') return _total(i, label);

    final assign = _assignment.firstMatch(body);
    if (assign != null) return _define(i, label, assign.group(1)!, assign.group(2)!.trim());

    if (!_digit.hasMatch(body) &&
        !_refWord.hasMatch(body) &&
        !_mentionsVariable(body) &&
        !isMathExpression(body)) {
      return LineResult(index: i, kind: LineKind.heading, label: t);
    }

    try {
      return _evaluateBody(i, label, body);
    } on _UnknownWord {
      // Prose with a number in it ("Trip to Rome 2026", "Q3 receipts") is a
      // heading, not a broken sum.
      return LineResult(index: i, kind: LineKind.heading, label: t);
    } on _LineError catch (e) {
      return LineResult(
          index: i, kind: LineKind.error, label: label, message: e.message);
    } on _NeedsRate catch (e) {
      final r = LineResult(
          index: i,
          kind: LineKind.needsRate,
          label: label,
          message: e.message);
      if (e.need != null) _needOf[r] = e.need!;
      return r;
    }
  }

  /// `name = expression`: works the expression out like any line and makes
  /// its result available by name to every line below.
  LineResult _define(int i, String? label, String name, String rhs) {
    final key = name.toLowerCase();
    final problem = variableNameProblem(name);
    LineResult r;
    if (problem != null) {
      r = LineResult(index: i, kind: LineKind.error, label: label, message: problem);
    } else {
      try {
        r = _evaluateBody(i, label ?? name, rhs);
        if (r.label == null) {
          r = LineResult(
              index: i,
              kind: r.kind,
              label: name,
              value: r.value,
              tag: r.tag,
              rate: r.rate,
              newPin: r.newPin);
        }
      } on _UnknownWord {
        r = LineResult(
            index: i,
            kind: LineKind.error,
            label: label ?? name,
            message: 'Unknown name in "$rhs"');
      } on _LineError catch (e) {
        r = LineResult(
            index: i, kind: LineKind.error, label: label ?? name, message: e.message);
      } on _NeedsRate catch (e) {
        r = LineResult(
            index: i,
            kind: LineKind.needsRate,
            label: label ?? name,
            message: e.message);
        if (e.need != null) _needOf[r] = e.need!;
      }
    }
    if (problem == null && r.hasValue) {
      r = LineResult(
          index: i,
          kind: r.kind,
          label: r.label,
          value: r.value,
          tag: r.tag,
          rate: r.rate,
          variable: name,
          newPin: r.newPin);
    }
    if (problem == null) {
      if (r.hasValue) {
        _vars[key] = r;
        _brokenVars.remove(key);
      } else {
        _vars.remove(key);
        _brokenVars[key] = i;
      }
    }
    return r;
  }

  LineResult _total(int i, String? label) {
    // First pass: the most common tag above this line. Second pass: the
    // footer's tag, whatever it turned out to be.
    final tag = _forced ? totalTag : _mainTag(out);
    var sum = 0.0;
    for (final r in out) {
      if (r.isTotal || r.isSetting || !r.hasValue) continue;
      if (r.tag == tag) sum += r.value!;
    }
    return LineResult(
        index: i,
        kind: LineKind.value,
        label: label ?? 'Total',
        value: sum,
        tag: tag,
        isTotal: true);
  }

  LineResult _evaluateBody(int i, String? label, String body) {
    final conv = _conversion.firstMatch(body);
    if (conv != null) {
      final target = _tagFor(conv.group(3)!);
      if (target != null) {
        if (target.error != null) throw _LineError(target.error!);
        final source = _expr(i, conv.group(1)!.trim());
        return _convert(i, label, source, target.tag!, conv.group(2));
      }
    }
    final dateOnly = _dateOnly.firstMatch(body);
    if (dateOnly != null && parseSheetDate(dateOnly.group(2)!, today) != null) {
      _Tagged? amount;
      try {
        amount = _expr(i, dateOnly.group(1)!);
      } catch (_) {}
      if (amount?.tag?.isCurrency ?? false) {
        throw const _LineError(
            'Add the currency to convert to, e.g. "… on 14 Sep in USD"');
      }
    }
    final v = _expr(i, body);
    return LineResult(
        index: i,
        kind: LineKind.value,
        label: label,
        value: _round(v.value, v.tag),
        tag: v.tag);
  }

  double _round(double v, Tag? tag) {
    if (tag == null || !tag.isCurrency) return v;
    return (v * 100).roundToDouble() / 100;
  }

  LineResult _convert(
      int i, String? label, _Tagged src, Tag target, String? dateText) {
    if (!target.isCurrency) {
      if (dateText != null) {
        throw const _LineError('A date only applies to currency lines');
      }
      final from = src.tag;
      if (from == null) {
        throw _LineError(
            'Say which unit to convert from, e.g. "12 ft in ${target.label}"');
      }
      if (from.isCurrency || from.unit!.category.id != target.unit!.category.id) {
        throw _LineError("Can't convert ${from.label} to ${target.label}");
      }
      final v =
          convert(src.value, from.unit!.unit.id, target.unit!.unit.id, target.unit!.category);
      if (!v.isFinite) throw const _LineError('Not a number');
      return LineResult(index: i, kind: LineKind.value, label: label, value: v, tag: target);
    }

    final from = src.tag;
    final quote = target.currency!;
    if (from == null) {
      throw _LineError(
          'Say which currency to convert from, e.g. "100 EUR in $quote"');
    }
    if (!from.isCurrency) {
      throw _LineError("Can't convert ${from.label} to $quote");
    }
    final base = from.currency!;

    if (dateText != null) {
      final date = parseSheetDate(dateText, today);
      if (date == null) throw _LineError('Can\'t read the date "$dateText"');
      if (date.isBefore(ecbFirstDate)) {
        throw const _LineError('ECB rates start on 4 Jan 1999');
      }
      final day0 = DateTime.utc(today.year, today.month, today.day);
      if (date.isAfter(day0)) {
        throw const _LineError('That date is in the future');
      }
      final requested = isoDate(date);
      if (base == quote) {
        return LineResult(
            index: i, kind: LineKind.value, label: label, value: src.value, tag: target);
      }
      final key = datedRateKey(requested, base, quote);
      final hit = rates.dated[key];
      if (hit != null) {
        final use = RateUse(rate: hit, requestedDate: requested);
        return LineResult(
            index: i,
            kind: LineKind.value,
            label: label,
            value: _round(src.value * hit.rate, target),
            tag: target,
            rate: use);
      }
      final failed = rates.datedFailures[key];
      final when = dayMonth(date);
      switch (failed) {
        case RateFailure.offline:
          throw _NeedsRate(
              'Needs a connection to get the ECB rate for $when',
              RateNeed(date: requested, base: base, quote: quote));
        case RateFailure.beforeEcb:
          throw const _LineError('ECB rates start on 4 Jan 1999');
        case RateFailure.future:
          throw const _LineError('That date is in the future');
        case RateFailure.unsupported:
          throw _LineError(noEcbRateMessage(isEcbCurrency(base) ? quote : base));
        case RateFailure.http:
          throw _LineError('Frankfurter returned no ECB rate for $when');
        case null:
          throw _NeedsRate('Getting the ECB rate for $when…',
              RateNeed(date: requested, base: base, quote: quote));
      }
    }

    if (base == quote) {
      return LineResult(
          index: i, kind: LineKind.value, label: label, value: src.value, tag: target);
    }
    final pin = lines[i].pin;
    if (pin != null && pin.matches(base, quote)) {
      final use = RateUse(
          rate: EcbRate(
              base: base, quote: quote, rate: pin.rate, ecbDate: pin.date),
          pinned: true);
      return LineResult(
          index: i,
          kind: LineKind.value,
          label: label,
          value: _round(src.value * pin.rate, target),
          tag: target,
          rate: use);
    }
    final table = rates.latest;
    final cross = table == null ? null : crossRateFrom(table, base, quote);
    if (cross == null) {
      throw _NeedsRate(
          rates.latestOffline || table != null
              ? "Needs a connection to get today's ECB rate"
              : "Getting today's ECB rate…",
          RateNeed(base: base, quote: quote));
    }
    final use = RateUse(rate: cross, cachedOffline: !table!.live);
    return LineResult(
      index: i,
      kind: LineKind.value,
      label: label,
      value: _round(src.value * cross.rate, target),
      tag: target,
      rate: use,
      newPin: RatePin(
          base: base, quote: quote, rate: cross.rate, date: cross.ecbDate),
    );
  }

  // ---- expressions --------------------------------------------------------

  _Tagged _expr(int i, String src) {
    final s = src.trim();
    if (s.isEmpty) throw const _LineError('Nothing to work out');

    final add = _pctAdd.firstMatch(s);
    if (add != null) {
      final base = _expr(i, add.group(1)!);
      final p = double.parse(add.group(3)!) / 100;
      final up = add.group(2) == '+';
      return _Tagged(base.value * (up ? 1 + p : 1 - p), base.tag);
    }
    final of = _pctOf.firstMatch(s);
    if (of != null) {
      final base = _expr(i, of.group(2)!);
      return _Tagged(base.value * double.parse(of.group(1)!) / 100, base.tag);
    }
    return _arith(i, s);
  }

  _Tagged _arith(int i, String src) {
    final tags = <Tag>[];
    var taggedOperands = 0;
    Tag? first;

    String place(double v, Tag? tag) {
      if (tag != null) {
        taggedOperands++;
        if (first == null) {
          first = tag;
        } else if (tag != first) {
          final a = first!, b = tag;
          if (a.isCurrency || b.isCurrency) {
            if (a.isCurrency && b.isCurrency) {
              throw _LineError(
                  "Can't mix ${a.label} and ${b.label} on one line — convert one first");
            }
            throw _LineError("Can't combine ${a.label} and ${b.label}");
          }
          if (a.unit!.category.id != b.unit!.category.id) {
            throw _LineError("Can't combine ${a.label} and ${b.label}");
          }
          // Same kind of unit: express it in the line's first unit.
          v = convert(v, b.unit!.unit.id, a.unit!.unit.id, a.unit!.category);
        }
        tags.add(tag);
      }
      final lit = v.toString().contains('e') ? v.toStringAsFixed(20) : v.toString();
      return '($lit)';
    }

    var s = src;

    // References.
    s = s.replaceAllMapped(RegExp(r'#(\d+)'), (m) {
      final n = int.parse(m.group(1)!);
      final r = _ref(i, n - 1, '#$n');
      return place(r.value!, r.tag);
    });
    s = s.replaceAllMapped(RegExp(r'\bprev\b', caseSensitive: false), (m) {
      if (i == 0) throw const _LineError('There is no line above');
      final r = _ref(i, i - 1, 'prev');
      return place(r.value!, r.tag);
    });
    // Named variables defined on lines above.
    if (_vars.isNotEmpty || _brokenVars.isNotEmpty) {
      s = s.replaceAllMapped(_identifier, (m) {
        final word = m.group(0)!;
        final key = word.toLowerCase();
        final v = _vars[key];
        if (v != null) return place(v.value!, v.tag);
        final broken = _brokenVars[key];
        if (broken != null) {
          throw _LineError('"$word" (line ${broken + 1}) has no value');
        }
        return word;
      });
    }

    // Currency symbol before or after a number: €38.50, 38.50€.
    s = s.replaceAllMapped(
        RegExp('([€£\\\$¥₹₩])\\s*($_number)'),
        (m) => place(_num(m.group(2)!), _tagFor(m.group(1)!)!.tag));
    s = s.replaceAllMapped(RegExp('($_number)\\s*([€£\\\$¥₹₩])'),
        (m) => place(_num(m.group(1)!), _tagFor(m.group(2)!)!.tag));

    // A number followed by a currency code or unit: 38.50 EUR, 12 ft, 3'.
    s = s.replaceAllMapped(
        RegExp('($_number)\\s*([A-Za-z°][A-Za-z°/0-9²³]*|\'|"|′|″)'), (m) {
      final word = m.group(2)!;
      final t = _tagFor(word);
      if (t == null) return m.group(0)!; // sin, pi, e… left for lib_calc
      if (t.error != null) throw _LineError(t.error!);
      return place(_num(m.group(1)!), t.tag);
    });
    // A bare non-ECB code anywhere: give the specific reason.
    for (final m in RegExp(r'\b[A-Za-z]{3}\b').allMatches(s)) {
      final code = m.group(0)!.toUpperCase();
      if (nonEcbCurrencies.contains(code)) {
        throw _LineError(noEcbRateMessage(code));
      }
    }

    if (taggedOperands > 1 && RegExp(r'[*/^×÷]|\bx\b').hasMatch(s)) {
      throw const _LineError(
          'Only one amount on a line can carry a unit when multiplying or dividing');
    }

    s = _argCommas(s)
        .replaceAll('×', '*')
        .replaceAll('÷', '/')
        .replaceAll('−', '-')
        .replaceAllMapped(RegExp(r'(\d|\))\s*[xX]\s*(?=[\d(])'),
            (m) => '${m.group(1)}*')
        .replaceAllMapped(RegExp(r'(\d),(?=\d{3}\b)'), (m) => m.group(1)!)
        // A bare percentage is a fraction: 18% → (18/100). `10 % 3` (modulo)
        // keeps its operand.
        .replaceAllMapped(
            RegExp(r'(\d+(?:\.\d+)?)\s*%(?!\s*[\d(.])'), (m) => '(${m.group(1)}/100)');

    double v;
    try {
      v = evaluate(s);
    } on CalcError catch (e) {
      if (e.friendly) throw _LineError(e.message);
      final word = RegExp(r'Unsupported function (\w+)').firstMatch(e.message);
      if (word != null && word.group(1)!.length >= 3) {
        throw const _UnknownWord();
      }
      throw _LineError(_explain(e.message));
    } catch (_) {
      throw const _LineError("Can't work this line out");
    }
    if (!v.isFinite) throw const _LineError('Not a number (division by zero?)');
    return _Tagged(v, first);
  }

  double _num(String s) => double.parse(s.replaceAll(',', ''));

  /// Inside a function's brackets a comma separates arguments —
  /// `log(8,2)`, `nCr(10,100)` — so it must not be read as a thousands
  /// separator. Those commas become `;`, which the evaluator also accepts.
  static String _argCommas(String s) {
    final out = StringBuffer();
    final inCall = <bool>[];
    for (var i = 0; i < s.length; i++) {
      final c = s[i];
      if (c == '(') {
        final name = RegExp(r'([A-Za-z]+\d*)\s*$')
            .firstMatch(s.substring(0, i))
            ?.group(1)
            ?.toLowerCase();
        inCall.add(name != null && mathFunctions.contains(name));
      } else if (c == ')') {
        if (inCall.isNotEmpty) inCall.removeLast();
      } else if (c == ',' && inCall.isNotEmpty && inCall.last) {
        out.write(';');
        continue;
      }
      out.write(c);
    }
    return out.toString();
  }

  LineResult _ref(int i, int target, String name) {
    if (target < 0 || target >= lines.length) {
      throw _LineError('$name: there is no line ${target + 1}');
    }
    if (target == i) throw _LineError('$name refers to this line');
    if (target > i) throw _LineError('$name is below this line');
    final r = out[target];
    if (!r.hasValue) {
      throw _LineError('Line ${target + 1} has no result');
    }
    return r;
  }

  String _explain(String m) {
    final ch = RegExp(r'Unexpected char (.)').firstMatch(m);
    if (ch != null) return 'Unknown symbol "${ch.group(1)}"';
    final fn = RegExp(r'Unsupported function (\w+)').firstMatch(m);
    if (fn != null) return 'Unknown word "${fn.group(1)}"';
    if (m.contains('paren')) return 'Brackets do not match';
    return "Can't work this line out";
  }
}

class _UnknownWord implements Exception {
  const _UnknownWord();
}

class _NeedsRate implements Exception {
  final String message;
  final RateNeed? need;
  const _NeedsRate(this.message, this.need);
}

/// The rate needed by a [LineKind.needsRate] result, if any.
RateNeed? rateNeedOf(LineResult r) => _needOf[r];
