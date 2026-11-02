import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mauna_ranga/main.dart';
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

void main() {
  setUpAll(initRustLibrary);

  testWidgets('opening a file adds it to the File menu and saves settings', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    final Directory dir = Directory.systemTemp.createTempSync('ranga_recent');
    addTearDown(() => dir.deleteSync(recursive: true));
    final File script = File('${dir.path}/story.fountain')
      ..writeAsStringSync('INT. ROOM - DAY\n\nText.\n');
    final File settingsFile = File('${dir.path}/settings.json');
    await tester.pumpWidget(
      RangaApp(
        store: SettingsStore(settingsFile),
        settings: const AppSettings(),
        initialPath: script.path,
      ),
    );
    await settle(tester);

    await tester.tap(find.text('File'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Open story.fountain'), findsOneWidget);
    await tester.tap(find.text('Open story.fountain'));
    await settle(tester);
    final AppSettings saved =
        await tester.runAsync(SettingsStore(settingsFile).load) as AppSettings;
    expect(saved.recentFiles, <String>[script.path]);
  });

  testWidgets('a missing recent file is dropped from the list', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    final Directory dir = Directory.systemTemp.createTempSync('ranga_recent');
    addTearDown(() => dir.deleteSync(recursive: true));
    final String missing = '${dir.path}/gone.fountain';
    await tester.pumpWidget(
      RangaApp(
        store: SettingsStore(File('${dir.path}/settings.json')),
        settings: AppSettings(recentFiles: <String>[missing]),
      ),
    );
    await settle(tester);

    await tester.tap(find.text('File'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Open gone.fountain'));
    await settle(tester);
    expect(find.text('Cannot open the file'), findsWidgets);
    await tester.tapAt(const Offset(5, 5));
    await settle(tester);
    await tester.tap(find.text('File'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Open gone.fountain'), findsNothing);
  });
}
