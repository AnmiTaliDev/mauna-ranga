import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mauna_ranga/editor/editor_controller.dart';

import 'rust_library.dart';

const String script =
    'INT. HOUSE - DAY\n\nSTEEL\nHello.\n\nSTELLA\nHi.\n\nSTEEL (V.O.)\nAgain.\n\nEXT. GARDEN - NIGHT\n\nRain.\n\nINT. HALL - DAY\n\nDark.\n\n';

Future<EditorController> editorAt(String typed) async {
  final EditorController editor = EditorController();
  await editor.load(script);
  editor.text.value = TextEditingValue(
    text: script + typed,
    selection: TextSelection.collapsed(offset: script.length + typed.length),
  );
  return editor;
}

void main() {
  setUpAll(initRustLibrary);

  test('Tab completes a character name, most frequent first', () async {
    final EditorController editor = await editorAt('ST');
    expect(editor.complete(), isTrue);
    expect(editor.text.text, '${script}STEEL');
    expect(editor.text.selection.baseOffset, editor.text.text.length);
    expect(editor.complete(), isTrue);
    expect(editor.text.text, '${script}STELLA');
    expect(editor.complete(), isTrue);
    expect(editor.text.text, '${script}STEEL');
    editor.dispose();
  });

  test('Tab completes a location without the time of day', () async {
    final EditorController editor = await editorAt('int. h');
    expect(editor.complete(), isTrue);
    expect(editor.text.text, '${script}INT. HOUSE');
    expect(editor.complete(), isTrue);
    expect(editor.text.text, '${script}INT. HALL');
    editor.dispose();
  });

  test('Tab does nothing on ordinary lines', () async {
    final EditorController editor = await editorAt('She');
    expect(editor.complete(), isFalse);
    expect(editor.text.text, '${script}She');
    editor.dispose();
  });

  test(
    'Tab needs a blank line before the line and a collapsed caret',
    () async {
      final EditorController editor = EditorController();
      await editor.load('STEEL\nHello.\n');
      editor.text.value = const TextEditingValue(
        text: 'STEEL\nHello.\nST',
        selection: TextSelection.collapsed(offset: 16),
      );
      expect(editor.complete(), isFalse);
      editor.text.value = TextEditingValue(
        text: '${script}ST',
        selection: TextSelection(
          baseOffset: script.length,
          extentOffset: script.length + 2,
        ),
      );
      expect(editor.complete(), isFalse);
      editor.dispose();
    },
  );
}
