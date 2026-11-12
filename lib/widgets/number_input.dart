import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/tokens.dart';

class NumberInput extends StatefulWidget {
  final String? label;
  final TextEditingController controller;
  final String? unitSymbol;
  final TextInputType keyboardType;
  final bool autofocus;

  final bool readOnly;
  final VoidCallback? onTap;

  /// One-tap values under the field: tip 10 / 15 / 18 / 20 %, say.
  final List<num> presets;

  /// How a preset chip reads; defaults to the number itself.
  final String Function(num)? presetLabel;

  /// Adds − / + buttons that step the value by this much (people, years…).
  final num? step;

  /// The smallest value the − button goes down to.
  final num stepMin;

  const NumberInput({
    super.key,
    this.label,
    required this.controller,
    this.unitSymbol,
    this.keyboardType = const TextInputType.numberWithOptions(decimal: true),
    this.autofocus = false,
    this.readOnly = false,
    this.onTap,
    this.presets = const [],
    this.presetLabel,
    this.step,
    this.stepMin = 0,
  });

  @override
  State<NumberInput> createState() => _NumberInputState();
}

String _plain(num n) =>
    n == n.roundToDouble() ? n.toInt().toString() : n.toString();

class _NumberInputState extends State<NumberInput> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
    widget.controller.addListener(_onText);
  }

  @override
  void didUpdateWidget(NumberInput old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onText);
      widget.controller.addListener(_onText);
    }
  }

  void _onText() {
    if (mounted && (widget.presets.isNotEmpty || widget.step != null)) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onText);
    _focus.dispose();
    super.dispose();
  }

  void _set(num v) {
    HapticFeedback.selectionClick();
    final t = _plain(v);
    widget.controller.value = TextEditingValue(
        text: t, selection: TextSelection.collapsed(offset: t.length));
  }

  num get _current =>
      num.tryParse(widget.controller.text.replaceAll(',', '')) ?? 0;

  @override
  Widget build(BuildContext context) {
    final c = context.ledger;
    final focused = _focus.hasFocus;
    final label = widget.label;
    final unit = widget.unitSymbol;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null)
            Padding(
              padding: const EdgeInsets.only(left: 2, bottom: 6),
              child: Text(
                label,
                style: TextStyle(
                  color: focused ? c.primary : c.inkSoft,
                  fontSize: 13,
                  fontWeight: focused ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(Radii.input),
              border: Border.all(
                color: focused ? c.primary : c.rule,
                width: focused ? 1.5 : 1,
              ),
              boxShadow: focused
                  ? [
                      BoxShadow(
                        color: c.primary.withValues(alpha: 0.12),
                        blurRadius: 0,
                        spreadRadius: 3,
                      )
                    ]
                  : const [],
            ),
            padding: EdgeInsets.only(
              left: Spacing.lg,
              right: widget.step != null ? Spacing.xs : Spacing.lg,
              top: Spacing.md,
              bottom: Spacing.md,
            ),
            child: Row(
              children: [
                Expanded(
                  // The caption above the box is a plain Text in a sibling
                  // node, so the field itself would otherwise be announced as
                  // an unnamed text field. Name it, and append the unit so the
                  // value has units when read back.
                  child: Semantics(
                    label: [
                      if (label != null) label,
                      if (unit != null) 'in $unit',
                    ].join(' '),
                    textField: true,
                    child: TextField(
                      controller: widget.controller,
                      focusNode: _focus,
                      keyboardType: widget.keyboardType,
                      autofocus: widget.autofocus,
                      readOnly: widget.readOnly,
                      onTap: widget.onTap,
                      style: TextStyle(
                        fontFamily: Fonts.figures,
                        fontFeatures: Fonts.tabular,
                        color: c.ink,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                      cursorColor: c.primary,
                      // The box above is the field's only outline: switch off
                      // every border the app theme would otherwise draw.
                      decoration: InputDecoration(
                        isCollapsed: true,
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                        hintText: '0',
                        hintStyle: TextStyle(
                          fontFamily: Fonts.figures,
                          color: c.inkSoft.withValues(alpha: 0.6),
                        ),
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]')),
                      ],
                    ),
                  ),
                ),
                if (unit != null) ...[
                  const SizedBox(width: Spacing.sm),
                  Text(
                    unit,
                    style: TextStyle(
                      color: c.inkSoft,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                if (widget.step != null) ...[
                  const SizedBox(width: Spacing.sm),
                  _StepButton(
                    icon: Icons.remove,
                    label: 'Decrease ${label ?? ''}',
                    onTap: _current - widget.step! >= widget.stepMin
                        ? () => _set(_current - widget.step!)
                        : null,
                  ),
                  _StepButton(
                    icon: Icons.add,
                    label: 'Increase ${label ?? ''}',
                    onTap: () => _set(_current + widget.step!),
                  ),
                ],
              ],
            ),
          ),
          if (widget.presets.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: Spacing.sm),
              child: Wrap(
                spacing: Spacing.sm,
                runSpacing: Spacing.sm,
                children: [
                  for (final p in widget.presets)
                    _Preset(
                      text: widget.presetLabel?.call(p) ?? _plain(p),
                      active: _current == p &&
                          widget.controller.text.trim().isNotEmpty,
                      onTap: () => _set(p),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _StepButton({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.ledger;
    return IconButton(
      tooltip: label.trim(),
      visualDensity: VisualDensity.compact,
      onPressed: onTap,
      icon: Icon(icon, size: 20, color: onTap == null ? c.rule : c.primary),
    );
  }
}

class _Preset extends StatelessWidget {
  final String text;
  final bool active;
  final VoidCallback onTap;
  const _Preset(
      {required this.text, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.ledger;
    return Semantics(
      button: true,
      selected: active,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: active ? c.primary : c.surface,
          borderRadius: BorderRadius.circular(Radii.chip),
          border: Border.all(color: active ? c.primary : c.rule),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(Radii.chip),
          onTap: onTap,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: 7),
            child: Text(
              text,
              style: TextStyle(
                fontFamily: Fonts.figures,
                fontFeatures: Fonts.tabular,
                color: active ? c.onPrimary : c.ink,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
