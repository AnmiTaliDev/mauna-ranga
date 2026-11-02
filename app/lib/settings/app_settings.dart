import 'package:flutter/widgets.dart';
import 'package:mauna/mauna.dart';

enum ThemePreset {
  paper('Paper'),
  sepia('Sepia'),
  ink('Ink'),
  midnight('Midnight');

  const ThemePreset(this.label);

  final String label;

  bool get isLight => this == ThemePreset.paper || this == ThemePreset.sepia;
}

enum AccentChoice {
  steelBlue('Steel blue', MaunaAccents.steelBlue),
  graphite('Graphite', MaunaAccents.graphite),
  coolTeal('Cool teal', MaunaAccents.coolTeal),
  indigo('Indigo', MaunaAccents.indigo);

  const AccentChoice(this.label, this.value);

  final String label;

  final MaunaAccent value;
}

enum DocumentFont {
  courierPrime('Courier Prime', 'CourierPrime', 'Latin only'),
  jetBrainsMono('JetBrains Mono', 'JetBrainsMono', 'Latin and Cyrillic');

  const DocumentFont(this.family, this.filePrefix, this.coverage);

  final String family;

  final String filePrefix;

  final String coverage;
}

const int recentFilesLimit = 10;

class AppSettings {
  const AppSettings({
    this.preset = ThemePreset.paper,
    this.accent = AccentChoice.steelBlue,
    this.font = DocumentFont.courierPrime,
    this.dimWhileTyping = true,
    this.minutesPerPage = 1.0,
    this.recentFiles = const <String>[],
  });

  factory AppSettings.fromJson(Map<String, Object?> json) {
    const AppSettings defaults = AppSettings();
    final Object? dim = json['dimWhileTyping'];
    final Object? minutes = json['minutesPerPage'];
    final Object? recent = json['recentFiles'];
    return AppSettings(
      preset: _byName(ThemePreset.values, json['theme'], defaults.preset),
      accent: _byName(AccentChoice.values, json['accent'], defaults.accent),
      font: _byName(DocumentFont.values, json['font'], defaults.font),
      dimWhileTyping: dim is bool ? dim : defaults.dimWhileTyping,
      minutesPerPage: minutes is num && minutes > 0
          ? minutes.toDouble()
          : defaults.minutesPerPage,
      recentFiles: recent is List<Object?>
          ? recent.whereType<String>().take(recentFilesLimit).toList()
          : defaults.recentFiles,
    );
  }

  final ThemePreset preset;

  final AccentChoice accent;

  final DocumentFont font;

  final bool dimWhileTyping;

  final double minutesPerPage;

  final List<String> recentFiles;

  AppSettings copyWith({
    ThemePreset? preset,
    AccentChoice? accent,
    DocumentFont? font,
    bool? dimWhileTyping,
    double? minutesPerPage,
    List<String>? recentFiles,
  }) {
    return AppSettings(
      preset: preset ?? this.preset,
      accent: accent ?? this.accent,
      font: font ?? this.font,
      dimWhileTyping: dimWhileTyping ?? this.dimWhileTyping,
      minutesPerPage: minutesPerPage ?? this.minutesPerPage,
      recentFiles: recentFiles ?? this.recentFiles,
    );
  }

  AppSettings withRecentFile(String path) {
    return copyWith(
      recentFiles: <String>[
        path,
        ...recentFiles.where((String file) => file != path),
      ].take(recentFilesLimit).toList(),
    );
  }

  AppSettings withoutRecentFile(String path) {
    return copyWith(
      recentFiles: recentFiles.where((String file) => file != path).toList(),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'theme': preset.name,
      'accent': accent.name,
      'font': font.name,
      'dimWhileTyping': dimWhileTyping,
      'minutesPerPage': minutesPerPage,
      'recentFiles': recentFiles,
    };
  }

  MaunaThemeData theme() {
    final Color accentColor = preset.isLight
        ? accent.value.light
        : accent.value.dark;
    final MaunaThemeData base = switch (preset) {
      ThemePreset.paper => MaunaThemeData.light(accent: accentColor),
      ThemePreset.sepia => MaunaThemeData.sepia(accent: accentColor),
      ThemePreset.ink => MaunaThemeData.dark(accent: accentColor),
      ThemePreset.midnight => MaunaThemeData.midnight(accent: accentColor),
    };
    return base.copyWith(fontDoc: font.family);
  }
}

T _byName<T extends Enum>(List<T> values, Object? name, T fallback) {
  for (final T value in values) {
    if (value.name == name) {
      return value;
    }
  }
  return fallback;
}
