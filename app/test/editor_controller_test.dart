import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mauna_ranga/bridge/generated/api/document.dart';
import 'package:mauna_ranga/editor/editor_controller.dart';
import 'package:mauna_ranga/editor/fountain_elements.dart';

import 'rust_library.dart';

List<String> describe(List<FountainElement> elements) {
  return <String>[
    for (final FountainElement e in elements)
      '${e.kind} ${e.start}-${e.end} ${e.spans.map((s) => '${s.style}:${s.start}-${s.end}').join(',')}',
  ];
}

void main() {
  setUpAll(initRustLibrary);

  test('patched elements match a fresh parse after random edits', () async {
    final EditorController editor = EditorController();
    await editor.load(
      'Title: Test\n\nINT. HOUSE - DAY\n\nShe *waits* 🎬.\n\nSTEEL\n(quietly)\nHello.\n',
    );
    final Random random = Random(7);
    const List<String> pieces = <String>[
      'a',
      ' ',
      '\n',
      '\n\n',
      '*',
      '🎬',
      'INT. ',
      '(',
      ')',
      'Ω',
    ];
    for (int i = 0; i < 300; i++) {
      final String text = editor.text.text;
      int start = random.nextInt(text.length + 1);
      int end = min(text.length, start + random.nextInt(4));
      if (start > 0 &&
          start < text.length &&
          text.codeUnitAt(start) >= 0xDC00 &&
          text.codeUnitAt(start) <= 0xDFFF) {
        start--;
      }
      if (end < text.length &&
          text.codeUnitAt(end) >= 0xDC00 &&
          text.codeUnitAt(end) <= 0xDFFF) {
        end++;
      }
      final String replacement = random.nextBool()
          ? pieces[random.nextInt(pieces.length)]
          : '';
      editor.text.value = TextEditingValue(
        text: text.replaceRange(start, end, replacement),
        selection: TextSelection.collapsed(offset: start + replacement.length),
      );
    }
    final DocumentHandle fresh = await createDocument(source: editor.text.text);
    final List<FountainElement> expected = <FountainElement>[];
    applySnapshot(expected, documentSnapshot(handle: fresh));
    expect(describe(editor.text.elements), describe(expected));
    expect(editor.words, wordCount(handle: fresh));
    editor.dispose();
  });
}
