import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/tokens.dart';

/// "How lines work": the sheet's line grammar, with an example of each rule.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const rules = <(String, String, String)>[
    ('Arithmetic', '12 * (3 + 4)', 'Brackets, + − × ÷, powers (^), sqrt, sin, log…'),
    ('A label', 'Hotel: 120 GBP', 'Text before ": " sits on the left; the result on the right.'),
    ('Other lines', '#2 * 3   or   prev + 10', '#n is line n\'s result; prev is the line above.'),
    ('Names', 'nights = 3   then   120 EUR * nights', 'Give a value a name and use it on any line below. Change it once and every line that uses it updates. A plain-number name is a setting and stays out of the total.'),
    ('Percentages', '#1 + 18%   ·   20% of 250', 'Add or take off a percentage, or take a share.'),
    ('Just type it', 'dinner 18 euro for 2 people', 'Write it the way you\'d say it — typos are fine. The answer appears straight away, with the sheet\'s new total. Press Enter or Use to keep it, or tap another way to work it out (whole bill, with a tip, in your currency). It also reads "pizza 12 and drinks 8", "3 nights 120 EUR", "tip 15", "two people" and "1,200".'),
    ('Paid & due', 'Swipe a line → PAID   ← DUE', 'Rubber-stamp a line by swiping it, or from the line-number menu. The footer splits the total into paid and pending. Swipe again to lift the stamp.'),
    ('Units', '12 ft in m', 'Distance, volume, weight, temperature, speed, area, data, fuel, pressure, energy.'),
    ('Currency', '38.50 EUR in USD', 'Converted at the European Central Bank reference rate. Undated lines keep (pin) the rate they were first worked out with; tap Re-price to move them to today\'s rate.'),
    ('Rate on the day', '38.50 EUR on 14 Sep in USD', 'Converted at the ECB rate for that date (back to 4 Jan 1999). On a weekend or holiday the ECB\'s previous working day is used, and the line says which day that was.'),
    ('Total', 'total', 'Adds the lines above in the sheet\'s main currency or unit. Lines in anything else are left out, and the footer says how many.'),
    ('Headings', 'Trip to Lisbon', 'A line with no number is a heading.'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.ledger;
    return Scaffold(
      backgroundColor: c.paper,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        title: const Text('How lines work'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            Spacing.lg, Spacing.sm, Spacing.lg, Spacing.xxl),
        children: [
          Text(
            'Every line works out as you type. Tap a result to put its '
            'reference (#n) into the line you are editing; long-press a '
            'result to copy it.',
            style: TextStyle(color: c.inkSoft, fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: Spacing.md),
          for (final (title, example, note) in rules)
            Container(
              padding: const EdgeInsets.symmetric(vertical: Spacing.md),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: c.rule)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: c.ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(example,
                      style: TextStyle(
                          fontFamily: Fonts.figures,
                          color: c.result,
                          fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(note,
                      style: TextStyle(
                          color: c.inkSoft, fontSize: 13, height: 1.35)),
                ],
              ),
            ),
          const SizedBox(height: Spacing.lg),
          Text(
            'Exchange rates: European Central Bank reference rates via '
            'Frankfurter (api.frankfurter.dev), 30 currencies. They are '
            'reference rates, not the rate your bank or card charged.',
            style: TextStyle(color: c.inkSoft, fontSize: 13, height: 1.35),
          ),
        ],
      ),
    );
  }
}
