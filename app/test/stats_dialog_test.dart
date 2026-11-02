import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mauna_ranga/bridge/generated/api/document.dart';
import 'package:mauna_ranga/editor/editor_controller.dart';
import 'package:mauna_ranga/main.dart';
import 'package:mauna_ranga/settings/app_settings.dart';
import 'package:mauna_ranga/settings/settings_store.dart';

import 'rust_library.dart';

Future<void> settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  setUpAll(initRustLibrary);

  test('the controller reports speeches and words per character', () async {
    final EditorController editor = EditorController();
    await editor.load('STEEL\nHello there.\n\nBRICK\nHi.\n\nSTEEL\nBye.\n');
    final List<CharacterStat> stats = editor.characterStats();
    expect(stats.map((CharacterStat s) => s.name).toList(), <String>[
      'STEEL',
      'BRICK',
    ]);
    expect(stats.first.speeches, 2);
    expect(stats.first.words, 3);
    editor.dispose();
  });

  testWidgets('the Statistics command lists characters', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    final Directory dir = Directory.systemTemp.createTempSync('ranga_stats');
    addTearDown(() => dir.deleteSync(recursive: true));
    await tester.pumpWidget(
      RangaApp(
        store: SettingsStore(File('${dir.path}/settings.json')),
        settings: const AppSettings(),
      ),
    );
    await settle(tester);
    await tester.enterText(
      find.byType(EditableText).first,
      'STEEL\nHello there.\n\nBRICK\nHi.\n',
    );
    await settle(tester);

    await tester.tap(find.text('View'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Find and replace'), findsOneWidget);
    await tester.tap(find.text('Statistics'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Character'), findsOneWidget);
    expect(find.text('STEEL'), findsWidgets);
    expect(find.text('BRICK'), findsWidgets);
    expect(find.text('2'), findsWidgets);
  });
}
