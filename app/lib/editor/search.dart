import 'package:flutter/widgets.dart';

const String _wordChars = r'\p{L}\p{N}_';

RegExp _pattern(String query, bool wholeWord) {
  final String escaped = RegExp.escape(query);
  return RegExp(
    wholeWord ? '(?<![$_wordChars])$escaped(?![$_wordChars])' : escaped,
    caseSensitive: false,
    unicode: true,
  );
}

bool findNext(
  TextEditingController text,
  String query, {
  bool wholeWord = false,
}) {
  if (query.isEmpty) {
    return false;
  }
  final String source = text.text;
  final RegExp pattern = _pattern(query, wholeWord);
  final int from = text.selection.isValid
      ? text.selection.end.clamp(0, source.length)
      : 0;
  final RegExpMatch? match =
      pattern.allMatches(source, from).firstOrNull ??
      pattern.allMatches(source).firstOrNull;
  if (match == null) {
    return false;
  }
  text.selection = TextSelection(
    baseOffset: match.start,
    extentOffset: match.end,
  );
  return true;
}

bool replaceCurrent(
  TextEditingController text,
  String query,
  String replacement, {
  bool wholeWord = false,
}) {
  final TextSelection selection = text.selection;
  final String source = text.text;
  if (query.isNotEmpty && selection.isValid && !selection.isCollapsed) {
    final Match? match = _pattern(
      query,
      wholeWord,
    ).matchAsPrefix(source, selection.start);
    if (match != null && match.end == selection.end) {
      text.value = TextEditingValue(
        text: source.replaceRange(selection.start, selection.end, replacement),
        selection: TextSelection.collapsed(
          offset: selection.start + replacement.length,
        ),
      );
    }
  }
  return findNext(text, query, wholeWord: wholeWord);
}

int replaceAll(
  TextEditingController text,
  String query,
  String replacement, {
  bool wholeWord = false,
}) {
  if (query.isEmpty) {
    return 0;
  }
  final RegExp pattern = _pattern(query, wholeWord);
  final String source = text.text;
  final int count = pattern.allMatches(source).length;
  if (count == 0) {
    return 0;
  }
  final String replaced = source.replaceAllMapped(
    pattern,
    (Match match) => replacement,
  );
  text.value = TextEditingValue(
    text: replaced,
    selection: const TextSelection.collapsed(offset: 0),
  );
  return count;
}
