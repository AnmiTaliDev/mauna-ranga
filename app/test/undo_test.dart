import 'dart:io';

import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mauna_ranga/main.dart';
import 'package:mauna_ranga/settings/app_settings.dart';
import 'package:mauna_ranga/settings/settings_store.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'rust_library.dart';

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

Future<void> chord(
  WidgetTester tester,
  LogicalKeyboardKey key, {
  bool alt = false,
}) async {
  await tester.sendKeyDownEvent(
    alt ? LogicalKeyboardKey.altLeft : LogicalKeyboardKey.controlLeft,
  );
  await tester.sendKeyEvent(key);
  await tester.sendKeyUpEvent(
    alt ? LogicalKeyboardKey.altLeft : LogicalKeyboardKey.controlLeft,
  );
  await settle(tester);
}

String documentText(WidgetTester tester) {
  final EditableText document = tester.widget(find.byType(EditableText).first);
  return document.controller.text;
}

Future<void> start(WidgetTester tester, String text) async {
  await tester.binding.setSurfaceSize(const Size(1280, 800));
  final Directory dir = Directory.systemTemp.createTempSync('ranga_undo');
  addTearDown(() => dir.deleteSync(recursive: true));
  await tester.pumpWidget(
    RangaApp(
      store: SettingsStore(File('${dir.path}/settings.json')),
      settings: const AppSettings(),
    ),
  );
  await settle(tester);
  await tester.enterText(find.byType(EditableText).first, text);
  await settle(tester);
}

void main() {
  setUpAll(initRustLibrary);

  testWidgets('Ctrl+Z undoes Replace all', (WidgetTester tester) async {
    const String original = 'ST\nHello.\n\nST\nBye.';
    await start(tester, original);
    await chord(tester, LogicalKeyboardKey.keyF);
    await tester.enterText(find.byType(EditableText).at(1), 'ST');
    await tester.enterText(find.byType(EditableText).at(2), 'STEEL');
    await tester.tap(find.text('Replace all'));
    await settle(tester);
    await tester.tapAt(const Offset(5, 5));
    await settle(tester);
    expect(documentText(tester), 'STEEL\nHello.\n\nSTEEL\nBye.');
    await chord(tester, LogicalKeyboardKey.keyZ);
    expect(documentText(tester), original);
  });

  testWidgets('Ctrl+Z undoes a scene move', (WidgetTester tester) async {
    const String original = 'INT. A - DAY\n\nFirst.\n\nINT. B - DAY\n\nSecond.';
    await start(tester, original);
    final EditableText document = tester.widget(
      find.byType(EditableText).first,
    );
    document.controller.selection = const TextSelection.collapsed(offset: 0);
    await settle(tester);
    await chord(tester, LogicalKeyboardKey.arrowDown, alt: true);
    expect(documentText(tester), isNot(original));
    await chord(tester, LogicalKeyboardKey.keyZ);
    expect(documentText(tester), original);
  });

  testWidgets('Ctrl+Z after opening a file keeps the opened text', (
    WidgetTester tester,
  ) async {
    final Directory dir = Directory.systemTemp.createTempSync('ranga_open');
    addTearDown(() => dir.deleteSync(recursive: true));
    final File other = File('${dir.path}/other.fountain')
      ..writeAsStringSync('The other file.\n');
    FileSelectorPlatform.instance = FakeOpenSelector()..path = other.path;
    await start(tester, 'My unsaved draft.');
    await chord(tester, LogicalKeyboardKey.keyO);
    expect(documentText(tester), 'The other file.\n');
    final EditableText document = tester.widget(
      find.byType(EditableText).first,
    );
    expect(document.focusNode.hasPrimaryFocus, isTrue);
    await chord(tester, LogicalKeyboardKey.keyZ);
    expect(documentText(tester), 'The other file.\n');
  });
}
