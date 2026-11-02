import 'package:flutter/widgets.dart';
import 'package:mauna/mauna.dart';

class DialogTextField extends StatelessWidget {
  const DialogTextField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.placeholder,
    this.onSubmitted,
    this.onChanged,
    this.autofocus = false,
  });

  final TextEditingController controller;

  final FocusNode focusNode;

  final String placeholder;

  final VoidCallback? onSubmitted;

  final ValueChanged<String>? onChanged;

  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final MaunaThemeData theme = MaunaThemeData.of(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: theme.spacing.sm,
        vertical: theme.spacing.xs,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: theme.line, width: theme.metrics.borderWidth),
      ),
      child: Stack(
        children: <Widget>[
          ListenableBuilder(
            listenable: controller,
            builder: (BuildContext context, Widget? child) {
              return controller.text.isEmpty
                  ? IgnorePointer(
                      child: Text(
                        placeholder,
                        style: theme.uiStyle.copyWith(
                          color: theme.textSecondary,
                        ),
                      ),
                    )
                  : const SizedBox.shrink();
            },
          ),
          EditableText(
            controller: controller,
            focusNode: focusNode,
            autofocus: autofocus,
            style: theme.uiStyle,
            cursorColor: theme.accent,
            backgroundCursorColor: theme.textSecondary,
            cursorWidth: theme.metrics.cursorWidth,
            selectionColor: theme.selectionColor,
            onChanged: onChanged,
            onSubmitted: (String value) => onSubmitted?.call(),
          ),
        ],
      ),
    );
  }
}
