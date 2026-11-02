import 'package:flutter/widgets.dart';
import 'package:mauna/mauna.dart';

enum ThemePreset {
  paper,
  sepia,
  ink,
  midnight;

  bool get isLight => this == ThemePreset.paper || this == ThemePreset.sepia;
}

enum AccentChoice {
  steelBlue(MaunaAccents.steelBlue),
  graphite(MaunaAccents.graphite),
  coolTeal(MaunaAccents.coolTeal),
  indigo(MaunaAccents.indigo);

  const AccentChoice(this.value);

  final MaunaAccent value;
}

enum DocumentFont {
  courierPrime('Courier Prime', 'CourierPrime', false),
  jetBrainsMono('JetBrains Mono', 'JetBrainsMono', true);

  const DocumentFont(this.family, this.filePrefix, this.hasCyrillic);

  final String family;

  final String filePrefix;

  final bool hasCyrillic;
}

enum AppLanguage {
  system(null),
  english(Locale('en')),
  russian(Locale('ru'));

  const AppLanguage(this.locale);

  final Locale? locale;
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
    this.pdfTitlePage = true,
    this.pdfPageNumbers = true,
    this.pdfNotesPage = false,
    this.language = AppLanguage.system,
    this.pdfWatermark = '',
  });

  factory AppSettings.fromJson(Map<String, Object?> json) {
    const AppSettings defaults = AppSettings();
    final Object? dim = json['dimWhileTyping'];
    final Object? minutes = json['minutesPerPage'];
    final Object? recent = json['recentFiles'];
    final Object? titlePage = json['pdfTitlePage'];
    final Object? pageNumbers = json['pdfPageNumbers'];
    final Object? watermark = json['pdfWatermark'];
    final Object? notesPage = json['pdfNotesPage'];
    return AppSettings(
      preset: _byName(ThemePreset.values, json['theme'], defaults.preset),
      accent: _byName(AccentChoice.values, json['accent'], defaults.accent),
      font: _byName(DocumentFont.values, json['font'], defaults.font),
      language: _byName(
        AppLanguage.values,
        json['language'],
        defaults.language,
      ),
      dimWhileTyping: dim is bool ? dim : defaults.dimWhileTyping,
      minutesPerPage: minutes is num && minutes > 0
          ? minutes.toDouble()
          : defaults.minutesPerPage,
      recentFiles: recent is List<Object?>
          ? recent.whereType<String>().take(recentFilesLimit).toList()
          : defaults.recentFiles,
      pdfTitlePage: titlePage is bool ? titlePage : defaults.pdfTitlePage,
      pdfPageNumbers: pageNumbers is bool
          ? pageNumbers
          : defaults.pdfPageNumbers,
      pdfNotesPage: notesPage is bool ? notesPage : defaults.pdfNotesPage,
      pdfWatermark: watermark is String ? watermark : defaults.pdfWatermark,
    );
  }

  final ThemePreset preset;

  final AccentChoice accent;

  final DocumentFont font;

  final bool dimWhileTyping;

  final double minutesPerPage;

  final List<String> recentFiles;

  final bool pdfTitlePage;

  final bool pdfPageNumbers;

  final bool pdfNotesPage;

  final AppLanguage language;

  final String pdfWatermark;

  AppSettings copyWith({
    ThemePreset? preset,
    AccentChoice? accent,
    DocumentFont? font,
    bool? dimWhileTyping,
    double? minutesPerPage,
    List<String>? recentFiles,
    bool? pdfTitlePage,
    bool? pdfPageNumbers,
    bool? pdfNotesPage,
    AppLanguage? language,
    String? pdfWatermark,
  }) {
    return AppSettings(
      preset: preset ?? this.preset,
      accent: accent ?? this.accent,
      font: font ?? this.font,
      dimWhileTyping: dimWhileTyping ?? this.dimWhileTyping,
      minutesPerPage: minutesPerPage ?? this.minutesPerPage,
      recentFiles: recentFiles ?? this.recentFiles,
      pdfTitlePage: pdfTitlePage ?? this.pdfTitlePage,
      pdfPageNumbers: pdfPageNumbers ?? this.pdfPageNumbers,
      pdfNotesPage: pdfNotesPage ?? this.pdfNotesPage,
      language: language ?? this.language,
      pdfWatermark: pdfWatermark ?? this.pdfWatermark,
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
      'pdfTitlePage': pdfTitlePage,
      'pdfPageNumbers': pdfPageNumbers,
      'pdfNotesPage': pdfNotesPage,
      'language': language.name,
      'pdfWatermark': pdfWatermark,
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
