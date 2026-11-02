// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Mauna Ranga';

  @override
  String get untitledFileName => 'Untitled.fountain';

  @override
  String get close => 'Close';

  @override
  String get closeMenu => 'Close menu';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get saveAs => 'Save as';

  @override
  String get discard => 'Discard';

  @override
  String get restore => 'Restore';

  @override
  String get open => 'Open';

  @override
  String openRecent(String name) {
    return 'Open $name';
  }

  @override
  String get settings => 'Settings';

  @override
  String get menuFile => 'File';

  @override
  String get menuView => 'View';

  @override
  String get menuCommands => 'Commands';

  @override
  String get sidebarHide => 'Hide sidebar';

  @override
  String get sidebarShow => 'Show sidebar';

  @override
  String get focusModeEnter => 'Enter focus mode';

  @override
  String get focusModeExit => 'Exit focus mode';

  @override
  String get findAndReplace => 'Find and replace';

  @override
  String get statistics => 'Statistics';

  @override
  String get notes => 'Notes';

  @override
  String get moveSceneUp => 'Move scene up';

  @override
  String get moveSceneDown => 'Move scene down';

  @override
  String get importFdx => 'Import FDX';

  @override
  String get exportPdf => 'Export to PDF';

  @override
  String get exportFdx => 'Export to FDX';

  @override
  String get exportHtml => 'Export to HTML';

  @override
  String get exportText => 'Export to text';

  @override
  String get commandOpenFile => 'Open file';

  @override
  String get commandOpenSettings => 'Open settings';

  @override
  String get commandShowStatistics => 'Show statistics';

  @override
  String get commandShowNotes => 'Show notes';

  @override
  String commandUseTheme(String theme) {
    return 'Use $theme theme';
  }

  @override
  String commandUseFont(String font) {
    return 'Use $font font';
  }

  @override
  String commandGoTo(String title) {
    return 'Go to $title';
  }

  @override
  String get paletteHint => 'Enter a command';

  @override
  String get paletteEmpty => 'No matching commands';

  @override
  String statusWords(int count) {
    return 'Words: $count';
  }

  @override
  String statusPages(int count) {
    return 'Pages: $count';
  }

  @override
  String statusRuntime(int minutes) {
    return 'Runtime: $minutes min';
  }

  @override
  String get sidebarTitle => 'Scenes';

  @override
  String get documentPlaceholder => 'Start writing';

  @override
  String get errorRestore => 'Cannot restore the document';

  @override
  String get errorImport => 'Cannot import the file';

  @override
  String get errorOpen => 'Cannot open the file';

  @override
  String get errorSave => 'Cannot save the file';

  @override
  String get errorExportPdf => 'Cannot export to PDF';

  @override
  String get errorExportFdx => 'Cannot export to FDX';

  @override
  String get errorExportHtml => 'Cannot export to HTML';

  @override
  String get errorExportText => 'Cannot export to text';

  @override
  String get restoreTitle => 'Restore unsaved changes';

  @override
  String get restoreUntitled =>
      'An unsaved document from the previous session was found.';

  @override
  String restoreFile(String name) {
    return 'Unsaved changes to $name from the previous session were found.';
  }

  @override
  String get unsavedTitle => 'Unsaved changes';

  @override
  String unsavedMessage(String name) {
    return 'Save changes to $name before closing?';
  }

  @override
  String get findPlaceholder => 'Find';

  @override
  String get replacePlaceholder => 'Replace with';

  @override
  String get findNext => 'Find next';

  @override
  String get replace => 'Replace';

  @override
  String get replaceAll => 'Replace all';

  @override
  String get wholeWordOn => 'Whole word: on';

  @override
  String get wholeWordOff => 'Whole word: off';

  @override
  String get noMatches => 'No matches';

  @override
  String replacedCount(int count) {
    return 'Replaced $count';
  }

  @override
  String get statsEmpty => 'No characters';

  @override
  String get statsCharacter => 'Character';

  @override
  String get statsSpeeches => 'Speeches';

  @override
  String get statsWords => 'Words';

  @override
  String get notesEmpty => 'No notes';

  @override
  String get notesBeforeFirstScene => 'Before the first scene';

  @override
  String get notesPageTitle => 'NOTES';

  @override
  String get windowMinimize => 'Minimize';

  @override
  String get windowMaximize => 'Maximize';

  @override
  String get windowClose => 'Close window';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsDocument => 'Document';

  @override
  String get settingsEditor => 'Editor';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themePaper => 'Paper';

  @override
  String get themeSepia => 'Sepia';

  @override
  String get themeInk => 'Ink';

  @override
  String get themeMidnight => 'Midnight';

  @override
  String get settingsAccent => 'Accent color';

  @override
  String get accentSteelBlue => 'Steel blue';

  @override
  String get accentGraphite => 'Graphite';

  @override
  String get accentCoolTeal => 'Cool teal';

  @override
  String get accentIndigo => 'Indigo';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageDescription => 'Interface language.';

  @override
  String get languageSystem => 'System';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageRussian => 'Русский';

  @override
  String get settingsFont => 'Font';

  @override
  String get settingsFontDescription => 'Used in the editor and in PDF export.';

  @override
  String get fontCoverageLatin => 'Latin only';

  @override
  String get fontCoverageCyrillic => 'Latin and Cyrillic';

  @override
  String get settingsPdfTitlePage => 'PDF title page';

  @override
  String get settingsPdfTitlePageDescription =>
      'Print the title page as the first page.';

  @override
  String get settingsPdfPageNumbers => 'PDF page numbers';

  @override
  String get settingsPdfPageNumbersDescription =>
      'Print the page number on every page except the first.';

  @override
  String get settingsPdfNotesPage => 'PDF notes page';

  @override
  String get settingsPdfNotesPageDescription =>
      'Add a last page that lists the notes of the document.';

  @override
  String get settingsPdfWatermark => 'PDF watermark';

  @override
  String get settingsPdfWatermarkDescription =>
      'Diagonal text on every page. Leave empty for none.';

  @override
  String get watermarkPlaceholder => 'No watermark';

  @override
  String get settingsRuntime => 'Runtime estimate';

  @override
  String get settingsRuntimeDescription => 'Screen minutes per page.';

  @override
  String minutesValue(double value) {
    final intl.NumberFormat valueNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String valueString = valueNumberFormat.format(value);

    return '$valueString min';
  }

  @override
  String get on => 'On';

  @override
  String get off => 'Off';

  @override
  String get settingsDim => 'Dim panels while typing';

  @override
  String get settingsDimDescription =>
      'Toolbar, sidebar and status bar lose contrast while you type and return when the pointer moves.';

  @override
  String get aboutDescription => 'Version 0.1.0. Fountain screenplay editor.';

  @override
  String get aboutComponents => 'Components';

  @override
  String get aboutComponentsText =>
      'Mauna Ranga engine, mauna design system, Courier Prime, JetBrains Mono, Inter.';

  @override
  String get aboutLicense => 'License';

  @override
  String get aboutLicenseText => 'Apache License 2.0.';

  @override
  String get showToolbar => 'Show toolbar';

  @override
  String get paperSize => 'Paper size';

  @override
  String get paperSizeDescription =>
      'Page size of the PDF and of the page count.';

  @override
  String get paperUsLetter => 'US Letter';

  @override
  String get paperA4 => 'A4';
}
