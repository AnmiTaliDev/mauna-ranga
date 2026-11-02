import 'package:flutter/widgets.dart';
import 'package:mauna/mauna.dart';

import '../bridge/generated/api/document.dart';
import '../l10n/app_localizations.dart';
import '../l10n/labels.dart';
import '../settings/app_settings.dart';

List<MaunaCommand> editorCommands({
  required AppLocalizations l10n,
  required List<OutlineEntry> outline,
  required ValueChanged<int> goTo,
  required VoidCallback find,
  required VoidCallback statistics,
  required VoidCallback notes,
  required VoidCallback moveSceneUp,
  required VoidCallback moveSceneDown,
  required VoidCallback open,
  required VoidCallback save,
  required VoidCallback saveAs,
  required VoidCallback exportPdf,
  required VoidCallback importFdx,
  required VoidCallback exportFdx,
  required VoidCallback exportHtml,
  required VoidCallback exportText,
  required bool focusMode,
  required VoidCallback toggleFocusMode,
  required bool sidebarOpen,
  required VoidCallback toggleSidebar,
  required AppSettings settings,
  required ValueChanged<AppSettings> changeSettings,
  required VoidCallback openSettings,
}) {
  return <MaunaCommand>[
    MaunaCommand(label: l10n.commandOpenFile, onSelected: open),
    MaunaCommand(label: l10n.save, onSelected: save),
    MaunaCommand(label: l10n.saveAs, onSelected: saveAs),
    MaunaCommand(label: l10n.exportPdf, onSelected: exportPdf),
    MaunaCommand(label: l10n.importFdx, onSelected: importFdx),
    MaunaCommand(label: l10n.exportFdx, onSelected: exportFdx),
    MaunaCommand(label: l10n.exportHtml, onSelected: exportHtml),
    MaunaCommand(label: l10n.exportText, onSelected: exportText),
    MaunaCommand(
      label: focusMode ? l10n.focusModeExit : l10n.focusModeEnter,
      onSelected: toggleFocusMode,
    ),
    MaunaCommand(
      label: sidebarOpen ? l10n.sidebarHide : l10n.sidebarShow,
      onSelected: toggleSidebar,
    ),
    for (final ThemePreset preset in ThemePreset.values)
      MaunaCommand(
        label: l10n.commandUseTheme(preset.label(l10n)),
        onSelected: () => changeSettings(settings.copyWith(preset: preset)),
      ),
    for (final DocumentFont font in DocumentFont.values)
      MaunaCommand(
        label: l10n.commandUseFont(font.family),
        onSelected: () => changeSettings(settings.copyWith(font: font)),
      ),
    MaunaCommand(label: l10n.commandOpenSettings, onSelected: openSettings),
    MaunaCommand(label: l10n.findAndReplace, onSelected: find),
    MaunaCommand(label: l10n.commandShowStatistics, onSelected: statistics),
    MaunaCommand(label: l10n.commandShowNotes, onSelected: notes),
    MaunaCommand(label: l10n.moveSceneUp, onSelected: moveSceneUp),
    MaunaCommand(label: l10n.moveSceneDown, onSelected: moveSceneDown),
    for (int i = 0; i < outline.length; i++)
      MaunaCommand(
        label: l10n.commandGoTo(outline[i].title),
        onSelected: () => goTo(i),
      ),
  ];
}
