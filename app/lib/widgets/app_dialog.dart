import 'package:flutter/widgets.dart';
import 'package:mauna/mauna.dart';

import '../l10n/app_localizations.dart';

Future<T?> showAppDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return showMaunaDialog<T>(
    context: context,
    builder: builder,
    barrierLabel: AppLocalizations.of(context).close,
  );
}

Future<T?> showAppPopup<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return showMaunaPopup<T>(
    context: context,
    builder: builder,
    barrierLabel: AppLocalizations.of(context).close,
  );
}

class AppDialog extends StatelessWidget {
  const AppDialog({super.key, required this.title, required this.child});

  final String title;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaunaDialog(
      title: title,
      closeLabel: AppLocalizations.of(context).close,
      child: child,
    );
  }
}
