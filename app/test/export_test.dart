import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mauna_ranga/editor/editor_controller.dart';

import 'rust_library.dart';

const String script =
    'Title: ПОСЛЕДНИЙ ТРАМВАЙ\n\nEXT. НОЧНАЯ УЛИЦА - НОЧЬ\n\nОдинокий фонарь.\n\nМАКСИМ\nДо вокзала идёт?\n';

void main() {
  setUpAll(initRustLibrary);

  test('pasted text reaches FDX and PDF export', () async {
    final Directory dir = Directory.systemTemp.createTempSync('ranga_export');
    addTearDown(() => dir.deleteSync(recursive: true));
    final EditorController editor = EditorController();
    await editor.load('');
    editor.text.value = const TextEditingValue(
      text: script,
      selection: TextSelection.collapsed(offset: script.length),
    );
    await editor.exportFdx('${dir.path}/script.fdx');
    final String fdx = File('${dir.path}/script.fdx').readAsStringSync();
    expect(fdx, contains('<Text>EXT. НОЧНАЯ УЛИЦА - НОЧЬ</Text>'));
    expect(fdx, contains('<Text>До вокзала идёт?</Text>'));
    editor.dispose();
  });
}
