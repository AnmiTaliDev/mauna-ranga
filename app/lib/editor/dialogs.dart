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

Future<bool> showConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmLabel,
  required String cancelLabel,
}) async {
  final bool? confirmed = await showMaunaDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      final MaunaThemeData theme = MaunaThemeData.of(context);
      return MaunaDialog(
        title: title,
        child: Padding(
          padding: EdgeInsets.all(theme.spacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(message, style: theme.uiStyle),
              SizedBox(height: theme.spacing.md),
              Wrap(
                spacing: theme.spacing.xs,
                children: <Widget>[
                  MaunaToolbarChip(
                    label: confirmLabel,
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                  MaunaToolbarChip(
                    label: cancelLabel,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
  return confirmed ?? false;
}

enum UnsavedChoice { save, discard, cancel }

Future<UnsavedChoice> showUnsavedDialog({
  required BuildContext context,
  required String name,
}) async {
  final UnsavedChoice? choice = await showMaunaDialog<UnsavedChoice>(
    context: context,
    builder: (BuildContext context) {
      final MaunaThemeData theme = MaunaThemeData.of(context);
      return MaunaDialog(
        title: 'Unsaved changes',
        child: Padding(
          padding: EdgeInsets.all(theme.spacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Save changes to $name before closing?',
                style: theme.uiStyle,
              ),
              SizedBox(height: theme.spacing.md),
              Wrap(
                spacing: theme.spacing.xs,
                children: <Widget>[
                  for (final UnsavedChoice option in UnsavedChoice.values)
                    MaunaToolbarChip(
                      label: switch (option) {
                        UnsavedChoice.save => 'Save',
                        UnsavedChoice.discard => 'Discard',
                        UnsavedChoice.cancel => 'Cancel',
                      },
                      onPressed: () => Navigator.of(context).pop(option),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
  return choice ?? UnsavedChoice.cancel;
}
