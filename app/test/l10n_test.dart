import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mauna_ranga/editor/editor_controller.dart';
import 'package:mauna_ranga/l10n/app_localizations.dart';
import 'package:mauna_ranga/l10n/app_localizations_ru.dart';
import 'package:mauna_ranga/main.dart';
import 'package:mauna_ranga/settings/app_settings.dart';
import 'package:mauna_ranga/settings/settings_store.dart';

import 'rust_library.dart';

Map<String, Object?> readArb(String locale) {
  final String text = File('lib/l10n/app_$locale.arb').readAsStringSync();
  return jsonDecode(text) as Map<String, Object?>;
}

Set<String> placeholders(String message) {
  return RegExp(
    r'\{(\w+)\}',
  ).allMatches(message).map((RegExpMatch match) => match.group(1)!).toSet();
}

Future<void> settle(WidgetTester tester) async {
  for (int i = 0; i < 6; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 40)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<Directory> start(WidgetTester tester, AppSettings settings) async {
  await tester.binding.setSurfaceSize(const Size(1280, 800));
  final Directory dir = Directory.systemTemp.createTempSync('ranga_l10n');
  addTearDown(() => dir.deleteSync(recursive: true));
  await tester.pumpWidget(
    RangaApp(
      store: SettingsStore(File('${dir.path}/settings.json')),
      settings: settings,
    ),
  );
  await settle(tester);
  return dir;
}

void main() {
  setUpAll(initRustLibrary);

  test('English and Russian define the same messages and placeholders', () {
    final Map<String, Object?> en = readArb('en');
    final Map<String, Object?> ru = readArb('ru');
    final Set<String> enKeys = en.keys
        .where((String key) => !key.startsWith('@'))
        .toSet();
    final Set<String> ruKeys = ru.keys
        .where((String key) => !key.startsWith('@'))
        .toSet();
    expect(ruKeys, enKeys);
    for (final String key in enKeys) {
      final String english = en[key]! as String;
      final String russian = ru[key]! as String;
      expect(russian.trim(), isNotEmpty, reason: key);
      expect(placeholders(russian), placeholders(english), reason: key);
    }
  });

  test('Russian messages are really translated', () {
    final Map<String, Object?> en = readArb('en');
    final Map<String, Object?> ru = readArb('ru');
    final Set<String> sameAllowed = <String>{
      'appTitle',
      'languageEnglish',
      'languageRussian',
      'aboutLicenseText',
    };
    for (final String key in en.keys.where((String k) => !k.startsWith('@'))) {
      if (sameAllowed.contains(key)) {
        continue;
      }
      expect(ru[key], isNot(en[key]), reason: key);
    }
  });

  test('the language setting is stored and unknown values fall back', () {
    expect(const AppSettings().language, AppLanguage.system);
    expect(
      AppSettings.fromJson(
        const AppSettings(language: AppLanguage.russian).toJson(),
      ).language,
      AppLanguage.russian,
    );
    expect(
      AppSettings.fromJson(<String, Object?>{'language': 'klingon'}).language,
      AppLanguage.system,
    );
    expect(AppLanguage.system.locale, isNull);
    expect(AppLanguage.russian.locale, const Locale('ru'));
  });

  testWidgets('the interface follows the language setting', (
    WidgetTester tester,
  ) async {
    final Directory dir = await start(
      tester,
      const AppSettings(language: AppLanguage.russian),
    );
    expect(find.text('Файл'), findsOneWidget);
    expect(find.text('Вид'), findsOneWidget);
    expect(find.text('Настройки'), findsOneWidget);
    expect(find.text('Сцены'.toUpperCase()), findsOneWidget);
    expect(find.text('Слов: 0'), findsOneWidget);
    expect(find.text('File'), findsNothing);

    await tester.tap(find.text('Вид'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Заметки'), findsOneWidget);
    expect(find.text('Найти и заменить'), findsOneWidget);
    await tester.tapAt(const Offset(5, 5));
    await settle(tester);

    await tester.tap(find.text('Настройки'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Редактор'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('ЯЗЫК'), findsOneWidget);
    await tester.tap(find.text('English'));
    await settle(tester);
    expect(find.text('File'), findsOneWidget);
    expect(find.text('Файл'), findsNothing);
    final String saved = File('${dir.path}/settings.json').readAsStringSync();
    expect(saved, contains('"language": "english"'));
  });

  testWidgets('the generated localizations expose both locales', (
    WidgetTester tester,
  ) async {
    expect(
      AppLocalizations.supportedLocales,
      containsAll(<Locale>[const Locale('en'), const Locale('ru')]),
    );
    final AppLocalizations ru = await AppLocalizations.delegate.load(
      const Locale('ru'),
    );
    expect(ru.statusWords(5), 'Слов: 5');
    expect(ru.minutesValue(0.75), '0,75 мин');
    expect(ru.restoreFile('a.fountain'), contains('a.fountain'));
  });

  test('PDF labels stay English when the font has no Cyrillic glyphs', () {
    final AppLocalizations ru = AppLocalizationsRu();
    expect(pdfLabels(const AppSettings(), ru).notesPageTitle, 'NOTES');
    expect(
      pdfLabels(
        const AppSettings(font: DocumentFont.jetBrainsMono),
        ru,
      ).notesPageTitle,
      'ЗАМЕТКИ',
    );
  });
}
