import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/generated/app_localizations.dart';
import '../sheet/add_to_sheet.dart';
import '../theme/tokens.dart';
import 'receipt_tear_off.dart';

class InnerScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget> actions;

  /// The line "Add to sheet" appends, or null while the tool has nothing to
  /// add yet. Leave the whole callback null for a tool that never adds to a
  /// sheet (BMI) — then there is no button at all.
  final String? Function()? sheetLine;

  /// Analytics name of the tool, for "add to sheet".
  final String? tool;

  /// Put "Add to sheet" in the title row instead of a bar along the bottom —
  /// for full-height keypads that need every pixel.
  final bool addInHeader;

  const InnerScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.actions = const [],
    this.sheetLine,
    this.tool,
    this.addInHeader = false,
  });

  @override
  Widget build(BuildContext context) {
    final line = sheetLine?.call();
    void add() {
      if (line == null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(
              content: Text('Enter values first — there is nothing to add yet')));
        return;
      }
      addLineToSheet(context, line, tool: tool ?? title);
      playReceiptTearOff(context, line);
    }

    return Scaffold(
      backgroundColor: context.ledger.paper,
      bottomNavigationBar: sheetLine == null || addInHeader
          ? null
          : SafeArea(
              top: false,
              child: Container(
                decoration: BoxDecoration(
                  color: context.ledger.paper,
                  border: Border(top: BorderSide(color: context.ledger.rule)),
                ),
                padding: const EdgeInsets.fromLTRB(
                    Spacing.lg, Spacing.sm, Spacing.lg, Spacing.sm),
                child: Align(
                  heightFactor: 1,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.playlist_add, size: 20),
                        label: Text(AppLocalizations.of(context)?.sheetAddToSheet ??
                            'Add to sheet'),
                        onPressed: add,
                      ),
                    ),
                  ),
                ),
              ),
            ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
              Spacing.lg, Spacing.sm, Spacing.lg, Spacing.xxl),
          // Single-task forms read best in a comfortable column rather than
          // stretched across a wide desktop window.
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Go back',
                        icon: Icon(Icons.chevron_left,
                            color: context.ledger.ink, size: 28),
                        onPressed: () => context.pop(),
                      ),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                              color: context.ledger.ink,
                              fontSize: 22,
                              fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      ...actions,
                      if (sheetLine != null && addInHeader)
                        IconButton(
                          tooltip: AppLocalizations.of(context)
                                  ?.sheetAddToSheet ??
                              'Add to sheet',
                          icon: Icon(Icons.playlist_add,
                              color: context.ledger.primary),
                          onPressed: add,
                        ),
                    ],
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: EdgeInsets.only(left: 36, top: 2),
                      child: Text(subtitle!,
                          style: TextStyle(
                              color: context.ledger.inkSoft, fontSize: 13)),
                    ),
                  SizedBox(height: Spacing.md),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
