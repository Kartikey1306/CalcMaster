import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../lib_currency.dart';
import '../monetization/analytics_service.dart';
import 'sheets_controller.dart';

/// Appends [line] — one parseable, labelled sheet line such as
/// `Per person (bill 100 + 18% tip, 2 people): 59.00 USD` — to the current
/// sheet, and says where it went with a way back to it.
void addLineToSheet(BuildContext context, String line, {required String tool}) {
  final sheets = context.read<SheetsController>();
  final title = sheets.appendLine(line);
  AnalyticsService.instance.logAddToSheet(tool);
  final router = GoRouter.maybeOf(context);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text('Added to $title'),
      action: router == null
          ? null
          : SnackBarAction(label: 'Open', onPressed: () => router.go('/')),
    ));
}

/// A money amount as a sheet reads it: `59.00 USD`. A currency the ECB does
/// not publish (the UAE dirham) stays a plain number with the code left in
/// the label, because the sheet only accepts the ECB's 30 codes.
String sheetMoney(double value, String currency) {
  final n = value.isFinite ? value.toStringAsFixed(2) : '0.00';
  return isEcbCurrency(currency) ? '$n $currency' : n;
}

/// The label suffix that keeps a non-ECB currency visible: `, AED`.
String nonEcbNote(String currency) =>
    isEcbCurrency(currency) ? '' : ', $currency';
