import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mauna_ranga/bridge/generated/api/document.dart';
import 'package:mauna_ranga/editor/editor_controller.dart';
import 'package:mauna_ranga/main.dart';
import 'package:mauna_ranga/settings/app_settings.dart';
import 'package:mauna_ranga/settings/settings_store.dart';

import 'rust_library.dart';

const String script =
    '🎬 [[opening shot]]\n\nINT. DEPOT - NIGHT\n\nRain [[check the sound]] falls.\n';

Future<void> settle(WidgetTester tester) async {
  for (int i = 0; i < 6; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 40)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUpAll(initRustLibrary);

  test('the controller lists notes with UTF-16 offsets and scenes', () async {
    final EditorController editor = EditorController();
    await editor.load(script);
    final List<NoteItem> notes = editor.notes();
    expect(notes.map((NoteItem n) => n.text).toList(), <String>[
      'opening shot',
      'check the sound',
    ]);
    expect(notes[0].scene, isNull);
    expect(notes[1].scene, 'INT. DEPOT - NIGHT');
    expect(notes[0].offset, script.indexOf('[[opening'));
    expect(notes[1].offset, script.indexOf('[[check'));
    editor.dispose();
  });

  testWidgets('the Notes dialog moves the caret to the chosen note', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    final Directory dir = Directory.systemTemp.createTempSync('ranga_notes');
    addTearDown(() => dir.deleteSync(recursive: true));
    await tester.pumpWidget(
      RangaApp(
        store: SettingsStore(File('${dir.path}/settings.json')),
        settings: const AppSettings(),
      ),
    );
    await settle(tester);
    await tester.enterText(find.byType(EditableText).first, script);
    await settle(tester);

    await tester.tap(find.text('View'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Notes'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('opening shot'), findsOneWidget);
    expect(find.text('Before the first scene'), findsOneWidget);
    await tester.tap(find.text('check the sound'));
    await settle(tester);
    final EditableText document = tester.widget(
      find.byType(EditableText).first,
    );
    expect(document.controller.selection.baseOffset, script.indexOf('[[check'));
  });
}
