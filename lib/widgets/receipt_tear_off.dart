import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/tokens.dart';

/// "Add to sheet", made visible: a till receipt with the line on it prints
/// out of the bottom bar, is torn off with a jerk, and flies up onto the
/// sheet. Skipped when the system asks for reduced motion.
Future<void> playReceiptTearOff(BuildContext context, String line) async {
  if (MediaQuery.of(context).disableAnimations) return;
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  final done = Completer<void>();
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _TearOff(
      line: line,
      colors: context.ledger,
      onDone: () {
        entry.remove();
        if (!done.isCompleted) done.complete();
      },
    ),
  );
  overlay.insert(entry);
  return done.future;
}

class _TearOff extends StatefulWidget {
  final String line;
  final LedgerColors colors;
  final VoidCallback onDone;
  const _TearOff(
      {required this.line, required this.colors, required this.onDone});

  @override
  State<_TearOff> createState() => _TearOffState();
}

class _TearOffState extends State<_TearOff>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1150))
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onDone();
    });

  bool _tore = false;

  @override
  void initState() {
    super.initState();
    _c.addListener(() {
      if (!_tore && _c.value > 0.45) {
        _tore = true;
        HapticFeedback.mediumImpact();
      }
    });
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final c = widget.colors;
    final colon = widget.line.indexOf(': ');
    final label = colon > 0 ? widget.line.substring(0, colon) : null;
    final value =
        colon > 0 ? widget.line.substring(colon + 2) : widget.line;
    final width = math.min(size.width - 64, 340.0);

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) {
          final t = _c.value;
          // 0 – .40  prints upward out of the bar
          // .40 – .52 a sharp tug: the tear
          // .52 – 1  flies up and away to the sheet, shrinking
          final print = Curves.easeOutCubic
              .transform((t / 0.40).clamp(0.0, 1.0));
          final tug = t < 0.40 || t > 0.52
              ? 0.0
              : math.sin((t - 0.40) / 0.12 * math.pi);
          final fly = Curves.easeInCubic
              .transform(((t - 0.52) / 0.48).clamp(0.0, 1.0));

          final bottom = 72.0 + 140 * print + 18 * tug + size.height * 0.75 * fly;
          final angle = -0.04 * tug + -0.22 * fly;
          final scale = 1 - 0.55 * fly;
          final opacity = (1 - fly * 1.1).clamp(0.0, 1.0);

          return Stack(children: [
            Positioned(
              left: (size.width - width) / 2 - 60 * fly,
              bottom: bottom,
              width: width,
              child: Opacity(
                opacity: opacity,
                child: Transform.rotate(
                  angle: angle,
                  child: Transform.scale(scale: scale, child: child),
                ),
              ),
            ),
          ]);
        },
        child: _Slip(label: label, value: value, colors: c),
      ),
    );
  }
}

class _Slip extends StatelessWidget {
  final String? label;
  final String value;
  final LedgerColors colors;
  const _Slip({this.label, required this.value, required this.colors});

  @override
  Widget build(BuildContext context) {
    final c = colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final paper = dark
        ? c.surface
        : Color.alphaBlend(Colors.white.withValues(alpha: 0.75), c.paper);
    return Material(
      type: MaterialType.transparency,
      child: DecoratedBox(
        decoration: BoxDecoration(boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 18,
              offset: const Offset(0, 8)),
        ]),
        child: ClipPath(
          clipper: const _ZigZag(),
          child: Container(
            color: paper,
            padding: const EdgeInsets.fromLTRB(
                Spacing.lg, Spacing.md, Spacing.lg, Spacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('CALCMASTER  ·  ADDED',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontFamily: Fonts.figures,
                        color: c.inkSoft,
                        fontSize: 10,
                        letterSpacing: 2)),
                const SizedBox(height: Spacing.sm),
                if (label != null)
                  Text(label!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontFamily: Fonts.figures,
                          color: c.ink,
                          fontSize: 13)),
                const SizedBox(height: Spacing.xs),
                Text(value,
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontFamily: Fonts.figures,
                        fontFeatures: Fonts.tabular,
                        color: c.result,
                        fontSize: 22,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A slip with a torn, saw-tooth bottom edge.
class _ZigZag extends CustomClipper<Path> {
  const _ZigZag();

  @override
  Path getClip(Size size) {
    const tooth = 8.0;
    final p = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height - tooth);
    var x = size.width;
    var down = true;
    while (x > 0) {
      x = math.max(0, x - tooth);
      p.lineTo(x, down ? size.height : size.height - tooth);
      down = !down;
    }
    return p..close();
  }

  @override
  bool shouldReclip(_ZigZag old) => false;
}
