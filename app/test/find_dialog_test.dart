import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
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

  testWidgets('Ctrl+F opens the dialog and Replace all renames a character', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    final Directory dir = Directory.systemTemp.createTempSync('ranga_test');
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
      'ST\nHello.\n\nSTELLA\nHi.\n\nST\nBye.',
    );
    await settle(tester);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Find and replace'), findsWidgets);

    await tester.enterText(find.byType(EditableText).at(1), 'ST');
    await tester.enterText(find.byType(EditableText).at(2), 'STEEL');
    await tester.tap(find.text('Whole word: off'));
    await tester.pump();
    await tester.tap(find.text('Replace all'));
    await tester.pump();
    expect(find.text('Replaced 2'), findsOneWidget);

    final EditableText document = tester.widget(
      find.byType(EditableText).first,
    );
    expect(
      document.controller.text,
      'STEEL\nHello.\n\nSTELLA\nHi.\n\nSTEEL\nBye.',
    );
  });
}
