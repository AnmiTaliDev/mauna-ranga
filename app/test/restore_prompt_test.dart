import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mauna_ranga/main.dart';
import 'package:mauna_ranga/recovery/recovery_store.dart';
import 'package:mauna_ranga/settings/app_settings.dart';
import 'package:mauna_ranga/settings/settings_store.dart';

import 'rust_library.dart';

Future<void> settle(WidgetTester tester) async {
  for (int i = 0; i < 8; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 40)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<Directory> start(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1200, 800));
  final Directory dir = Directory.systemTemp.createTempSync('ranga_restore');
  addTearDown(() => dir.deleteSync(recursive: true));
  final RecoveryStore store = RecoveryStore(File('${dir.path}/recovery.json'));
  await tester.runAsync(() => store.write(null, 'Recovered text.'));
  await tester.pumpWidget(
    RangaApp(
      store: SettingsStore(File('${dir.path}/settings.json')),
      settings: const AppSettings(),
      recovery: store,
    ),
  );
  await settle(tester);
  return dir;
}

void main() {
  setUpAll(initRustLibrary);

  testWidgets('Restore brings back the unsaved document', (
    WidgetTester tester,
  ) async {
    await start(tester);
    expect(find.text('Restore unsaved changes'), findsWidgets);
    await tester.tap(find.text('Restore'));
    await settle(tester);
    final EditableText document = tester.widget(
      find.byType(EditableText).first,
    );
    expect(document.controller.text, 'Recovered text.');
  });

  testWidgets('Discard opens an empty document and removes the copy', (
    WidgetTester tester,
  ) async {
    final Directory dir = await start(tester);
    await tester.tap(find.text('Discard'));
    await settle(tester);
    final EditableText document = tester.widget(
      find.byType(EditableText).first,
    );
    expect(document.controller.text, '');
    expect(File('${dir.path}/recovery.json').existsSync(), isFalse);
  });
}
