// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Mauna Ranga';

  @override
  String get untitledFileName => 'Без названия.fountain';

  @override
  String get close => 'Закрыть';

  @override
  String get closeMenu => 'Закрыть меню';

  @override
  String get cancel => 'Отмена';

  @override
  String get save => 'Сохранить';

  @override
  String get saveAs => 'Сохранить как';

  @override
  String get discard => 'Отбросить';

  @override
  String get restore => 'Восстановить';

  @override
  String get open => 'Открыть';

  @override
  String openRecent(String name) {
    return 'Открыть $name';
  }

  @override
  String get settings => 'Настройки';

  @override
  String get menuFile => 'Файл';

  @override
  String get menuView => 'Вид';

  @override
  String get menuCommands => 'Команды';

  @override
  String get sidebarHide => 'Скрыть боковую панель';

  @override
  String get sidebarShow => 'Показать боковую панель';

  @override
  String get focusModeEnter => 'Включить режим фокуса';

  @override
  String get focusModeExit => 'Выключить режим фокуса';

  @override
  String get findAndReplace => 'Найти и заменить';

  @override
  String get statistics => 'Статистика';

  @override
  String get notes => 'Заметки';

  @override
  String get moveSceneUp => 'Переместить сцену вверх';

  @override
  String get moveSceneDown => 'Переместить сцену вниз';

  @override
  String get importFdx => 'Импорт из FDX';

  @override
  String get exportPdf => 'Экспорт в PDF';

  @override
  String get exportFdx => 'Экспорт в FDX';

  @override
  String get exportHtml => 'Экспорт в HTML';

  @override
  String get exportText => 'Экспорт в текст';

  @override
  String get commandOpenFile => 'Открыть файл';

  @override
  String get commandOpenSettings => 'Открыть настройки';

  @override
  String get commandShowStatistics => 'Показать статистику';

  @override
  String get commandShowNotes => 'Показать заметки';

  @override
  String commandUseTheme(String theme) {
    return 'Тема: $theme';
  }

  @override
  String commandUseFont(String font) {
    return 'Шрифт: $font';
  }

  @override
  String commandGoTo(String title) {
    return 'Перейти: $title';
  }

  @override
  String get paletteHint => 'Введите команду';

  @override
  String get paletteEmpty => 'Нет подходящих команд';

  @override
  String statusWords(int count) {
    return 'Слов: $count';
  }

  @override
  String statusPages(int count) {
    return 'Страниц: $count';
  }

  @override
  String statusRuntime(int minutes) {
    return 'Время: $minutes мин';
  }

  @override
  String get sidebarTitle => 'Сцены';

  @override
  String get documentPlaceholder => 'Начните писать';

  @override
  String get errorRestore => 'Не удалось восстановить документ';

  @override
  String get errorImport => 'Не удалось импортировать файл';

  @override
  String get errorOpen => 'Не удалось открыть файл';

  @override
  String get errorSave => 'Не удалось сохранить файл';

  @override
  String get errorExportPdf => 'Не удалось экспортировать в PDF';

  @override
  String get errorExportFdx => 'Не удалось экспортировать в FDX';

  @override
  String get errorExportHtml => 'Не удалось экспортировать в HTML';

  @override
  String get errorExportText => 'Не удалось экспортировать в текст';

  @override
  String get restoreTitle => 'Восстановление несохранённых изменений';

  @override
  String get restoreUntitled =>
      'Найден несохранённый документ из предыдущего сеанса.';

  @override
  String restoreFile(String name) {
    return 'Найдены несохранённые изменения файла $name из предыдущего сеанса.';
  }

  @override
  String get unsavedTitle => 'Несохранённые изменения';

  @override
  String unsavedMessage(String name) {
    return 'Сохранить изменения в $name перед закрытием?';
  }

  @override
  String get findPlaceholder => 'Найти';

  @override
  String get replacePlaceholder => 'Заменить на';

  @override
  String get findNext => 'Найти далее';

  @override
  String get replace => 'Заменить';

  @override
  String get replaceAll => 'Заменить все';

  @override
  String get wholeWordOn => 'Целое слово: вкл';

  @override
  String get wholeWordOff => 'Целое слово: выкл';

  @override
  String get noMatches => 'Совпадений нет';

  @override
  String replacedCount(int count) {
    return 'Заменено: $count';
  }

  @override
  String get statsEmpty => 'Нет персонажей';

  @override
  String get statsCharacter => 'Персонаж';

  @override
  String get statsSpeeches => 'Реплики';

  @override
  String get statsWords => 'Слова';

  @override
  String get notesEmpty => 'Нет заметок';

  @override
  String get notesBeforeFirstScene => 'До первой сцены';

  @override
  String get notesPageTitle => 'ЗАМЕТКИ';

  @override
  String get windowMinimize => 'Свернуть';

  @override
  String get windowMaximize => 'Развернуть';

  @override
  String get windowClose => 'Закрыть окно';

  @override
  String get settingsAppearance => 'Оформление';

  @override
  String get settingsDocument => 'Документ';

  @override
  String get settingsEditor => 'Редактор';

  @override
  String get settingsAbout => 'О программе';

  @override
  String get settingsTheme => 'Тема';

  @override
  String get themeLight => 'Светлые';

  @override
  String get themeDark => 'Тёмные';

  @override
  String get themePaper => 'Бумага';

  @override
  String get themeSepia => 'Сепия';

  @override
  String get themeInk => 'Тушь';

  @override
  String get themeMidnight => 'Полночь';

  @override
  String get settingsAccent => 'Акцентный цвет';

  @override
  String get accentSteelBlue => 'Стальной синий';

  @override
  String get accentGraphite => 'Графит';

  @override
  String get accentCoolTeal => 'Холодный бирюзовый';

  @override
  String get accentIndigo => 'Индиго';

  @override
  String get settingsLanguage => 'Язык';

  @override
  String get settingsLanguageDescription => 'Язык интерфейса.';

  @override
  String get languageSystem => 'Как в системе';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageRussian => 'Русский';

  @override
  String get settingsFont => 'Шрифт';

  @override
  String get settingsFontDescription =>
      'Используется в редакторе и при экспорте в PDF.';

  @override
  String get fontCoverageLatin => 'Только латиница';

  @override
  String get fontCoverageCyrillic => 'Латиница и кириллица';

  @override
  String get settingsPdfTitlePage => 'Титульная страница в PDF';

  @override
  String get settingsPdfTitlePageDescription =>
      'Печатать титульную страницу первой.';

  @override
  String get settingsPdfPageNumbers => 'Номера страниц в PDF';

  @override
  String get settingsPdfPageNumbersDescription =>
      'Печатать номер на каждой странице, кроме первой.';

  @override
  String get settingsPdfNotesPage => 'Страница заметок в PDF';

  @override
  String get settingsPdfNotesPageDescription =>
      'Добавить последнюю страницу со списком заметок документа.';

  @override
  String get settingsPdfWatermark => 'Водяной знак в PDF';

  @override
  String get settingsPdfWatermarkDescription =>
      'Диагональный текст на каждой странице. Оставьте пустым, чтобы не печатать.';

  @override
  String get watermarkPlaceholder => 'Без водяного знака';

  @override
  String get settingsRuntime => 'Оценка хронометража';

  @override
  String get settingsRuntimeDescription =>
      'Минут экранного времени на страницу.';

  @override
  String minutesValue(double value) {
    final intl.NumberFormat valueNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String valueString = valueNumberFormat.format(value);

    return '$valueString мин';
  }

  @override
  String get on => 'Вкл';

  @override
  String get off => 'Выкл';

  @override
  String get settingsDim => 'Приглушать панели при наборе';

  @override
  String get settingsDimDescription =>
      'Панель инструментов, боковая панель и строка состояния теряют контраст при наборе и возвращаются при движении указателя.';

  @override
  String get aboutDescription => 'Версия 0.1.0. Редактор сценариев Fountain.';

  @override
  String get aboutComponents => 'Компоненты';

  @override
  String get aboutComponentsText =>
      'Движок Mauna Ranga, дизайн-система mauna, Courier Prime, JetBrains Mono, Inter.';

  @override
  String get aboutLicense => 'Лицензия';

  @override
  String get aboutLicenseText => 'Apache License 2.0.';

  @override
  String get showToolbar => 'Показать панель инструментов';
}
