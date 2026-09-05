import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';

import '../../lib_calc.dart';
import '../../lib_format.dart';
import '../../theme/tokens.dart';
import '../../widgets/calc_key.dart';
import '../../widgets/chip_picker.dart';
import '../../widgets/inner_scaffold.dart';
import '../../widgets/keypad_calc_state.dart';
import '../../widgets/number_input.dart';
import '../../widgets/pressable_scale.dart';
import '../../widgets/result_row.dart';

// =================== STANDARD ===================

class StandardCalc extends StatefulWidget {
  const StandardCalc({super.key});
  @override
  State<StandardCalc> createState() => _StandardCalcState();
}

class _StandardCalcState extends KeypadCalcState<StandardCalc> {
  @override
  Widget build(BuildContext context) {
    return InnerScaffold(
      title: AppLocalizations.of(context)!.calcStandard,
      subtitle: 'Swipe the display to delete · live result',
      child: LayoutBuilder(
        builder: (context, constraints) {
          const gap = 12.0;
          final size = ((constraints.maxWidth - gap * 3) / 4).clamp(56.0, 88.0);
          final keypadWidth = size * 4 + gap * 3;

          CalcKey k(
            String label,
            CalcKeyKind kind,
            VoidCallback onTap, {
            double widthFactor = 1,
            bool active = false,
            IconData? icon,
          }) =>
              CalcKey(
                label: icon == null ? label : null,
                icon: icon,
                kind: kind,
                size: size,
                gap: gap,
                widthFactor: widthFactor,
                active: active,
                onTap: onTap,
                haptic: label == '='
                    ? HapticFeedbackKind.medium
                    : HapticFeedbackKind.selection,
              );

          return Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.only(top: Spacing.xl, bottom: Spacing.xl),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 110),
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: CalcDisplay(
                      expression: displayExpression,
                      value: displayValue,
                      idle: isIdle,
                      maxWidth: keypadWidth,
                      onSwipe: backspace,
                    ),
                  ),
                ),
              ),
              CalcKeypad(
                gap: gap,
                rows: [
                  [
                    // The clear key becomes a backspace once there is
                    // something to delete, as in the reference design.
                    isIdle
                        ? k('AC', CalcKeyKind.function, clear)
                        : k('⌫', CalcKeyKind.function, backspace,
                            icon: Icons.backspace_outlined),
                    k('+/−', CalcKeyKind.function, toggleSign),
                    k('%', CalcKeyKind.function, percent),
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
            ],
          );
        },
      ),
    );
  }
}

// =================== SCIENTIFIC ===================

class ScientificCalc extends StatefulWidget {
  const ScientificCalc({super.key});
  @override
  State<ScientificCalc> createState() => _ScientificCalcState();
}

class _ScientificCalcState extends KeypadCalcState<ScientificCalc> {
  /// `2nd` swaps the trig/hyperbolic keys for their inverses.
  bool second = false;

  /// Single memory register behind `mc / m+ / m− / mr`.
  double memory = 0;

  final _rand = math.Random();

  @override
  int get resultDigits => 10;

  void _toggleSecond() => setState(() => second = !second);

  void _toggleAngle() => setState(
      () => angle = angle == AngleUnit.rad ? AngleUnit.deg : AngleUnit.rad);

  void _memory(String op) {
    setState(() {
      switch (op) {
        case 'mc':
          memory = 0;
          break;
        case 'm+':
          memory += currentValue;
          break;
        case 'm-':
          memory -= currentValue;
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return InnerScaffold(
      title: AppLocalizations.of(context)!.calcScientific,
      subtitle:
          'Trig, logs, powers, memory · ${angle == AngleUnit.deg ? 'Deg' : 'Rad'}'
          '${memory != 0 ? ' · M' : ''}',
      child: LayoutBuilder(
        builder: (context, constraints) {
          const gap = 8.0;
          final width = constraints.maxWidth;
          // Six function columns line up with the four main columns below.
          final sciSize = ((width - gap * 5) / 6).clamp(40.0, 56.0);
          final mainSize = ((width - gap * 3) / 4).clamp(52.0, 78.0);
          final keypadWidth = math.max(
            sciSize * 6 + gap * 5,
            mainSize * 4 + gap * 3,
          );

          CalcKey sci(
            String label,
            VoidCallback onTap, {
            bool active = false,
            double fontScale = 0.72,
          }) =>
              CalcKey(
                label: label,
                kind: CalcKeyKind.secondary,
                size: sciSize,
                gap: gap,
                active: active,
                fontScale: fontScale,
                onTap: onTap,
              );

          CalcKey ins(String label, String raw, {double fontScale = 0.72}) =>
              sci(label, () => input(raw), fontScale: fontScale);

          CalcKey main(
            String label,
            CalcKeyKind kind,
            VoidCallback onTap, {
            double widthFactor = 1,
            bool active = false,
            IconData? icon,
          }) =>
              CalcKey(
                label: icon == null ? label : null,
                icon: icon,
                kind: kind,
                size: mainSize,
                gap: gap,
                widthFactor: widthFactor,
                active: active,
                onTap: onTap,
                haptic: label == '='
                    ? HapticFeedbackKind.medium
                    : HapticFeedbackKind.selection,
              );

          return Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.only(top: Spacing.md, bottom: Spacing.lg),
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: CalcDisplay(
                    expression: displayExpression,
                    value: displayValue,
                    idle: isIdle,
                    maxWidth: keypadWidth,
                    onSwipe: backspace,
                  ),
                ),
              ),
              CalcKeypad(
                gap: gap,
                rows: [
                  [
                    ins('(', '('),
                    ins(')', ')'),
                    sci('mc', () => _memory('mc')),
                    sci('m+', () => _memory('m+')),
                    sci('m−', () => _memory('m-')),
                    sci('mr', () => input(plain(memory))),
                  ],
                  [
                    sci('2nd', _toggleSecond, active: second),
                    ins('x²', '^2'),
                    ins('x³', '^3'),
                    ins('xʸ', '^'),
                    ins('eˣ', 'exp('),
                    ins('10ˣ', '10^'),
                  ],
                  [
                    ins('¹/x', '^(-1)'),
                    ins('²√x', 'sqrt('),
                    ins('³√x', 'cbrt('),
                    ins('ʸ√x', '^(1/'),
                    ins('ln', 'ln('),
                    ins('log₁₀', 'log(', fontScale: 0.6),
                  ],
                  [
                    ins('x!', '!'),
                    ins(second ? 'sin⁻¹' : 'sin', second ? 'asin(' : 'sin(',
                        fontScale: second ? 0.58 : 0.72),
                    ins(second ? 'cos⁻¹' : 'cos', second ? 'acos(' : 'cos(',
                        fontScale: second ? 0.58 : 0.72),
                    ins(second ? 'tan⁻¹' : 'tan', second ? 'atan(' : 'tan(',
                        fontScale: second ? 0.58 : 0.72),
                    ins('e', 'e'),
                    ins('EE', '*10^'),
                  ],
                  [
                    sci('Rand',
                        () => input(_rand.nextDouble().toStringAsFixed(6)),
                        fontScale: 0.58),
                    ins(second ? 'sinh⁻¹' : 'sinh', second ? 'asinh(' : 'sinh(',
                        fontScale: second ? 0.5 : 0.62),
                    ins(second ? 'cosh⁻¹' : 'cosh', second ? 'acosh(' : 'cosh(',
                        fontScale: second ? 0.5 : 0.62),
                    ins(second ? 'tanh⁻¹' : 'tanh', second ? 'atanh(' : 'tanh(',
                        fontScale: second ? 0.5 : 0.62),
                    ins('π', 'pi'),
                    sci(angle == AngleUnit.rad ? 'Rad' : 'Deg', _toggleAngle,
                        active: angle == AngleUnit.deg, fontScale: 0.6),
                  ],
                ],
              ),
              const SizedBox(height: gap),
              CalcKeypad(
                gap: gap,
                rows: [
                  [
                    isIdle
                        ? main('AC', CalcKeyKind.function, clear)
                        : main('⌫', CalcKeyKind.function, backspace,
                            icon: Icons.backspace_outlined),
                    main('+/−', CalcKeyKind.function, toggleSign),
                    main('%', CalcKeyKind.function, percent),
                    main('÷', CalcKeyKind.operator, () => input('/'),
                        active: isPendingOperator('÷')),
                  ],
                  [
                    main('7', CalcKeyKind.digit, () => input('7')),
                    main('8', CalcKeyKind.digit, () => input('8')),
                    main('9', CalcKeyKind.digit, () => input('9')),
                    main('×', CalcKeyKind.operator, () => input('*'),
                        active: isPendingOperator('×')),
                  ],
                  [
                    main('4', CalcKeyKind.digit, () => input('4')),
                    main('5', CalcKeyKind.digit, () => input('5')),
                    main('6', CalcKeyKind.digit, () => input('6')),
                    main('−', CalcKeyKind.operator, () => input('-'),
                        active: isPendingOperator('−')),
                  ],
                  [
                    main('1', CalcKeyKind.digit, () => input('1')),
                    main('2', CalcKeyKind.digit, () => input('2')),
                    main('3', CalcKeyKind.digit, () => input('3')),
                    main('+', CalcKeyKind.operator, () => input('+'),
                        active: isPendingOperator('+')),
                  ],
                  [
                    main('0', CalcKeyKind.digit, () => input('0'),
                        widthFactor: 2),
                    main('.', CalcKeyKind.digit, () => input('.')),
                    main('=', CalcKeyKind.operator, equals),
                  ],
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

// =================== PERCENTAGE ===================

class PercentageCalc extends StatefulWidget {
  const PercentageCalc({super.key});
  @override
  State<PercentageCalc> createState() => _PercentageCalcState();
}

class _PercentageCalcState extends State<PercentageCalc> {
  final aC = TextEditingController();
  final bC = TextEditingController();

  @override
  void initState() {
    super.initState();
    aC.addListener(() => setState(() {}));
    bC.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    aC.dispose();
    bC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final A = safeNumber(aC.text);
    final B = safeNumber(bC.text);
    final pctOf = (A / 100) * B;
    final isPct = B == 0 ? double.nan : A / B;
    final change = A == 0 ? double.nan : (B - A) / A;
    return InnerScaffold(
      title: AppLocalizations.of(context)!.calcPercentage,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: NumberInput(label: 'X', controller: aC)),
          const SizedBox(width: Spacing.md),
          Expanded(child: NumberInput(label: 'Y', controller: bC)),
        ]),
        const SizedBox(height: Spacing.lg),
        Text(AppLocalizations.of(context)!.labelXofY,
            style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        ResultRow(
            label:
                '${aC.text.isEmpty ? '0' : aC.text}% of ${bC.text.isEmpty ? '0' : bC.text}',
            value: formatNumber(pctOf)),
        const SizedBox(height: Spacing.lg),
        Text(AppLocalizations.of(context)!.labelXisWhatPctOfY,
            style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        ResultRow(
            label:
                '${aC.text.isEmpty ? '0' : aC.text} of ${bC.text.isEmpty ? '0' : bC.text}',
            value: isPct.isFinite ? formatPercent(isPct) : '—'),
        const SizedBox(height: Spacing.lg),
        Text(AppLocalizations.of(context)!.labelPctChangeXtoY,
            style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        ResultRow(
            label: 'Change',
            value: change.isFinite ? formatPercent(change) : '—',
            highlight: change.isFinite),
      ]),
    );
  }
}

// =================== BASE ===================

class BaseCalc extends StatefulWidget {
  const BaseCalc({super.key});
  @override
  State<BaseCalc> createState() => _BaseCalcState();
}

class _BaseCalcState extends State<BaseCalc> {
  String base = 'dec';
  final controller = TextEditingController(text: '255');

  @override
  void initState() {
    super.initState();
    controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  int? _parsed() {
    final radix = {'bin': 2, 'oct': 8, 'dec': 10, 'hex': 16}[base]!;
    return int.tryParse(controller.text.trim(), radix: radix);
  }

  String _rep(String b) {
    final v = _parsed();
    if (v == null) return '—';
    final radix = {'bin': 2, 'oct': 8, 'dec': 10, 'hex': 16}[b]!;
    return v.toRadixString(radix).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return InnerScaffold(
      title: AppLocalizations.of(context)!.calcBase,
      subtitle: 'Bin · Oct · Dec · Hex',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(AppLocalizations.of(context)!.labelInputBase,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
        const SizedBox(height: Spacing.sm),
        ChipPicker<String>(
          options: const [
            (id: 'bin', label: 'BIN'),
            (id: 'oct', label: 'OCT'),
            (id: 'dec', label: 'DEC'),
            (id: 'hex', label: 'HEX')
          ],
          value: base,
          onChange: (v) => setState(() => base = v),
        ),
        NumberInput(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions()),
        const SizedBox(height: Spacing.md),
        ResultRow(label: 'Binary', caption: 'base 2', value: _rep('bin')),
        ResultRow(label: 'Octal', caption: 'base 8', value: _rep('oct')),
        ResultRow(
            label: 'Decimal',
            caption: 'base 10',
            value: _rep('dec'),
            highlight: true),
        ResultRow(label: 'Hex', caption: 'base 16', value: _rep('hex')),
      ]),
    );
  }
}

// =================== FRACTION ===================

class FractionCalc extends StatefulWidget {
  const FractionCalc({super.key});
  @override
  State<FractionCalc> createState() => _FractionCalcState();
}

class _FractionCalcState extends State<FractionCalc> {
  final n1 = TextEditingController(text: '1');
  final d1 = TextEditingController(text: '2');
  final n2 = TextEditingController(text: '1');
  final d2 = TextEditingController(text: '3');
  String op = '+';

  @override
  void initState() {
    super.initState();
    for (final c in [n1, d1, n2, d2]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [n1, d1, n2, d2]) {
      c.dispose();
    }
    super.dispose();
  }

  ({int n, int d}) _compute() {
    final a = safeNumber(n1.text).toInt();
    final b = safeNumber(d1.text).toInt();
    final c = safeNumber(n2.text).toInt();
    final d = safeNumber(d2.text).toInt();
    if (b == 0 || d == 0) return (n: 0, d: 0);
    switch (op) {
      case '+':
        return simplifyFraction(a * d + c * b, b * d);
      case '-':
        return simplifyFraction(a * d - c * b, b * d);
      case '×':
        return simplifyFraction(a * c, b * d);
      case '÷':
        if (c == 0) return (n: 0, d: 0);
        return simplifyFraction(a * d, b * c);
    }
    return (n: 0, d: 0);
  }

  String _toMixed(int n, int d) {
    if (d == 0) return '—';
    final whole = n ~/ d;
    final remainder = (n - whole * d).abs();
    if (remainder == 0) return '$whole';
    if (whole == 0) return '$n/$d';
    return '$whole $remainder/$d';
  }

  @override
  Widget build(BuildContext context) {
    final r = _compute();
    final dec = r.d == 0 ? double.nan : r.n / r.d;
    return InnerScaffold(
      title: AppLocalizations.of(context)!.calcFraction,
      subtitle: 'Add, subtract, multiply, divide',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Column(children: [
              NumberInput(label: 'Numerator A', controller: n1),
              NumberInput(label: 'Denominator A', controller: d1),
            ]),
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(children: [
              NumberInput(label: 'Numerator B', controller: n2),
              NumberInput(label: 'Denominator B', controller: d2),
            ]),
          ),
        ]),
        const SizedBox(height: Spacing.md),
        Text(AppLocalizations.of(context)!.labelOperator,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
        const SizedBox(height: Spacing.sm),
        ChipPicker<String>(
          options: const [
            (id: '+', label: '+'),
            (id: '-', label: '−'),
            (id: '×', label: '×'),
            (id: '÷', label: '÷')
          ],
          value: op,
          onChange: (v) => setState(() => op = v),
        ),
        const SizedBox(height: Spacing.lg),
        ResultRow(
            label: 'Simplified',
            value: r.d == 0 ? '—' : '${r.n}/${r.d}',
            highlight: true),
        ResultRow(label: 'Mixed number', value: _toMixed(r.n, r.d)),
        ResultRow(label: 'Decimal', value: dec.isFinite ? dec.toString() : '—'),
      ]),
    );
  }
}
