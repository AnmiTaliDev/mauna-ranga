import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../bridge/generated/api/document.dart';
import '../bridge/generated/api/export.dart' as bridge;
import '../bridge/generated/api/import.dart' as importer;
import '../recovery/recovery_store.dart';
import '../settings/app_settings.dart';
import 'fountain_elements.dart';
import 'completion.dart';
import 'fountain_text_controller.dart';
import 'scene_order.dart';

const Duration statsDelay = Duration(milliseconds: 300);

class EditorController extends ChangeNotifier {
  EditorController({
    this.recovery,
    this.recoveryDelay = const Duration(seconds: 2),
  }) {
    text.addListener(_onTextChanged);
  }

  final RecoveryStore? recovery;

  final Duration recoveryDelay;

  final FountainTextController text = FountainTextController();

  DocumentHandle? _handle;
  String _lastText = '';
  int _generation = 0;
  Timer? _statsTimer;
  Timer? _recoveryTimer;
  String _savedText = '';
  CompletionSession? _completion;

  String? path;
  int loadCount = 0;
  List<OutlineEntry> outline = <OutlineEntry>[];
  int words = 0;
  int? pages;
  double? runtimeMinutes;
  double _minutesPerPage = const AppSettings().minutesPerPage;

  set minutesPerPage(double value) {
    if (value == _minutesPerPage) {
      return;
    }
    _minutesPerPage = value;
    _scheduleStats();
  }

  @override
  void dispose() {
    _statsTimer?.cancel();
    _recoveryTimer?.cancel();
    text.dispose();
    _handle?.dispose();
    super.dispose();
  }

  Future<void> load(String source, {String? path}) async {
    await _replaceHandle(source);
    this.path = path;
    _savedText = source;
    loadCount++;
    text.value = TextEditingValue(
      text: source,
      selection: const TextSelection.collapsed(offset: 0),
    );
  }

  Future<void> open(String path) async {
    final String source = await File(path).readAsString();
    await load(source, path: path);
    await recovery?.clear();
  }

  Future<void> restore(RecoverySnapshot snapshot, String saved) async {
    await load(snapshot.text, path: snapshot.path);
    _savedText = saved;
    await _syncRecovery();
  }

  Future<void> save(String path) async {
    final String current = text.text;
    await File(path).writeAsString(current);
    this.path = path;
    _savedText = current;
    await recovery?.clear();
    notifyListeners();
  }

  bool get modified => text.text != _savedText;

  Future<void> discardRecovery() async {
    _recoveryTimer?.cancel();
    await recovery?.clear();
  }

  Future<void> exportPdf(String path, AppSettings settings) async {
    final String prefix = settings.font.filePrefix;
    final Uint8List bytes = await bridge.exportPdf(
      handle: _handle!,
      fonts: bridge.FontFiles(
        regular: await _font('$prefix-Regular.ttf'),
        bold: await _font('$prefix-Bold.ttf'),
        italic: await _font('$prefix-Italic.ttf'),
        boldItalic: await _font('$prefix-BoldItalic.ttf'),
      ),
      settings: bridge.PdfSettings(
        titlePage: settings.pdfTitlePage,
        pageNumbers: settings.pdfPageNumbers,
        notesPage: settings.pdfNotesPage,
        watermark: settings.pdfWatermark,
      ),
    );
    await File(path).writeAsBytes(bytes);
  }

  Future<void> exportFdx(String path) async {
    await File(path).writeAsString(await bridge.exportFdx(handle: _handle!));
  }

  int? currentOutlineIndex() {
    final int caret = text.selection.baseOffset;
    int? current;
    for (int i = 0; i < outline.length; i++) {
      if (outline[i].offset <= caret) {
        current = i;
      }
    }
    return current;
  }

  Future<void> importFdx(String path) async {
    final String fountain = await importer.importFdx(
      xml: await File(path).readAsString(),
    );
    await load(fountain);
    _savedText = '';
    await _syncRecovery();
  }

  Future<void> exportHtml(String path) async {
    await File(path).writeAsString(await bridge.exportHtml(handle: _handle!));
  }

  Future<void> exportText(String path) async {
    await File(path).writeAsString(await bridge.exportText(handle: _handle!));
  }

  List<NoteItem> notes() {
    return documentNotes(handle: _handle!);
  }

  List<CharacterStat> characterStats() {
    return documentCharacterStats(handle: _handle!);
  }

  bool complete() {
    final TextSelection selection = text.selection;
    final String source = text.text;
    if (!selection.isValid || !selection.isCollapsed) {
      return false;
    }
    final int caret = selection.baseOffset;
    if (caret == 0 || (caret < source.length && source[caret] != '\n')) {
      return false;
    }
    final int lineStart = source.lastIndexOf('\n', caret - 1) + 1;
    if (lineStart > 1 && source[lineStart - 2] != '\n') {
      return false;
    }
    final String line = source.substring(lineStart, caret);
    final CompletionSession? previous = _completion;
    final List<String> matches;
    final int index;
    if (previous != null &&
        previous.lineStart == lineStart &&
        previous.matches[previous.index] == line) {
      matches = previous.matches;
      index = (previous.index + 1) % matches.length;
    } else {
      matches = completionMatches(
        line,
        completionCandidates(source, text.elements, lineStart),
      );
      if (matches.isEmpty) {
        return false;
      }
      index = 0;
    }
    _completion = CompletionSession(lineStart, matches, index);
    text.value = TextEditingValue(
      text: source.replaceRange(lineStart, caret, matches[index]),
      selection: TextSelection.collapsed(
        offset: lineStart + matches[index].length,
      ),
    );
    return true;
  }

  void moveCurrentScene(int direction) {
    final int? index = currentOutlineIndex();
    if (index == null) {
      return;
    }
    final SceneMove? move = moveScene(text.text, outline, index, direction);
    if (move == null) {
      return;
    }
    text.value = TextEditingValue(
      text: move.text,
      selection: TextSelection.collapsed(offset: move.caret),
    );
  }

  Future<Uint8List> _font(String file) async {
    final ByteData data = await rootBundle.load('fonts/$file');
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }

  Future<void> _replaceHandle(String source) async {
    final DocumentHandle handle = await createDocument(source: source);
    _handle?.dispose();
    _handle = handle;
    _generation++;
    _lastText = source;
    text.elements = <FountainElement>[];
    final DocumentSnapshot snapshot = documentSnapshot(handle: handle);
    applySnapshot(text.elements, snapshot);
    _refresh(handle, snapshot);
  }

  void _onTextChanged() {
    final DocumentHandle? handle = _handle;
    final String current = text.text;
    if (handle == null || current == _lastText) {
      notifyListeners();
      return;
    }
    final TextEdit edit = _diff(_lastText, current);
    _lastText = current;
    _scheduleRecovery();
    try {
      final DocumentSnapshot snapshot = applyEdit(handle: handle, edit: edit);
      applySnapshot(text.elements, snapshot);
      _refresh(handle, snapshot);
    } catch (error) {
      unawaited(_replaceHandle(current));
    }
  }

  void _refresh(DocumentHandle handle, DocumentSnapshot snapshot) {
    words = snapshot.wordCount;
    outline = documentOutline(handle: handle);
    _scheduleStats();
    notifyListeners();
  }

  void _scheduleRecovery() {
    if (recovery == null) {
      return;
    }
    _recoveryTimer?.cancel();
    _recoveryTimer = Timer(recoveryDelay, () => unawaited(_syncRecovery()));
  }

  Future<void> _syncRecovery() async {
    final RecoveryStore? store = recovery;
    if (store == null) {
      return;
    }
    final String current = text.text;
    try {
      if (current == _savedText) {
        await store.clear();
      } else {
        await store.write(path, current);
      }
    } on FileSystemException {
      return;
    }
  }

  void _scheduleStats() {
    _statsTimer?.cancel();
    _statsTimer = Timer(statsDelay, _updateStats);
  }

  Future<void> _updateStats() async {
    final int generation = _generation;
    final DocumentStats stats = await documentStats(
      handle: _handle!,
      settings: PageSettings(minutesPerPage: _minutesPerPage),
    );
    if (generation != _generation) {
      return;
    }
    pages = stats.pages;
    runtimeMinutes = stats.runtimeMinutes;
    notifyListeners();
  }
}

TextEdit _diff(String before, String after) {
  final int limit = before.length < after.length ? before.length : after.length;
  int start = 0;
  while (start < limit && before.codeUnitAt(start) == after.codeUnitAt(start)) {
    start++;
  }
  int oldEnd = before.length;
  int newEnd = after.length;
  while (oldEnd > start &&
      newEnd > start &&
      before.codeUnitAt(oldEnd - 1) == after.codeUnitAt(newEnd - 1)) {
    oldEnd--;
    newEnd--;
  }
  if (start > 0 && _isHighSurrogate(before.codeUnitAt(start - 1))) {
    start--;
  }
  if (oldEnd < before.length && _isLowSurrogate(before.codeUnitAt(oldEnd))) {
    oldEnd++;
    newEnd++;
  }
  return TextEdit(
    start: start,
    end: oldEnd,
    replacement: after.substring(start, newEnd),
  );
}

bool _isHighSurrogate(int unit) => unit >= 0xD800 && unit <= 0xDBFF;

bool _isLowSurrogate(int unit) => unit >= 0xDC00 && unit <= 0xDFFF;
