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

  testWidgets('Tab in the editor completes a character name', (
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
      'STEEL\nHello.\n\nST',
    );
    await settle(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();

    final EditableText editable = tester.widget(
      find.byType(EditableText).first,
    );
    expect(editable.controller.text, 'STEEL\nHello.\n\nSTEEL');
  });
}
