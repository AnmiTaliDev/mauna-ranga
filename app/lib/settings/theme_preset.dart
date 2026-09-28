import 'package:mauna/mauna.dart';

enum ThemePreset {
  paper('Paper'),
  ink('Ink'),
  sepia('Sepia'),
  midnight('Midnight');

  const ThemePreset(this.label);

  final String label;

  MaunaThemeData build() {
    switch (this) {
      case ThemePreset.paper:
        return MaunaThemeData.light();
      case ThemePreset.ink:
        return MaunaThemeData.dark();
      case ThemePreset.sepia:
        return MaunaThemeData.sepia();
      case ThemePreset.midnight:
        return MaunaThemeData.midnight();
    }
  }
}
