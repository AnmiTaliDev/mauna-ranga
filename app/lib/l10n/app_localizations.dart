import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Mauna Ranga'**
  String get appTitle;

  /// No description provided for @untitledFileName.
  ///
  /// In en, this message translates to:
  /// **'Untitled.fountain'**
  String get untitledFileName;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @closeMenu.
  ///
  /// In en, this message translates to:
  /// **'Close menu'**
  String get closeMenu;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saveAs.
  ///
  /// In en, this message translates to:
  /// **'Save as'**
  String get saveAs;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @openRecent.
  ///
  /// In en, this message translates to:
  /// **'Open {name}'**
  String openRecent(String name);

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @menuFile.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get menuFile;

  /// No description provided for @menuView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get menuView;

  /// No description provided for @menuCommands.
  ///
  /// In en, this message translates to:
  /// **'Commands'**
  String get menuCommands;

  /// No description provided for @sidebarHide.
  ///
  /// In en, this message translates to:
  /// **'Hide sidebar'**
  String get sidebarHide;

  /// No description provided for @sidebarShow.
  ///
  /// In en, this message translates to:
  /// **'Show sidebar'**
  String get sidebarShow;

  /// No description provided for @focusModeEnter.
  ///
  /// In en, this message translates to:
  /// **'Enter focus mode'**
  String get focusModeEnter;

  /// No description provided for @focusModeExit.
  ///
  /// In en, this message translates to:
  /// **'Exit focus mode'**
  String get focusModeExit;

  /// No description provided for @findAndReplace.
  ///
  /// In en, this message translates to:
  /// **'Find and replace'**
  String get findAndReplace;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @moveSceneUp.
  ///
  /// In en, this message translates to:
  /// **'Move scene up'**
  String get moveSceneUp;

  /// No description provided for @moveSceneDown.
  ///
  /// In en, this message translates to:
  /// **'Move scene down'**
  String get moveSceneDown;

  /// No description provided for @importFdx.
  ///
  /// In en, this message translates to:
  /// **'Import FDX'**
  String get importFdx;

  /// No description provided for @exportPdf.
  ///
  /// In en, this message translates to:
  /// **'Export to PDF'**
  String get exportPdf;

  /// No description provided for @exportFdx.
  ///
  /// In en, this message translates to:
  /// **'Export to FDX'**
  String get exportFdx;

  /// No description provided for @exportHtml.
  ///
  /// In en, this message translates to:
  /// **'Export to HTML'**
  String get exportHtml;

  /// No description provided for @exportText.
  ///
  /// In en, this message translates to:
  /// **'Export to text'**
  String get exportText;

  /// No description provided for @commandOpenFile.
  ///
  /// In en, this message translates to:
  /// **'Open file'**
  String get commandOpenFile;

  /// No description provided for @commandOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get commandOpenSettings;

  /// No description provided for @commandShowStatistics.
  ///
  /// In en, this message translates to:
  /// **'Show statistics'**
  String get commandShowStatistics;

  /// No description provided for @commandShowNotes.
  ///
  /// In en, this message translates to:
  /// **'Show notes'**
  String get commandShowNotes;

  /// No description provided for @commandUseTheme.
  ///
  /// In en, this message translates to:
  /// **'Use {theme} theme'**
  String commandUseTheme(String theme);

  /// No description provided for @commandUseFont.
  ///
  /// In en, this message translates to:
  /// **'Use {font} font'**
  String commandUseFont(String font);

  /// No description provided for @commandGoTo.
  ///
  /// In en, this message translates to:
  /// **'Go to {title}'**
  String commandGoTo(String title);

  /// No description provided for @paletteHint.
  ///
  /// In en, this message translates to:
  /// **'Enter a command'**
  String get paletteHint;

  /// No description provided for @paletteEmpty.
  ///
  /// In en, this message translates to:
  /// **'No matching commands'**
  String get paletteEmpty;

  /// No description provided for @statusWords.
  ///
  /// In en, this message translates to:
  /// **'Words: {count}'**
  String statusWords(int count);

  /// No description provided for @statusPages.
  ///
  /// In en, this message translates to:
  /// **'Pages: {count}'**
  String statusPages(int count);

  /// No description provided for @statusRuntime.
  ///
  /// In en, this message translates to:
  /// **'Runtime: {minutes} min'**
  String statusRuntime(int minutes);

  /// No description provided for @sidebarTitle.
  ///
  /// In en, this message translates to:
  /// **'Scenes'**
  String get sidebarTitle;

  /// No description provided for @documentPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Start writing'**
  String get documentPlaceholder;

  /// No description provided for @errorRestore.
  ///
  /// In en, this message translates to:
  /// **'Cannot restore the document'**
  String get errorRestore;

  /// No description provided for @errorImport.
  ///
  /// In en, this message translates to:
  /// **'Cannot import the file'**
  String get errorImport;

  /// No description provided for @errorOpen.
  ///
  /// In en, this message translates to:
  /// **'Cannot open the file'**
  String get errorOpen;

  /// No description provided for @errorSave.
  ///
  /// In en, this message translates to:
  /// **'Cannot save the file'**
  String get errorSave;

  /// No description provided for @errorExportPdf.
  ///
  /// In en, this message translates to:
  /// **'Cannot export to PDF'**
  String get errorExportPdf;

  /// No description provided for @errorExportFdx.
  ///
  /// In en, this message translates to:
  /// **'Cannot export to FDX'**
  String get errorExportFdx;

  /// No description provided for @errorExportHtml.
  ///
  /// In en, this message translates to:
  /// **'Cannot export to HTML'**
  String get errorExportHtml;

  /// No description provided for @errorExportText.
  ///
  /// In en, this message translates to:
  /// **'Cannot export to text'**
  String get errorExportText;

  /// No description provided for @restoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore unsaved changes'**
  String get restoreTitle;

  /// No description provided for @restoreUntitled.
  ///
  /// In en, this message translates to:
  /// **'An unsaved document from the previous session was found.'**
  String get restoreUntitled;

  /// No description provided for @restoreFile.
  ///
  /// In en, this message translates to:
  /// **'Unsaved changes to {name} from the previous session were found.'**
  String restoreFile(String name);

  /// No description provided for @unsavedTitle.
  ///
  /// In en, this message translates to:
  /// **'Unsaved changes'**
  String get unsavedTitle;

  /// No description provided for @unsavedMessage.
  ///
  /// In en, this message translates to:
  /// **'Save changes to {name} before closing?'**
  String unsavedMessage(String name);

  /// No description provided for @findPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Find'**
  String get findPlaceholder;

  /// No description provided for @replacePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Replace with'**
  String get replacePlaceholder;

  /// No description provided for @findNext.
  ///
  /// In en, this message translates to:
  /// **'Find next'**
  String get findNext;

  /// No description provided for @replace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get replace;

  /// No description provided for @replaceAll.
  ///
  /// In en, this message translates to:
  /// **'Replace all'**
  String get replaceAll;

  /// No description provided for @wholeWordOn.
  ///
  /// In en, this message translates to:
  /// **'Whole word: on'**
  String get wholeWordOn;

  /// No description provided for @wholeWordOff.
  ///
  /// In en, this message translates to:
  /// **'Whole word: off'**
  String get wholeWordOff;

  /// No description provided for @noMatches.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get noMatches;

  /// No description provided for @replacedCount.
  ///
  /// In en, this message translates to:
  /// **'Replaced {count}'**
  String replacedCount(int count);

  /// No description provided for @statsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No characters'**
  String get statsEmpty;

  /// No description provided for @statsCharacter.
  ///
  /// In en, this message translates to:
  /// **'Character'**
  String get statsCharacter;

  /// No description provided for @statsSpeeches.
  ///
  /// In en, this message translates to:
  /// **'Speeches'**
  String get statsSpeeches;

  /// No description provided for @statsWords.
  ///
  /// In en, this message translates to:
  /// **'Words'**
  String get statsWords;

  /// No description provided for @notesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No notes'**
  String get notesEmpty;

  /// No description provided for @notesBeforeFirstScene.
  ///
  /// In en, this message translates to:
  /// **'Before the first scene'**
  String get notesBeforeFirstScene;

  /// No description provided for @notesPageTitle.
  ///
  /// In en, this message translates to:
  /// **'NOTES'**
  String get notesPageTitle;

  /// No description provided for @windowMinimize.
  ///
  /// In en, this message translates to:
  /// **'Minimize'**
  String get windowMinimize;

  /// No description provided for @windowMaximize.
  ///
  /// In en, this message translates to:
  /// **'Maximize'**
  String get windowMaximize;

  /// No description provided for @windowClose.
  ///
  /// In en, this message translates to:
  /// **'Close window'**
  String get windowClose;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsDocument.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get settingsDocument;

  /// No description provided for @settingsEditor.
  ///
  /// In en, this message translates to:
  /// **'Editor'**
  String get settingsEditor;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themePaper.
  ///
  /// In en, this message translates to:
  /// **'Paper'**
  String get themePaper;

  /// No description provided for @themeSepia.
  ///
  /// In en, this message translates to:
  /// **'Sepia'**
  String get themeSepia;

  /// No description provided for @themeInk.
  ///
  /// In en, this message translates to:
  /// **'Ink'**
  String get themeInk;

  /// No description provided for @themeMidnight.
  ///
  /// In en, this message translates to:
  /// **'Midnight'**
  String get themeMidnight;

  /// No description provided for @settingsAccent.
  ///
  /// In en, this message translates to:
  /// **'Accent color'**
  String get settingsAccent;

  /// No description provided for @accentSteelBlue.
  ///
  /// In en, this message translates to:
  /// **'Steel blue'**
  String get accentSteelBlue;

  /// No description provided for @accentGraphite.
  ///
  /// In en, this message translates to:
  /// **'Graphite'**
  String get accentGraphite;

  /// No description provided for @accentCoolTeal.
  ///
  /// In en, this message translates to:
  /// **'Cool teal'**
  String get accentCoolTeal;

  /// No description provided for @accentIndigo.
  ///
  /// In en, this message translates to:
  /// **'Indigo'**
  String get accentIndigo;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageDescription.
  ///
  /// In en, this message translates to:
  /// **'Interface language.'**
  String get settingsLanguageDescription;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageRussian.
  ///
  /// In en, this message translates to:
  /// **'Русский'**
  String get languageRussian;

  /// No description provided for @settingsFont.
  ///
  /// In en, this message translates to:
  /// **'Font'**
  String get settingsFont;

  /// No description provided for @settingsFontDescription.
  ///
  /// In en, this message translates to:
  /// **'Used in the editor and in PDF export.'**
  String get settingsFontDescription;

  /// No description provided for @fontCoverageLatin.
  ///
  /// In en, this message translates to:
  /// **'Latin only'**
  String get fontCoverageLatin;

  /// No description provided for @fontCoverageCyrillic.
  ///
  /// In en, this message translates to:
  /// **'Latin and Cyrillic'**
  String get fontCoverageCyrillic;

  /// No description provided for @settingsPdfTitlePage.
  ///
  /// In en, this message translates to:
  /// **'PDF title page'**
  String get settingsPdfTitlePage;

  /// No description provided for @settingsPdfTitlePageDescription.
  ///
  /// In en, this message translates to:
  /// **'Print the title page as the first page.'**
  String get settingsPdfTitlePageDescription;

  /// No description provided for @settingsPdfPageNumbers.
  ///
  /// In en, this message translates to:
  /// **'PDF page numbers'**
  String get settingsPdfPageNumbers;

  /// No description provided for @settingsPdfPageNumbersDescription.
  ///
  /// In en, this message translates to:
  /// **'Print the page number on every page except the first.'**
  String get settingsPdfPageNumbersDescription;

  /// No description provided for @settingsPdfNotesPage.
  ///
  /// In en, this message translates to:
  /// **'PDF notes page'**
  String get settingsPdfNotesPage;

  /// No description provided for @settingsPdfNotesPageDescription.
  ///
  /// In en, this message translates to:
  /// **'Add a last page that lists the notes of the document.'**
  String get settingsPdfNotesPageDescription;

  /// No description provided for @settingsPdfWatermark.
  ///
  /// In en, this message translates to:
  /// **'PDF watermark'**
  String get settingsPdfWatermark;

  /// No description provided for @settingsPdfWatermarkDescription.
  ///
  /// In en, this message translates to:
  /// **'Diagonal text on every page. Leave empty for none.'**
  String get settingsPdfWatermarkDescription;

  /// No description provided for @watermarkPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'No watermark'**
  String get watermarkPlaceholder;

  /// No description provided for @settingsRuntime.
  ///
  /// In en, this message translates to:
  /// **'Runtime estimate'**
  String get settingsRuntime;

  /// No description provided for @settingsRuntimeDescription.
  ///
  /// In en, this message translates to:
  /// **'Screen minutes per page.'**
  String get settingsRuntimeDescription;

  /// No description provided for @minutesValue.
  ///
  /// In en, this message translates to:
  /// **'{value} min'**
  String minutesValue(double value);

  /// No description provided for @on.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get on;

  /// No description provided for @off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get off;

  /// No description provided for @settingsDim.
  ///
  /// In en, this message translates to:
  /// **'Dim panels while typing'**
  String get settingsDim;

  /// No description provided for @settingsDimDescription.
  ///
  /// In en, this message translates to:
  /// **'Toolbar, sidebar and status bar lose contrast while you type and return when the pointer moves.'**
  String get settingsDimDescription;

  /// No description provided for @aboutDescription.
  ///
  /// In en, this message translates to:
  /// **'Version 0.1.0. Fountain screenplay editor.'**
  String get aboutDescription;

  /// No description provided for @aboutComponents.
  ///
  /// In en, this message translates to:
  /// **'Components'**
  String get aboutComponents;

  /// No description provided for @aboutComponentsText.
  ///
  /// In en, this message translates to:
  /// **'Mauna Ranga engine, mauna design system, Courier Prime, JetBrains Mono, Inter.'**
  String get aboutComponentsText;

  /// No description provided for @aboutLicense.
  ///
  /// In en, this message translates to:
  /// **'License'**
  String get aboutLicense;

  /// No description provided for @aboutLicenseText.
  ///
  /// In en, this message translates to:
  /// **'Apache License 2.0.'**
  String get aboutLicenseText;

  /// No description provided for @showToolbar.
  ///
  /// In en, this message translates to:
  /// **'Show toolbar'**
  String get showToolbar;

  /// No description provided for @paperSize.
  ///
  /// In en, this message translates to:
  /// **'Paper size'**
  String get paperSize;

  /// No description provided for @paperSizeDescription.
  ///
  /// In en, this message translates to:
  /// **'Page size of the PDF and of the page count.'**
  String get paperSizeDescription;

  /// No description provided for @paperUsLetter.
  ///
  /// In en, this message translates to:
  /// **'US Letter'**
  String get paperUsLetter;

  /// No description provided for @paperA4.
  ///
  /// In en, this message translates to:
  /// **'A4'**
  String get paperA4;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
