import 'dart:math' as math;

/// Why an expression could not be worked out.
///
/// [friendly] messages are plain-language reasons ("Division by zero") that
/// can be shown as they are; the others describe a typing problem and are
/// reworded by whoever shows them.
class CalcError implements Exception {
  final String message;
  final bool friendly;
  CalcError(this.message, {this.friendly = false});
  @override
  String toString() => 'CalcError: $message';
}

/// Angle unit trig functions are interpreted in. The scientific keypad's
/// Rad/Deg key flips this per evaluation; the parser itself stays stateless.
enum AngleUnit { rad, deg }

const _constants = <String, double>{
  'pi': math.pi,
  'e': math.e,
  'tau': 2 * math.pi,
  'phi': 1.618033988749895,
};

/// Every function name the evaluator knows, lower-case.
const mathFunctions = <String>{
  'sin', 'cos', 'tan', 'asin', 'acos', 'atan', 'atan2',
  'sec', 'csc', 'cot',
  'sinh', 'cosh', 'tanh', 'asinh', 'acosh', 'atanh',
  'sqrt', 'cbrt', 'root', 'exp', 'ln', 'log', 'log2', 'log10',
  'abs', 'ceil', 'floor', 'round', 'trunc', 'sign',
  'ncr', 'npr', 'comb', 'perm', 'choose', 'fact', 'gamma',
  'max', 'min', 'gcd', 'lcm', 'mod', 'hypot',
};

enum _T { num, ident, op, lparen, rparen, comma, end }

class _Tok {
  final _T t;
  final String s;
  final double v;
  const _Tok(this.t, [this.s = '', this.v = 0]);
}

final _numberAt = RegExp(r'(?:\d+\.?\d*|\.\d+)(?:[eE][+-]?\d+)?');
final _identAt = RegExp(r'[A-Za-z]+');

List<_Tok> _tokenize(String input) {
  final src = input
      .replaceAll('π', 'pi')
      .replaceAll('τ', 'tau')
      .replaceAll('φ', 'phi')
      .replaceAll('√', 'sqrt')
      .replaceAll('∛', 'cbrt')
      .replaceAll('×', '*')
      .replaceAll('÷', '/')
      .replaceAll('−', '-')
      .replaceAll('**', '^')
      .replaceAll(RegExp(r'\s+'), '');
  final tokens = <_Tok>[];
  var i = 0;
  while (i < src.length) {
    final c = src[i];
    final n = _numberAt.matchAsPrefix(src, i);
    if (n != null) {
      final text = n.group(0)!;
      final end = i + text.length;
      // 1.2.3 or 1e3.5: a number typed wrong, not two numbers.
      if (end < src.length && src[end] == '.') {
        throw CalcError('"${src.substring(i, end + 1)}…" is not a number',
            friendly: true);
      }
      tokens.add(_Tok(_T.num, text, double.parse(text)));
      i = end;
      continue;
    }
    final w = _identAt.matchAsPrefix(src, i);
    if (w != null) {
      var word = w.group(0)!.toLowerCase();
      var len = w.group(0)!.length;
      // atan2(…), log2(…), log10(…): names with digits in them.
      {
        final base = RegExp(r'(\d+)\(').matchAsPrefix(src, i + len);
        if (base != null && mathFunctions.contains('$word${base.group(1)}')) {
          word = '$word${base.group(1)}';
          len += base.group(1)!.length;
        }
      }
      if (word == 'mod' && tokens.isNotEmpty && _endsValue(tokens.last)) {
        tokens.add(const _Tok(_T.op, 'mod'));
      } else if (word == 'deg' || word == 'rad') {
        tokens.add(_Tok(_T.op, word));
      } else {
        tokens.add(_Tok(_T.ident, word));
      }
      i += len;
      continue;
    }
    switch (c) {
      case '(':
      case '[':
        tokens.add(const _Tok(_T.lparen));
      case ')':
      case ']':
        tokens.add(const _Tok(_T.rparen));
      case ',':
      case ';':
        tokens.add(const _Tok(_T.comma));
      case '°':
        tokens.add(const _Tok(_T.op, 'deg'));
      case '+' || '-' || '*' || '/' || '%' || '^' || '!':
        tokens.add(_Tok(_T.op, c));
      default:
        throw CalcError('Unexpected char $c');
    }
    i++;
  }
  tokens.add(const _Tok(_T.end));
  return tokens;
}

bool _endsValue(_Tok t) =>
    t.t == _T.num ||
    t.t == _T.rparen ||
    (t.t == _T.ident && _constants.containsKey(t.s)) ||
    (t.t == _T.op && (t.s == '!' || t.s == 'deg' || t.s == 'rad'));

/// Recursive-descent evaluator.
///
///   expr    := term (('+' | '-') term)*
///   term    := unary (('*' | '/' | '%' | 'mod') unary | implicit power)*
///   unary   := ('-' | '+') unary | power
///   power   := postfix ('^' unary)?           right-associative
///   postfix := primary ('!' | '°' | 'deg' | 'rad')*
///   primary := number | constant | '(' expr ')' | fn '(' args ')' | fn power
///
/// So -2^2 = -4, 2^-1 = 0.5, 2^3^2 = 512, 2pi = 6.28…, 2(3+4) = 14,
/// sin 30° = 0.5, 5 mod 3 = 2, log(8, 2) = 3.
class _Parser {
  _Parser(this.toks, this.angle);
  final List<_Tok> toks;
  final AngleUnit angle;
  int p = 0;

  _Tok get cur => toks[p];
  bool isOp(String s) => cur.t == _T.op && cur.s == s;

  double parse() {
    if (cur.t == _T.end) throw CalcError('Bad expr');
    final v = expr();
    if (cur.t == _T.rparen) throw CalcError('Mismatched parens');
    if (cur.t == _T.comma) throw CalcError('Unexpected char ,');
    if (cur.t != _T.end) throw CalcError('Invalid expr');
    return v;
  }

  double expr() {
    var v = term();
    while (true) {
      if (isOp('+')) {
        p++;
        v = _add(v, term());
      } else if (isOp('-')) {
        p++;
        v = _add(v, -term());
      } else {
        return v;
      }
    }
  }

  bool get _startsPrimary =>
      cur.t == _T.num || cur.t == _T.lparen || cur.t == _T.ident;

  double term() {
    var v = unary();
    while (true) {
      if (isOp('*')) {
        p++;
        v = v * unary();
      } else if (isOp('/')) {
        p++;
        final b = unary();
        if (b == 0) throw CalcError('Division by zero', friendly: true);
        v = v / b;
      } else if (isOp('%') || isOp('mod')) {
        p++;
        final b = unary();
        if (b == 0) throw CalcError('Division by zero', friendly: true);
        v = v % b;
      } else if (_startsPrimary) {
        // Implicit multiplication: 2pi, 2(3+4), (1+2)(3+4), 3sqrt(2).
        v = v * power();
      } else {
        return v;
      }
    }
  }

  double unary() {
    if (isOp('-')) {
      p++;
      return -unary();
    }
    if (isOp('+')) {
      p++;
      return unary();
    }
    return power();
  }

  double power() {
    final base = postfix();
    if (isOp('^')) {
      p++;
      return _pow(base, unary());
    }
    return base;
  }

  double postfix() {
    var v = primary();
    while (true) {
      if (isOp('!')) {
        p++;
        v = _factorial(v);
      } else if (isOp('deg')) {
        p++;
        if (angle == AngleUnit.rad) v = v * math.pi / 180;
      } else if (isOp('rad')) {
        p++;
        if (angle == AngleUnit.deg) v = v * 180 / math.pi;
      } else {
        return v;
      }
    }
  }

  double primary() {
    final t = cur;
    switch (t.t) {
      case _T.num:
        p++;
        return t.v;
      case _T.lparen:
        p++;
        final v = expr();
        _close();
        return v;
      case _T.ident:
        p++;
        final c = _constants[t.s];
        if (c != null) return c;
        if (!mathFunctions.contains(t.s)) {
          throw CalcError('Unsupported function ${t.s}');
        }
        final List<double> args;
        if (cur.t == _T.lparen) {
          p++;
          args = [expr()];
          while (cur.t == _T.comma) {
            p++;
            args.add(expr());
          }
          _close();
        } else {
          // sin30, sqrt 16, √2: the function takes the next value.
          args = [power()];
        }
        return _call(t.s, args);
      case _T.comma:
        throw CalcError('Unexpected char ,');
      case _T.rparen:
        throw CalcError('Mismatched parens');
      case _T.op:
      case _T.end:
        throw CalcError('Bad expr');
    }
  }

  void _close() {
    if (cur.t != _T.rparen) throw CalcError('Mismatched parens');
    p++;
  }

  // ---- Arithmetic with honest edges ----

  static double _add(double a, double b) {
    final r = a + b;
    // 0.1 + 0.2 - 0.3 is 5.5e-17 in binary floating point; it is 0.
    final scale = math.max(a.abs(), b.abs());
    if (r != 0 && r.abs() < scale * 1e-14) return 0;
    return r;
  }

  static double _pow(double a, double b) {
    if (a == 0 && b < 0) throw CalcError('Division by zero', friendly: true);
    if (a < 0 && b != b.roundToDouble()) {
      // (-8)^(1/3) = -2: an odd root of a negative number is real.
      final inv = 1 / b;
      final k = inv.roundToDouble();
      if ((inv - k).abs() < 1e-9 && k.toInt().isOdd) {
        return -math.pow(-a, b).toDouble();
      }
      throw CalcError(
          'No real answer (a negative number to a fractional power)',
          friendly: true);
    }
    return math.pow(a, b).toDouble();
  }

  double _toRad(double a) => angle == AngleUnit.deg ? a * math.pi / 180 : a;
  double _fromRad(double r) => angle == AngleUnit.deg ? r * 180 / math.pi : r;

  /// sin/cos/tan with exact answers where the true one is exact: sin 180° is
  /// 0 (not 1.2e-16), and tan 90° has no value (not 1.6e16).
  double _trig(String name, double a) {
    if (angle == AngleUnit.deg && a % 90 == 0) {
      final q = ((a / 90).round() % 4 + 4) % 4;
      switch (name) {
        case 'sin':
          return const [0.0, 1.0, 0.0, -1.0][q];
        case 'cos':
          return const [1.0, 0.0, -1.0, 0.0][q];
        case 'tan':
          if (q.isOdd) throw _undefined('tan');
          return 0;
      }
    }
    final x = _toRad(a);
    double r;
    switch (name) {
      case 'sin':
        r = math.sin(x);
      case 'cos':
        r = math.cos(x);
      default:
        if (math.cos(x).abs() < 1e-12) throw _undefined('tan');
        r = math.tan(x);
    }
    return r.abs() < 1e-15 ? 0 : r;
  }

  static CalcError _undefined(String fn) =>
      CalcError('$fn is undefined at this angle', friendly: true);

  static int _whole(double v, String fn) {
    if (v != v.roundToDouble() || v < 0) {
      throw CalcError('$fn needs whole numbers 0 or more', friendly: true);
    }
    return v.toInt();
  }

  double _call(String name, List<double> args) {
    void count(int n, [int? most]) {
      if (args.length < n || args.length > (most ?? n)) {
        final what = n == (most ?? n) ? '$n' : '$n to $most';
        throw CalcError(
            '$name takes $what number${what == '1' ? '' : 's'}',
            friendly: true);
      }
    }

    final a = args.first;
    switch (name) {
      case 'sin' || 'cos' || 'tan':
        count(1);
        return _trig(name, a);
      case 'sec' || 'csc' || 'cot':
        count(1);
        final base =
            _trig(const {'sec': 'cos', 'csc': 'sin', 'cot': 'tan'}[name]!, a);
        if (base == 0) throw _undefined(name);
        return 1 / base;
      case 'asin' || 'acos':
        count(1);
        if (a < -1 || a > 1) {
          throw CalcError('$name needs a number from −1 to 1', friendly: true);
        }
        return _fromRad(name == 'asin' ? math.asin(a) : math.acos(a));
      case 'atan':
        count(1);
        return _fromRad(math.atan(a));
      case 'atan2':
        count(2);
        return _fromRad(math.atan2(a, args[1]));
      case 'sinh':
        count(1);
        return (math.exp(a) - math.exp(-a)) / 2;
      case 'cosh':
        count(1);
        return (math.exp(a) + math.exp(-a)) / 2;
      case 'tanh':
        count(1);
        if (a.abs() > 20) return a.sign;
        final e2 = math.exp(2 * a);
        return (e2 - 1) / (e2 + 1);
      case 'asinh':
        count(1);
        return math.log(a + math.sqrt(a * a + 1));
      case 'acosh':
        count(1);
        if (a < 1) throw CalcError('acosh needs a number of 1 or more', friendly: true);
        return math.log(a + math.sqrt(a * a - 1));
      case 'atanh':
        count(1);
        if (a <= -1 || a >= 1) {
          throw CalcError('atanh needs a number between −1 and 1',
              friendly: true);
        }
        return 0.5 * math.log((1 + a) / (1 - a));
      case 'sqrt':
        count(1);
        if (a < 0) {
          throw CalcError('No real square root of a negative number',
              friendly: true);
        }
        return math.sqrt(a);
      case 'cbrt':
        count(1);
        return a < 0
            ? -math.pow(-a, 1 / 3).toDouble()
            : math.pow(a, 1 / 3).toDouble();
      case 'root':
        count(2);
        final n = args[1];
        if (n == 0) throw CalcError('root needs a degree other than 0', friendly: true);
        if (a < 0) {
          if (n == n.roundToDouble() && n.toInt().isOdd) {
            return -math.pow(-a, 1 / n).toDouble();
          }
          throw CalcError('No real even root of a negative number',
              friendly: true);
        }
        return math.pow(a, 1 / n).toDouble();
      case 'exp':
        count(1);
        return math.exp(a);
      case 'ln' || 'log' || 'log2' || 'log10':
        count(1, name == 'log' ? 2 : 1);
        if (a <= 0) {
          throw CalcError('A logarithm needs a number above 0', friendly: true);
        }
        if (name == 'ln') return math.log(a);
        if (name == 'log2') return math.log(a) / math.ln2;
        if (name == 'log' && args.length == 2) {
          final b = args[1];
          if (b <= 0 || b == 1) {
            throw CalcError('A log base must be above 0 and not 1',
                friendly: true);
          }
          return math.log(a) / math.log(b);
        }
        return math.log(a) / math.ln10;
      case 'abs':
        count(1);
        return a.abs();
      case 'ceil':
        count(1);
        return a.ceilToDouble();
      case 'floor':
        count(1);
        return a.floorToDouble();
      case 'trunc':
        count(1);
        return a.truncateToDouble();
      case 'sign':
        count(1);
        return a.sign;
      case 'round':
        count(1, 2);
        if (args.length == 1) return a.roundToDouble();
        final d = _whole(args[1], 'round');
        final f = math.pow(10, d).toDouble();
        return (a * f).roundToDouble() / f;
      case 'ncr' || 'comb' || 'choose':
        count(2);
        final n = _whole(a, 'nCr');
        final r = _whole(args[1], 'nCr');
        if (r > n) return 0;
        final k = math.min(r, n - r);
        double c = 1;
        for (var j = 1; j <= k; j++) {
          c = c * (n - k + j) / j;
        }
        return c.roundToDouble();
      case 'npr' || 'perm':
        count(2);
        final n = _whole(a, 'nPr');
        final r = _whole(args[1], 'nPr');
        if (r > n) return 0;
        double c = 1;
        for (var j = n - r + 1; j <= n; j++) {
          c *= j;
        }
        return c;
      case 'fact':
        count(1);
        return _factorial(a);
      case 'gamma':
        count(1);
        if (a <= 0 && a == a.roundToDouble()) {
          throw CalcError('gamma is undefined at 0 and negative whole numbers',
              friendly: true);
        }
        return _gamma(a);
      case 'max':
        return args.reduce(math.max);
      case 'min':
        return args.reduce(math.min);
      case 'hypot':
        return math.sqrt(args.fold<double>(0, (s, v) => s + v * v));
      case 'gcd' || 'lcm':
        if (args.length < 2) count(2);
        int gcd(int x, int y) {
          while (y != 0) {
            final t = y;
            y = x % y;
            x = t;
          }
          return x;
        }
        final ints = [for (final v in args) _whole(v.abs(), name)];
        var acc = ints.first;
        for (final v in ints.skip(1)) {
          acc = name == 'gcd'
              ? gcd(acc, v)
              : (acc == 0 || v == 0 ? 0 : acc ~/ gcd(acc, v) * v);
        }
        return acc.toDouble();
      case 'mod':
        count(2);
        if (args[1] == 0) throw CalcError('Division by zero', friendly: true);
        return a % args[1];
      default:
        throw CalcError('Unsupported function $name');
    }
  }
}

double _factorial(double n) {
  if (n == n.roundToDouble()) {
    if (n < 0) {
      throw CalcError('No factorial for a negative whole number',
          friendly: true);
    }
    if (n > 170) throw CalcError('Too large to work out', friendly: true);
    double f = 1;
    for (var k = 2; k <= n.toInt(); k++) {
      f *= k;
    }
    return f;
  }
  // 0.5! = Γ(1.5) = √π / 2, as on a scientific calculator.
  return _gamma(n + 1);
}

/// Γ(x) by the Lanczos approximation (g = 7), about 15 significant figures.
double _gamma(double x) {
  if (x < 0.5) {
    return math.pi / (math.sin(math.pi * x) * _gamma(1 - x));
  }
  const g = 7.0;
  const c = [
    0.99999999999980993,
    676.5203681218851,
    -1259.1392167224028,
    771.32342877765313,
    -176.61502916214059,
    12.507343278686905,
    -0.13857109526572012,
    9.9843695780195716e-6,
    1.5056327351493116e-7,
  ];
  x -= 1;
  var a = c[0];
  final t = x + g + 0.5;
  for (var i = 1; i < 9; i++) {
    a += c[i] / (x + i);
  }
  return math.sqrt(2 * math.pi) * math.pow(t, x + 0.5) * math.exp(-t) * a;
}

/// Works [input] out. Throws [CalcError] for anything that has no real,
/// finite answer — division by zero, √−1, tan 90° — rather than returning
/// NaN or infinity.
double evaluate(String input, {AngleUnit angle = AngleUnit.rad}) {
  final tokens = _tokenize(input);
  // Name the longest unknown word ("Q3 receipts" → receipts): it tells prose
  // from a typo better than whichever word happened to come first.
  final unknown = [
    for (final t in tokens)
      if (t.t == _T.ident &&
          !_constants.containsKey(t.s) &&
          !mathFunctions.contains(t.s))
        t.s
  ]..sort((a, b) => b.length.compareTo(a.length));
  if (unknown.isNotEmpty) throw CalcError('Unsupported function ${unknown.first}');
  final v = _Parser(tokens, angle).parse();
  if (v.isNaN) throw CalcError('No real answer', friendly: true);
  if (v.isInfinite) throw CalcError('Too large to work out', friendly: true);
  return _tidy(v);
}

/// Rounds away binary floating-point noise: 1.1 + 2.2 = 3.3, not
/// 3.3000000000000003; log(1000) = 3, not 2.9999999999999996. Fifteen
/// significant digits is all a double holds reliably.
double _tidy(double v) {
  if (v == 0) return 0; // never -0
  if (v.abs() >= 1e15) return v;
  return double.parse(v.toStringAsPrecision(15));
}

/// True when [input] is a maths expression that works out — `sin(pi)`,
/// `e^2` — even though it has no digit in it.
bool isMathExpression(String input) {
  try {
    evaluate(input);
    return true;
  } on Object {
    return false;
  }
}

({int n, int d}) simplifyFraction(int num, int den) {
  if (den == 0) return (n: 0, d: 0);
  final sign = (num * den < 0) ? -1 : 1;
  int gcd(int a, int b) {
    a = a.abs();
    b = b.abs();
    while (b != 0) {
      final t = b;
      b = a % b;
      a = t;
    }
    return a == 0 ? 1 : a;
  }

  final g = gcd(num, den);
  return (n: sign * (num.abs() ~/ g), d: den.abs() ~/ g);
}
