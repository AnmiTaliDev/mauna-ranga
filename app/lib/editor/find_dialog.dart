import 'package:flutter/widgets.dart';
import 'package:mauna/mauna.dart';

import '../widgets/dialog_text_field.dart';
import 'search.dart';

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
    setState(() => _status = found ? '' : 'No matches');
  }

  void _replaceOne() {
    final bool found = replaceCurrent(
      widget.text,
      _find.text,
      _replace.text,
      wholeWord: _wholeWord,
    );
    setState(() => _status = found ? '' : 'No matches');
  }

  void _replaceEvery() {
    final int count = replaceAll(
      widget.text,
      _find.text,
      _replace.text,
      wholeWord: _wholeWord,
    );
    setState(() => _status = count == 0 ? 'No matches' : 'Replaced $count');
  }

  @override
  Widget build(BuildContext context) {
    final MaunaThemeData theme = MaunaThemeData.of(context);
    return MaunaDialog(
      title: 'Find and replace',
      child: Padding(
        padding: EdgeInsets.all(theme.spacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            DialogTextField(
              controller: _find,
              focusNode: _findFocus,
              placeholder: 'Find',
              autofocus: true,
              onSubmitted: _next,
            ),
            SizedBox(height: theme.spacing.sm),
            DialogTextField(
              controller: _replace,
              focusNode: _replaceFocus,
              placeholder: 'Replace with',
              onSubmitted: _replaceOne,
            ),
            SizedBox(height: theme.spacing.sm),
            Wrap(
              spacing: theme.spacing.xs,
              runSpacing: theme.spacing.xs,
              children: <Widget>[
                MaunaToolbarChip(label: 'Find next', onPressed: _next),
                MaunaToolbarChip(label: 'Replace', onPressed: _replaceOne),
                MaunaToolbarChip(
                  label: 'Replace all',
                  onPressed: _replaceEvery,
                ),
                MaunaToolbarChip(
                  label: _wholeWord ? 'Whole word: on' : 'Whole word: off',
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
