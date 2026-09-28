import 'package:flutter/widgets.dart';
import 'package:mauna/mauna.dart';

Future<String?> showPathDialog({
  required BuildContext context,
  required String title,
  required String action,
  String initialPath = '',
}) {
  return showMaunaDialog<String>(
    context: context,
    builder: (BuildContext context) =>
        _PathDialog(title: title, action: action, initialPath: initialPath),
  );
}

Future<void> showMessageDialog({
  required BuildContext context,
  required String title,
  required String message,
}) {
  return showMaunaDialog<void>(
    context: context,
    builder: (BuildContext context) {
      final MaunaThemeData theme = MaunaThemeData.of(context);
      return MaunaDialog(
        title: title,
        child: Padding(
          padding: EdgeInsets.all(theme.spacing.md),
          child: Text(message, style: theme.uiStyle),
        ),
      );
    },
  );
}

class _PathDialog extends StatefulWidget {
  const _PathDialog({
    required this.title,
    required this.action,
    required this.initialPath,
  });

  final String title;

  final String action;

  final String initialPath;

  @override
  State<_PathDialog> createState() => _PathDialogState();
}

class _PathDialogState extends State<_PathDialog> {
  late final MaunaTextController _path = MaunaTextController(
    text: widget.initialPath,
  );
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _path.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final String path = _path.text.trim();
    if (path.isNotEmpty) {
      Navigator.of(context).pop(path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final MaunaThemeData theme = MaunaThemeData.of(context);
    return MaunaDialog(
      title: widget.title,
      child: Padding(
        padding: EdgeInsets.all(theme.spacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: theme.spacing.sm,
          children: <Widget>[
            Text('File path', style: theme.captionStyle),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: theme.spacing.sm,
                vertical: theme.spacing.xs,
              ),
              decoration: BoxDecoration(
                color: theme.bgCanvas,
                border: Border.all(
                  color: theme.line,
                  width: theme.metrics.borderWidth,
                ),
                borderRadius: BorderRadius.circular(theme.radiusSm),
              ),
              child: EditableText(
                controller: _path,
                focusNode: _focusNode,
                autofocus: true,
                style: theme.uiStyle,
                cursorColor: theme.accent,
                backgroundCursorColor: theme.textSecondary,
                cursorWidth: theme.metrics.cursorWidth,
                selectionColor: theme.selectionColor,
                onSubmitted: (String value) => _submit(),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: MaunaToolbarButton(
                label: widget.action,
                accent: true,
                onPressed: _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
