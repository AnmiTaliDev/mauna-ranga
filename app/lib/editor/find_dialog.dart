import 'package:flutter/widgets.dart';
import 'package:mauna/mauna.dart';

import '../widgets/dialog_text_field.dart';
import 'search.dart';
import '../l10n/app_localizations.dart';
import '../widgets/app_dialog.dart';

class FindReplaceDialog extends StatefulWidget {
  const FindReplaceDialog({
    super.key,
    required this.text,
    required this.initialQuery,
  });

  final TextEditingController text;

  final String initialQuery;

  @override
  State<FindReplaceDialog> createState() => _FindReplaceDialogState();
}

class _FindReplaceDialogState extends State<FindReplaceDialog> {
  late final TextEditingController _find = TextEditingController(
    text: widget.initialQuery,
  );
  final TextEditingController _replace = TextEditingController();
  final FocusNode _findFocus = FocusNode();
  final FocusNode _replaceFocus = FocusNode();
  bool _wholeWord = false;
  String _status = '';

  @override
  void dispose() {
    _find.dispose();
    _replace.dispose();
    _findFocus.dispose();
    _replaceFocus.dispose();
    super.dispose();
  }

  void _next() {
    final bool found = findNext(widget.text, _find.text, wholeWord: _wholeWord);
    setState(
      () => _status = found ? '' : AppLocalizations.of(context).noMatches,
    );
  }

  void _replaceOne() {
    final bool found = replaceCurrent(
      widget.text,
      _find.text,
      _replace.text,
      wholeWord: _wholeWord,
    );
    setState(
      () => _status = found ? '' : AppLocalizations.of(context).noMatches,
    );
  }

  void _replaceEvery() {
    final int count = replaceAll(
      widget.text,
      _find.text,
      _replace.text,
      wholeWord: _wholeWord,
    );
    final AppLocalizations l10n = AppLocalizations.of(context);
    setState(
      () => _status = count == 0 ? l10n.noMatches : l10n.replacedCount(count),
    );
  }

  @override
  Widget build(BuildContext context) {
    final MaunaThemeData theme = MaunaThemeData.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);
    return AppDialog(
      title: l10n.findAndReplace,
      child: Padding(
        padding: EdgeInsets.all(theme.spacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            DialogTextField(
              controller: _find,
              focusNode: _findFocus,
              placeholder: l10n.findPlaceholder,
              autofocus: true,
              onSubmitted: _next,
            ),
            SizedBox(height: theme.spacing.sm),
            DialogTextField(
              controller: _replace,
              focusNode: _replaceFocus,
              placeholder: l10n.replacePlaceholder,
              onSubmitted: _replaceOne,
            ),
            SizedBox(height: theme.spacing.sm),
            Wrap(
              spacing: theme.spacing.xs,
              runSpacing: theme.spacing.xs,
              children: <Widget>[
                MaunaToolbarChip(label: l10n.findNext, onPressed: _next),
                MaunaToolbarChip(label: l10n.replace, onPressed: _replaceOne),
                MaunaToolbarChip(
                  label: l10n.replaceAll,
                  onPressed: _replaceEvery,
                ),
                MaunaToolbarChip(
                  label: _wholeWord ? l10n.wholeWordOn : l10n.wholeWordOff,
                  onPressed: () => setState(() => _wholeWord = !_wholeWord),
                ),
              ],
            ),
            SizedBox(height: theme.spacing.sm),
            Text(
              _status,
              style: theme.uiStyle.copyWith(color: theme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
