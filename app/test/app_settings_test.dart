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
}
