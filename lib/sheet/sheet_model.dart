/// The saved shape of a sheet. Pure Dart; results are never stored — they are
/// recomputed from the line text (and any pinned rate) every time.
library;

/// The rate an undated currency line was first worked out with. Kept so a
/// saved sheet shows the same answer next month; replaced only by an explicit
/// Re-price.
class RatePin {
  final String base;
  final String quote;
  final double rate;

  /// ECB reference date of [rate], `YYYY-MM-DD`.
  final String date;

  const RatePin({
    required this.base,
    required this.quote,
    required this.rate,
    required this.date,
  });

  Map<String, dynamic> toJson() =>
      {'base': base, 'quote': quote, 'rate': rate, 'date': date};

  static RatePin? fromJson(Object? json) {
    if (json is! Map) return null;
    final base = json['base'], quote = json['quote'];
    final rate = json['rate'], date = json['date'];
    if (base is! String || quote is! String || rate is! num || date is! String) {
      return null;
    }
    return RatePin(base: base, quote: quote, rate: rate.toDouble(), date: date);
  }

  bool matches(String b, String q) => base == b && quote == q;

  @override
  bool operator ==(Object other) =>
      other is RatePin &&
      other.base == base &&
      other.quote == quote &&
      other.rate == rate &&
      other.date == date;

  @override
  int get hashCode => Object.hash(base, quote, rate, date);
}

/// A rubber stamp on a line: the footer splits the total into what is paid
/// and what is still owed.
enum LineStamp {
  paid,
  pending;

  static LineStamp? fromName(Object? name) {
    for (final s in values) {
      if (s.name == name) return s;
    }
    return null;
  }
}

class SheetLine {
  final String text;
  final RatePin? pin;
  final LineStamp? stamp;
  const SheetLine(this.text, {this.pin, this.stamp});

  SheetLine withText(String t) => SheetLine(t, pin: pin, stamp: stamp);
  SheetLine withPin(RatePin? p) => SheetLine(text, pin: p, stamp: stamp);
  SheetLine withStamp(LineStamp? s) => SheetLine(text, pin: pin, stamp: s);

  Map<String, dynamic> toJson() => {
        'text': text,
        if (pin != null) 'pin': pin!.toJson(),
        if (stamp != null) 'stamp': stamp!.name,
      };

  static SheetLine fromJson(Object? json) {
    if (json is String) return SheetLine(json);
    if (json is! Map) return const SheetLine('');
    final text = json['text'];
    return SheetLine(text is String ? text : '',
        pin: RatePin.fromJson(json['pin']),
        stamp: LineStamp.fromName(json['stamp']));
  }
}

class Sheet {
  final String id;

  /// The user's title; empty means "use the first line".
  final String title;
  final int createdAt;
  final int updatedAt;
  final List<SheetLine> lines;

  const Sheet({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.lines,
  });

  /// True when there is nothing worth keeping: no title and every line blank.
  bool get isBlank =>
      title.trim().isEmpty && lines.every((l) => l.text.trim().isEmpty);

  /// [title], or the first non-blank line, or "Untitled sheet".
  String get displayTitle {
    if (title.trim().isNotEmpty) return title.trim();
    for (final l in lines) {
      final t = l.text.trim();
      if (t.isNotEmpty) return t.length > 40 ? '${t.substring(0, 40)}…' : t;
    }
    return 'Untitled sheet';
  }

  Sheet copyWith({
    String? id,
    String? title,
    int? createdAt,
    int? updatedAt,
    List<SheetLine>? lines,
  }) =>
      Sheet(
        id: id ?? this.id,
        title: title ?? this.title,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        lines: lines ?? this.lines,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'lines': [for (final l in lines) l.toJson()],
      };

  static Sheet? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    if (id is! String || id.isEmpty) return null;
    final rawLines = json['lines'];
    final lines = rawLines is List
        ? [for (final l in rawLines) SheetLine.fromJson(l)]
        : <SheetLine>[];
    int asInt(Object? v) => v is num ? v.toInt() : 0;
    final title = json['title'];
    return Sheet(
      id: id,
      title: title is String ? title : '',
      createdAt: asInt(json['createdAt']),
      updatedAt: asInt(json['updatedAt']),
      lines: lines.isEmpty ? [const SheetLine('')] : lines,
    );
  }
}
