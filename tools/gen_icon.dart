// =====================================================================
//  CalcMaster · Icon + Splash Asset Generator
// =====================================================================
//
//  Run from the project root:
//      dart run tools/gen_icon.dart
//
//  The mark is a heavy "=" in bottle green on ruled paper, with a short
//  copper double underline — the "total" mark. No Material glyph, no
//  gradient. Colours are the "Ledger" palette in lib/theme/tokens.dart.
//
//  Outputs:
//      assets/icon/app_icon.png             1024×1024, full-bleed paper
//      assets/icon/app_icon_foreground.png  1024×1024, transparent (Android
//                                           adaptive foreground)
//      assets/splash/splash_logo.png        720×720 mark for the paper
//                                           launch screen
//      assets/splash/splash_logo_dark.png   720×720 mark for Night ledger
//
//  After running this, run:
//      dart run flutter_launcher_icons
//      dart run flutter_native_splash:create
//
// =====================================================================

import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

const int kIconSize = 1024;
const int kSplashSize = 720;

// "Ledger" (must mirror lib/theme/tokens.dart)
final _paper = img.ColorRgba8(0xF4, 0xF0, 0xE6, 255);
final _rule = img.ColorRgba8(0xD9, 0xD2, 0xC1, 255);
final _green = img.ColorRgba8(0x2C, 0x5E, 0x4F, 255);
final _copper = img.ColorRgba8(0x9A, 0x4A, 0x14, 255);
// "Night ledger"
final _nightGreen = img.ColorRgba8(0x7F, 0xB8, 0x9F, 255);
final _nightCopper = img.ColorRgba8(0xE2, 0xA2, 0x73, 255);

void main() {
  Directory('assets/icon').createSync(recursive: true);
  Directory('assets/splash').createSync(recursive: true);

  final icon = _icon(background: true);
  final foreground = _icon(background: false);
  final splash = _splash(_green, _copper);
  final splashDark = _splash(_nightGreen, _nightCopper);

  File('assets/icon/app_icon.png').writeAsBytesSync(img.encodePng(icon));
  File('assets/icon/app_icon_foreground.png')
      .writeAsBytesSync(img.encodePng(foreground));
  File('assets/splash/splash_logo.png').writeAsBytesSync(img.encodePng(splash));
  File('assets/splash/splash_logo_dark.png')
      .writeAsBytesSync(img.encodePng(splashDark));

  stdout.writeln('✓ assets/icon/app_icon.png            (1024×1024)');
  stdout.writeln('✓ assets/icon/app_icon_foreground.png (1024×1024)');
  stdout.writeln('✓ assets/splash/splash_logo.png       (720×720)');
  stdout.writeln('✓ assets/splash/splash_logo_dark.png  (720×720)');
}

/// The app icon: ruled paper and the "=" total mark. [background] false gives
/// the Android adaptive foreground (the paper colour comes from
/// `adaptive_icon_background`), with the mark kept inside the safe zone.
img.Image _icon({required bool background}) {
  final s = kIconSize;
  final image = img.Image(width: s, height: s, numChannels: 4);
  img.fill(image,
      color: background ? _paper : img.ColorRgba8(0, 0, 0, 0));

  // The adaptive foreground is cropped to a circle or squircle: keep the
  // mark (and the rules it sits on) closer to the centre so it survives
  // every launcher mask.
  final scale = background ? 1.0 : 0.72;

  // Three horizontal rules across the page; the "=" is written on the
  // middle one.
  final ruleH = (s * 0.012).round();
  for (final f in [0.24, 0.64, 0.84]) {
    final y = (s * (0.5 + (f - 0.5) * scale)).round();
    _rect(image, 0, y - ruleH ~/ 2, s, y - ruleH ~/ 2 + ruleH, 0, _rule);
  }

  _mark(image, scale: scale, green: _green, copper: _copper);
  return image;
}

img.Image _splash(img.Color green, img.Color copper) {
  final image =
      img.Image(width: kSplashSize, height: kSplashSize, numChannels: 4);
  img.fill(image, color: img.ColorRgba8(0, 0, 0, 0));
  _mark(image, scale: 0.9, green: green, copper: copper, centred: true);
  return image;
}

/// A heavy "=" right of centre, and a short double underline beneath its
/// right end.
void _mark(img.Image image,
    {required double scale,
    required img.Color green,
    required img.Color copper,
    bool centred = false}) {
  final w = image.width;
  final h = image.height;
  final barW = (w * 0.44 * scale).round();
  final barH = (w * 0.095 * scale).round();
  final gap = (w * 0.085 * scale).round();
  final radius = math.max(2, (w * 0.012 * scale).round());
  // Right of centre on the icon; centred on the splash.
  final cx = centred ? w ~/ 2 : (w * (0.5 + 0.06 * scale)).round();
  final cy = (h * (centred ? 0.46 : 0.5 + (0.4675 - 0.5) * scale)).round();
  final left = cx - barW ~/ 2;
  final top1 = cy - gap ~/ 2 - barH;
  final top2 = cy + gap ~/ 2;
  _rect(image, left, top1, left + barW, top1 + barH, radius, green);
  _rect(image, left, top2, left + barW, top2 + barH, radius, green);

  // The total mark: two thin copper lines, short, under the right end.
  final ulW = (barW * 0.5).round();
  final ulH = math.max(2, (w * 0.022 * scale).round());
  final ulGap = math.max(2, (w * 0.02 * scale).round());
  final ulRight = left + barW;
  final ulTop = top2 + barH + (w * 0.075 * scale).round();
  _rect(image, ulRight - ulW, ulTop, ulRight, ulTop + ulH, 0, copper);
  _rect(image, ulRight - ulW, ulTop + ulH + ulGap, ulRight,
      ulTop + 2 * ulH + ulGap, 0, copper);
}

/// Fills [x1,y1)-(x2,y2) with [color], corners rounded by [radius].
void _rect(img.Image image, int x1, int y1, int x2, int y2, int radius,
    img.Color color) {
  final w = x2 - x1;
  final h = y2 - y1;
  if (w <= 0 || h <= 0) return;
  final r = math.min(radius, math.min(w, h) ~/ 2);
  for (var y = math.max(0, y1); y < math.min(image.height, y2); y++) {
    for (var x = math.max(0, x1); x < math.min(image.width, x2); x++) {
      if (r == 0 || _inRounded(x - x1, y - y1, w, h, r)) {
        image.setPixel(x, y, color);
      }
    }
  }
}

bool _inRounded(int x, int y, int w, int h, int r) {
  final rx = math.min(x, w - 1 - x);
  final ry = math.min(y, h - 1 - y);
  if (rx >= r || ry >= r) return true;
  final dx = r - rx;
  final dy = r - ry;
  return dx * dx + dy * dy <= r * r;
}
