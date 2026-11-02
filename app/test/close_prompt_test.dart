import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mauna_ranga/main.dart';
import 'package:mauna_ranga/recovery/recovery_store.dart';
import 'package:mauna_ranga/settings/app_settings.dart';
import 'package:mauna_ranga/settings/settings_store.dart';

import 'rust_library.dart';

const MethodChannel channel = MethodChannel('mauna_ranga/window');

Future<void> settle(WidgetTester tester) async {
  for (int i = 0; i < 8; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 40)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> requestClose(WidgetTester tester) async {
  unawaited(
    tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      channel.name,
      const StandardMethodCodec().encodeMethodCall(
        const MethodCall('closeRequested'),
      ),
      (ByteData? data) {},
    ),
  );
  await settle(tester);
}

class Setup {
  Setup(this.dir, this.script, this.recovery, this.calls);

  final Directory dir;
  final File script;
  final RecoveryStore recovery;
  final List<String> calls;
}

Future<Setup> start(WidgetTester tester) async {
  final List<String> calls = <String>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
    MethodCall call,
  ) async {
    calls.add(call.method);
    return null;
  });
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      null,
    ),
  );
  await tester.binding.setSurfaceSize(const Size(1280, 800));
  final Directory dir = Directory.systemTemp.createTempSync('ranga_close');
  addTearDown(() => dir.deleteSync(recursive: true));
  final File script = File('${dir.path}/story.fountain')
    ..writeAsStringSync('INT. ROOM - DAY\n\nText.\n');
  final RecoveryStore recovery = RecoveryStore(
    File('${dir.path}/recovery.json'),
  );
  await tester.pumpWidget(
    RangaApp(
      store: SettingsStore(File('${dir.path}/settings.json')),
      settings: const AppSettings(),
      initialPath: script.path,
      recovery: recovery,
    ),
  );
  await settle(tester);
  return Setup(dir, script, recovery, calls);
}

Future<void> edit(WidgetTester tester) async {
  await tester.enterText(
    find.byType(EditableText).first,
    'INT. ROOM - DAY\n\nText changed.\n',
  );
  await settle(tester);
}

void main() {
  setUpAll(initRustLibrary);

  testWidgets('a clean document closes without a prompt', (
    WidgetTester tester,
  ) async {
    final Setup setup = await start(tester);
    await requestClose(tester);
    expect(find.text('Unsaved changes'), findsNothing);
    expect(setup.calls, contains('forceClose'));
  });

  testWidgets('Cancel keeps the window open', (WidgetTester tester) async {
    final Setup setup = await start(tester);
    await edit(tester);
    await requestClose(tester);
    expect(find.text('Unsaved changes'), findsWidgets);
    await tester.tap(find.text('Cancel'));
    await settle(tester);
    expect(setup.calls, isNot(contains('forceClose')));
    expect(find.text('Unsaved changes'), findsNothing);
  });

  testWidgets('Save writes the file and then closes', (
    WidgetTester tester,
  ) async {
    final Setup setup = await start(tester);
    await edit(tester);
    await requestClose(tester);
    await tester.tap(find.text('Save'));
    await settle(tester);
    expect(
      setup.script.readAsStringSync(),
      'INT. ROOM - DAY\n\nText changed.\n',
    );
    expect(setup.calls, contains('forceClose'));
  });

  testWidgets('Discard closes and removes the recovery copy', (
    WidgetTester tester,
  ) async {
    final Setup setup = await start(tester);
    await edit(tester);
    await tester.runAsync(
      () => setup.recovery.write(setup.script.path, 'draft'),
    );
    await requestClose(tester);
    await tester.tap(find.text('Discard'));
    await settle(tester);
    expect(setup.calls, contains('forceClose'));
    expect(setup.script.readAsStringSync(), 'INT. ROOM - DAY\n\nText.\n');
    expect(
      setup.dir.listSync().any((e) => e.path.endsWith('recovery.json')),
      isFalse,
    );
  });
}
