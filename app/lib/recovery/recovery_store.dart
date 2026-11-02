import 'dart:convert';
import 'dart:io';

import '../settings/app_directory.dart';

class RecoverySnapshot {
  const RecoverySnapshot(this.path, this.text);

  final String? path;

  final String text;
}

class RecoveryStore {
  RecoveryStore(this.file);

  factory RecoveryStore.forUser() {
    return RecoveryStore(File('${appDataDirectory()}/recovery.json'));
  }

  final File file;

  Future<RecoverySnapshot?> read() async {
    if (!await file.exists()) {
      return null;
    }
    try {
      final Object? json = jsonDecode(await file.readAsString());
      if (json is Map<String, Object?> && json['text'] is String) {
        final Object? path = json['path'];
        return RecoverySnapshot(
          path is String ? path : null,
          json['text'] as String,
        );
      }
    } on FormatException {
      return null;
    }
    return null;
  }

  Future<void> write(String? path, String text) async {
    await file.parent.create(recursive: true);
    final File temporary = File('${file.path}.tmp');
    await temporary.writeAsString(
      jsonEncode(<String, Object?>{'path': path, 'text': text}),
    );
    await temporary.rename(file.path);
  }

  Future<void> clear() async {
    if (await file.exists()) {
      await file.delete();
    }
  }
}
