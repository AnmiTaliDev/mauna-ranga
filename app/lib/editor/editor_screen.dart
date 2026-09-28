import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:mauna/mauna.dart';

import '../bridge/generated/api/document.dart';
import '../focus/focus_mode_controller.dart';
import '../settings/settings_dialog.dart';
import '../settings/theme_preset.dart';
import 'command_palette_commands.dart';
import 'dialogs.dart';
import 'editor_controller.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({
    super.key,
    required this.preset,
    required this.onPresetChanged,
    this.initialPath,
  });

  final ThemePreset preset;

  final ValueChanged<ThemePreset> onPresetChanged;

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
    _editor.addListener(_onChanged);
    _editor.text.addListener(_onTextChanged);
    _focus.addListener(_onChanged);
    _documentFocus.addListener(_onChanged);
    unawaited(_start());
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
      await _showError(
        failure,
        '${error.message}: ${error.path}. Check the path.',
      );
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

  Future<String?> _askPath(
    String title,
    String action,
    String initialPath,
  ) async {
    final String? path = await showPathDialog(
      context: context,
      title: title,
      action: action,
      initialPath: initialPath,
    );
    _documentFocus.requestFocus();
    return path;
  }

  String _siblingPath(String extension) {
    final String? path = _editor.path;
    if (path == null) {
      return '';
    }
    final int dot = path.lastIndexOf('.');
    final int slash = path.lastIndexOf(Platform.pathSeparator);
    final String stem = dot > slash ? path.substring(0, dot) : path;
    return '$stem.$extension';
  }

  Future<void> _open() async {
    final String? path = await _askPath(
      'Open file',
      'Open',
      _editor.path ?? '',
    );
    if (path != null) {
      await _run('Cannot open the file', () => _editor.open(path));
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
    final String? path = await _askPath('Save as', 'Save', _editor.path ?? '');
    if (path != null) {
      await _run('Cannot save the file', () => _editor.save(path));
    }
  }

  Future<void> _exportPdf() async {
    final String? path = await _askPath(
      'Export to PDF',
      'Export',
      _siblingPath('pdf'),
    );
    if (path != null) {
      await _run('Cannot export to PDF', () => _editor.exportPdf(path));
    }
  }

  Future<void> _exportFdx() async {
    final String? path = await _askPath(
      'Export to FDX',
      'Export',
      _siblingPath('fdx'),
    );
    if (path != null) {
      await _run('Cannot export to FDX', () => _editor.exportFdx(path));
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

  Future<void> _openPalette() async {
    await showMaunaPopup<void>(
      context: context,
      builder: (BuildContext context) => MaunaCommandPalette(
        commands: editorCommands(
          outline: _editor.outline,
          goTo: _goTo,
          open: _open,
          save: _save,
          saveAs: _saveAs,
          exportPdf: _exportPdf,
          exportFdx: _exportFdx,
          focusMode: _focus.focusMode,
          toggleFocusMode: _toggleFocusMode,
          sidebarOpen: _focus.sidebarOpen,
          toggleSidebar: _focus.toggleSidebar,
          setTheme: widget.onPresetChanged,
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
        preset: widget.preset,
        onPresetChanged: widget.onPresetChanged,
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
    final bool dimmed = _focus.writing && _documentFocus.hasFocus;
    final List<OutlineEntry> outline = _editor.outline;
    final int? current = _editor.currentOutlineIndex();
    final String? path = _editor.path;

    return CallbackShortcuts(
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
        const SingleActivator(LogicalKeyboardKey.escape): _focus.exitFocusMode,
        const SingleActivator(LogicalKeyboardKey.keyO, control: true): _open,
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): _save,
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
                      MaunaToolbarButton(
                        icon: MaunaGlyphs.menu(),
                        label: _focus.sidebarOpen
                            ? 'Hide sidebar'
                            : 'Show sidebar',
                        onPressed: _focus.toggleSidebar,
                      ),
                      MaunaToolbarButton(
                        icon: MaunaGlyphs.file(),
                        label: 'Open file',
                        onPressed: _open,
                      ),
                      MaunaToolbarButton(
                        icon: MaunaGlyphs.save(),
                        label: 'Save',
                        onPressed: _save,
                      ),
                    ],
                    trailing: <Widget>[
                      MaunaToolbarButton(
                        icon: MaunaGlyphs.command(),
                        label: 'Commands',
                        onPressed: _openPalette,
                      ),
                      MaunaToolbarButton(
                        icon: MaunaGlyphs.download(),
                        label: 'Export to PDF',
                        onPressed: _exportPdf,
                      ),
                      MaunaToolbarButton(
                        icon: MaunaGlyphs.focus(),
                        label: 'Enter focus mode',
                        onPressed: _toggleFocusMode,
                      ),
                      MaunaToolbarButton(
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
    );
  }
}
