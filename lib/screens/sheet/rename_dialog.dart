import 'package:flutter/material.dart';

/// Asks for a sheet title. Owns its text controller, so the field is never
/// left holding a disposed controller while the dialog animates away.
class RenameSheetDialog extends StatefulWidget {
  final String title;
  final String current;
  final String placeholder;

  const RenameSheetDialog({
    super.key,
    required this.title,
    required this.current,
    required this.placeholder,
  });

  static Future<String?> show(BuildContext context,
          {required String title,
          required String current,
          required String placeholder}) =>
      showDialog<String>(
        context: context,
        builder: (_) => RenameSheetDialog(
            title: title, current: current, placeholder: placeholder),
      );

  @override
  State<RenameSheetDialog> createState() => _RenameSheetDialogState();
}

class _RenameSheetDialogState extends State<RenameSheetDialog> {
  late final TextEditingController _ctrl =
      TextEditingController(text: widget.current);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        decoration: InputDecoration(hintText: widget.placeholder),
        onSubmitted: (v) => Navigator.pop(context, v),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        TextButton(
            onPressed: () => Navigator.pop(context, _ctrl.text),
            child: const Text('Save')),
      ],
    );
  }
}
