import 'dart:convert';
import 'dart:io';

import 'app_directory.dart';
import 'app_settings.dart';

class SettingsStore {
  SettingsStore(this.file);

  factory SettingsStore.forUser() {
    return SettingsStore(File('${appDataDirectory()}/settings.json'));
  }

  final File file;

  Future<AppSettings> load() async {
    if (!await file.exists()) {
      return const AppSettings();
    }
    try {
      final Object? json = jsonDecode(await file.readAsString());
      return json is Map<String, Object?>
          ? AppSettings.fromJson(json)
          : const AppSettings();
    } on FormatException {
      return const AppSettings();
    }
  }

  Future<void> save(AppSettings settings) async {
    await file.parent.create(recursive: true);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(settings.toJson()),
    );
  }
}
