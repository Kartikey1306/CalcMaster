import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:calcmaster/sheet/sheet_model.dart';
import 'package:calcmaster/sheet/sheet_store.dart';
import 'package:calcmaster/sheet/sheets_controller.dart';

import 'support/fake_rates.dart';

/// Sheets persistence (spec M1): `sheets_v1`, autosave, the Sheets list
/// operations, and the one-time move of the old Notes into sheets.
String _notesJson(int n) => jsonEncode([
      for (var i = 0; i < n; i++)
        {
          'id': 'n$i',
          'title': 'Note $i',
          'body': 'Groceries: 12 + 8\nline two of $i',
          'createdAt': 1000 + i,
          'updatedAt': 2000 + i,
        }
    ]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<SheetsController> open(Map<String, Object> prefs) async {
    SharedPreferences.setMockInitialValues(prefs);
    final c = SheetsController(
        rates: FakeRates(), saveDelay: const Duration(milliseconds: 1));
    await c.init();
    return c;
  }

  group('notes migration', () {
    for (final n in [0, 1, 3]) {
      test('$n note(s) become $n sheet(s), once', () async {
        SharedPreferences.setMockInitialValues(
            {if (n > 0) 'notes': _notesJson(n)});
        final prefs = await SharedPreferences.getInstance();
        final store = SheetStore(prefs);

        expect(await store.migrateNotes(), n);
        var sheets = store.loadSheets();
        expect(sheets, hasLength(n));
        for (var i = 0; i < n; i++) {
          final s = sheets.firstWhere((s) => s.id == 'note-n$i');
          expect(s.title, 'Note $i');
          expect(s.lines.map((l) => l.text),
              ['Groceries: 12 + 8', 'line two of $i']);
          expect(s.updatedAt, 2000 + i);
        }
        expect(prefs.getBool(SheetStore.kNotesMigrated), isTrue);

        // Running it again adds nothing…
        expect(await store.migrateNotes(), 0);
        expect(store.loadSheets(), hasLength(n));
        // …and the old key is left exactly as it was for this release.
        if (n > 0) expect(prefs.getString('notes'), _notesJson(n));
      });
    }

    test('an interrupted run (flag never written) cannot duplicate notes',
        () async {
      SharedPreferences.setMockInitialValues({'notes': _notesJson(3)});
      final prefs = await SharedPreferences.getInstance();
      await SheetStore(prefs).migrateNotes();
      await prefs.remove(SheetStore.kNotesMigrated);
      expect(await SheetStore(prefs).migrateNotes(), 0);
      expect(SheetStore(prefs).loadSheets(), hasLength(3));
    });

    test('the app opens on a migrated note', () async {
      final c = await open({'notes': _notesJson(1)});
      expect(c.current.title, 'Note 0');
      expect(c.evaluation().lines.first.display, '20');
      c.dispose();
    });
  });

  group('persist and reload', () {
    test('a sheet is saved under sheets_v1 and comes back as it was',
        () async {
      final c = await open({});
      c.setLineText(0, 'Trip');
      c.insertLine(1, '12 ft in m');
      c.rename(c.current.id, 'DIY shelf');
      await c.flush();
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonDecode(prefs.getString(SheetStore.kSheets)!) as List;
      expect(raw.single['title'], 'DIY shelf');
      expect(raw.single['lines'], [
        {'text': 'Trip'},
        {'text': '12 ft in m'},
      ]);
      c.dispose();

      // "Relaunch" with the same storage: the last sheet opens again and its
      // results are recomputed, not stored.
      final again = SheetsController(rates: FakeRates());
      await again.init(prefs: prefs);
      expect(again.current.title, 'DIY shelf');
      expect(again.evaluation().lines[1].display, '3.6576 m');
      again.dispose();
    });

    test('autosave happens without an explicit flush', () async {
      final c = await open({});
      c.setLineText(0, '1 + 1');
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(SheetStore.kSheets), contains('1 + 1'));
      c.dispose();
    });

    test('a pinned rate is saved with its line', () async {
      final c = await open({});
      c.setLineText(0, 'x');
      final s = c.current;
      // Simulate a pinned line as the evaluator would leave it.
      c.restore(s.copyWith(id: 'p', lines: [
        const SheetLine('100 EUR in USD',
            pin: RatePin(base: 'EUR', quote: 'USD', rate: 1.1181, date: '2026-10-12')),
      ]));
      await c.flush();
      final prefs = await SharedPreferences.getInstance();
      final saved = SheetStore(prefs).loadSheets().firstWhere((s) => s.id == 'p');
      expect(saved.lines.single.pin!.rate, 1.1181);
      expect(saved.lines.single.pin!.date, '2026-10-12');
      c.dispose();
    });

    test('blank sheets are not kept', () async {
      final c = await open({});
      c.newSheet();
      await c.flush();
      expect(c.savedSheets(), isEmpty);
      c.dispose();
    });
  });

  group('the Sheets list', () {
    late SheetsController c;
    setUp(() async {
      c = await open({});
      c.setLineText(0, 'Lisbon trip');
      c.insertLine(1, '38.50 EUR');
      await Future<void>.delayed(const Duration(milliseconds: 2));
      c.newSheet();
      c.setLineText(0, 'Shelf');
      c.insertLine(1, '12 ft in m');
    });
    tearDown(() => c.dispose());

    test('newest edit first', () {
      expect(c.savedSheets().map((s) => s.displayTitle),
          ['Shelf', 'Lisbon trip']);
    });

    test('search covers titles and line text', () {
      expect(c.savedSheets(query: 'lisbon').map((s) => s.displayTitle),
          ['Lisbon trip']);
      expect(c.savedSheets(query: 'ft in').map((s) => s.displayTitle),
          ['Shelf']);
      expect(c.savedSheets(query: 'nothing like this'), isEmpty);
    });

    test('rename and duplicate', () {
      final id = c.savedSheets().last.id;
      c.rename(id, 'Lisbon, Sept');
      final copy = c.duplicate(id)!;
      expect(copy.displayTitle, 'Lisbon, Sept (copy)');
      expect(copy.lines.map((l) => l.text), ['Lisbon trip', '38.50 EUR']);
      expect(c.savedSheets(), hasLength(3));
    });

    test('delete, then Undo puts it back', () async {
      final target = c.savedSheets().last;
      final removed = c.delete(target.id)!;
      expect(c.savedSheets().map((s) => s.id), isNot(contains(target.id)));
      c.restore(removed);
      expect(c.savedSheets().map((s) => s.id), contains(target.id));
      await c.flush();
      final prefs = await SharedPreferences.getInstance();
      expect(SheetStore(prefs).loadSheets().map((s) => s.id),
          contains(target.id));
    });

    test('deleting the open sheet opens the next one', () {
      final open = c.current.id;
      c.delete(open);
      expect(c.current.id, isNot(open));
      expect(c.current.displayTitle, 'Lisbon trip');
    });
  });
}
