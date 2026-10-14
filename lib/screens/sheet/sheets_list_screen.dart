import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../sheet/sheet_engine.dart';
import '../../sheet/sheet_model.dart';
import '../../sheet/sheets_controller.dart';
import '../../theme/tokens.dart';
import '../../widgets/banner_ad_slot.dart';
import 'rename_dialog.dart';

/// Phone route: every saved sheet, newest edit first. The banner ad lives
/// here (and on Tools), never on the sheet itself.
class SheetsListScreen extends StatelessWidget {
  const SheetsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.ledger;
    return Scaffold(
      backgroundColor: c.paper,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back to the sheet',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        title: Text(AppLocalizations.of(context)!.sheetsTitle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: c.rule),
        ),
      ),
      body: SafeArea(
        child: SheetsListPane(
          onOpened: () => context.canPop() ? context.pop() : context.go('/'),
        ),
      ),
      bottomNavigationBar: const SafeArea(top: false, child: BannerAdSlot()),
    );
  }
}

/// The list itself: search, new sheet, and per-sheet rename, duplicate and
/// delete (with Undo). Also used as the left pane on wide windows.
class SheetsListPane extends StatefulWidget {
  /// Called after a sheet was opened.
  final VoidCallback onOpened;
  const SheetsListPane({super.key, required this.onOpened});

  @override
  State<SheetsListPane> createState() => _SheetsListPaneState();
}

class _SheetsListPaneState extends State<SheetsListPane> {
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _rename(Sheet sheet) async {
    final title = await RenameSheetDialog.show(context,
        title: 'Rename sheet',
        current: sheet.title,
        placeholder: sheet.displayTitle);
    if (title == null || !mounted) return;
    context.read<SheetsController>().rename(sheet.id, title);
  }

  void _delete(Sheet sheet) {
    final sheets = context.read<SheetsController>();
    final removed = sheets.delete(sheet.id);
    if (removed == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('Deleted “${removed.displayTitle}”'),
        action: SnackBarAction(
            label: AppLocalizations.of(context)!.sheetUndo,
            onPressed: () => sheets.restore(removed)),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final sheets = context.watch<SheetsController>();
    final c = context.ledger;
    final list = sheets.savedSheets(query: _search.text);
    final currentId = sheets.current.id;
    final searching = _search.text.trim().isNotEmpty;

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(
            Spacing.lg, Spacing.md, Spacing.lg, Spacing.sm),
        child: Row(children: [
          Expanded(
            child: Semantics(
              label: 'Search sheets',
              textField: true,
              child: TextField(
                controller: _search,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  isDense: true,
                  prefixIcon: Icon(Icons.search, color: c.inkSoft),
                  hintText: AppLocalizations.of(context)!.sheetsSearchHint,
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: Spacing.md, horizontal: Spacing.sm),
                ),
              ),
            ),
          ),
          const SizedBox(width: Spacing.sm),
          FilledButton.icon(
            onPressed: () {
              sheets.newSheet();
              widget.onOpened();
            },
            icon: const Icon(Icons.add, size: 18),
            label: Text(AppLocalizations.of(context)!.sheetsNew),
          ),
        ]),
      ),
      Divider(height: 1, color: c.rule),
      Expanded(
        child: list.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(Spacing.xxl),
                  child: Text(
                    searching
                        ? 'No sheet matches “${_search.text.trim()}”.'
                        : AppLocalizations.of(context)!.sheetsEmpty,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: c.inkSoft, fontSize: 15),
                  ),
                ),
              )
            : ListView.separated(
                itemCount: list.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: c.rule),
                itemBuilder: (context, i) {
                  final s = list[i];
                  return _SheetTile(
                    sheet: s,
                    total: sheets.evaluation(s.id),
                    current: s.id == currentId,
                    onOpen: () {
                      sheets.open(s.id);
                      widget.onOpened();
                    },
                    onRename: () => _rename(s),
                    onDuplicate: () => sheets.duplicate(s.id),
                    onDelete: () => _delete(s),
                  );
                },
              ),
      ),
    ]);
  }
}

class _SheetTile extends StatelessWidget {
  final Sheet sheet;
  final SheetEvaluation total;
  final bool current;
  final VoidCallback onOpen;
  final VoidCallback onRename;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  const _SheetTile({
    required this.sheet,
    required this.total,
    required this.current,
    required this.onOpen,
    required this.onRename,
    required this.onDuplicate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.ledger;
    final lines = sheet.lines.where((l) => l.text.trim().isNotEmpty).length;
    final edited = DateTime.fromMillisecondsSinceEpoch(sheet.updatedAt);
    final subtitle = [
      '$lines ${lines == 1 ? 'line' : 'lines'}',
      'edited ${dayMonthYear(edited)}',
      if (total.hasValues) 'total ${total.totalDisplay}',
    ].join(' · ');
    return Material(
      color: current ? c.primary.withValues(alpha: 0.08) : Colors.transparent,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.only(left: Spacing.lg),
          child: Row(children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: Spacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sheet.displayTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: c.ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: c.inkSoft, fontSize: 13)),
                  ],
                ),
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'Sheet actions for ${sheet.displayTitle}',
              onSelected: (a) => switch (a) {
                'rename' => onRename(),
                'duplicate' => onDuplicate(),
                'delete' => onDelete(),
                _ => null,
              },
              itemBuilder: (_) {
                final loc = AppLocalizations.of(context)!;
                return [
                  PopupMenuItem(value: 'rename', child: Text(loc.sheetRename)),
                  PopupMenuItem(
                      value: 'duplicate', child: Text(loc.sheetDuplicate)),
                  PopupMenuItem(value: 'delete', child: Text(loc.sheetDelete)),
                ];
              },
            ),
          ]),
        ),
      ),
    );
  }
}
