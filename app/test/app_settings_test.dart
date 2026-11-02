import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mauna_ranga/settings/app_settings.dart';
import 'package:mauna_ranga/settings/settings_store.dart';

void main() {
  test('settings survive a save and load', () async {
    final Directory dir = Directory.systemTemp.createTempSync('ranga_settings');
    addTearDown(() => dir.deleteSync(recursive: true));
    final SettingsStore store = SettingsStore(
      File('${dir.path}/a/settings.json'),
    );
    const AppSettings settings = AppSettings(
      preset: ThemePreset.midnight,
      accent: AccentChoice.indigo,
      font: DocumentFont.jetBrainsMono,
      dimWhileTyping: false,
      minutesPerPage: 1.25,
    );
    await store.save(settings);
    final AppSettings loaded = await store.load();
    expect(loaded.toJson(), settings.toJson());
    expect(loaded.theme().fontDoc, 'JetBrains Mono');
  });

  test('broken settings file falls back to defaults', () async {
    final Directory dir = Directory.systemTemp.createTempSync('ranga_settings');
    addTearDown(() => dir.deleteSync(recursive: true));
    final File file = File('${dir.path}/settings.json')..writeAsStringSync('{');
    final AppSettings loaded = await SettingsStore(file).load();
    expect(loaded.toJson(), const AppSettings().toJson());
  });

  test('recent files keep the newest first without duplicates', () {
    AppSettings settings = const AppSettings();
    settings = settings.withRecentFile('/a').withRecentFile('/b');
    settings = settings.withRecentFile('/a');
    expect(settings.recentFiles, <String>['/a', '/b']);
    expect(settings.withoutRecentFile('/a').recentFiles, <String>['/b']);
  });

  test('recent files are limited and survive a save and load', () async {
    AppSettings settings = const AppSettings();
    for (int i = 0; i < recentFilesLimit + 3; i++) {
      settings = settings.withRecentFile('/file$i');
    }
    expect(settings.recentFiles.length, recentFilesLimit);
    expect(settings.recentFiles.first, '/file${recentFilesLimit + 2}');
    final AppSettings loaded = AppSettings.fromJson(settings.toJson());
    expect(loaded.recentFiles, settings.recentFiles);
    expect(
      AppSettings.fromJson(<String, Object?>{
        'recentFiles': <Object?>['/a', 3, null],
      }).recentFiles,
      <String>['/a'],
    );
  });

  test('PDF options default to a plain export and survive a round trip', () {
    const AppSettings defaults = AppSettings();
    expect(defaults.pdfTitlePage, isTrue);
    expect(defaults.pdfPageNumbers, isTrue);
    expect(defaults.pdfWatermark, '');
    expect(defaults.pdfNotesPage, isFalse);
    expect(
      AppSettings.fromJson(
        const AppSettings(pdfNotesPage: true).toJson(),
      ).pdfNotesPage,
      isTrue,
    );
    final AppSettings loaded = AppSettings.fromJson(
      const AppSettings(
        pdfTitlePage: false,
        pdfPageNumbers: false,
        pdfWatermark: 'DRAFT',
      ).toJson(),
    );
    expect(loaded.pdfTitlePage, isFalse);
    expect(loaded.pdfPageNumbers, isFalse);
    expect(loaded.pdfWatermark, 'DRAFT');
    expect(
      AppSettings.fromJson(<String, Object?>{'pdfWatermark': 3}).pdfWatermark,
      '',
    );
  });
}
