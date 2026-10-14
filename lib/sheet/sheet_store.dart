import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../lib_currency.dart';
import 'sheet_model.dart';

/// On-device persistence for sheets and the ECB rate cache. Nothing here
/// leaves the device.
class SheetStore {
  SheetStore(this.prefs);

  final SharedPreferences prefs;

  /// `[{id, title, createdAt, updatedAt, lines:[{text, pin?}]}]`
  static const kSheets = 'sheets_v1';
  static const kLastSheet = 'last_sheet_v1';

  /// The old Notes tab's key. Read once for the migration and then left
  /// untouched for this release, so nothing a Play user wrote is lost.
  static const kNotes = 'notes';
  static const kNotesMigrated = 'notes_migrated_v1';

  /// Dated ECB rates, `date|BASE|QUOTE` → rate. Published rates never change.
  static const kRateCache = 'ecb_rates_v1';

  List<Sheet> loadSheets() {
    final raw = prefs.getString(kSheets);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw);
      if (list is! List) return [];
      return [
        for (final s in list)
          if (Sheet.fromJson(s) case final Sheet sheet) sheet,
      ];
    } catch (_) {
      return [];
    }
  }

  /// Saves every sheet that has something on it; blank sheets are not kept.
  Future<void> saveSheets(Iterable<Sheet> sheets) async {
    final keep = [
      for (final s in sheets)
        if (!s.isBlank) s.toJson(),
    ];
    await prefs.setString(kSheets, jsonEncode(keep));
  }

  String? get lastSheetId => prefs.getString(kLastSheet);
  Future<void> setLastSheetId(String id) => prefs.setString(kLastSheet, id);

  Map<String, EcbRate> loadRateCache() {
    final raw = prefs.getString(kRateCache);
    if (raw == null) return {};
    try {
      final map = jsonDecode(raw);
      if (map is! Map) return {};
      return {
        for (final e in map.entries)
          if (e.key is String && EcbRate.fromJson(e.value) != null)
            e.key as String: EcbRate.fromJson(e.value)!,
      };
    } catch (_) {
      return {};
    }
  }

  Future<void> saveRateCache(Map<String, EcbRate> cache) => prefs.setString(
      kRateCache,
      jsonEncode({for (final e in cache.entries) e.key: e.value.toJson()}));

  Future<void> clearRateCache() => prefs.remove(kRateCache);

  /// Moves the old Notes into sheets, once: each note becomes a sheet with the
  /// note's title and one line per body line. Returns how many were added.
  ///
  /// Idempotent twice over: the `notes_migrated_v1` flag stops a second run,
  /// and each migrated sheet's id is derived from its note's id, so even a
  /// run interrupted before the flag was written cannot duplicate a note.
  /// The `notes` key itself is never modified.
  Future<int> migrateNotes() async {
    if (prefs.getBool(kNotesMigrated) ?? false) return 0;
    final raw = prefs.getString(kNotes);
    var added = 0;
    if (raw != null) {
      List<dynamic> notes;
      try {
        final decoded = jsonDecode(raw);
        notes = decoded is List ? decoded : const [];
      } catch (_) {
        notes = const [];
      }
      final sheets = loadSheets();
      final ids = {for (final s in sheets) s.id};
      for (final n in notes) {
        if (n is! Map) continue;
        final noteId = n['id'];
        if (noteId is! String) continue;
        final id = 'note-$noteId';
        if (ids.contains(id)) continue;
        final title = n['title'] is String ? n['title'] as String : '';
        final body = n['body'] is String ? n['body'] as String : '';
        final created = n['createdAt'] is num ? (n['createdAt'] as num).toInt() : 0;
        final updated = n['updatedAt'] is num ? (n['updatedAt'] as num).toInt() : created;
        final lines = body.split('\n').map((l) => SheetLine(l)).toList();
        sheets.add(Sheet(
          id: id,
          title: title,
          createdAt: created,
          updatedAt: updated,
          lines: lines.isEmpty ? [const SheetLine('')] : lines,
        ));
        ids.add(id);
        added++;
      }
      await saveSheets(sheets);
    }
    await prefs.setBool(kNotesMigrated, true);
    return added;
  }
}
