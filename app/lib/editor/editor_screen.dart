import 'dart:async';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:mauna/mauna.dart';

import '../bridge/generated/api/document.dart';
import '../focus/focus_mode_controller.dart';
import '../settings/app_settings.dart';
import '../settings/settings_dialog.dart';
import 'command_palette_commands.dart';
import 'dialogs.dart';
import 'editor_controller.dart';
import 'find_dialog.dart';
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
const String untitledName = 'Untitled.fountain';

class EditorScreen extends StatefulWidget {
  const EditorScreen({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
    this.initialPath,
  });

  final AppSettings settings;

  final ValueChanged<AppSettings> onSettingsChanged;

  final String? initialPath;

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final EditorController _editor = EditorController();
  final FocusModeController _focus = FocusModeController();
  final FocusNode _documentFocus = FocusNode();
  String _lastText = '';

  @override
  void initState() {
    super.initState();
    _editor.minutesPerPage = widget.settings.minutesPerPage;
    _editor.addListener(_onChanged);
    _editor.text.addListener(_onTextChanged);
    _focus.addListener(_onChanged);
    _documentFocus.addListener(_onChanged);
    unawaited(_start());
  }

  @override
  void didUpdateWidget(EditorScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _editor.minutesPerPage = widget.settings.minutesPerPage;
  }

  @override
  void dispose() {
    _editor.dispose();
    _focus.dispose();
    _documentFocus.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final String? path = widget.initialPath;
    if (path == null) {
      await _editor.load('');
      return;
    }
    await _run('Cannot open the file', () => _editor.open(path));
  }

  void _onChanged() {
    setState(() {});
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

  Future<void> _run(String failure, Future<void> Function() action) async {
    try {
      await action();
    } on FileSystemException catch (error) {
      await _showError(failure, '${error.message}: ${error.path}.');
    } on String catch (error) {
      await _showError(failure, error);
    }
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
        ? untitledName
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
      await _run('Cannot open the file', () => _editor.open(file.path));
    }
  }

  Future<void> _save() async {
    final String? path = _editor.path;
    if (path == null) {
      await _saveAs();
      return;
    }
    await _run('Cannot save the file', () => _editor.save(path));
  }

  Future<void> _saveAs() async {
    final String? path = await _saveLocation(fountainFiles, 'fountain');
    if (path != null) {
      await _run('Cannot save the file', () => _editor.save(path));
    }
  }

  Future<void> _exportPdf() async {
    final String? path = await _saveLocation(pdfFiles, 'pdf');
    if (path != null) {
      await _run(
        'Cannot export to PDF',
        () => _editor.exportPdf(path, widget.settings.font),
      );
    }
  }

  Future<void> _exportFdx() async {
    final String? path = await _saveLocation(fdxFiles, 'fdx');
    if (path != null) {
      await _run('Cannot export to FDX', () => _editor.exportFdx(path));
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

  Future<void> _openFind() async {
    final TextSelection selection = _editor.text.selection;
    final String selected = selection.isValid && !selection.isCollapsed
        ? selection.textInside(_editor.text.text)
        : '';
    await showMaunaDialog<void>(
      context: context,
      builder: (BuildContext context) => FindReplaceDialog(
        text: _editor.text,
        initialQuery: selected.contains('\n') ? '' : selected,
      ),
    );
    _documentFocus.requestFocus();
  }

  Future<void> _openPalette() async {
    await showMaunaPopup<void>(
      context: context,
      builder: (BuildContext context) => MaunaCommandPalette(
        commands: editorCommands(
          outline: _editor.outline,
          goTo: _goTo,
          find: _openFind,
          moveSceneUp: _moveSceneUp,
          moveSceneDown: _moveSceneDown,
          open: _open,
          save: _save,
          saveAs: _saveAs,
          exportPdf: _exportPdf,
          exportFdx: _exportFdx,
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
    await showMaunaDialog<void>(
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
      'Words: ${_editor.words}',
      if (pages != null) 'Pages: $pages',
      if (runtime != null) 'Runtime: ${runtime.round()} min',
    ];
  }

  @override
  Widget build(BuildContext context) {
    final MaunaThemeData theme = MaunaThemeData.of(context);
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
                    MaunaToolbar(
                      hidden: _focus.focusMode,
                      dimmed: dimmed,
                      leading: <Widget>[
                        ToolbarMenu(
                          label: 'File',
                          entries: <MenuEntry>[
                            MenuEntry('Open', _open, shortcut: 'Ctrl+O'),
                            MenuEntry('Save', _save, shortcut: 'Ctrl+S'),
                            MenuEntry(
                              'Save as',
                              _saveAs,
                              shortcut: 'Ctrl+Shift+S',
                            ),
                            const MenuEntry.separator(),
                            MenuEntry('Export to PDF', _exportPdf),
                            MenuEntry('Export to FDX', _exportFdx),
                          ],
                        ),
                        ToolbarMenu(
                          label: 'View',
                          entries: <MenuEntry>[
                            MenuEntry(
                              'Commands',
                              _openPalette,
                              shortcut: 'Ctrl+K',
                            ),
                            MenuEntry(
                              _focus.sidebarOpen
                                  ? 'Hide sidebar'
                                  : 'Show sidebar',
                              _focus.toggleSidebar,
                              shortcut: 'Ctrl+B',
                            ),
                            MenuEntry(
                              'Move scene up',
                              _moveSceneUp,
                              shortcut: 'Alt+Up',
                            ),
                            MenuEntry(
                              'Move scene down',
                              _moveSceneDown,
                              shortcut: 'Alt+Down',
                            ),
                            MenuEntry(
                              'Enter focus mode',
                              _toggleFocusMode,
                              shortcut: 'Ctrl+Shift+F',
                            ),
                          ],
                        ),
                      ],
                      trailing: <Widget>[
                        MaunaToolbarChip(
                          icon: MaunaGlyphs.settings(),
                          label: 'Settings',
                          onPressed: _openSettings,
                        ),
                      ],
                    ),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          MaunaSidebar(
                            title: 'Scenes',
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
                              controller: _editor.text,
                              focusNode: _documentFocus,
                              placeholder: 'Start writing',
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
                if (_focus.focusMode)
                  Positioned(
                    top: theme.spacing.xs,
                    right: theme.spacing.xs,
                    child: MaunaToolbarRestoreButton(
                      onPressed: _focus.exitFocusMode,
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
