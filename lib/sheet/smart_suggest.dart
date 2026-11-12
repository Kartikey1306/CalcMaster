/// Reads a loosely typed line — "finner 18 eurp for 2 peoer" — and offers
/// sheet lines that work it out: per person, with a tip, in the home
/// currency. Pure Dart, offline, typo-tolerant.
///
/// Every suggestion's [SmartSuggestion.line] is ordinary sheet grammar, so
/// what the user taps is exactly what the sheet then shows and saves.
library;

import '../lib_currency.dart' show isEcbCurrency;

class SmartSuggestion {
  /// Short chip text: "Per person", "+ 10% tip", "In USD".
  final String title;

  /// The sheet line that replaces what was typed.
  final String line;

  const SmartSuggestion(this.title, this.line);

  @override
  String toString() => '$title → $line';
}

/// What was understood from a line; exposed for tests.
class SmartReading {
  final String? label;
  final double? amount;
  final String? currency;
  final int? people;
  final double? tipPct;
  final double? taxPct;
  final double? offPct;
  final String? target;

  /// Several amounts on one line ("pizza 12 and drinks 8") are added up;
  /// [amount] is their sum. A single amount is a list of one.
  final List<double> parts;

  /// "3 tickets at 12 each", "3 nights 120": [amount] is quantity × price.
  final int? quantity;
  final double? unitPrice;

  const SmartReading({
    this.label,
    this.amount,
    this.currency,
    this.people,
    this.tipPct,
    this.taxPct,
    this.offPct,
    this.target,
    this.parts = const [],
    this.quantity,
    this.unitPrice,
  });

  bool get understood =>
      amount != null &&
      (currency != null ||
          people != null ||
          tipPct != null ||
          taxPct != null ||
          offPct != null ||
          target != null ||
          label != null ||
          quantity != null ||
          parts.length > 1);
}

// ---------------------------------------------------------------------------
// Vocabulary
// ---------------------------------------------------------------------------

const _currencyWords = {
  'euro': 'EUR', 'euros': 'EUR', 'eur': 'EUR', '€': 'EUR',
  'dollar': 'USD', 'dollars': 'USD', 'usd': 'USD', 'bucks': 'USD', r'$': 'USD',
  'pound': 'GBP', 'pounds': 'GBP', 'quid': 'GBP', 'gbp': 'GBP', '£': 'GBP',
  'sterling': 'GBP',
  'rupee': 'INR', 'rupees': 'INR', 'rs': 'INR', 'inr': 'INR', '₹': 'INR',
  'yen': 'JPY', 'jpy': 'JPY', '¥': 'JPY',
  'yuan': 'CNY', 'rmb': 'CNY', 'renminbi': 'CNY', 'cny': 'CNY',
  'won': 'KRW', 'krw': 'KRW', '₩': 'KRW',
  'franc': 'CHF', 'francs': 'CHF', 'chf': 'CHF',
  'real': 'BRL', 'reais': 'BRL', 'brl': 'BRL',
  'peso': 'MXN', 'pesos': 'MXN', 'mxn': 'MXN',
  'zloty': 'PLN', 'pln': 'PLN',
  'krona': 'SEK', 'kronor': 'SEK', 'sek': 'SEK',
  'krone': 'NOK', 'kroner': 'NOK', 'nok': 'NOK',
  'lira': 'TRY', 'try': 'TRY',
  'rand': 'ZAR', 'zar': 'ZAR',
  'baht': 'THB', 'thb': 'THB',
  'ringgit': 'MYR', 'myr': 'MYR',
  'rupiah': 'IDR', 'idr': 'IDR',
  'forint': 'HUF', 'huf': 'HUF',
  'koruna': 'CZK', 'czk': 'CZK',
  'aud': 'AUD', 'cad': 'CAD', 'nzd': 'NZD', 'sgd': 'SGD', 'hkd': 'HKD',
  'dkk': 'DKK', 'ron': 'RON', 'php': 'PHP', 'ils': 'ILS', 'isk': 'ISK',
};

const _peopleWords = [
  'people', 'persons', 'person', 'ppl', 'pax', 'guys', 'friends', 'heads',
  'adults', 'ways', 'of us', 'mates',
];

const _tipWords = ['tip', 'tips', 'gratuity', 'service'];
const _taxWords = ['tax', 'vat', 'gst', 'sales tax'];
const _offWords = ['off', 'discount', 'sale'];
const _fillers = {
  'for', 'the', 'a', 'an', 'and', 'with', 'split', 'between', 'among',
  'each', 'per', 'plus', 'at', 'of', 'on', 'my', 'our', 'was', 'is', 'cost',
  'costs', 'paid', 'spent', 'total', 'bill', 'in', 'to', 'into', 'us', 'me',
  'x', 'times', 'apiece', 'ea', 'also', 'came', 'it',
};

/// Things counted before a price: "3 nights 120 EUR", "2 tickets 15 each".
const _countWords = {
  'night', 'nights', 'day', 'days', 'hour', 'hours', 'hrs', 'week', 'weeks',
  'month', 'months', 'ticket', 'tickets', 'item', 'items', 'piece', 'pieces',
  'pcs', 'unit', 'units', 'round', 'rounds', 'bottle', 'bottles', 'box',
  'boxes', 'pack', 'packs', 'pass', 'passes', 'room', 'rooms', 'seat',
  'seats', 'lesson', 'lessons', 'class', 'classes', 'session', 'sessions',
  'beers', 'coffees', 'meals', 'shirts', 'kg', 'kilos', 'litres', 'liters',
};

/// Everyday things people total up, for fixing typos in the label.
const _labelWords = [
  'dinner', 'lunch', 'breakfast', 'brunch', 'coffee', 'drinks', 'beer',
  'groceries', 'grocery', 'food', 'snacks', 'pizza', 'restaurant', 'cafe',
  'hotel', 'hostel', 'airbnb', 'rent', 'taxi', 'uber', 'cab', 'bus', 'train',
  'flight', 'flights', 'fuel', 'petrol', 'gas', 'parking', 'tickets', 'ticket',
  'museum', 'movie', 'cinema', 'concert', 'gift', 'gifts', 'shopping',
  'clothes', 'electricity', 'water', 'internet', 'phone', 'insurance',
  'gym', 'trip', 'holiday', 'vacation', 'tour', 'ferry', 'car', 'bike',
  'books', 'school', 'tuition', 'doctor', 'medicine', 'pharmacy', 'salary',
  'bills', 'utilities', 'subscription', 'netflix', 'birthday', 'party',
];

// ---------------------------------------------------------------------------
// Fuzzy matching
// ---------------------------------------------------------------------------

int _distance(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;
  var prev = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 1; i <= a.length; i++) {
    final cur = List<int>.filled(b.length + 1, 0)..[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      cur[j] = [prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + cost]
          .reduce((x, y) => x < y ? x : y);
    }
    prev = cur;
  }
  return prev[b.length];
}

/// The closest of [words] to [w], allowing about one slip per three letters.
/// Short words (≤ 3 letters) must match exactly.
String? _closest(String w, Iterable<String> words) {
  if (w.length <= 3) return words.contains(w) ? w : null;
  final allowed = w.length <= 5 ? 1 : 2;
  String? best;
  var bestD = allowed + 1;
  for (final c in words) {
    if (c.length <= 3) continue;
    final d = _distance(w, c);
    if (d < bestD) {
      best = c;
      bestD = d;
    }
  }
  return best;
}

bool _isPeopleWord(String w) {
  if (_closest(w, _peopleWords) != null) return true;
  // "peoer", "peeps", "perso…": a typed start of people / persons.
  return w.length >= 3 && (w.startsWith('peo') || w.startsWith('pers'));
}

String? _currencyOf(String w) {
  final exact = _currencyWords[w];
  if (exact != null) return exact;
  if (w.length == 3 && isEcbCurrency(w.toUpperCase())) return w.toUpperCase();
  final near = _closest(w, _currencyWords.keys.where((k) => k.length > 3));
  return near == null ? null : _currencyWords[near];
}

// ---------------------------------------------------------------------------
// Reading
// ---------------------------------------------------------------------------

// A number may carry thousands commas (1,200), a decimal (18.50 or 18,50),
// a "k" for thousands (2k) and a trailing %.
final _token = RegExp(
    r"[€£$¥₹₩@×]|\d[\d,]*(?:\.\d+)?(?:k(?![a-z]))?%?|[A-Za-z][A-Za-z']*",
    caseSensitive: false);

final _thousands = RegExp(r'^\d{1,3}(?:,\d{3})+(?:\.\d+)?$');

/// "1,200" → 1200, "18,50" → 18.5, "2k" → 2000, "15%" → 15.
double? _parseNumber(String t) {
  var s = t.toLowerCase().replaceAll('%', '');
  var scale = 1.0;
  if (s.endsWith('k')) {
    scale = 1000;
    s = s.substring(0, s.length - 1);
  }
  if (s.isEmpty || !RegExp(r'^\d').hasMatch(s)) return null;
  if (_thousands.hasMatch(s)) {
    s = s.replaceAll(',', '');
  } else {
    s = s.replaceAll(',', '.');
  }
  final v = double.tryParse(s);
  return v == null ? null : v * scale;
}

const _numberWords = {
  'one': 1, 'two': 2, 'three': 3, 'four': 4, 'five': 5, 'six': 6,
  'seven': 7, 'eight': 8, 'nine': 9, 'ten': 10, 'eleven': 11, 'twelve': 12,
  'couple': 2, 'half': 2, 'halves': 2,
};

/// Understands what it can of [input].
SmartReading readLine(String input) {
  final raw = input.trim();
  if (raw.isEmpty) return const SmartReading();
  final tokens = [
    for (final m in _token.allMatches(raw)) m.group(0)!,
  ];
  final lower = [for (final t in tokens) t.toLowerCase()];

  double? amount;
  String? currency;
  int? people;
  double? tip, tax, off;
  String? target;
  var parts = <double>[];
  int? quantity;
  double? unitPrice;
  String? countNote;
  final labelWords = <String>[];
  final used = List<bool>.filled(tokens.length, false);

  double? numAt(int i) {
    if (i < 0 || i >= tokens.length) return null;
    return _parseNumber(tokens[i]);
  }

  /// A currency word or sign right beside token [i].
  bool hasCurrencyBeside(int i) => [i - 1, i + 1].any((j) =>
      j >= 0 &&
      j < lower.length &&
      !used[j] &&
      numAt(j) == null &&
      // "persons" is one slip from "pesos": a people word is never money.
      !_isPeopleWord(lower[j]) &&
      _currencyOf(lower[j]) != null);

  bool isPct(int i) => i >= 0 && i < tokens.length && tokens[i].endsWith('%');

  String? wordAt(int i) =>
      i >= 0 && i < lower.length && RegExp(r'^[a-z]').hasMatch(lower[i])
          ? lower[i]
          : null;

  // Pass 1: "in usd" / "to dollars" — the target currency.
  for (var i = 0; i < lower.length - 1; i++) {
    if (lower[i] == 'in' || lower[i] == 'to' || lower[i] == 'into') {
      final c = _currencyOf(lower[i + 1]);
      if (c != null) {
        target = c;
        used[i] = used[i + 1] = true;
      }
    }
  }

  // Pass 2: percentages — tip, tax, discount — by the nearest keyword.
  for (var i = 0; i < tokens.length; i++) {
    if (used[i] || !isPct(i)) continue;
    final p = numAt(i)!;
    String? kind;
    for (final j in [i + 1, i - 1, i + 2, i - 2]) {
      final w = wordAt(j);
      if (w == null || used[j]) continue;
      if (_closest(w, _tipWords) != null || w == 'tip') {
        kind = 'tip';
      } else if (_closest(w, _taxWords) != null || _taxWords.contains(w)) {
        kind = 'tax';
      } else if (_offWords.contains(w) || _closest(w, _offWords) != null) {
        kind = 'off';
      }
      if (kind != null) {
        used[j] = true;
        break;
      }
    }
    kind ??= 'tip';
    used[i] = true;
    switch (kind) {
      case 'tip':
        tip = p;
      case 'tax':
        tax = p;
      default:
        off = p;
    }
  }

  // Pass 2b: "tip 15", "15 tip", "tax 8" — a whole number from 1 to 30 right
  // beside a tip or tax word, with no currency of its own, is a percentage.
  for (var i = 0; i < tokens.length; i++) {
    if (used[i] || isPct(i)) continue;
    final n = numAt(i);
    if (n == null || n != n.roundToDouble() || n < 1 || n > 30) continue;
    if (hasCurrencyBeside(i)) continue;
    for (final j in [i - 1, i + 1]) {
      final w = wordAt(j);
      if (w == null || used[j]) continue;
      if (tip == null && (w == 'tip' || _closest(w, _tipWords) != null)) {
        tip = n;
      } else if (tax == null &&
          (_taxWords.contains(w) || _closest(w, _taxWords) != null)) {
        tax = n;
      } else {
        continue;
      }
      used[i] = used[j] = true;
      break;
    }
  }

  // Pass 3: people — "2 people", "two people", "split 4 ways", "in half".
  for (var i = 0; i < tokens.length; i++) {
    if (used[i] || isPct(i)) continue;
    final next = wordAt(i + 1);
    final peopleAfter = next != null &&
        !used[i + 1] &&
        (next == 'ways' || _isPeopleWord(next));
    final n = numAt(i) ?? _numberWords[lower[i]]?.toDouble();
    if (n != null &&
        n == n.roundToDouble() &&
        n >= 1 &&
        n <= 1000 &&
        peopleAfter &&
        !hasCurrencyBeside(i)) {
      people = n.toInt();
      used[i] = used[i + 1] = true;
      break;
    }
    if (lower[i] == 'half' || lower[i] == 'halves') {
      people = 2;
      used[i] = true;
      if (i > 0 && lower[i - 1] == 'in') used[i - 1] = true;
      break;
    }
  }

  // "for 2", "split 3", "between four" with no people word: only when another
  // number is left over to be the amount, and never a number with a currency.
  if (people == null) {
    final numbers = [
      for (var i = 0; i < tokens.length; i++)
        if (!used[i] && !isPct(i) && numAt(i) != null) i
    ];
    for (var i = 0; i < tokens.length; i++) {
      if (used[i] || isPct(i)) continue;
      final n = numAt(i) ?? _numberWords[lower[i]]?.toDouble();
      if (n == null || n != n.roundToDouble() || n < 2 || n > 100) continue;
      if (hasCurrencyBeside(i)) continue;
      final isDigit = numAt(i) != null;
      if (isDigit && numbers.length < 2) continue;
      final prev = wordAt(i - 1);
      if ({'for', 'between', 'among', 'by', 'split'}.contains(prev)) {
        // "for 2 coffees" counts coffees, not people.
        final next = wordAt(i + 1);
        if (next != null && _countWords.contains(next)) continue;
        people = n.toInt();
        used[i] = true;
        break;
      }
    }
  }

  // Pass 4: the amounts, and a currency beside any of them.
  final amountAt = [
    for (var i = 0; i < tokens.length; i++)
      if (!used[i] && !isPct(i) && numAt(i) != null) i
  ];
  for (final i in amountAt) {
    used[i] = true;
  }
  for (final i in amountAt) {
    for (final j in [i + 1, i - 1]) {
      if (j < 0 || j >= tokens.length || used[j]) continue;
      final c = _currencyOf(lower[j]);
      if (c != null) {
        currency ??= c;
        used[j] = true;
        break;
      }
    }
    if (currency != null) break;
  }

  // A currency word anywhere else, if none sat next to an amount.
  if (currency == null) {
    for (var i = 0; i < tokens.length; i++) {
      if (used[i]) continue;
      final c = _currencyOf(lower[i]);
      if (c != null && lower[i].length > 1) {
        currency = c;
        used[i] = true;
        break;
      }
    }
  }

  if (amountAt.length == 2) {
    // Quantity × price: "3 x 12", "3 @ 12", "3 tickets at 12 each",
    // "3 nights 120 EUR". The count is a whole number; the price may not be.
    final a = amountAt[0], b = amountAt[1];
    final between = [for (var k = a + 1; k < b; k++) lower[k]];
    final after = [
      for (var k = b + 1; k < tokens.length && k <= b + 2; k++) lower[k]
    ];
    final timesWord = between.any(
        (w) => const {'x', '×', '@', 'at', 'times'}.contains(w));
    final eachWord =
        after.any((w) => const {'each', 'apiece', 'ea'}.contains(w));
    final counted =
        a + 1 < tokens.length && _countWords.contains(lower[a + 1]);
    final qa = numAt(a)!, pb = numAt(b)!;
    final countAfterPrice =
        b + 1 < tokens.length && _countWords.contains(lower[b + 1]);
    if (!counted && !timesWord && !eachWord && countAfterPrice) {
      // "8 EUR for 2 coffees": the 2 counts what was bought; the price is
      // the total.
      countNote = '${tokens[b]} ${tokens[b + 1]}';
      used[b + 1] = true;
      amountAt.removeAt(1);
    } else if ((timesWord || eachWord || counted) &&
        qa == qa.roundToDouble() &&
        qa >= 1 &&
        qa <= 1000) {
      quantity = qa.toInt();
      unitPrice = pb;
      amount = qa * pb;
      for (var k = a + 1; k < b; k++) {
        if (const {'x', '×', '@', 'at', 'times'}.contains(lower[k])) {
          used[k] = true;
        }
      }
      if (counted) {
        countNote = '$quantity ${tokens[a + 1]}';
        used[a + 1] = true;
      }
    }
  }
  if (quantity == null && amountAt.isNotEmpty) {
    // Several amounts are added up ("pizza 12 and drinks 8").
    parts = [for (final i in amountAt.take(12)) numAt(i)!];
    amount = parts.fold<double>(0, (s, v) => s + v);
  }

  // Whatever words are left (before the amount, mostly) are the label.
  for (var i = 0; i < tokens.length; i++) {
    if (used[i]) continue;
    final w = lower[i];
    if (!RegExp(r'^[a-z]').hasMatch(w)) continue;
    if (_fillers.contains(w)) continue;
    if (!_labelWords.contains(w) && _isPeopleWord(w)) continue;
    if (_closest(w, _tipWords) != null && tip == null) {
      continue;
    }
    final fixed = _closest(w, _labelWords) ?? tokens[i];
    labelWords.add(fixed);
  }
  String? label;
  if (labelWords.isNotEmpty) {
    final l = labelWords.join(' ');
    label = l[0].toUpperCase() + l.substring(1);
  }
  if (countNote != null) {
    label = label == null ? countNote : '$label, $countNote';
  }

  return SmartReading(
    label: label,
    amount: amount,
    currency: currency,
    people: people,
    tipPct: tip,
    taxPct: tax,
    offPct: off,
    target: target,
    parts: parts,
    quantity: quantity,
    unitPrice: unitPrice,
  );
}

// ---------------------------------------------------------------------------
// Suggesting
// ---------------------------------------------------------------------------

String _n(double v) {
  if (v == v.roundToDouble()) return v.toInt().toString();
  return v.toString();
}

/// Suggestions for a line the sheet couldn't work out as typed. Empty when
/// nothing useful was understood.
///
/// [homeCurrency] (the region's) adds an "In USD" style suggestion for a
/// foreign amount; [customaryTip] adds "+ N% tip" when someone is splitting a
/// bill and named no tip.
List<SmartSuggestion> suggestLines(
  String input, {
  String? homeCurrency,
  double? customaryTip,
}) {
  final r = readLine(input);
  if (!r.understood) return const [];
  final amt = r.amount!;
  final cur = r.currency;
  final label = r.label;

  /// The amount in sheet grammar, split [split] ways. The sheet lets only one
  /// amount carry a currency when dividing, so a split sum is written
  /// "(12 + 8) / 2 EUR", and an unsplit one "12 EUR + 8 EUR".
  String amountExpr(int? split) {
    final q = r.quantity, u = r.unitPrice;
    if (q != null && u != null) {
      final e = cur == null ? '${_n(u)} * $q' : '${_n(u)} $cur * $q';
      return split == null ? e : '$e / $split';
    }
    if (r.parts.length > 1) {
      final sum = r.parts.map(_n).join(' + ');
      if (split != null) {
        return cur == null ? '($sum) / $split' : '($sum) / $split $cur';
      }
      return cur == null
          ? sum
          : r.parts.map((p) => '${_n(p)} $cur').join(' + ');
    }
    final b = cur == null ? _n(amt) : '${_n(amt)} $cur';
    return split == null ? b : '$b / $split';
  }

  // Percent steps must end the line ("A / 2 + 18%"): the sheet reads a
  // trailing "± N%" as a markup and chains them left to right, while a % in
  // the middle of a sum is a plain fraction.
  final steps = StringBuffer();
  final notes = <String>[];
  if (r.offPct != null) {
    steps.write(' - ${_n(r.offPct!)}%');
    notes.add('${_n(r.offPct!)}% off');
  }
  if (r.taxPct != null) {
    steps.write(' + ${_n(r.taxPct!)}%');
    notes.add('${_n(r.taxPct!)}% tax');
  }
  if (r.tipPct != null) {
    steps.write(' + ${_n(r.tipPct!)}%');
    notes.add('${_n(r.tipPct!)}% tip');
  }

  String line(String what, {int? split, double? extraTip, String? into}) {
    final n = [
      ...notes,
      if (extraTip != null) '${_n(extraTip)}% tip',
    ];
    final head = [
      if (label != null) label,
      if (what.isNotEmpty) what,
      if (n.isNotEmpty) '(${n.join(', ')})',
    ].join(' ');
    final body = StringBuffer(amountExpr(split));
    body.write(steps);
    if (extraTip != null) body.write(' + ${_n(extraTip)}%');
    if (into != null) body.write(' in $into');
    return head.isEmpty ? '$body' : '$head: $body';
  }

  final out = <SmartSuggestion>[];
  final p = r.people != null && r.people! > 1 ? r.people : null;
  final tipWorthy = r.tipPct == null &&
      r.taxPct == null &&
      r.offPct == null &&
      (customaryTip ?? 0) > 0;

  if (p != null) {
    out.add(SmartSuggestion('Per person', line('per person', split: p, into: r.target)));
    if (tipWorthy) {
      out.add(SmartSuggestion('+ ${_n(customaryTip!)}% tip, each',
          line('per person', split: p, extraTip: customaryTip, into: r.target)));
    }
    out.add(SmartSuggestion('Whole bill', line('', into: r.target)));
  } else {
    out.add(SmartSuggestion(
        notes.isEmpty ? 'Work it out' : notes.join(', '),
        line('', into: r.target)));
    final first = label?.toLowerCase().split(' ').first;
    if (tipWorthy &&
        first != null &&
        _closest(first, const [
              'dinner', 'lunch', 'breakfast', 'brunch', 'drinks', 'restaurant',
              'pizza', 'coffee', 'cafe', 'taxi', 'uber', 'cab', 'food',
            ]) !=
            null) {
      out.add(SmartSuggestion('+ ${_n(customaryTip!)}% tip',
          line('', extraTip: customaryTip, into: r.target)));
    }
  }

  // Convert to the home currency when the amount is foreign.
  if (cur != null &&
      r.target == null &&
      homeCurrency != null &&
      homeCurrency != cur &&
      isEcbCurrency(cur) &&
      isEcbCurrency(homeCurrency)) {
    out.add(SmartSuggestion('In $homeCurrency${p != null ? ', each' : ''}',
        line(p != null ? 'per person' : '', split: p, into: homeCurrency)));
  }

  // No duplicates.
  final seen = <String>{};
  return [
    for (final s in out)
      if (seen.add(s.line)) s,
  ];
}
