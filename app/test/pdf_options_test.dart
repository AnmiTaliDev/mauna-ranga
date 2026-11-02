import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mauna_ranga/editor/editor_controller.dart';
import 'package:mauna_ranga/settings/app_settings.dart';

import 'rust_library.dart';

const String script = 'Title: Test\n\nINT. ROOM - DAY\n\nText.\n';

int pageCount(List<int> bytes) {
  final String text = String.fromCharCodes(bytes);
  final RegExpMatch? match = RegExp(
    r'/Type/Pages/Count (\d+)',
  ).firstMatch(text);
  return int.parse(match!.group(1)!);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(initRustLibrary);

  test('PDF settings change the exported file', () async {
    final Directory dir = Directory.systemTemp.createTempSync('ranga_pdf');
    addTearDown(() => dir.deleteSync(recursive: true));
    final EditorController editor = EditorController();
    await editor.load('');
    editor.text.value = const TextEditingValue(
      text: script,
      selection: TextSelection.collapsed(offset: script.length),
    );
    await editor.exportPdf('${dir.path}/default.pdf', const AppSettings());
    await editor.exportPdf(
      '${dir.path}/plain.pdf',
      const AppSettings(pdfTitlePage: false),
    );
    await editor.exportPdf(
      '${dir.path}/marked.pdf',
      const AppSettings(pdfWatermark: 'CONFIDENTIAL'),
    );
    final List<int> byDefault = File(
      '${dir.path}/default.pdf',
    ).readAsBytesSync();
    final List<int> plain = File('${dir.path}/plain.pdf').readAsBytesSync();
    final List<int> marked = File('${dir.path}/marked.pdf').readAsBytesSync();
    expect(pageCount(byDefault), 2);
    expect(pageCount(plain), 1);
    expect(marked.length, greaterThan(byDefault.length + 50));
    editor.dispose();
  });
}
