import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../i18n_helpers.dart';
import '../l10n/generated/app_localizations.dart';
import '../lib_units.dart';
import '../theme/tokens.dart';
import '../widgets/calc_key.dart';
import '../widgets/keypad_calc_state.dart';
import '../widgets/pressable_scale.dart';

/// Keypad-driven Convert detail screen: a FROM readout you type into with the
/// calculator keypad, a SWAP key, a TO readout underneath, and a bottom-sheet
/// unit picker. `ALL CONVERSIONS` moved behind the list action in the header
/// so the keypad owns the bottom of the screen.
class ConvertDetail extends StatefulWidget {
  final String categoryId;
  const ConvertDetail({super.key, required this.categoryId});

  @override
  State<ConvertDetail> createState() => _ConvertDetailState();
}

class _ConvertDetailState extends KeypadCalcState<ConvertDetail> {
  late String _fromUnit;
  late String _toUnit;
  late Category _cat;

  @override
  void initState() {
    super.initState();
    _cat = categoryById(widget.categoryId) ?? categories.first;
    _fromUnit = _cat.units.first.id;
    _toUnit = _cat.units.length > 1 ? _cat.units[1].id : _cat.units.first.id;
    expr = '1';
  }

  String _formatValue(double v) {
    if (!v.isFinite) return '—';
    final abs = v.abs();
    if (abs == 0) return '0';
    if (abs < 0.001 || abs >= 1e7) return v.toStringAsExponential(6);
    if (abs >= 100) return v.toStringAsFixed(math.max(0, 6 - v.toInt().toString().length));
    return v.toStringAsPrecision(8).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }

  void _swap() => setState(() {
        final tmp = _fromUnit;
        _fromUnit = _toUnit;
        _toUnit = tmp;
      });

  Unit get _from => _cat.unitById(_fromUnit) ?? _cat.units.first;
  Unit get _to => _cat.unitById(_toUnit) ?? _cat.units.first;

  Future<void> _pickUnit({required bool isFrom}) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => UnitPickerSheet(
        category: _cat,
        selected: isFrom ? _fromUnit : _toUnit,
        title: isFrom ? 'Convert from' : 'Convert to',
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isFrom) {
        _fromUnit = picked;
      } else {
        _toUnit = picked;
      }
    });
  }

  void _showAllConversions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _AllConversionsSheet(
        category: _cat,
        value: currentValue,
        fromUnit: _fromUnit,
        toUnit: _toUnit,
        format: _formatValue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final accent = _cat.accent;
    final result = convert(currentValue, _fromUnit, _toUnit, _cat);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            const gap = 12.0;
            final keyArea = math.min(constraints.maxWidth - Spacing.lg * 2, 420.0);
            final size = ((keyArea - gap * 3) / 4).clamp(52.0, 80.0);
            final keypadWidth = size * 4 + gap * 3;

            CalcKey k(
              String label,
              CalcKeyKind kind,
              VoidCallback onTap, {
              double widthFactor = 1,
              bool active = false,
              IconData? icon,
              double fontScale = 1,
            }) =>
                CalcKey(
                  label: icon == null ? label : null,
                  icon: icon,
                  kind: kind,
                  size: size,
                  gap: gap,
                  widthFactor: widthFactor,
                  active: active,
                  fontScale: fontScale,
                  onTap: onTap,
                  haptic: label == '=' ? HapticFeedbackKind.medium : HapticFeedbackKind.selection,
                );

            return Column(
              children: [
                // ---- Header ----
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Go back',
                        icon: const Icon(Icons.chevron_left, size: 26, color: AppColors.text),
                        onPressed: () => context.pop(),
                        // Keep the 44pt minimum touch target from Apple's HIG.
                        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              localizedCategoryLabel(context, _cat.id),
                              style: const TextStyle(
                                color: AppColors.text,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              loc.labelUnitsAvailable(_cat.units.length),
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: loc.labelAllConversions,
                        icon: const Icon(Icons.format_list_bulleted,
                            size: 22, color: AppColors.textMuted),
                        onPressed: _showAllConversions,
                      ),
                    ],
                  ),
                ),

                // ---- FROM / TO readout ----
                // Scrolls (bottom-anchored) so a short window — a small phone
                // in landscape, or a widget test — never overflows the column.
                Expanded(
                  child: SingleChildScrollView(
                    reverse: true,
                    child: Center(
                      child: SizedBox(
                        width: keypadWidth,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _UnitLabel(
                              unit: _from,
                              accent: accent,
                              onTap: () => _pickUnit(isFrom: true),
                            ),
                            const SizedBox(height: 2),
                            CalcDisplay(
                              expression: displayExpression,
                              value: displayValue,
                              idle: false,
                              maxWidth: keypadWidth,
                              onSwipe: backspace,
                            ),
                            const SizedBox(height: Spacing.md),
                            Row(
                              children: [
                                const Expanded(child: Divider(color: AppColors.borderStrong)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
                                  child: PressableScale(
                                    onTap: _swap,
                                    haptic: HapticFeedbackKind.light,
                                    child: const Icon(Icons.swap_vert,
                                        size: 26, color: AppColors.accentPrimary),
                                  ),
                                ),
                                const Expanded(child: Divider(color: AppColors.borderStrong)),
                              ],
                            ),
                            const SizedBox(height: Spacing.md),
                            _UnitLabel(
                              unit: _to,
                              accent: accent,
                              onTap: () => _pickUnit(isFrom: false),
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              alignment: Alignment.centerRight,
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _formatValue(result),
                                maxLines: 1,
                                style: TextStyle(
                                  color: accent,
                                  fontSize: 44,
                                  fontWeight: FontWeight.w300,
                                  height: 1.1,
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // ---- Keypad ----
                Padding(
                  padding: const EdgeInsets.only(bottom: Spacing.md, top: Spacing.sm),
                  child: CalcKeypad(
                    gap: gap,
                    rows: [
                      [
                        isIdle
                            ? k('AC', CalcKeyKind.function, clear)
                            : k('⌫', CalcKeyKind.function, backspace,
                                icon: Icons.backspace_outlined),
                        k('+/−', CalcKeyKind.function, toggleSign),
                        k('SWAP', CalcKeyKind.function, _swap, fontScale: 0.55),
                        k('÷', CalcKeyKind.operator, () => input('/'),
                            active: isPendingOperator('÷')),
                      ],
                      [
                        k('7', CalcKeyKind.digit, () => input('7')),
                        k('8', CalcKeyKind.digit, () => input('8')),
                        k('9', CalcKeyKind.digit, () => input('9')),
                        k('×', CalcKeyKind.operator, () => input('*'),
                            active: isPendingOperator('×')),
                      ],
                      [
                        k('4', CalcKeyKind.digit, () => input('4')),
                        k('5', CalcKeyKind.digit, () => input('5')),
                        k('6', CalcKeyKind.digit, () => input('6')),
                        k('−', CalcKeyKind.operator, () => input('-'),
                            active: isPendingOperator('−')),
                      ],
                      [
                        k('1', CalcKeyKind.digit, () => input('1')),
                        k('2', CalcKeyKind.digit, () => input('2')),
                        k('3', CalcKeyKind.digit, () => input('3')),
                        k('+', CalcKeyKind.operator, () => input('+'),
                            active: isPendingOperator('+')),
                      ],
                      [
                        k('0', CalcKeyKind.digit, () => input('0'), widthFactor: 2),
                        k('.', CalcKeyKind.digit, () => input('.')),
                        k('=', CalcKeyKind.operator, equals),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// `SYMBOL · UNIT NAME` caption above a readout — tapping it opens the picker.
class _UnitLabel extends StatelessWidget {
  final Unit unit;
  final Color accent;
  final VoidCallback onTap;
  const _UnitLabel({required this.unit, required this.accent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: PressableScale(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  '${unit.symbol} · ${unit.label}'.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.expand_more, size: 16, color: accent),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom-sheet unit picker: the category's units with a check on the current
/// one, plus chips to jump straight to another category.
class UnitPickerSheet extends StatefulWidget {
  final Category category;
  final String selected;
  final String title;
  const UnitPickerSheet({
    super.key,
    required this.category,
    required this.selected,
    required this.title,
  });

  @override
  State<UnitPickerSheet> createState() => _UnitPickerSheetState();
}

class _UnitPickerSheetState extends State<UnitPickerSheet> {
  late Category _cat = widget.category;

  @override
  Widget build(BuildContext context) {
    final accent = _cat.accent;
    return DraggableScrollableSheet(
      initialChildSize: 0.62,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      // Material (not a plain DecoratedBox) so the list tiles' ink and
      // selection fills paint on top of the sheet's own surface.
      builder: (context, scrollController) => Material(
        color: AppColors.surface,
        clipBehavior: Clip.antiAlias,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(Radii.sheet)),
        child: Column(
          children: [
            // Grab handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: Spacing.md),
              decoration: BoxDecoration(
                color: AppColors.borderStrong,
                borderRadius: BorderRadius.circular(Radii.pill),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
              child: Row(
                children: [
                  Text(
                    widget.title.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Spacing.sm),
            // Category chips
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: Spacing.sm),
                itemBuilder: (context, i) {
                  final c = categories[i];
                  final active = c.id == _cat.id;
                  return PressableScale(
                    onTap: () => setState(() => _cat = c),
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: active ? AppColors.accentSoft : Colors.transparent,
                        borderRadius: BorderRadius.circular(Radii.pill),
                        border: Border.all(
                          color: active ? AppColors.accentPrimary : AppColors.border,
                        ),
                      ),
                      child: Text(
                        localizedCategoryLabel(context, c.id),
                        style: TextStyle(
                          color: active ? AppColors.accentPrimary : AppColors.textMuted,
                          fontSize: 13,
                          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: Spacing.sm),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.only(bottom: Spacing.xxl),
                itemCount: _cat.units.length,
                separatorBuilder: (_, __) => const Divider(
                  height: 1,
                  indent: Spacing.lg,
                  color: AppColors.border,
                ),
                itemBuilder: (context, i) {
                  final u = _cat.units[i];
                  // Only the originating category can report a selection.
                  final active = _cat.id == widget.category.id && u.id == widget.selected;
                  return ListTile(
                    onTap: _cat.id == widget.category.id
                        ? () => Navigator.of(context).pop(u.id)
                        : null,
                    enabled: _cat.id == widget.category.id,
                    title: Text(
                      '${u.label} (${u.symbol})',
                      style: TextStyle(
                        color: active ? AppColors.accentPrimary : AppColors.text,
                        fontSize: 15,
                        fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    trailing: active
                        ? const Icon(Icons.check, size: 18, color: AppColors.accentPrimary)
                        : null,
                  );
                },
              ),
            ),
            if (_cat.id != widget.category.id)
              Padding(
                padding: const EdgeInsets.fromLTRB(Spacing.lg, 0, Spacing.lg, Spacing.lg),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.pushReplacement('/convert/${_cat.id}');
                    },
                    child: Text('Open ${localizedCategoryLabel(context, _cat.id)}'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Every unit in the category converted from the current input at once.
class _AllConversionsSheet extends StatelessWidget {
  final Category category;
  final double value;
  final String fromUnit;
  final String toUnit;
  final String Function(double) format;

  const _AllConversionsSheet({
    required this.category,
    required this.value,
    required this.fromUnit,
    required this.toUnit,
    required this.format,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final accent = category.accent;
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      // Material (not a plain DecoratedBox) so the list tiles' ink and
      // selection fills paint on top of the sheet's own surface.
      builder: (context, scrollController) => Material(
        color: AppColors.surface,
        clipBehavior: Clip.antiAlias,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(Radii.sheet)),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: Spacing.md),
              decoration: BoxDecoration(
                color: AppColors.borderStrong,
                borderRadius: BorderRadius.circular(Radii.pill),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  loc.labelAllConversions,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: Spacing.sm),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.only(bottom: Spacing.xxl),
                itemCount: category.units.length,
                separatorBuilder: (_, __) => const Divider(
                  height: 1,
                  indent: Spacing.lg,
                  color: AppColors.border,
                ),
                itemBuilder: (context, i) {
                  final u = category.units[i];
                  final active = u.id == toUnit;
                  return Container(
                    color: active ? AppColors.surfaceAlt : Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            u.label,
                            style: TextStyle(
                              color: active ? AppColors.text : AppColors.textMuted,
                              fontSize: 15,
                              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ),
                        Text(
                          format(convert(value, fromUnit, u.id, category)),
                          style: TextStyle(
                            color: active ? accent : AppColors.text,
                            fontSize: 15,
                            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
