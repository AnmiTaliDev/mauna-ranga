import 'dart:io';

import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mauna_ranga/editor/editor_controller.dart';
import 'package:mauna_ranga/main.dart';
import 'package:mauna_ranga/recovery/recovery_store.dart';
import 'package:mauna_ranga/settings/app_settings.dart';
import 'package:mauna_ranga/settings/settings_store.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'rust_library.dart';

const String fdx = '''<?xml version="1.0" encoding="UTF-8" standalone="no" ?>
<FinalDraft DocumentType="Script" Template="No" Version="2">
  <Content>
    <Paragraph Number="1" Type="Scene Heading"><Text>INT. KITCHEN - DAY</Text></Paragraph>
    <Paragraph Type="Action"><Text>Tom &amp; Jerry.</Text></Paragraph>
    <Paragraph Type="Character"><Text>TOM</Text></Paragraph>
    <Paragraph Type="Dialogue"><Text>Hello.</Text></Paragraph>
  </Content>
</FinalDraft>''';

const String expected =
    'INT. KITCHEN - DAY #1#\n\nTom & Jerry.\n\nTOM\nHello.\n';

class FakeOpenSelector extends FileSelectorPlatform
    with MockPlatformInterfaceMixin {
  String path = '';

  @override
  Future<XFile?> openFile({
    List<XTypeGroup>? acceptedTypeGroups,
    String? confirmButtonText,
    String? initialDirectory,
  }) async => XFile(path);
}

Future<void> settle(WidgetTester tester) async {
  for (int i = 0; i < 8; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 40)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUpAll(initRustLibrary);

  test('importFdx loads the converted text as an unsaved document', () async {
    final Directory dir = Directory.systemTemp.createTempSync('ranga_import');
    addTearDown(() => dir.deleteSync(recursive: true));
    final File file = File('${dir.path}/story.fdx')..writeAsStringSync(fdx);
    final RecoveryStore store = RecoveryStore(
      File('${dir.path}/recovery.json'),
    );
    final EditorController editor = EditorController(recovery: store);
    await editor.load('old text', path: '/tmp/old.fountain');
    await editor.importFdx(file.path);
    expect(editor.text.text, expected);
    expect(editor.path, isNull);
    expect((await store.read())?.text, expected);
    editor.dispose();
  });

  test('importFdx rejects a file that is not Final Draft', () async {
    final Directory dir = Directory.systemTemp.createTempSync('ranga_import');
    addTearDown(() => dir.deleteSync(recursive: true));
    final File file = File('${dir.path}/other.fdx')
      ..writeAsStringSync('<html></html>');
    final EditorController editor = EditorController();
    await editor.load('keep me');
    await expectLater(editor.importFdx(file.path), throwsA(isA<String>()));
    expect(editor.text.text, 'keep me');
    editor.dispose();
  });

  testWidgets('File menu imports an FDX file', (WidgetTester tester) async {
    final Directory dir = Directory.systemTemp.createTempSync('ranga_import');
    addTearDown(() => dir.deleteSync(recursive: true));
    final File file = File('${dir.path}/story.fdx')..writeAsStringSync(fdx);
    final FakeOpenSelector selector = FakeOpenSelector()..path = file.path;
    FileSelectorPlatform.instance = selector;
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    await tester.pumpWidget(
      RangaApp(
        store: SettingsStore(File('${dir.path}/settings.json')),
        settings: const AppSettings(),
      ),
    );
    await settle(tester);
    await tester.tap(find.text('File'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Import FDX'));
    await settle(tester);
    final EditableText document = tester.widget(
      find.byType(EditableText).first,
    );
    expect(document.controller.text, expected);
  });
}
