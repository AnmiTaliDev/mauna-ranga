import 'package:flutter/widgets.dart';
import 'package:mauna/mauna.dart';

import '../bridge/generated/api/document.dart';
import '../settings/theme_preset.dart';

List<MaunaCommand> editorCommands({
  required List<OutlineEntry> outline,
  required ValueChanged<int> goTo,
  required VoidCallback open,
  required VoidCallback save,
  required VoidCallback saveAs,
  required VoidCallback exportPdf,
  required VoidCallback exportFdx,
  required bool focusMode,
  required VoidCallback toggleFocusMode,
  required bool sidebarOpen,
  required VoidCallback toggleSidebar,
  required ValueChanged<ThemePreset> setTheme,
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
        onSelected: () => setTheme(preset),
      ),
    MaunaCommand(label: 'Open settings', onSelected: openSettings),
    for (int i = 0; i < outline.length; i++)
      MaunaCommand(
        label: 'Go to ${outline[i].title}',
        onSelected: () => goTo(i),
      ),
  ];
}
