import '../settings/app_settings.dart';
import 'app_localizations.dart';

extension ThemePresetLabel on ThemePreset {
  String label(AppLocalizations l10n) {
    return switch (this) {
      ThemePreset.paper => l10n.themePaper,
      ThemePreset.sepia => l10n.themeSepia,
      ThemePreset.ink => l10n.themeInk,
      ThemePreset.midnight => l10n.themeMidnight,
    };
  }

  String tone(AppLocalizations l10n) =>
      isLight ? l10n.themeLight : l10n.themeDark;
}

extension AccentChoiceLabel on AccentChoice {
  String label(AppLocalizations l10n) {
    return switch (this) {
      AccentChoice.steelBlue => l10n.accentSteelBlue,
      AccentChoice.graphite => l10n.accentGraphite,
      AccentChoice.coolTeal => l10n.accentCoolTeal,
      AccentChoice.indigo => l10n.accentIndigo,
    };
  }
}

extension DocumentFontLabel on DocumentFont {
  String coverage(AppLocalizations l10n) {
    return hasCyrillic ? l10n.fontCoverageCyrillic : l10n.fontCoverageLatin;
  }
}

extension PaperChoiceLabel on PaperChoice {
  String label(AppLocalizations l10n) {
    return switch (this) {
      PaperChoice.usLetter => l10n.paperUsLetter,
      PaperChoice.a4 => l10n.paperA4,
    };
  }
}

extension AppLanguageLabel on AppLanguage {
  String label(AppLocalizations l10n) {
    return switch (this) {
      AppLanguage.system => l10n.languageSystem,
      AppLanguage.english => l10n.languageEnglish,
      AppLanguage.russian => l10n.languageRussian,
    };
  }
}
