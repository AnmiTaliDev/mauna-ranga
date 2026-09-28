import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mauna/mauna.dart';
import 'dart:io';

import 'package:mauna_ranga/main.dart';
import 'package:mauna_ranga/settings/app_settings.dart';
import 'package:mauna_ranga/settings/settings_store.dart';

import 'rust_library.dart';

Future<void> settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  await tester.pump(const Duration(milliseconds: 400));
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> chord(
  WidgetTester tester,
  LogicalKeyboardKey key, {
  bool shift = false,
}) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  if (shift) {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  }
  await tester.sendKeyEvent(key);
  if (shift) {
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  }
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  setUpAll(initRustLibrary);

  testWidgets(
    'typing updates outline, palette runs a command, focus mode hides chrome',
    (WidgetTester tester) async {
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
        'INT. HOUSE - DAY\n\nShe waits.\n\nEXT. GARDEN - NIGHT\n\nRain.\n',
      );
      await settle(tester);

      expect(find.text('INT. HOUSE - DAY'), findsWidgets);
      expect(find.text('EXT. GARDEN - NIGHT'), findsWidgets);
      expect(find.text('Words: 9'), findsOneWidget);
      expect(find.text('Pages: 1'), findsOneWidget);

      await chord(tester, LogicalKeyboardKey.keyK);
      expect(find.byType(MaunaCommandPalette), findsOneWidget);
      await tester.tap(find.text('Hide sidebar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(MaunaCommandPalette), findsNothing);
      expect(tester.getSize(find.byType(MaunaSidebar)).width, 0);

      await chord(tester, LogicalKeyboardKey.keyB);
      expect(tester.getSize(find.byType(MaunaSidebar)).width, greaterThan(0));

      await chord(tester, LogicalKeyboardKey.keyF, shift: true);
      expect(tester.getSize(find.byType(MaunaToolbar)).height, 0);
      expect(tester.getSize(find.byType(MaunaSidebar)).width, 0);
      expect(find.byType(MaunaToolbarRestoreButton), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.getSize(find.byType(MaunaToolbar)).height, greaterThan(0));
    },
  );
}
