import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:mauna/mauna.dart';

import '../bridge/generated/api/document.dart';
import 'fountain_elements.dart';

class FountainTextController extends MaunaTextController {
  FountainTextController({super.text});

  List<FountainElement> elements = <FountainElement>[];

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final bool composing =
        withComposing &&
        value.isComposingRangeValid &&
        !value.composing.isCollapsed;
    if (composing) {
      return super.buildTextSpan(
        context: context,
        style: style,
        withComposing: withComposing,
      );
    }
    final MaunaThemeData theme = MaunaThemeData.of(context);
    final TextStyle base = style ?? theme.docStyle;
    final List<_Piece> pieces = <_Piece>[];
    int cursor = 0;
    for (final FountainElement element in elements) {
      final int start = math.min(element.start, text.length);
      final int end = math.min(element.end, text.length);
      if (start < cursor) {
        continue;
      }
      if (start > cursor) {
        pieces.add(_Piece(cursor, start, base));
      }
      _addElement(
        pieces,
        element,
        start,
        end,
        _elementStyle(theme, base, element.kind),
        theme,
      );
      cursor = end;
    }
    if (cursor < text.length) {
      pieces.add(_Piece(cursor, text.length, base));
    }
    return TextSpan(
      style: base,
      children: _withSelection(pieces, theme.textOnAccent),
    );
  }

  TextStyle _elementStyle(
    MaunaThemeData theme,
    TextStyle base,
    ElementType kind,
  ) {
    switch (kind) {
      case ElementType.sceneHeading:
        return base.copyWith(fontWeight: FontWeight.w700);
      case ElementType.section:
        return base.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.textSecondary,
        );
      case ElementType.transition:
      case ElementType.synopsis:
      case ElementType.note:
      case ElementType.boneyard:
      case ElementType.pageBreak:
        return base.copyWith(color: theme.textSecondary);
      case ElementType.action:
      case ElementType.character:
      case ElementType.dialogue:
      case ElementType.parenthetical:
      case ElementType.centered:
      case ElementType.lyric:
        return base;
    }
  }

  void _addElement(
    List<_Piece> pieces,
    FountainElement element,
    int start,
    int end,
    TextStyle style,
    MaunaThemeData theme,
  ) {
    final List<int> cuts = <int>[start, end];
    for (final FountainSpan span in element.spans) {
      cuts
        ..add(span.start.clamp(start, end))
        ..add(span.end.clamp(start, end));
    }
    cuts.sort();
    for (int i = 0; i + 1 < cuts.length; i++) {
      final int from = cuts[i];
      final int to = cuts[i + 1];
      if (from == to) {
        continue;
      }
      TextStyle pieceStyle = style;
      for (final FountainSpan span in element.spans) {
        if (span.start > from || span.end < to) {
          continue;
        }
        pieceStyle = _applySpan(pieceStyle, span.style, theme);
      }
      pieces.add(_Piece(from, to, pieceStyle));
    }
  }

  TextStyle _applySpan(TextStyle style, SpanStyle span, MaunaThemeData theme) {
    switch (span) {
      case SpanStyle.bold:
        return style.copyWith(fontWeight: FontWeight.w700);
      case SpanStyle.italic:
        return style.copyWith(fontStyle: FontStyle.italic);
      case SpanStyle.underline:
        return style.copyWith(decoration: TextDecoration.underline);
      case SpanStyle.marker:
      case SpanStyle.note:
      case SpanStyle.boneyard:
        return style.copyWith(color: theme.textSecondary);
    }
  }

  List<TextSpan> _withSelection(List<_Piece> pieces, Color selected) {
    final TextSelection selection = value.selection;
    final bool hasSelection = selection.isValid && !selection.isCollapsed;
    final List<TextSpan> spans = <TextSpan>[];
    for (final _Piece piece in pieces) {
      if (!hasSelection ||
          piece.end <= selection.start ||
          piece.start >= selection.end) {
        spans.add(_span(piece.start, piece.end, piece.style));
        continue;
      }
      final int from = math.max(piece.start, selection.start);
      final int to = math.min(piece.end, selection.end);
      if (piece.start < from) {
        spans.add(_span(piece.start, from, piece.style));
      }
      spans.add(_span(from, to, piece.style.copyWith(color: selected)));
      if (to < piece.end) {
        spans.add(_span(to, piece.end, piece.style));
      }
    }
    return spans;
  }

  TextSpan _span(int start, int end, TextStyle style) {
    return TextSpan(text: text.substring(start, end), style: style);
  }
}

class _Piece {
  const _Piece(this.start, this.end, this.style);

  final int start;
  final int end;
  final TextStyle style;
}
