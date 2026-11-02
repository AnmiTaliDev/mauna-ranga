import 'dart:async';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:mauna/mauna.dart';

import '../bridge/generated/api/document.dart';
import '../focus/focus_mode_controller.dart';
import '../l10n/app_localizations.dart';
import '../widgets/app_dialog.dart';
import '../recovery/recovery_store.dart';
import '../settings/app_settings.dart';
import '../settings/settings_dialog.dart';
import '../window/title_bar.dart';
import '../window/window_controls.dart';
import 'command_palette_commands.dart';
import 'dialogs.dart';
import 'editor_controller.dart';
import 'find_dialog.dart';
import 'notes_dialog.dart';
import 'stats_dialog.dart';
import 'toolbar_menu.dart';

const XTypeGroup fountainFiles = XTypeGroup(
  label: 'Fountain',
  extensions: <String>['fountain', 'spmd', 'txt'],
);
const XTypeGroup pdfFiles = XTypeGroup(
  label: 'PDF',
  extensions: <String>['pdf'],
);
const XTypeGroup fdxFiles = XTypeGroup(
  label: 'Final Draft',
  extensions: <String>['fdx'],
);
const XTypeGroup htmlFiles = XTypeGroup(
  label: 'HTML',
  extensions: <String>['html'],
);
const XTypeGroup textFiles = XTypeGroup(
  label: 'Text',
  extensions: <String>['txt'],
);

class EditorScreen extends StatefulWidget {
  const EditorScreen({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
    this.initialPath,
    this.recovery,
  });

  final AppSettings settings;

  final ValueChanged<AppSettings> onSettingsChanged;

  final String? initialPath;

  final RecoveryStore? recovery;

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late final EditorController _editor = EditorController(
    recovery: widget.recovery,
  );
  final FocusModeController _focus = FocusModeController();
  final FocusNode _documentFocus = FocusNode();
  String _lastText = '';
  String _lastTitle = '';
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _editor.minutesPerPage = widget.settings.minutesPerPage;
    _editor.addListener(_onChanged);
    _editor.text.addListener(_onTextChanged);
    _focus.addListener(_onChanged);
    _documentFocus.addListener(_onChanged);
    if (WindowControls.available) {
      WindowControls.onCloseRequested(_requestClose);
    }
    unawaited(_start());
  }

  @override
  void didUpdateWidget(EditorScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _editor.minutesPerPage = widget.settings.minutesPerPage;
  }

  @override
  void dispose() {
    if (WindowControls.available) {
      WindowControls.stopListening();
    }
    _editor.dispose();
    _focus.dispose();
    _documentFocus.dispose();
    super.dispose();
  }

  AppLocalizations get _l10n => AppLocalizations.of(context);

  Future<void> _start() async {
    final String? path = widget.initialPath;
    final RecoverySnapshot? snapshot = await widget.recovery?.read();
    if (snapshot != null && (path == null || snapshot.path == path)) {
      final String saved = await _savedText(snapshot.path);
      if (snapshot.text != saved && await _askRestore(snapshot)) {
        await _run(_l10n.errorRestore, () => _editor.restore(snapshot, saved));
        return;
      }
    }
    await widget.recovery?.clear();
    if (path == null) {
      await _editor.load('');
      return;
    }
    await _openPath(path);
  }

  Future<String> _savedText(String? path) async {
    if (path == null) {
      return '';
    }
    try {
      return await File(path).readAsString();
    } on FileSystemException {
      return '';
    }
  }

  Future<bool> _askRestore(RecoverySnapshot snapshot) async {
    if (!mounted) {
      return false;
    }
    final String? path = snapshot.path;
    final bool restore = await showConfirmDialog(
      context: context,
      title: _l10n.restoreTitle,
      message: path == null
          ? _l10n.restoreUntitled
          : _l10n.restoreFile(path.split(Platform.pathSeparator).last),
      confirmLabel: _l10n.restore,
      cancelLabel: _l10n.discard,
    );
    _documentFocus.requestFocus();
    return restore;
  }

  Future<void> _requestClose() async {
    if (_closing) {
      return;
    }
    _closing = true;
    try {
      if (_editor.modified && mounted) {
        final UnsavedChoice choice = await showUnsavedDialog(
          context: context,
          name: _fileName(),
        );
        if (choice == UnsavedChoice.cancel) {
          return;
        }
        if (choice == UnsavedChoice.save) {
          await _save();
          if (_editor.modified) {
            return;
          }
        } else {
          await _editor.discardRecovery();
        }
      }
      WindowControls.forceClose();
    } finally {
      _closing = false;
    }
  }

  void _onChanged() {
    setState(() {});
    if (WindowControls.available) {
      final String title = _windowTitle();
      if (title != _lastTitle) {
        _lastTitle = title;
        WindowControls.setTitle(title);
      }
    }
  }

  String _fileName() {
    final String? path = _editor.path;
    return path == null
        ? _l10n.untitledFileName
        : path.split(Platform.pathSeparator).last;
  }

  String _windowTitle() {
    final String name = _fileName();
    return _editor.modified ? '$name \u2022' : name;
  }

  void _onTextChanged() {
    final String text = _editor.text.text;
    if (text != _lastText) {
      _lastText = text;
      _focus.startWriting();
    } else {
      _focus.stopWriting();
    }
  }

  void _onPointerMoved(PointerHoverEvent event) {
    _focus.stopWriting();
  }

  Future<bool> _run(String failure, Future<void> Function() action) async {
    try {
      await action();
      return true;
    } on FileSystemException catch (error) {
      await _showError(failure, '${error.message}: ${error.path}.');
    } on String catch (error) {
      await _showError(failure, error);
    }
    return false;
  }

  Future<void> _showError(String title, String message) async {
    if (!mounted) {
      return;
    }
    await showMessageDialog(context: context, title: title, message: message);
    _documentFocus.requestFocus();
  }

  String? _directory() {
    final String? path = _editor.path;
    return path == null ? null : File(path).parent.path;
  }

  String _suggestedName(String extension) {
    final String? path = _editor.path;
    final String name = path == null
        ? _l10n.untitledFileName
        : path.split(Platform.pathSeparator).last;
    final int dot = name.lastIndexOf('.');
    return '${dot > 0 ? name.substring(0, dot) : name}.$extension';
  }

  Future<String?> _saveLocation(XTypeGroup group, String extension) async {
    final FileSaveLocation? location = await getSaveLocation(
      acceptedTypeGroups: <XTypeGroup>[group],
      initialDirectory: _directory(),
      suggestedName: _suggestedName(extension),
    );
    _documentFocus.requestFocus();
    return location?.path;
  }

  Future<void> _open() async {
    final XFile? file = await openFile(
      acceptedTypeGroups: const <XTypeGroup>[fountainFiles],
      initialDirectory: _directory(),
    );
    _documentFocus.requestFocus();
    if (file != null) {
      await _openPath(file.path);
    }
  }

  Future<void> _importFdx() async {
    final XFile? file = await openFile(
      acceptedTypeGroups: const <XTypeGroup>[fdxFiles],
      initialDirectory: _directory(),
    );
    _documentFocus.requestFocus();
    if (file != null) {
      await _run(_l10n.errorImport, () => _editor.importFdx(file.path));
    }
  }

  Future<void> _openPath(String path) async {
    final bool opened = await _run(_l10n.errorOpen, () => _editor.open(path));
    widget.onSettingsChanged(
      opened
          ? widget.settings.withRecentFile(path)
          : widget.settings.withoutRecentFile(path),
    );
  }

  Future<void> _save() async {
    final String? path = _editor.path;
    if (path == null) {
      await _saveAs();
      return;
    }
    await _saveTo(path);
  }

  Future<void> _saveTo(String path) async {
    final bool saved = await _run(_l10n.errorSave, () => _editor.save(path));
    if (saved) {
      widget.onSettingsChanged(widget.settings.withRecentFile(path));
    }
  }

  Future<void> _saveAs() async {
    final String? path = await _saveLocation(fountainFiles, 'fountain');
    if (path != null) {
      await _saveTo(path);
    }
  }

  Future<void> _exportPdf() async {
    final String? path = await _saveLocation(pdfFiles, 'pdf');
    if (path != null) {
      await _run(
        _l10n.errorExportPdf,
        () => _editor.exportPdf(path, widget.settings, _l10n),
      );
    }
  }

  Future<void> _exportFdx() async {
    final String? path = await _saveLocation(fdxFiles, 'fdx');
    if (path != null) {
      await _run(_l10n.errorExportFdx, () => _editor.exportFdx(path));
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    final bool plain =
        !HardwareKeyboard.instance.isControlPressed &&
        !HardwareKeyboard.instance.isAltPressed &&
        !HardwareKeyboard.instance.isMetaPressed &&
        !HardwareKeyboard.instance.isShiftPressed;
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.tab &&
        plain &&
        _documentFocus.hasFocus &&
        _editor.complete()) {
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> _exportHtml() async {
    final String? path = await _saveLocation(htmlFiles, 'html');
    if (path != null) {
      await _run(_l10n.errorExportHtml, () => _editor.exportHtml(path));
    }
  }

  Future<void> _exportText() async {
    final String? path = await _saveLocation(textFiles, 'txt');
    if (path != null) {
      await _run(_l10n.errorExportText, () => _editor.exportText(path));
    }
  }

  void _toggleFocusMode() {
    _focus.toggleFocusMode();
    _documentFocus.requestFocus();
  }

  void _goTo(int index) {
    _editor.text.selection = TextSelection.collapsed(
      offset: _editor.outline[index].offset,
    );
    _documentFocus.requestFocus();
  }

  void _moveSceneUp() => _editor.moveCurrentScene(-1);

  void _moveSceneDown() => _editor.moveCurrentScene(1);

  Future<void> _openNotes() async {
    final int? offset = await showAppDialog<int>(
      context: context,
      builder: (BuildContext context) => NotesDialog(notes: _editor.notes()),
    );
    if (offset != null) {
      _editor.text.selection = TextSelection.collapsed(offset: offset);
    }
    _documentFocus.requestFocus();
  }

  Future<void> _openStats() async {
    await showAppDialog<void>(
      context: context,
      builder: (BuildContext context) =>
          StatsDialog(stats: _editor.characterStats()),
    );
    _documentFocus.requestFocus();
  }

  Future<void> _openFind() async {
    final TextSelection selection = _editor.text.selection;
    final String selected = selection.isValid && !selection.isCollapsed
        ? selection.textInside(_editor.text.text)
        : '';
    await showAppDialog<void>(
      context: context,
      builder: (BuildContext context) => FindReplaceDialog(
        text: _editor.text,
        initialQuery: selected.contains('\n') ? '' : selected,
      ),
    );
    _documentFocus.requestFocus();
  }

  Future<void> _openPalette() async {
    await showAppPopup<void>(
      context: context,
      builder: (BuildContext context) => MaunaCommandPalette(
        placeholder: _l10n.paletteHint,
        emptyLabel: _l10n.paletteEmpty,
        commands: editorCommands(
          l10n: _l10n,
          outline: _editor.outline,
          goTo: _goTo,
          find: _openFind,
          statistics: _openStats,
          notes: _openNotes,
          moveSceneUp: _moveSceneUp,
          moveSceneDown: _moveSceneDown,
          open: _open,
          save: _save,
          saveAs: _saveAs,
          exportPdf: _exportPdf,
          importFdx: _importFdx,
          exportFdx: _exportFdx,
          exportHtml: _exportHtml,
          exportText: _exportText,
          focusMode: _focus.focusMode,
          toggleFocusMode: _toggleFocusMode,
          sidebarOpen: _focus.sidebarOpen,
          toggleSidebar: _focus.toggleSidebar,
          settings: widget.settings,
          changeSettings: widget.onSettingsChanged,
          openSettings: _openSettings,
        ),
      ),
    );
    _documentFocus.requestFocus();
  }

  Future<void> _openSettings() async {
    await showAppDialog<void>(
      context: context,
      builder: (BuildContext context) => SettingsDialog(
        settings: widget.settings,
        onChanged: widget.onSettingsChanged,
      ),
    );
    _documentFocus.requestFocus();
  }

  List<String> _statusItems() {
    final int? pages = _editor.pages;
    final double? runtime = _editor.runtimeMinutes;
    return <String>[
      _l10n.statusWords(_editor.words),
      if (pages != null) _l10n.statusPages(pages),
      if (runtime != null) _l10n.statusRuntime(runtime.round()),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final MaunaThemeData theme = MaunaThemeData.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool dimmed =
        widget.settings.dimWhileTyping &&
        _focus.writing &&
        _documentFocus.hasFocus;
    final List<OutlineEntry> outline = _editor.outline;
    final int? current = _editor.currentOutlineIndex();
    final String? path = _editor.path;

    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: _onKey,
      child: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.keyK, control: true):
              _openPalette,
          const SingleActivator(LogicalKeyboardKey.keyB, control: true):
              _focus.toggleSidebar,
          const SingleActivator(LogicalKeyboardKey.comma, control: true):
              _openSettings,
          const SingleActivator(
            LogicalKeyboardKey.keyF,
            control: true,
            shift: true,
          ): _toggleFocusMode,
          const SingleActivator(LogicalKeyboardKey.arrowUp, alt: true):
              _moveSceneUp,
          const SingleActivator(LogicalKeyboardKey.arrowDown, alt: true):
              _moveSceneDown,
          const SingleActivator(LogicalKeyboardKey.escape):
              _focus.exitFocusMode,
          const SingleActivator(LogicalKeyboardKey.keyF, control: true):
              _openFind,
          const SingleActivator(LogicalKeyboardKey.keyO, control: true): _open,
          const SingleActivator(LogicalKeyboardKey.keyS, control: true): _save,
          const SingleActivator(
            LogicalKeyboardKey.keyS,
            control: true,
            shift: true,
          ): _saveAs,
        },
        child: MouseRegion(
          onHover: _onPointerMoved,
          child: ColoredBox(
            color: theme.bgCanvas,
            child: Stack(
              children: <Widget>[
                Column(
                  children: <Widget>[
                    if (WindowControls.available && !_focus.focusMode)
                      TitleBar(title: _windowTitle(), dimmed: dimmed),
                    MaunaToolbar(
                      hidden: _focus.focusMode,
                      dimmed: dimmed,
                      leading: <Widget>[
                        ToolbarMenu(
                          label: l10n.menuFile,
                          entries: <MenuEntry>[
                            MenuEntry(l10n.open, _open, shortcut: 'Ctrl+O'),
                            for (final String file
                                in widget.settings.recentFiles)
                              MenuEntry(
                                l10n.openRecent(
                                  file.split(Platform.pathSeparator).last,
                                ),
                                () => _openPath(file),
                              ),
                            MenuEntry(l10n.save, _save, shortcut: 'Ctrl+S'),
                            MenuEntry(
                              l10n.saveAs,
                              _saveAs,
                              shortcut: 'Ctrl+Shift+S',
                            ),
                            const MenuEntry.separator(),
                            MenuEntry(l10n.importFdx, _importFdx),
                            MenuEntry(l10n.exportPdf, _exportPdf),
                            MenuEntry(l10n.exportFdx, _exportFdx),
                            MenuEntry(l10n.exportHtml, _exportHtml),
                            MenuEntry(l10n.exportText, _exportText),
                          ],
                        ),
                        ToolbarMenu(
                          label: l10n.menuView,
                          entries: <MenuEntry>[
                            MenuEntry(
                              l10n.menuCommands,
                              _openPalette,
                              shortcut: 'Ctrl+K',
                            ),
                            MenuEntry(
                              _focus.sidebarOpen
                                  ? l10n.sidebarHide
                                  : l10n.sidebarShow,
                              _focus.toggleSidebar,
                              shortcut: 'Ctrl+B',
                            ),
                            MenuEntry(
                              l10n.findAndReplace,
                              _openFind,
                              shortcut: 'Ctrl+F',
                            ),
                            MenuEntry(l10n.statistics, _openStats),
                            MenuEntry(l10n.notes, _openNotes),
                            MenuEntry(
                              l10n.moveSceneUp,
                              _moveSceneUp,
                              shortcut: 'Alt+Up',
                            ),
                            MenuEntry(
                              l10n.moveSceneDown,
                              _moveSceneDown,
                              shortcut: 'Alt+Down',
                            ),
                            MenuEntry(
                              l10n.focusModeEnter,
                              _toggleFocusMode,
                              shortcut: 'Ctrl+Shift+F',
                            ),
                          ],
                        ),
                      ],
                      trailing: <Widget>[
                        MaunaToolbarChip(
                          icon: MaunaGlyphs.settings(),
                          label: l10n.settings,
                          onPressed: _openSettings,
                        ),
                      ],
                    ),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          MaunaSidebar(
                            title: l10n.sidebarTitle,
                            items: <String>[
                              for (final OutlineEntry entry in outline)
                                entry.title,
                            ],
                            selectedIndex: current,
                            onSelected: _goTo,
                            collapsed: _focus.sidebarCollapsed,
                            dimmed: dimmed,
                          ),
                          Expanded(
                            child: MaunaDocumentCanvas(
                              key: ValueKey<int>(_editor.loadCount),
                              controller: _editor.text,
                              focusNode: _documentFocus,
                              placeholder: l10n.documentPlaceholder,
                              autofocus: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                    MaunaStatusBar(
                      dimmed: dimmed,
                      leading: _statusItems(),
                      trailing: <String>[
                        if (current != null)
                          outline[current].title
                        else if (path != null)
                          path.split(Platform.pathSeparator).last,
                      ],
                    ),
                  ],
                ),
                if (WindowControls.available) const ResizeHandles(),
                if (_focus.focusMode)
                  Positioned(
                    top: theme.spacing.xs,
                    right: theme.spacing.xs,
                    child: MaunaToolbarRestoreButton(
                      onPressed: _focus.exitFocusMode,
                      label: l10n.showToolbar,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
