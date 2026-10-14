import 'dart:async';
import '../../l10n/generated/app_localizations.dart';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

import '../../lib_format.dart';
import '../../theme/tokens.dart';
import '../../widgets/chip_picker.dart';
import '../../widgets/inner_scaffold.dart';
import '../../widgets/number_input.dart';
import '../../widgets/result_row.dart';

// =================== GPS ===================

class GpsCalc extends StatefulWidget {
  const GpsCalc({super.key});
  @override
  State<GpsCalc> createState() => _GpsCalcState();
}

class _GpsCalcState extends State<GpsCalc> {
  final lat = TextEditingController();
  final lng = TextEditingController();
  bool loading = false;
  @override
  void initState() {
    super.initState();
    for (final c in [lat, lng]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [lat, lng]) {
      c.dispose();
    }
    super.dispose();
  }

  String _toDms(double dec, bool isLat) {
    if (!dec.isFinite) return '—';
    final sign = dec >= 0 ? (isLat ? 'N' : 'E') : (isLat ? 'S' : 'W');
    final abs = dec.abs();
    final deg = abs.floor();
    final minF = (abs - deg) * 60;
    final min = minF.floor();
    final sec = (minF - min) * 60;
    return '$deg° $min\' ${sec.toStringAsFixed(2)}" $sign';
  }

  Future<void> _useMyLoc() async {
    setState(() => loading = true);
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever ||
          perm == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content:
                  Text(AppLocalizations.of(context)!.actionPermissionDenied)));
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      lat.text = pos.latitude.toStringAsFixed(6);
      lng.text = pos.longitude.toStringAsFixed(6);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InnerScaffold(
      title: AppLocalizations.of(context)!.toolGps,
      subtitle: 'Decimal ↔ DMS',
      tool: 'gps',
      sheetLine: () {
        if (lat.text.isEmpty) return null;
        final la = safeNumber(lat.text);
        return 'Latitude (${_toDms(la, true)}): ${plainNumber(la)}';
      },
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        NumberInput(label: 'Latitude (decimal)', controller: lat),
        NumberInput(label: 'Longitude (decimal)', controller: lng),
        SizedBox(height: Spacing.md),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
                backgroundColor: context.ledger.ink,
                foregroundColor: context.ledger.paper,
                padding: EdgeInsets.symmetric(vertical: 14)),
            onPressed: loading ? null : _useMyLoc,
            icon: Icon(Icons.navigation, size: 18),
            label: Text(loading
                ? AppLocalizations.of(context)!.actionLocating
                : AppLocalizations.of(context)!.actionUseMyLocation),
          ),
        ),
        SizedBox(height: Spacing.lg),
        ResultRow(
            label: 'Latitude (DMS)',
            value: _toDms(safeNumber(lat.text), true),
            highlight: true),
        ResultRow(
            label: 'Longitude (DMS)',
            value: _toDms(safeNumber(lng.text), false),
            highlight: true),
      ]),
    );
  }
}

// =================== OHM ===================

class OhmCalc extends StatefulWidget {
  const OhmCalc({super.key});
  @override
  State<OhmCalc> createState() => _OhmCalcState();
}

class _OhmCalcState extends State<OhmCalc> {
  final v = TextEditingController();
  final i = TextEditingController();
  final r = TextEditingController();
  final p = TextEditingController();
  @override
  void initState() {
    super.initState();
    for (final c in [v, i, r, p]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [v, i, r, p]) {
      c.dispose();
    }
    super.dispose();
  }

  ({double? V, double? I, double? R, double? P}) _solve() {
    double? V = v.text.isEmpty ? null : safeNumber(v.text);
    double? I = i.text.isEmpty ? null : safeNumber(i.text);
    double? R = r.text.isEmpty ? null : safeNumber(r.text);
    double? P = p.text.isEmpty ? null : safeNumber(p.text);
    for (int pass = 0; pass < 4; pass++) {
      V ??= (I != null && R != null) ? I * R : null;
      V ??= (P != null && I != null && I != 0) ? P / I : null;
      I ??= (V != null && R != null && R != 0) ? V / R : null;
      I ??= (P != null && V != null && V != 0) ? P / V : null;
      R ??= (V != null && I != null && I != 0) ? V / I : null;
      R ??= (V != null && P != null && P != 0) ? (V * V) / P : null;
      R ??= (P != null && I != null && I != 0) ? P / (I * I) : null;
      P ??= (V != null && I != null) ? V * I : null;
      P ??= (V != null && R != null && R != 0) ? (V * V) / R : null;
      P ??= (I != null && R != null) ? I * I * R : null;
    }
    return (V: V, I: I, R: R, P: P);
  }

  @override
  Widget build(BuildContext context) {
    final s = _solve();
    String f(double? x, String unit) =>
        (x == null || !x.isFinite) ? '—' : '${formatNumber(x)} $unit';
    return InnerScaffold(
      title: AppLocalizations.of(context)!.toolOhm,
      subtitle: 'Enter any two values',
      tool: 'ohm',
      sheetLine: () {
        // The first value the user did not type is the one that was solved.
        for (final (name, unit, typed, value) in [
          ('Voltage', 'V', v.text, s.V),
          ('Current', 'A', i.text, s.I),
          ('Resistance', 'ohm', r.text, s.R),
          ('Power', 'W', p.text, s.P),
        ]) {
          if (typed.isEmpty && value != null && value.isFinite) {
            return '$name in $unit (Ohm\'s law): ${plainNumber(value)}';
          }
        }
        return null;
      },
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        NumberInput(label: 'Voltage (V)', controller: v),
        NumberInput(label: 'Current (A)', controller: i),
        NumberInput(label: 'Resistance (Ω)', controller: r),
        NumberInput(label: 'Power (W)', controller: p),
        SizedBox(height: Spacing.lg),
        Text('Solved',
            style: TextStyle(color: context.ledger.inkSoft, fontSize: 13)),
        SizedBox(height: Spacing.sm),
        ResultRow(
            label: 'V',
            caption: 'Voltage',
            value: f(s.V, 'V'),
            highlight: s.V != null && v.text.isEmpty),
        ResultRow(
            label: 'I',
            caption: 'Current',
            value: f(s.I, 'A'),
            highlight: s.I != null && i.text.isEmpty),
        ResultRow(
            label: 'R',
            caption: 'Resistance',
            value: f(s.R, 'Ω'),
            highlight: s.R != null && r.text.isEmpty),
        ResultRow(
            label: 'P',
            caption: 'Power',
            value: f(s.P, 'W'),
            highlight: s.P != null && p.text.isEmpty),
      ]),
    );
  }
}

// =================== BMI ===================

class BmiCalc extends StatefulWidget {
  const BmiCalc({super.key});
  @override
  State<BmiCalc> createState() => _BmiCalcState();
}

class _BmiCalcState extends State<BmiCalc> {
  String system = 'metric';
  final h = TextEditingController();
  final w = TextEditingController();
  @override
  void initState() {
    super.initState();
    for (final c in [h, w]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [h, w]) {
      c.dispose();
    }
    super.dispose();
  }

  ({String label, Color color}) _category(double bmi) {
    if (!bmi.isFinite || bmi <= 0) {
      return (label: '—', color: context.ledger.inkSoft);
    }
    if (bmi < 18.5) {
      return (label: 'Underweight', color: context.ledger.result);
    }
    if (bmi < 25) return (label: 'Healthy weight', color: context.ledger.primary);
    if (bmi < 30) return (label: 'Overweight', color: context.ledger.result);
    return (label: 'Obese', color: context.ledger.error);
  }

  @override
  Widget build(BuildContext context) {
    final hv = safeNumber(h.text);
    final wv = safeNumber(w.text);
    double bmi = double.nan;
    if (hv > 0 && wv > 0) {
      if (system == 'metric') {
        final hm = hv / 100;
        bmi = wv / (hm * hm);
      } else {
        bmi = (703 * wv) / (hv * hv);
      }
    }
    final cat = _category(bmi);
    return InnerScaffold(
      title: AppLocalizations.of(context)!.toolBmi,
      subtitle: 'Body Mass Index',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Units',
            style: TextStyle(color: context.ledger.inkSoft, fontSize: 13)),
        SizedBox(height: Spacing.sm),
        ChipPicker<String>(
          options: [
            (id: 'metric', label: 'Metric (cm, kg)'),
            (id: 'imperial', label: 'Imperial (in, lb)')
          ],
          value: system,
          onChange: (v) => setState(() => system = v),
        ),
        NumberInput(
            label: system == 'metric' ? 'Height (cm)' : 'Height (in)',
            controller: h),
        NumberInput(
            label: system == 'metric' ? 'Weight (kg)' : 'Weight (lb)',
            controller: w),
        SizedBox(height: Spacing.lg),
        Container(
          padding: EdgeInsets.all(Spacing.lg),
          decoration: BoxDecoration(
            color: context.ledger.surface,
            border: Border.all(color: cat.color.withValues(alpha: 0.33)),
            borderRadius: BorderRadius.circular(Radii.button),
          ),
          child: Column(children: [
            Text(bmi.isFinite ? formatNumber(bmi, maxDigits: 1) : '—',
                style: TextStyle(
                    color: context.ledger.ink,
                    fontSize: 32,
                    fontWeight: FontWeight.w700)),
            Text(cat.label,
                style: TextStyle(
                    color: cat.color,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
          ]),
        ),
        SizedBox(height: Spacing.md),
        ResultRow(label: 'Healthy range', value: '18.5 – 24.9'),
      ]),
    );
  }
}

// =================== DATE DIFF ===================

DateTime? _parseDate(String input) {
  final m = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})$').firstMatch(input);
  if (m == null) return null;
  try {
    return DateTime(
        int.parse(m.group(1)!), int.parse(m.group(2)!), int.parse(m.group(3)!));
  } catch (_) {
    return null;
  }
}

String _isoDate(DateTime d) {
  final mm = d.month.toString().padLeft(2, '0');
  final dd = d.day.toString().padLeft(2, '0');
  return '${d.year}-$mm-$dd';
}

class DateDiffCalc extends StatefulWidget {
  const DateDiffCalc({super.key});

  @override
  State<DateDiffCalc> createState() => _DateDiffCalcState();
}

class _DateDiffCalcState extends State<DateDiffCalc> {
  late TextEditingController from;
  late TextEditingController to;

  @override
  void initState() {
    super.initState();
    final today = _isoDate(DateTime.now());

    from = TextEditingController(text: today);
    to = TextEditingController(text: today);

    for (final c in [from, to]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [from, to]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final initial = _parseDate(controller.text) ?? DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context),
          child: child!,
        );
      },
    );

    if (picked != null) {
      controller.text = _isoDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a0 = _parseDate(from.text);
    final b0 = _parseDate(to.text);

    DateTime? a = a0, b = b0;

    if (a != null && b != null && a.isAfter(b)) {
      final t = a;
      a = b;
      b = t;
    }

    String calendar = '—';
    String totalDays = '—';
    String weeks = '—';
    String hours = '—';

    if (a != null && b != null) {
      var years = b.year - a.year;
      var months = b.month - a.month;
      var days = b.day - a.day;

      if (days < 0) {
        months--;
        final prevLast = DateTime(b.year, b.month, 0).day;
        days += prevLast;
      }

      if (months < 0) {
        years--;
        months += 12;
      }

      calendar = '${years}y ${months}m ${days}d';

      final diff = b.difference(a);

      totalDays = '${diff.inDays}';
      weeks = '${diff.inDays ~/ 7}';
      hours = '${diff.inHours}';
    }

    return InnerScaffold(
      title: AppLocalizations.of(context)!.toolDateDiff,
      subtitle: 'Tap the fields to select dates',
      tool: 'date_diff',
      sheetLine: () => a == null || b == null
          ? null
          : 'Days from ${_isoDate(a)} to ${_isoDate(b)}: ${b.difference(a).inDays}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NumberInput(
            label: 'From',
            controller: from,
            keyboardType: TextInputType.text,
            readOnly: true,
            onTap: () => _pickDate(from),
          ),
          NumberInput(
            label: 'To',
            controller: to,
            keyboardType: TextInputType.text,
            readOnly: true,
            onTap: () => _pickDate(to),
          ),
          SizedBox(height: Spacing.lg),
          ResultRow(
            label: 'Calendar',
            value: calendar,
            highlight: true,
          ),
          ResultRow(
            label: 'Total days',
            value: totalDays,
          ),
          ResultRow(
            label: 'Weeks',
            value: weeks,
          ),
          ResultRow(
            label: 'Hours',
            value: hours,
          ),
        ],
      ),
    );
  }
}
// =================== TIME ZONES ===================

/// Daylight-saving rules in force for the cities on the Time Zones screen
/// (US Energy Policy Act 2005, EU Directive 2000/84/EC, NSW/VIC/ACT/TAS law).
enum DstRule { none, us, eu, auSoutheast }

/// The [n]th (1-based) Sunday of [month] in [year], or the last one if [n] is 0.
DateTime _sunday(int year, int month, int n) {
  if (n == 0) {
    final last = DateTime.utc(year, month + 1, 0);
    return DateTime.utc(year, month, last.day - last.weekday % 7);
  }
  final first = DateTime.utc(year, month, 1);
  return DateTime.utc(year, month, 1 + (7 - first.weekday) % 7 + 7 * (n - 1));
}

/// UTC offset in hours at instant [utc] for a place whose standard offset is
/// [standardHours] and which follows [rule].
double utcOffsetHours(double standardHours, DstRule rule, DateTime utc) {
  final y = utc.year;
  final std = standardHours;
  bool inDst;
  switch (rule) {
    case DstRule.none:
      return std;
    case DstRule.us:
      // 02:00 local standard time, 2nd Sunday of March, to 02:00 local
      // daylight time, 1st Sunday of November.
      final start =
          _sunday(y, 3, 2).add(Duration(minutes: ((2 - std) * 60).round()));
      final end =
          _sunday(y, 11, 1).add(Duration(minutes: ((1 - std) * 60).round()));
      inDst = !utc.isBefore(start) && utc.isBefore(end);
    case DstRule.eu:
      // 01:00 UTC, last Sunday of March, to 01:00 UTC, last Sunday of October.
      final start = _sunday(y, 3, 0).add(Duration(hours: 1));
      final end = _sunday(y, 10, 0).add(Duration(hours: 1));
      inDst = !utc.isBefore(start) && utc.isBefore(end);
    case DstRule.auSoutheast:
      // Southern hemisphere: daylight time until 03:00 local daylight time,
      // 1st Sunday of April, and again from 02:00 local standard time,
      // 1st Sunday of October.
      final end =
          _sunday(y, 4, 1).add(Duration(minutes: ((2 - std) * 60).round()));
      final start =
          _sunday(y, 10, 1).add(Duration(minutes: ((2 - std) * 60).round()));
      inDst = utc.isBefore(end) || !utc.isBefore(start);
  }
  return inDst ? std + 1 : std;
}

class TimeZonesScreen extends StatefulWidget {
  const TimeZonesScreen({super.key});
  @override
  State<TimeZonesScreen> createState() => _TimeZonesScreenState();
}

class _TimeZonesScreenState extends State<TimeZonesScreen> {
  Timer? _timer;

  /// The city "Add to sheet" measures from here; tap a row to choose.
  int _selected = 0;
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Standard UTC offsets plus each place's current daylight-saving rule.
  final List<({String label, String flag, double offsetHours, DstRule dst})>
      zones = [
    (label: 'San Francisco', flag: '🇺🇸', offsetHours: -8, dst: DstRule.us),
    (label: 'New York', flag: '🇺🇸', offsetHours: -5, dst: DstRule.us),
    (label: 'London', flag: '🇬🇧', offsetHours: 0, dst: DstRule.eu),
    (label: 'Berlin', flag: '🇩🇪', offsetHours: 1, dst: DstRule.eu),
    (label: 'Mumbai', flag: '🇮🇳', offsetHours: 5.5, dst: DstRule.none),
    (label: 'Singapore', flag: '🇸🇬', offsetHours: 8, dst: DstRule.none),
    (label: 'Tokyo', flag: '🇯🇵', offsetHours: 9, dst: DstRule.none),
    (label: 'Sydney', flag: '🇦🇺', offsetHours: 10, dst: DstRule.auSoutheast),
    (label: 'São Paulo', flag: '🇧🇷', offsetHours: -3, dst: DstRule.none),
    (label: 'Dubai', flag: '🇦🇪', offsetHours: 4, dst: DstRule.none),
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final nowUtc = now.toUtc();
    final here = now.timeZoneOffset.inMinutes / 60;
    final pick = zones[_selected];
    return InnerScaffold(
      title: AppLocalizations.of(context)!.toolTimeZones,
      subtitle: 'Live world clocks · tap a city to add it',
      tool: 'time_zones',
      sheetLine: () {
        final diff = utcOffsetHours(pick.offsetHours, pick.dst, nowUtc) - here;
        return 'Hours from here to ${pick.label}: ${plainNumber(diff, maxDigits: 2)}';
      },
      child: Column(children: [
        for (final (index, z) in zones.indexed)
          Builder(builder: (_) {
            final dt = nowUtc.add(Duration(
                minutes:
                    (utcOffsetHours(z.offsetHours, z.dst, nowUtc) * 60)
                        .round()));
            final time = DateFormat('h:mm:ss a').format(dt);
            final day = DateFormat('EEE, MMM d').format(dt);
            final chosen = index == _selected;
            return Semantics(
              button: true,
              selected: chosen,
              label: '${z.label}, $time',
              excludeSemantics: true,
              child: InkWell(
              onTap: () => setState(() => _selected = index),
              child: Container(
              margin: EdgeInsets.symmetric(vertical: 4),
              padding: EdgeInsets.symmetric(
                  horizontal: Spacing.lg, vertical: Spacing.md),
              decoration: BoxDecoration(
                color: context.ledger.surface,
                border: Border.all(
                    color: chosen ? context.ledger.primary : context.ledger.rule,
                    width: chosen ? 1.5 : 1),
                borderRadius: BorderRadius.circular(Radii.button),
              ),
              child: Row(children: [
                Text(z.flag, style: TextStyle(fontSize: 22)),
                SizedBox(width: Spacing.md),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(z.label,
                            style: TextStyle(
                                color: context.ledger.ink,
                                fontSize: 16,
                                fontWeight: FontWeight.w600)),
                        Text(day,
                            style: TextStyle(
                                color: context.ledger.inkSoft, fontSize: 13)),
                      ]),
                ),
                Text(time,
                    style: TextStyle(
                        fontFamily: Fonts.figures,
                        color: context.ledger.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
              ]),
            ),
              ),
            );
          }),
      ]),
    );
  }
}

// =================== ADC / DAC ===================

class AdcDacCalc extends StatefulWidget {
  const AdcDacCalc({super.key});
  @override
  State<AdcDacCalc> createState() => _AdcDacCalcState();
}

class _AdcDacCalcState extends State<AdcDacCalc> {
  String mode = 'adc';
  final bits = TextEditingController(text: '12');
  final vref = TextEditingController(text: '3.3');
  final analog = TextEditingController();
  final digital = TextEditingController();
  @override
  void initState() {
    super.initState();
    for (final c in [bits, vref, analog, digital]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [bits, vref, analog, digital]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = safeNumber(bits.text).round().clamp(1, 64);
    final ref = safeNumber(vref.text);
    final maxCode = (1 << n) - 1;
    final lsb = ref / (1 << n);
    int? code;
    double? voltage;
    if (mode == 'adc') {
      final v = safeNumber(analog.text);
      if (ref > 0) code = ((v / ref) * maxCode).round().clamp(0, maxCode);
    } else {
      final c = safeNumber(digital.text).round().clamp(0, maxCode);
      voltage = (c / maxCode) * ref;
      code = c;
    }
    return InnerScaffold(
      title: AppLocalizations.of(context)!.toolAdcDac,
      subtitle: mode == 'adc' ? 'Analog → Digital' : 'Digital → Analog',
      tool: 'adc_dac',
      sheetLine: () {
        if (mode == 'adc') {
          if (analog.text.isEmpty || code == null) return null;
          return 'ADC code ($n-bit, ${plainNumber(safeNumber(analog.text))} V of '
              '${plainNumber(ref)} V): $code';
        }
        if (digital.text.isEmpty || voltage == null) return null;
        return 'DAC output in V ($n-bit, code $code, ${plainNumber(ref)} V ref): '
            '${plainNumber(voltage)}';
      },
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ChipPicker<String>(options: [
          (id: 'adc', label: 'ADC'),
          (id: 'dac', label: 'DAC')
        ], value: mode, onChange: (v) => setState(() => mode = v)),
        NumberInput(
            label: 'Resolution (bits)',
            controller: bits,
            keyboardType: TextInputType.number),
        NumberInput(label: 'Reference voltage (V)', controller: vref),
        if (mode == 'adc')
          NumberInput(label: 'Analog input (V)', controller: analog)
        else
          NumberInput(
              label: 'Digital code',
              controller: digital,
              keyboardType: TextInputType.number),
        SizedBox(height: Spacing.lg),
        if (mode == 'adc') ...[
          ResultRow(
              label: 'Digital code (decimal)',
              value: code?.toString() ?? '—',
              highlight: true),
          ResultRow(
              label: 'Digital code (hex)',
              value: code != null
                  ? '0x${code.toRadixString(16).toUpperCase()}'
                  : '—'),
        ] else
          ResultRow(
              label: 'Analog output (V)',
              value: voltage != null ? '${formatNumber(voltage)} V' : '—',
              highlight: true),
        ResultRow(label: 'Full-scale code', value: '$maxCode'),
        ResultRow(label: 'LSB step', value: '${formatNumber(lsb)} V'),
      ]),
    );
  }
}

// =================== AGE ===================

class AgeCalc extends StatefulWidget {
  const AgeCalc({super.key});

  @override
  State<AgeCalc> createState() => _AgeCalcState();
}

class _AgeCalcState extends State<AgeCalc> {
  final dob = TextEditingController(text: '2000-01-01');
  late TextEditingController ref;

  @override
  void initState() {
    super.initState();
    ref = TextEditingController(text: _isoDate(DateTime.now()));

    for (final c in [dob, ref]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [dob, ref]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final initial = _parseDate(controller.text) ?? DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context),
          child: child!,
        );
      },
    );

    if (picked != null) {
      controller.text = _isoDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = _parseDate(dob.text);
    final b = _parseDate(ref.text);

    String age = '—', total = '—', next = '—';

    if (a != null && b != null && !a.isAfter(b)) {
      var years = b.year - a.year;
      var months = b.month - a.month;
      var days = b.day - a.day;

      if (days < 0) {
        months--;
        final prevLast = DateTime(b.year, b.month, 0).day;
        days += prevLast;
      }

      if (months < 0) {
        years--;
        months += 12;
      }

      age = '${years}y ${months}m ${days}d';
      total = '${b.difference(a).inDays}';

      var nb = DateTime(b.year, a.month, a.day);
      if (nb.isBefore(b)) {
        nb = DateTime(b.year + 1, a.month, a.day);
      }

      final daysToNext = nb.difference(b).inDays;
      next = '${_isoDate(nb)} · in $daysToNext days';
    }

    return InnerScaffold(
      title: AppLocalizations.of(context)!.toolAge,
      subtitle: 'Tap the fields to select dates',
      tool: 'age',
      sheetLine: () {
        if (a == null || b == null || a.isAfter(b)) return null;
        var years = b.year - a.year;
        if (b.month < a.month || (b.month == a.month && b.day < a.day)) years--;
        return 'Age in years on ${_isoDate(b)} (born ${_isoDate(a)}): $years';
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NumberInput(
            label: 'Date of birth',
            controller: dob,
            keyboardType: TextInputType.text,
            readOnly: true,
            onTap: () => _pickDate(dob),
          ),
          NumberInput(
            label: 'Reference date',
            controller: ref,
            keyboardType: TextInputType.text,
            readOnly: true,
            onTap: () => _pickDate(ref),
          ),
          SizedBox(height: Spacing.lg),
          ResultRow(
            label: (AppLocalizations.of(context)?.toolAge ?? 'Age'),
            value: age,
            highlight: true,
          ),
          ResultRow(
            label: 'Total days lived',
            value: total,
          ),
          ResultRow(
            label: 'Next birthday',
            value: next,
          ),
        ],
      ),
    );
  }
}
// =================== ASPECT RATIO ===================

class AspectRatioCalc extends StatefulWidget {
  const AspectRatioCalc({super.key});
  @override
  State<AspectRatioCalc> createState() => _AspectRatioCalcState();
}

class _AspectRatioCalcState extends State<AspectRatioCalc> {
  final w1 = TextEditingController(text: '1920');
  final h1 = TextEditingController(text: '1080');
  final w2 = TextEditingController();
  final h2 = TextEditingController();
  @override
  void initState() {
    super.initState();
    for (final c in [w1, h1, w2, h2]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [w1, h1, w2, h2]) {
      c.dispose();
    }
    super.dispose();
  }

  String _reduce(double w, double h) {
    if (!w.isFinite || !h.isFinite || w <= 0 || h <= 0) return '—';
    final target = w / h;
    int bestA = 0, bestB = 0;
    double bestErr = double.infinity;
    for (int b = 1; b <= 50; b++) {
      final a = (target * b).round();
      final err = (target - a / b).abs();
      if (err < bestErr) {
        bestErr = err;
        bestA = a;
        bestB = b;
      }
    }
    return '$bestA:$bestB';
  }

  @override
  Widget build(BuildContext context) {
    final width1 = safeNumber(w1.text);
    final height1 = safeNumber(h1.text);
    final width2 = w2.text.isEmpty ? double.nan : safeNumber(w2.text);
    final height2 = h2.text.isEmpty ? double.nan : safeNumber(h2.text);
    final ratio = (width1 > 0 && height1 > 0) ? width1 / height1 : double.nan;
    String? computedLabel;
    String? computedValue;
    if (ratio.isFinite) {
      if (width2.isFinite && !height2.isFinite) {
        computedLabel = 'Solved height';
        computedValue = '${formatNumber(width2 / ratio, maxDigits: 2)} px';
      } else if (height2.isFinite && !width2.isFinite) {
        computedLabel = 'Solved width';
        computedValue = '${formatNumber(height2 * ratio, maxDigits: 2)} px';
      }
    }
    return InnerScaffold(
      title: AppLocalizations.of(context)!.toolAspectRatio,
      subtitle: 'Solve missing W or H',
      tool: 'aspect_ratio',
      sheetLine: () {
        if (!ratio.isFinite) return null;
        if (width2.isFinite && !height2.isFinite) {
          return 'Height for width ${plainNumber(width2)} at '
              '${_reduce(width1, height1)}: ${plainNumber(width2 / ratio, maxDigits: 2)}';
        }
        if (height2.isFinite && !width2.isFinite) {
          return 'Width for height ${plainNumber(height2)} at '
              '${_reduce(width1, height1)}: ${plainNumber(height2 * ratio, maxDigits: 2)}';
        }
        return 'Aspect ratio ${_reduce(width1, height1)}: ${plainNumber(ratio, maxDigits: 4)}';
      },
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
              child: Column(children: [
            NumberInput(label: 'W₁', controller: w1),
            NumberInput(label: 'H₁', controller: h1),
          ])),
          SizedBox(width: Spacing.md),
          Expanded(
              child: Column(children: [
            NumberInput(label: 'W₂ (optional)', controller: w2),
            NumberInput(label: 'H₂ (optional)', controller: h2),
          ])),
        ]),
        SizedBox(height: Spacing.lg),
        ResultRow(
            label: 'Ratio (decimal)',
            value: ratio.isFinite ? formatNumber(ratio, maxDigits: 4) : '—'),
        ResultRow(
            label: 'Ratio (a:b)',
            value: _reduce(width1, height1),
            highlight: true),
        if (computedLabel != null)
          ResultRow(
              label: computedLabel, value: computedValue!, highlight: true),
      ]),
    );
  }
}
