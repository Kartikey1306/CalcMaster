import 'dart:math' as math;

class CalcError implements Exception {
  final String message;
  CalcError(this.message);
  @override
  String toString() => 'CalcError: $message';
}

class _Tok {
  final String type;
  final dynamic value;
  _Tok(this.type, this.value);
}

const Map<String, ({int prec, bool right})> _ops = {
  '+': (prec: 1, right: false),
  '-': (prec: 1, right: false),
  '*': (prec: 2, right: false),
  '/': (prec: 2, right: false),
  '%': (prec: 2, right: false),
  // Unary minus: tighter than × ÷ but looser than ^, so -2^2 = -4 and
  // 10^-3 = 0.001.
  'neg': (prec: 3, right: true),
  '^': (prec: 4, right: true),
};

double _apply(String op, double a, double b) {
  switch (op) {
    case '+':
      return a + b;
    case '-':
      return a - b;
    case '*':
      return a * b;
    case '/':
      return a / b;
    case '%':
      return a % b;
    case '^':
      return math.pow(a, b).toDouble();
    default:
      throw CalcError('Bad op $op');
  }
}

/// Angle unit trig functions are interpreted in. The scientific keypad's
/// Rad/Deg key flips this per evaluation; the parser itself stays stateless.
enum AngleUnit { rad, deg }

const _degPerRad = 180 / math.pi;

double _fn(String name, double a, AngleUnit angle) {
  // Only the trig family cares about the angle unit: inputs come in as
  // degrees, results of the inverse functions go back out as degrees.
  final inRad = angle == AngleUnit.deg ? a / _degPerRad : a;
  double outAngle(double rad) =>
      angle == AngleUnit.deg ? rad * _degPerRad : rad;

  switch (name) {
    case 'sin':
      return math.sin(inRad);
    case 'cos':
      return math.cos(inRad);
    case 'tan':
      return math.tan(inRad);
    case 'asin':
      return outAngle(math.asin(a));
    case 'acos':
      return outAngle(math.acos(a));
    case 'atan':
      return outAngle(math.atan(a));
    case 'sinh':
      return (math.exp(a) - math.exp(-a)) / 2;
    case 'cosh':
      return (math.exp(a) + math.exp(-a)) / 2;
    case 'tanh':
      final e2 = math.exp(2 * a);
      return (e2 - 1) / (e2 + 1);
    case 'asinh':
      return math.log(a + math.sqrt(a * a + 1));
    case 'acosh':
      return math.log(a + math.sqrt(a * a - 1));
    case 'atanh':
      return 0.5 * math.log((1 + a) / (1 - a));
    case 'cbrt':
      return a < 0
          ? -math.pow(-a, 1 / 3).toDouble()
          : math.pow(a, 1 / 3).toDouble();
    case 'log':
      return math.log(a) / math.ln10;
    case 'ln':
      return math.log(a);
    case 'sqrt':
      return math.sqrt(a);
    case 'exp':
      return math.exp(a);
    case 'abs':
      return a.abs();
    case 'ceil':
      return a.ceilToDouble();
    case 'floor':
      return a.floorToDouble();
    case 'round':
      return a.roundToDouble();
    default:
      throw CalcError('Unsupported function $name');
  }
}

double _factorial(double n) {
  if (n < 0 || n != n.toInt()) return double.nan;
  double f = 1;
  for (int k = 2; k <= n.toInt(); k++) {
    f *= k;
  }
  return f;
}

List<_Tok> _tokenize(String input) {
  final src = input
      .replaceAll('π', 'pi')
      .replaceAll('√', 'sqrt')
      .replaceAll(RegExp(r'\s+'), '');
  final tokens = <_Tok>[];
  int i = 0;
  while (i < src.length) {
    final c = src[i];
    if (RegExp(r'[0-9.]').hasMatch(c)) {
      int j = i;
      while (j < src.length && RegExp(r'[0-9.]').hasMatch(src[j])) {
        j++;
      }
      tokens.add(_Tok('num', double.parse(src.substring(i, j))));
      i = j;
      continue;
    }
    if (RegExp(r'[a-zA-Z]').hasMatch(c)) {
      int j = i;
      while (j < src.length && RegExp(r'[a-zA-Z]').hasMatch(src[j])) {
        j++;
      }
      final ident = src.substring(i, j).toLowerCase();
      if (ident == 'pi') {
        tokens.add(_Tok('num', math.pi));
      } else if (ident == 'e') {
        tokens.add(_Tok('num', math.e));
      } else {
        tokens.add(_Tok('fn', ident));
      }
      i = j;
      continue;
    }
    if (c == '(') {
      tokens.add(_Tok('lparen', null));
      i++;
      continue;
    }
    if (c == ')') {
      tokens.add(_Tok('rparen', null));
      i++;
      continue;
    }
    if (c == '!') {
      tokens.add(_Tok('op', '!'));
      i++;
      continue;
    }
    if (_ops.containsKey(c)) {
      final last = tokens.isEmpty ? null : tokens.last;
      // A minus that doesn't follow a value (a number, a closing bracket or
      // a factorial) negates what comes next.
      final afterValue = last != null &&
          (last.type == 'num' ||
              last.type == 'rparen' ||
              (last.type == 'op' && last.value == '!'));
      if (c == '-' && !afterValue) {
        tokens.add(_Tok('op', 'neg'));
        i++;
        continue;
      }
      tokens.add(_Tok('op', c));
      i++;
      continue;
    }
    throw CalcError('Unexpected char $c');
  }
  return tokens;
}

double evaluate(String input, {AngleUnit angle = AngleUnit.rad}) {
  final tokens = _tokenize(input);
  final out = <_Tok>[];
  final ops = <_Tok>[];

  for (final tok in tokens) {
    if (tok.type == 'num') {
      out.add(tok);
    } else if (tok.type == 'fn') {
      ops.add(tok);
    } else if (tok.type == 'op') {
      if (tok.value == '!') {
        // Postfix: applies to the value just completed — a number, a
        // bracket or a function call: 5!, (1+2)!, sqrt(9)!.
        if (out.isEmpty) throw CalcError("'!' must follow a number");
        out.add(tok);
        continue;
      }
      if (tok.value == 'neg') {
        // Prefix: nothing to its left to pop.
        ops.add(tok);
        continue;
      }
      while (ops.isNotEmpty) {
        final top = ops.last;
        if (top.type == 'fn') {
          out.add(ops.removeLast());
          continue;
        }
        if (top.type == 'op') {
          final opTop = _ops[top.value];
          final opCur = _ops[tok.value];
          if (opTop == null || opCur == null) break;
          if ((!opCur.right && opCur.prec <= opTop.prec) ||
              (opCur.right && opCur.prec < opTop.prec)) {
            out.add(ops.removeLast());
            continue;
          }
        }
        break;
      }
      ops.add(tok);
    } else if (tok.type == 'lparen') {
      ops.add(tok);
    } else if (tok.type == 'rparen') {
      while (ops.isNotEmpty && ops.last.type != 'lparen') {
        out.add(ops.removeLast());
      }
      if (ops.isEmpty) throw CalcError('Mismatched parens');
      ops.removeLast();
      if (ops.isNotEmpty && ops.last.type == 'fn') {
        out.add(ops.removeLast());
      }
    }
  }
  while (ops.isNotEmpty) {
    final t = ops.removeLast();
    if (t.type == 'lparen' || t.type == 'rparen') {
      throw CalcError('Mismatched parens');
    }
    out.add(t);
  }

  final stack = <double>[];
  for (final tok in out) {
    if (tok.type == 'num') {
      stack.add(tok.value as double);
    } else if (tok.type == 'op' && tok.value == '!') {
      if (stack.isEmpty) throw CalcError("'!' must follow a number");
      stack.add(_factorial(stack.removeLast()));
    } else if (tok.type == 'op' && tok.value == 'neg') {
      if (stack.isEmpty) throw CalcError('Bad expr');
      stack.add(-stack.removeLast());
    } else if (tok.type == 'op') {
      if (stack.length < 2) throw CalcError('Bad expr');
      final b = stack.removeLast();
      final a = stack.removeLast();
      stack.add(_apply(tok.value as String, a, b));
    } else if (tok.type == 'fn') {
      if (stack.isEmpty) throw CalcError('Bad expr');
      final a = stack.removeLast();
      stack.add(_fn(tok.value as String, a, angle));
    }
  }
  if (stack.length != 1) throw CalcError('Invalid expr');
  return stack.single;
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
