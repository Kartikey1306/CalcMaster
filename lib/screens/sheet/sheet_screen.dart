import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../sheet/sheet_engine.dart';
import '../../sheet/sheet_export.dart';
import '../../sheet/sheet_model.dart';
import '../../sheet/sheet_share.dart';
import '../../sheet/sheets_controller.dart';
import '../../sheet/smart_suggest.dart';
import '../../lib_tax.dart' show customaryTipPercent;
import '../../state/region_provider.dart';
import '../../theme/tokens.dart';
import 'rename_dialog.dart';
import 'ruled_paper.dart';
import 'sheets_list_screen.dart';

/// Grey example lines on an empty first sheet. They are placeholders only:
/// never saved, gone as soon as the user types.
const sheetHints = <String>[
  'Dinner: 38.50 EUR on 14 Sep in USD',
  '12 ft in m',
  '#1 + 18%',
  'total',
];

/// Home: the sheet being worked on. On a wide window (unfolded foldable,
/// tablet, desktop) the Sheets list sits beside it.
class SheetScreen extends StatelessWidget {
  const SheetScreen({super.key});

  /// At or above this width the Sheets list is shown as a left pane.
  static const double twoPaneBreakpoint = 840;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= twoPaneBreakpoint;
      if (!wide) return const SheetEditor(showSheetsButton: true);
      return Scaffold(
        backgroundColor: context.ledger.paper,
        body: Row(children: [
          SizedBox(
            width: 320,
            child: SafeArea(
              right: false,
              child: SheetsListPane(
                  onOpened: () {}, key: const ValueKey('sheets-pane')),
            ),
          ),
          VerticalDivider(width: 1, color: context.ledger.rule),
          const Expanded(child: SheetEditor(showSheetsButton: false)),
        ]),
      );
    });
  }
}

class SheetEditor extends StatefulWidget {
  final bool showSheetsButton;
  const SheetEditor({super.key, required this.showSheetsButton});

  @override
  State<SheetEditor> createState() => _SheetEditorState();
}

class _SheetEditorState extends State<SheetEditor> {
  final List<TextEditingController> _ctrls = [];
  final List<FocusNode> _nodes = [];
  String? _sheetId;
  int? _focused;
  final _moreKey = GlobalKey();

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  FocusNode _newNode() {
    final node = FocusNode();
    node.addListener(() {
      if (!mounted) return;
      final i = _nodes.indexOf(node);
      if (node.hasFocus) {
        setState(() => _focused = i);
      } else if (_focused == i) {
        // Keep the key row while focus moves to another line; drop it once
        // nothing on the sheet has focus.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_nodes.any((n) => n.hasFocus)) {
            setState(() => _focused = null);
          }
        });
      }
    });
    return node;
  }

  /// Keeps one controller and focus node per line, in step with the sheet.
  void _sync(Sheet sheet) {
    if (_sheetId != sheet.id) {
      for (final c in _ctrls) {
        c.dispose();
      }
      for (final n in _nodes) {
        n.dispose();
      }
      _ctrls.clear();
      _nodes.clear();
      _sheetId = sheet.id;
      _focused = null;
    }
    while (_ctrls.length < sheet.lines.length) {
      _ctrls.add(TextEditingController());
      _nodes.add(_newNode());
    }
    while (_ctrls.length > sheet.lines.length) {
      _ctrls.removeLast().dispose();
      _nodes.removeLast().dispose();
    }
    for (var i = 0; i < sheet.lines.length; i++) {
      final text = sheet.lines[i].text;
      if (_ctrls[i].text != text) {
        _ctrls[i].value = TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
      }
    }
  }

  void _focusLine(int i) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || i >= _nodes.length) return;
      _nodes[i].requestFocus();
    });
  }

  void _insertAtCursor(String insert) {
    final i = _focused;
    if (i == null || i >= _ctrls.length) return;
    final c = _ctrls[i];
    final sel = c.selection;
    final text = c.text;
    final start = sel.isValid ? sel.start : text.length;
    final end = sel.isValid ? sel.end : text.length;
    final next = text.replaceRange(start, end, insert);
    c.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: start + insert.length),
    );
    context.read<SheetsController>().setLineText(i, next);
  }

  void _onSubmitted(int i) {
    final sheets = context.read<SheetsController>();
    sheets.insertLine(i + 1);
    _focusLine(i + 1);
  }

  /// Smart suggestions for the line being typed — only while the sheet can't
  /// work it out as written ("finner 18 eurp for 2 peoer").
  List<SmartSuggestion> _suggestionsFor(
      String text, LineResult? r, RegionProvider regions) {
    if (text.trim().isEmpty) return const [];
    if (r != null && r.kind != LineKind.heading && r.kind != LineKind.error) {
      return const [];
    }
    return suggestLines(text,
        homeCurrency: regions.region.currency,
        customaryTip: customaryTipPercent[regions.regionId]);
  }

  void _applySuggestion(int i, String line) {
    HapticFeedback.selectionClick();
    final ctrl = _ctrls[i];
    ctrl.value = TextEditingValue(
        text: line, selection: TextSelection.collapsed(offset: line.length));
    context.read<SheetsController>().setLineText(i, line);
  }

  void _stamp(int i, LineStamp? stamp) {
    final sheets = context.read<SheetsController>();
    final current = sheets.current.lines[i].stamp;
    // Stamping a line with the stamp it already has lifts it.
    final next = current == stamp ? null : stamp;
    sheets.setLineStamp(i, next);
    HapticFeedback.mediumImpact();
  }

  Future<void> _lineMenu(int i) async {
    final sheets = context.read<SheetsController>();
    final stamp = sheets.current.lines[i].stamp;
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.vertical_align_top),
            title: Text('Insert a line above line ${i + 1}'),
            onTap: () => Navigator.pop(ctx, 'above'),
          ),
          ListTile(
            leading: const Icon(Icons.vertical_align_bottom),
            title: Text('Insert a line below line ${i + 1}'),
            onTap: () => Navigator.pop(ctx, 'below'),
          ),
          if (stamp != LineStamp.paid)
            ListTile(
              leading: Icon(Icons.verified_outlined, color: ctx.ledger.primary),
              title: Text('Stamp line ${i + 1} PAID'),
              onTap: () => Navigator.pop(ctx, 'paid'),
            ),
          if (stamp != LineStamp.pending)
            ListTile(
              leading: Icon(Icons.schedule, color: ctx.ledger.result),
              title: Text('Stamp line ${i + 1} PENDING'),
              onTap: () => Navigator.pop(ctx, 'pending'),
            ),
          if (stamp != null)
            ListTile(
              leading: const Icon(Icons.layers_clear_outlined),
              title: const Text('Remove the stamp'),
              onTap: () => Navigator.pop(ctx, 'unstamp'),
            ),
          ListTile(
            leading: Icon(Icons.delete_outline, color: ctx.ledger.error),
            title: Text('Delete line ${i + 1}'),
            onTap: () => Navigator.pop(ctx, 'delete'),
          ),
        ]),
      ),
    );
    if (!mounted || choice == null) return;
    switch (choice) {
      case 'above':
        sheets.insertLine(i);
        _focusLine(i);
      case 'below':
        sheets.insertLine(i + 1);
        _focusLine(i + 1);
      case 'delete':
        sheets.removeLine(i);
      case 'paid':
        sheets.setLineStamp(i, LineStamp.paid);
      case 'pending':
        sheets.setLineStamp(i, LineStamp.pending);
      case 'unstamp':
        sheets.setLineStamp(i, null);
    }
  }

  Future<void> _rename(Sheet sheet) async {
    final title = await RenameSheetDialog.show(context,
        title: 'Sheet title',
        current: sheet.title,
        placeholder: sheet.displayTitle);
    if (title == null || !mounted) return;
    context.read<SheetsController>().rename(sheet.id, title);
  }

  Rect? _origin() {
    final box = _moreKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  Future<void> _reprice() async {
    final sheets = context.read<SheetsController>();
    final messenger = ScaffoldMessenger.of(context);
    final result = await sheets.reprice();
    final date = result.asOf == null ? null : DateTime.tryParse(result.asOf!);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(result.ok
            ? 'Re-priced at the ECB rates of ${date == null ? 'today' : dayMonthYear(date)}'
            : "Can't re-price offline — showing rates as of "
                '${date == null ? 'the last fetch' : dayMonth(date)}'),
      ));
  }

  Future<void> _menu(String action, Sheet sheet, SheetEvaluation eval) async {
    final sheets = context.read<SheetsController>();
    switch (action) {
      case 'new':
        sheets.newSheet();
        _focusLine(0);
      case 'text':
        final origin = _origin();
        await ExportPreviewSheet.show(
          context,
          title: AppLocalizations.of(context)!.sheetShareText,
          body: sheetAsText(sheet, eval),
          shareLabel: 'Share…',
          copyWhat: 'Sheet',
          share: () => SheetSharer.asText(context, sheet, eval, origin: origin),
        );
      case 'csv':
        final origin = _origin();
        await ExportPreviewSheet.show(
          context,
          title: AppLocalizations.of(context)!.sheetExportCsv,
          body: sheetAsCsv(sheet, eval),
          shareLabel: 'Share file…',
          copyWhat: 'CSV',
          share: () => SheetSharer.asCsv(context, sheet, eval, origin: origin),
        );
      case 'copy':
        await SheetSharer.copy(context, sheetAsText(sheet, eval));
      case 'reprice':
        await _reprice();
      case 'help':
        context.push('/help');
      case 'settings':
        context.push('/settings');
    }
  }

  @override
  Widget build(BuildContext context) {
    final sheets = context.watch<SheetsController>();
    final c = context.ledger;
    if (!sheets.ready) {
      return Scaffold(backgroundColor: c.paper);
    }
    final sheet = sheets.current;
    final eval = sheets.evaluation();
    final regions = context.watch<RegionProvider>();
    _sync(sheet);
    final fresh = sheet.lines.length == 1 &&
        sheet.lines.first.text.isEmpty &&
        sheet.title.isEmpty;
    final asOf =
        eval.pinnedAsOf == null ? null : DateTime.tryParse(eval.pinnedAsOf!);

    return Scaffold(
      backgroundColor: c.paper,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: widget.showSheetsButton ? 0 : 16,
        leading: widget.showSheetsButton
            ? IconButton(
                tooltip: AppLocalizations.of(context)!.sheetsTitle,
                icon: const Icon(Icons.library_books_outlined),
                onPressed: () => context.push('/sheets'),
              )
            : null,
        title: Semantics(
          button: true,
          label: 'Sheet title: ${sheet.displayTitle}',
          hint: 'Rename',
          excludeSemantics: true,
          child: InkWell(
            onTap: () => _rename(sheet),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(sheet.displayTitle,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: AppLocalizations.of(context)!.toolsTitle,
            icon: const Icon(Icons.calculate_outlined),
            onPressed: () => context.push('/tools'),
          ),
          PopupMenuButton<String>(
            key: _moreKey,
            tooltip: 'More',
            onSelected: (a) => _menu(a, sheet, eval),
            itemBuilder: (_) {
              final loc = AppLocalizations.of(context)!;
              return [
                PopupMenuItem(value: 'new', child: Text(loc.sheetNewSheet)),
                PopupMenuItem(value: 'text', child: Text(loc.sheetShareText)),
                PopupMenuItem(value: 'csv', child: Text(loc.sheetExportCsv)),
                PopupMenuItem(value: 'copy', child: Text(loc.sheetCopy)),
                if (asOf != null)
                  PopupMenuItem(
                      value: 'reprice', child: Text(loc.sheetReprice)),
                PopupMenuItem(value: 'help', child: Text(loc.helpHowLinesWork)),
                PopupMenuItem(
                    value: 'settings', child: Text(loc.settingsTitle)),
              ];
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: c.rule),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(children: [
          if (asOf != null) _RatesBanner(asOf: asOf, onReprice: _reprice),
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverList.builder(
                  itemCount: sheet.lines.length,
                  itemBuilder: (context, i) => _LineRow(
                    key: ValueKey('line-${sheet.id}-$i'),
                    index: i,
                    controller: _ctrls[i],
                    focusNode: _nodes[i],
                    result: i < eval.lines.length ? eval.lines[i] : null,
                    hint: fresh && i == 0 ? sheetHints.first : null,
                    stamp: sheet.lines[i].stamp,
                    onStamp: (st) => _stamp(i, st),
                    suggestions: _focused == i
                        ? _suggestionsFor(
                            sheet.lines[i].text,
                            i < eval.lines.length ? eval.lines[i] : null,
                            regions)
                        : const [],
                    onSuggestion: (line) => _applySuggestion(i, line),
                    onChanged: (t) => sheets.setLineText(i, t),
                    onSubmitted: () => _onSubmitted(i),
                    onGutter: () => _lineMenu(i),
                    onInsertRef: () {
                      if (_focused != null && _focused != i) {
                        _insertAtCursor('#${i + 1}');
                      } else {
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(SnackBar(
                              content: Text(
                                  'Tap another line first, then this result to insert #${i + 1}')));
                      }
                    },
                  ),
                ),
                if (fresh) ...[
                  for (final h in sheetHints.skip(1))
                    SliverToBoxAdapter(child: _HintRow(text: h)),
                  SliverToBoxAdapter(
                    child: RuledPaper(
                      child: Padding(
                        padding: const EdgeInsets.only(
                            left: RuledPaper.gutter + Spacing.xs),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: () => context.push('/help'),
                            child: Text(
                                AppLocalizations.of(context)!.helpHowLinesWork),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Semantics(
                    button: true,
                    label: 'Continue on the last line',
                    excludeSemantics: true,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      // Tapping the empty paper continues on the last line.
                      onTap: () => _focusLine(sheet.lines.length - 1),
                      child: const RuledPaper(
                          fill: true, child: SizedBox(height: 96)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_focused != null) _KeyRow(onKey: _insertAtCursor),
          _Footer(eval: eval),
        ]),
      ),
    );
  }
}

class _RatesBanner extends StatelessWidget {
  final DateTime asOf;
  final VoidCallback onReprice;
  const _RatesBanner({required this.asOf, required this.onReprice});

  @override
  Widget build(BuildContext context) {
    final c = context.ledger;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: Spacing.lg, right: Spacing.xs),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.rule)),
      ),
      child: Row(children: [
        Icon(Icons.push_pin_outlined, size: 16, color: c.inkSoft),
        const SizedBox(width: Spacing.sm),
        Expanded(
          child: Text(
              AppLocalizations.of(context)!.sheetRatesAsOf(dayMonthYear(asOf)),
              style: TextStyle(color: c.inkSoft, fontSize: 13)),
        ),
        TextButton(
            onPressed: onReprice,
            child: Text(AppLocalizations.of(context)!.sheetReprice)),
      ]),
    );
  }
}

class _LineRow extends StatelessWidget {
  final int index;
  final TextEditingController controller;
  final FocusNode focusNode;
  final LineResult? result;
  final String? hint;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;
  final VoidCallback onGutter;
  final VoidCallback onInsertRef;
  final LineStamp? stamp;
  final ValueChanged<LineStamp?> onStamp;
  final List<SmartSuggestion> suggestions;
  final ValueChanged<String> onSuggestion;

  const _LineRow({
    super.key,
    required this.index,
    required this.controller,
    required this.focusNode,
    required this.result,
    required this.hint,
    required this.onChanged,
    required this.onSubmitted,
    required this.onGutter,
    required this.onInsertRef,
    required this.stamp,
    required this.onStamp,
    required this.suggestions,
    required this.onSuggestion,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.ledger;
    final r = result;
    final n = index + 1;
    final caption = r?.rate?.caption;

    Widget? trailing;
    if (r != null && r.hasValue) {
      trailing = Semantics(
        container: true,
        button: true,
        label: 'Line $n result ${r.display}',
        hint: 'Tap to insert #$n into the line you are editing. '
            'Long press to copy.',
        excludeSemantics: true,
        child: InkWell(
          onTap: onInsertRef,
          onLongPress: () async {
            await Clipboard.setData(ClipboardData(text: r.display!));
            if (!context.mounted) return;
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text('Copied ${r.display}')));
          },
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            child: Align(
              alignment: Alignment.centerRight,
              widthFactor: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (stamp != null)
                    Padding(
                      padding: const EdgeInsets.only(right: Spacing.sm),
                      child: _RubberStamp(stamp: stamp!),
                    ),
                  Flexible(
                      child: Text(
                    r.display!,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontFamily: Fonts.figures,
                      fontFeatures: Fonts.tabular,
                      color: r.isTotal ? c.ink : c.result,
                      fontWeight: r.isTotal ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 16,
                    ),
                  )),
                ]),
              ),
            ),
          ),
        ),
      );
    } else if (r != null &&
        (r.kind == LineKind.error || r.kind == LineKind.needsRate)) {
      final isError = r.kind == LineKind.error;
      trailing = Semantics(
        container: true,
        label: 'Line $n: ${r.message}',
        excludeSemantics: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: Spacing.sm, vertical: Spacing.sm),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (!isError)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(Icons.cloud_off, size: 14, color: c.inkSoft),
              ),
            Flexible(
              child: Text(
                r.message ?? '',
                textAlign: TextAlign.end,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isError ? c.error : c.inkSoft,
                  fontSize: 13,
                  height: 1.25,
                ),
              ),
            ),
          ]),
        ),
      );
    }

    final row = RuledPaper(
      child: Padding(
        padding: const EdgeInsets.only(right: Spacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Semantics(
                  button: true,
                  label: 'Line $n options',
                  excludeSemantics: true,
                  child: InkWell(
                    onLongPress: onGutter,
                    onTap: onGutter,
                    child: SizedBox(
                      width: RuledPaper.gutter,
                      height: 48,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(right: Spacing.sm),
                          child: Text('$n',
                              style: TextStyle(
                                fontFamily: Fonts.figures,
                                fontFeatures: Fonts.tabular,
                                color: c.inkSoft,
                                fontSize: 13,
                              )),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: Semantics(
                    container: true,
                    label: 'Line $n',
                    textField: true,
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      onChanged: onChanged,
                      onSubmitted: (_) => onSubmitted(),
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.text,
                      // Long lines wrap; the action key still moves on to a
                      // new line instead of typing a line break.
                      minLines: 1,
                      maxLines: null,
                      autocorrect: false,
                      enableSuggestions: false,
                      smartDashesType: SmartDashesType.disabled,
                      smartQuotesType: SmartQuotesType.disabled,
                      style: TextStyle(
                        fontFamily: Fonts.figures,
                        fontFeatures: Fonts.tabular,
                        color: c.ink,
                        fontWeight: r?.kind == LineKind.heading
                            ? FontWeight.w600
                            : FontWeight.w400,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: Spacing.md),
                        hintText: hint,
                        hintStyle: TextStyle(
                          fontFamily: Fonts.figures,
                          color: c.inkSoft,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
                if (trailing != null)
                  ConstrainedBox(
                    // The result hugs the right edge; long lines wrap rather
                    // than push it off.
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.sizeOf(context).width *
                            (stamp != null ? 0.55 : 0.45)),
                    child: trailing,
                  ),
              ],
            ),
            if (caption != null)
              Padding(
                padding: const EdgeInsets.only(
                    left: RuledPaper.gutter + Spacing.md,
                    right: Spacing.sm,
                    bottom: Spacing.sm),
                child: Text(
                  caption,
                  textAlign: TextAlign.end,
                  style: TextStyle(color: c.inkSoft, fontSize: 12),
                ),
              ),
            if (suggestions.isNotEmpty)
              _SuggestionStrip(suggestions: suggestions, onPick: onSuggestion),
          ],
        ),
      ),
    );

    final stamped = row;

    // Swipe right: PAID. Swipe left: PENDING. Swiping again lifts the stamp.
    // The row never leaves — the swipe only stamps it.
    if (r == null || !r.hasValue || r.isTotal) return stamped;
    return Dismissible(
      key: ValueKey('stamp-${key.hashCode}-$index'),
      direction: DismissDirection.horizontal,
      dismissThresholds: const {
        DismissDirection.startToEnd: 0.28,
        DismissDirection.endToStart: 0.28,
      },
      confirmDismiss: (dir) async {
        onStamp(dir == DismissDirection.startToEnd
            ? LineStamp.paid
            : LineStamp.pending);
        return false;
      },
      background:
          _SwipeHint(stamp: LineStamp.paid, lifting: stamp == LineStamp.paid),
      secondaryBackground: _SwipeHint(
          stamp: LineStamp.pending, lifting: stamp == LineStamp.pending),
      child: stamped,
    );
  }
}

/// An inked rubber stamp, a little crooked, over the line's result.
class _RubberStamp extends StatelessWidget {
  final LineStamp stamp;
  const _RubberStamp({required this.stamp});

  @override
  Widget build(BuildContext context) {
    final c = context.ledger;
    final paid = stamp == LineStamp.paid;
    final ink = paid ? c.primary : c.result;
    return Semantics(
      label: paid ? 'Stamped paid' : 'Stamped pending',
      child: TweenAnimationBuilder<double>(
        // Lands like a stamp: a touch big, then pressed flat.
        tween: Tween(begin: 1.35, end: 1),
        duration: MediaQuery.of(context).disableAnimations
            ? Duration.zero
            : const Duration(milliseconds: 260),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: Transform.rotate(
          angle: paid ? -0.14 : 0.1,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              border: Border.all(color: ink.withValues(alpha: 0.8), width: 2),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              paid ? 'PAID' : 'DUE',
              style: TextStyle(
                fontFamily: Fonts.figures,
                color: ink.withValues(alpha: 0.8),
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SwipeHint extends StatelessWidget {
  final LineStamp stamp;
  final bool lifting;
  const _SwipeHint({required this.stamp, required this.lifting});

  @override
  Widget build(BuildContext context) {
    final c = context.ledger;
    final paid = stamp == LineStamp.paid;
    final ink = paid ? c.primary : c.result;
    return Container(
      color: ink.withValues(alpha: 0.12),
      alignment: paid ? Alignment.centerLeft : Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: Spacing.xl),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(
            lifting
                ? Icons.layers_clear_outlined
                : (paid ? Icons.verified_outlined : Icons.schedule),
            color: ink,
            size: 20),
        const SizedBox(width: Spacing.sm),
        Text(lifting ? 'Remove stamp' : (paid ? 'PAID' : 'PENDING'),
            style: TextStyle(
                color: ink, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
      ]),
    );
  }
}

/// "Did you mean" chips under a line the sheet couldn't read as typed.
class _SuggestionStrip extends StatelessWidget {
  final List<SmartSuggestion> suggestions;
  final ValueChanged<String> onPick;
  const _SuggestionStrip({required this.suggestions, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final c = context.ledger;
    // Part of the text field's tap region, so tapping a chip doesn't close
    // the keyboard first.
    return TextFieldTapRegion(
      child: Padding(
        padding: const EdgeInsets.only(
            left: RuledPaper.gutter + Spacing.md, bottom: Spacing.sm),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            Icon(Icons.auto_awesome, size: 16, color: c.primary),
            const SizedBox(width: Spacing.xs),
            for (final s in suggestions)
              Padding(
                padding: const EdgeInsets.only(left: Spacing.xs),
                child: Semantics(
                  button: true,
                  label: 'Suggestion: ${s.title}. ${s.line}',
                  excludeSemantics: true,
                  child: Material(
                    color: c.primary.withValues(alpha: 0.1),
                    shape: StadiumBorder(
                        side: BorderSide(
                            color: c.primary.withValues(alpha: 0.35))),
                    child: InkWell(
                      customBorder: const StadiumBorder(),
                      onTap: () => onPick(s.line),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: Spacing.md, vertical: 6),
                        child: Text(s.title,
                            style: TextStyle(
                                color: c.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

class _HintRow extends StatelessWidget {
  final String text;
  const _HintRow({required this.text});

  @override
  Widget build(BuildContext context) {
    final c = context.ledger;
    return RuledPaper(
      child: SizedBox(
        height: 48,
        child: Row(children: [
          const SizedBox(width: RuledPaper.gutter + Spacing.md),
          Expanded(
            child: Text(text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: Fonts.figures,
                  color: c.inkSoft,
                  fontSize: 16,
                )),
          ),
        ]),
      ),
    );
  }
}

/// The input-accessory row: the symbols a sheet line needs that a phone
/// keyboard hides.
class _KeyRow extends StatelessWidget {
  final ValueChanged<String> onKey;
  const _KeyRow({required this.onKey});

  static const keys = <(String, String, String)>[
    ('+', ' + ', 'Plus'),
    ('−', ' - ', 'Minus'),
    ('×', ' × ', 'Multiply'),
    ('÷', ' ÷ ', 'Divide'),
    ('(', '(', 'Open bracket'),
    (')', ')', 'Close bracket'),
    ('%', '%', 'Percent'),
    ('#', '#', 'Line reference'),
    ('in', ' in ', 'Convert with in'),
    ('on', ' on ', 'Date with on'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.ledger;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.rule)),
      ),
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Spacing.xs),
        children: [
          for (final (label, insert, spoken) in keys)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
              child: Semantics(
                button: true,
                label: 'Insert $spoken',
                excludeSemantics: true,
                child: Material(
                  color: c.paper,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Radii.button),
                    side: BorderSide(color: c.rule),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(Radii.button),
                    onTap: () => onKey(insert),
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: Center(
                        child: Text(label,
                            style: TextStyle(
                              fontFamily: Fonts.figures,
                              color: c.ink,
                              fontSize: 17,
                              fontWeight: FontWeight.w500,
                            )),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  final SheetEvaluation eval;
  const _Footer({required this.eval});

  @override
  Widget build(BuildContext context) {
    final c = context.ledger;
    final value = eval.hasValues ? eval.totalDisplay : '—';
    return Semantics(
      container: true,
      label: 'Total, $value'
          '${eval.hasStamps ? '. Paid ${eval.paidDisplay}, pending ${eval.pendingDisplay}' : ''}'
          '${eval.excludedNote == null ? '' : '. ${eval.excludedNote}'}',
      excludeSemantics: true,
      child: Container(
        decoration: BoxDecoration(
          color: c.surface,
          border: Border(top: BorderSide(color: c.ink, width: 1.5)),
        ),
        padding: const EdgeInsets.fromLTRB(
            Spacing.lg, Spacing.md, Spacing.lg, Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              Text(AppLocalizations.of(context)!.sheetTotal,
                  style: TextStyle(
                      color: c.ink, fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: Fonts.figures,
                    fontFeatures: Fonts.tabular,
                    color: c.result,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ]),
            if (eval.hasStamps)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: Spacing.lg,
                  children: [
                    _StampTotal(
                        label: 'Paid',
                        value: eval.paidDisplay,
                        color: c.primary),
                    _StampTotal(
                        label: 'Pending',
                        value: eval.pendingDisplay,
                        color: c.result),
                  ],
                ),
              ),
            if (eval.excludedNote != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(eval.excludedNote!,
                    textAlign: TextAlign.end,
                    style: TextStyle(color: c.inkSoft, fontSize: 12)),
              ),
          ],
        ),
      ),
    );
  }
}

class _StampTotal extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StampTotal(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text('$label ',
          style: TextStyle(color: context.ledger.inkSoft, fontSize: 13)),
      Text(value,
          style: TextStyle(
              fontFamily: Fonts.figures,
              fontFeatures: Fonts.tabular,
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600)),
    ]);
  }
}
