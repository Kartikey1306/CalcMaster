import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../monetization/analytics_service.dart';
import 'sheet_engine.dart';
import 'sheet_export.dart';
import 'sheet_model.dart';

/// Hands a sheet to the system share sheet as text or as a CSV file. When
/// sharing is not available it copies to the clipboard instead and says so.
class SheetSharer {
  /// Replaced in widget tests, where no platform share sheet exists.
  static Future<void> Function(String text, String subject, Rect? origin)
      shareText = _shareText;
  static Future<void> Function(
          Uint8List bytes, String fileName, String subject, Rect? origin)
      shareFile = _shareFile;

  static Future<void> _shareText(String text, String subject, Rect? origin) =>
      Share.share(text, subject: subject, sharePositionOrigin: origin);

  static Future<void> _shareFile(
          Uint8List bytes, String fileName, String subject, Rect? origin) =>
      Share.shareXFiles(
        [XFile.fromData(bytes, mimeType: 'text/csv', name: fileName)],
        subject: subject,
        sharePositionOrigin: origin,
      );

  static String fileNameFor(Sheet sheet) {
    final base = sheet.displayTitle
        .replaceAll(RegExp(r'[^A-Za-z0-9 _-]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '-');
    return '${base.isEmpty ? 'sheet' : base}.csv';
  }

  static Future<void> asText(BuildContext context, Sheet sheet,
      SheetEvaluation eval, {Rect? origin}) async {
    final text = sheetAsText(sheet, eval);
    AnalyticsService.instance.logSheetShared('text');
    try {
      await shareText(text, sheet.displayTitle, origin);
    } catch (_) {
      if (!context.mounted) return;
      await copy(context, text, what: 'Sheet');
    }
  }

  static Future<void> asCsv(BuildContext context, Sheet sheet,
      SheetEvaluation eval, {Rect? origin}) async {
    final csv = sheetAsCsv(sheet, eval);
    AnalyticsService.instance.logSheetShared('csv');
    try {
      await shareFile(Uint8List.fromList(utf8.encode(csv)), fileNameFor(sheet),
          sheet.displayTitle, origin);
    } catch (_) {
      if (!context.mounted) return;
      await copy(context, csv, what: 'CSV');
    }
  }

  static Future<void> copy(BuildContext context, String text,
      {String what = 'Sheet'}) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$what copied to the clipboard')));
  }
}

/// Shows exactly what will be shared — every line, each ECB rate with its
/// date, and the source — before it leaves the app.
class ExportPreviewSheet extends StatelessWidget {
  final String title;
  final String body;
  final String shareLabel;
  final VoidCallback onShare;
  final VoidCallback onCopy;

  const ExportPreviewSheet({
    super.key,
    required this.title,
    required this.body,
    required this.shareLabel,
    required this.onShare,
    required this.onCopy,
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String body,
    required String shareLabel,
    required Future<void> Function() share,
    required String copyWhat,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => ExportPreviewSheet(
        title: title,
        body: body,
        shareLabel: shareLabel,
        onShare: () async {
          Navigator.pop(ctx);
          await share();
        },
        onCopy: () async {
          Navigator.pop(ctx);
          await SheetSharer.copy(context, body, what: copyWhat);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.85),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title,
                  style: TextStyle(
                      color: c.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Flexible(
                child: Container(
                  decoration: BoxDecoration(
                    color: c.surface,
                    border: Border.all(color: c.outlineVariant),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: SelectableText(
                      body,
                      style: TextStyle(
                        fontFamily: 'RedditMono',
                        color: c.onSurface,
                        fontSize: 12.5,
                        height: 1.45,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onCopy,
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Copy'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onShare,
                    icon: const Icon(Icons.ios_share, size: 18),
                    label: Text(shareLabel),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
