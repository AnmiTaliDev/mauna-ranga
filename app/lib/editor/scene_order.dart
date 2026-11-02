import '../bridge/generated/api/document.dart';

class SceneMove {
  const SceneMove(this.text, this.caret);

  final String text;

  final int caret;
}

SceneMove? moveScene(
  String text,
  List<OutlineEntry> outline,
  int index,
  int direction,
) {
  final int neighbor = index + direction;
  if (neighbor < 0 ||
      neighbor >= outline.length ||
      outline[index].level != 0 ||
      outline[neighbor].level != 0) {
    return null;
  }
  final int upper = direction < 0 ? neighbor : index;
  final int start = outline[upper].offset;
  final int middle = outline[upper + 1].offset;
  final int end = upper + 2 < outline.length
      ? outline[upper + 2].offset
      : text.length;
  final String first = text.substring(start, middle);
  final String second = text.substring(middle, end);
  final String firstBody = _body(first);
  final String secondBody = _body(second);
  final String firstTrail = first.substring(firstBody.length);
  final String secondTrail = second.substring(secondBody.length);
  final String movedFirst =
      secondBody + (firstTrail.length >= 2 ? firstTrail : '\n\n');
  final String movedSecond = firstBody + secondTrail;
  return SceneMove(
    text.substring(0, start) + movedFirst + movedSecond + text.substring(end),
    direction < 0 ? start : start + movedFirst.length,
  );
}

String _body(String block) {
  int end = block.length;
  while (end > 0 && block.codeUnitAt(end - 1) == 0x0A) {
    end--;
  }
  return block.substring(0, end);
}
