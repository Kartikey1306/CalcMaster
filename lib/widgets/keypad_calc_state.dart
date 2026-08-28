import 'package:flutter/widgets.dart';

import '../lib_calc.dart';
import '../lib_format.dart';

/// Expression state shared by every keypad-driven screen (Standard,
/// Scientific, Converter).
///
/// `expr` is always the raw, parseable string (`*`, `/`, `-`, `sqrt(`…); the
/// display renders a prettified copy of it. After `=` the committed
/// expression moves to the small line above and the answer becomes the large
/// one.
abstract class KeypadCalcState<T extends StatefulWidget> extends State<T> {
  String expr = '';

  /// Expression captured when `=` was pressed, shown above the answer.
  String? committed;

  AngleUnit angle = AngleUnit.rad;

  /// Significant digits the large readout is formatted to.
  int get resultDigits => 6;

  /// Auto-closes any unbalanced `(` so the result stays live while typing.
  double? _eval(String source) {
    if (source.trim().isEmpty) return null;
    try {
      final open = '('.allMatches(source).length;
      final close = ')'.allMatches(source).length;
      final padded = source + (')' * (open - close).clamp(0, 100));
      final v = evaluate(padded, angle: angle);
      return v.isFinite ? v : null;
    } catch (_) {
      return null;
    }
  }

  double? get liveValue => _eval(expr);

  /// The value memory keys and downstream conversions operate on.
  double get currentValue => liveValue ?? 0;

  static const _prettyMap = {
    '*': '×',
    '/': '÷',
    '-': '−',
    'sqrt(': '√(',
    'cbrt(': '∛(',
    'pi': 'π',
  };

  String pretty(String source) {
    var out = source;
    _prettyMap.forEach((raw, glyph) => out = out.replaceAll(raw, glyph));
    return out;
  }

  /// Plain, re-parseable text for a computed value (no thousands separators —
  /// those would break the tokenizer when the answer is reused).
  String plain(double v) {
    if (v == v.roundToDouble() && v.abs() < 1e15) return v.toInt().toString();
    return v.toString();
  }

  // ---- Display projection ----

  bool get isIdle => expr.isEmpty && committed == null;

  String get displayExpression {
    if (committed != null) return '$committed =';
    final v = liveValue;
    if (v == null) return '';
    // While a bare number is being typed there is nothing to preview.
    return plain(v) == expr ? '' : pretty(expr);
  }

  String get displayValue {
    if (isIdle) return '0';
    final v = liveValue;
    if (committed != null || (v != null && plain(v) != expr)) {
      return v == null ? pretty(expr) : formatNumber(v, maxDigits: resultDigits);
    }
    return pretty(expr);
  }

  // ---- Key actions ----

  /// Multi-character tokens that backspace removes in one press.
  static const _tokens = [
    'asinh(', 'acosh(', 'atanh(', 'sinh(', 'cosh(', 'tanh(',
    'asin(', 'acos(', 'atan(', 'sqrt(', 'cbrt(', 'sin(', 'cos(', 'tan(',
    'exp(', 'log(', 'ln(', 'pi', '*10^', '^(-1)', '^(1/',
  ];

  void input(String raw) {
    setState(() {
      // A digit typed straight after `=` starts a new calculation; an
      // operator continues from the answer.
      if (committed != null) {
        committed = null;
        if (RegExp(r'^[0-9.]').hasMatch(raw)) expr = '';
      }
      expr += raw;
    });
  }

  void backspace() {
    setState(() {
      committed = null;
      if (expr.isEmpty) return;
      for (final t in _tokens) {
        if (expr.endsWith(t)) {
          expr = expr.substring(0, expr.length - t.length);
          return;
        }
      }
      expr = expr.substring(0, expr.length - 1);
    });
  }

  void clear() => setState(() {
        expr = '';
        committed = null;
      });

  /// Flips the sign of the trailing number (the `+/−` key).
  void toggleSign() {
    final m = RegExp(r'(\d*\.?\d+)$').firstMatch(expr);
    if (m == null) return;
    final idx = m.start;
    final hasUnaryMinus = idx > 0 &&
        expr[idx - 1] == '-' &&
        (idx - 1 == 0 || '(+-*/%^'.contains(expr[idx - 2]));
    setState(() {
      committed = null;
      expr = hasUnaryMinus
          ? expr.substring(0, idx - 1) + expr.substring(idx)
          : '${expr.substring(0, idx)}-${expr.substring(idx)}';
    });
  }

  /// Divides the trailing number by 100 — `50 %` becomes `(50/100)`.
  void percent() {
    final m = RegExp(r'(\d*\.?\d+)$').firstMatch(expr);
    if (m == null) return;
    setState(() {
      committed = null;
      expr = '${expr.substring(0, m.start)}(${m.group(0)}/100)';
    });
  }

  void equals() {
    final v = liveValue;
    if (v == null || expr.isEmpty) return;
    setState(() {
      committed = pretty(expr);
      expr = plain(v);
    });
  }

  /// True while `label`'s operator is the trailing character — the pending
  /// operator's key renders inverted.
  bool isPendingOperator(String label) {
    const opChar = {'÷': '/', '×': '*', '−': '-', '+': '+'};
    final ch = opChar[label];
    return ch != null && committed == null && expr.endsWith(ch);
  }
}
