import 'package:flutter/widgets.dart';
import 'package:mauna/mauna.dart';

import '../bridge/generated/api/document.dart';
import '../settings/app_settings.dart';

List<MaunaCommand> editorCommands({
  required List<OutlineEntry> outline,
  required ValueChanged<int> goTo,
  required VoidCallback find,
  required VoidCallback moveSceneUp,
  required VoidCallback moveSceneDown,
  required VoidCallback open,
  required VoidCallback save,
  required VoidCallback saveAs,
  required VoidCallback exportPdf,
  required VoidCallback exportFdx,
  required bool focusMode,
  required VoidCallback toggleFocusMode,
  required bool sidebarOpen,
  required VoidCallback toggleSidebar,
  required AppSettings settings,
  required ValueChanged<AppSettings> changeSettings,
  required VoidCallback openSettings,
}) {
  return <MaunaCommand>[
    MaunaCommand(label: 'Open file', onSelected: open),
    MaunaCommand(label: 'Save', onSelected: save),
    MaunaCommand(label: 'Save as', onSelected: saveAs),
    MaunaCommand(label: 'Export to PDF', onSelected: exportPdf),
    MaunaCommand(label: 'Export to FDX', onSelected: exportFdx),
    MaunaCommand(
      label: focusMode ? 'Exit focus mode' : 'Enter focus mode',
      onSelected: toggleFocusMode,
    ),
    MaunaCommand(
      label: sidebarOpen ? 'Hide sidebar' : 'Show sidebar',
      onSelected: toggleSidebar,
    ),
    for (final ThemePreset preset in ThemePreset.values)
      MaunaCommand(
        label: 'Use ${preset.label} theme',
        onSelected: () => changeSettings(settings.copyWith(preset: preset)),
      ),
    for (final DocumentFont font in DocumentFont.values)
      MaunaCommand(
        label: 'Use ${font.family} font',
        onSelected: () => changeSettings(settings.copyWith(font: font)),
      ),
    MaunaCommand(label: 'Open settings', onSelected: openSettings),
    MaunaCommand(label: 'Find and replace', onSelected: find),
    MaunaCommand(label: 'Move scene up', onSelected: moveSceneUp),
    MaunaCommand(label: 'Move scene down', onSelected: moveSceneDown),
    for (int i = 0; i < outline.length; i++)
      MaunaCommand(
        label: 'Go to ${outline[i].title}',
        onSelected: () => goTo(i),
      ),
  ];
}
