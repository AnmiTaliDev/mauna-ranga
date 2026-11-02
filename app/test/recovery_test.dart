import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mauna_ranga/editor/editor_controller.dart';
import 'package:mauna_ranga/recovery/recovery_store.dart';

import 'rust_library.dart';

const Duration delay = Duration(milliseconds: 20);

Future<void> wait() => Future<void>.delayed(const Duration(milliseconds: 120));

void type(EditorController editor, String text) {
  editor.text.value = TextEditingValue(
    text: text,
    selection: TextSelection.collapsed(offset: text.length),
  );
}

void main() {
  setUpAll(initRustLibrary);

  late Directory dir;
  late RecoveryStore store;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('ranga_recovery');
    store = RecoveryStore(File('${dir.path}/state/recovery.json'));
  });

  tearDown(() => dir.deleteSync(recursive: true));

  test('store round-trips a snapshot and ignores a damaged file', () async {
    expect(await store.read(), isNull);
    await store.write('/tmp/a.fountain', 'text');
    final RecoverySnapshot? snapshot = await store.read();
    expect(snapshot?.path, '/tmp/a.fountain');
    expect(snapshot?.text, 'text');
    await store.write(null, 'untitled');
    expect((await store.read())?.path, isNull);
    await store.file.writeAsString('{broken');
    expect(await store.read(), isNull);
    await store.clear();
    expect(await store.file.exists(), isFalse);
  });

  test('edits are written after the delay and cleared by a save', () async {
    final EditorController editor = EditorController(
      recovery: store,
      recoveryDelay: delay,
    );
    await editor.load('one');
    type(editor, 'one two');
    expect(await store.read(), isNull);
    await wait();
    final RecoverySnapshot? snapshot = await store.read();
    expect(snapshot?.text, 'one two');
    expect(snapshot?.path, isNull);
    await editor.save('${dir.path}/a.fountain');
    expect(await store.read(), isNull);
    type(editor, 'one two three');
    await wait();
    expect((await store.read())?.path, '${dir.path}/a.fountain');
    editor.dispose();
  });

  test('returning to the saved text clears the copy', () async {
    final EditorController editor = EditorController(
      recovery: store,
      recoveryDelay: delay,
    );
    await editor.load('one');
    type(editor, 'one two');
    await wait();
    expect(await store.read(), isNotNull);
    type(editor, 'one');
    await wait();
    expect(await store.read(), isNull);
    editor.dispose();
  });

  test('restore keeps the document modified against the saved text', () async {
    final EditorController editor = EditorController(
      recovery: store,
      recoveryDelay: delay,
    );
    await editor.restore(const RecoverySnapshot(null, 'draft'), '');
    expect(editor.text.text, 'draft');
    expect((await store.read())?.text, 'draft');
    editor.dispose();
  });
}
