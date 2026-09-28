import '../bridge/generated/api/document.dart';

class FountainSpan {
  FountainSpan(this.style, this.start, this.end);

  final SpanStyle style;
  int start;
  int end;
}

class FountainElement {
  FountainElement(this.kind, this.start, this.end, this.spans);

  FountainElement.fromSnapshot(ElementSnapshot snapshot)
    : kind = snapshot.kind,
      start = snapshot.start,
      end = snapshot.end,
      spans = <FountainSpan>[
        for (final StyleSpan span in snapshot.spans)
          FountainSpan(span.style, span.start, span.end),
      ];

  final ElementType kind;
  int start;
  int end;
  final List<FountainSpan> spans;

  void shift(int delta) {
    start += delta;
    end += delta;
    for (final FountainSpan span in spans) {
      span.start += delta;
      span.end += delta;
    }
  }
}

void applySnapshot(List<FountainElement> elements, DocumentSnapshot snapshot) {
  final int first = snapshot.first;
  final int shift = snapshot.shift.toInt();
  elements.replaceRange(first, first + snapshot.removed, <FountainElement>[
    for (final ElementSnapshot element in snapshot.inserted)
      FountainElement.fromSnapshot(element),
  ]);
  if (shift == 0) {
    return;
  }
  for (int i = first + snapshot.inserted.length; i < elements.length; i++) {
    elements[i].shift(shift);
  }
}
