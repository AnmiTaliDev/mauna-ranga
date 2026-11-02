import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mauna_ranga/bridge/generated/api/document.dart';
import 'package:mauna_ranga/editor/editor_controller.dart';
import 'package:mauna_ranga/editor/scene_order.dart';

import 'rust_library.dart';

const String source =
    'INT. A - DAY\n\nFirst.\n\nINT. B - DAY\n\nSecond.\n\nINT. C - DAY\n\nThird.';

void main() {
  setUpAll(initRustLibrary);

  test('moving a scene down swaps it with the next scene', () async {
    final EditorController editor = EditorController();
    await editor.load(source);
    final SceneMove? move = moveScene(source, editor.outline, 0, 1);
    expect(
      move?.text,
      'INT. B - DAY\n\nSecond.\n\nINT. A - DAY\n\nFirst.\n\nINT. C - DAY\n\nThird.',
    );
    expect(move?.caret, move?.text.indexOf('INT. A - DAY'));
    editor.dispose();
  });

  test('moving the last scene up keeps a blank line between scenes', () async {
    final EditorController editor = EditorController();
    await editor.load(source);
    final SceneMove? move = moveScene(source, editor.outline, 2, -1);
    expect(
      move?.text,
      'INT. A - DAY\n\nFirst.\n\nINT. C - DAY\n\nThird.\n\nINT. B - DAY\n\nSecond.',
    );
    expect(move?.caret, source.indexOf('INT. B - DAY'));
    editor.dispose();
  });

  test('moving past the first or last scene does nothing', () async {
    final EditorController editor = EditorController();
    await editor.load(source);
    expect(moveScene(source, editor.outline, 0, -1), isNull);
    expect(moveScene(source, editor.outline, 2, 1), isNull);
    editor.dispose();
  });

  test('a scene does not move across a section heading', () async {
    const String text =
        'INT. A - DAY\n\nFirst.\n\n# Act\n\nINT. B - DAY\n\nSecond.';
    final EditorController editor = EditorController();
    await editor.load(text);
    expect(moveScene(text, editor.outline, 0, 1), isNull);
    expect(moveScene(text, editor.outline, 2, -1), isNull);
    editor.dispose();
  });

  test('moveCurrentScene moves the scene under the caret', () async {
    final EditorController editor = EditorController();
    await editor.load(source);
    editor.text.selection = TextSelection.collapsed(
      offset: source.indexOf('Second.'),
    );
    editor.moveCurrentScene(-1);
    expect(
      editor.text.text.startsWith('INT. B - DAY\n\nSecond.\n\nINT. A - DAY'),
      isTrue,
    );
    expect(editor.outline.map((OutlineEntry e) => e.title).toList(), <String>[
      'INT. B - DAY',
      'INT. A - DAY',
      'INT. C - DAY',
    ]);
    editor.dispose();
  });
}
