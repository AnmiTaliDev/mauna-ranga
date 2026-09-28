import 'package:flutter/widgets.dart';
import 'package:mauna/mauna.dart';

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
