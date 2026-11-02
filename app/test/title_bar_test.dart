import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mauna_ranga/main.dart';
import 'package:mauna_ranga/settings/app_settings.dart';
import 'package:mauna_ranga/settings/settings_store.dart';

import 'rust_library.dart';

Future<void> settle(WidgetTester tester) async {
  for (int i = 0; i < 6; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 40)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUpAll(initRustLibrary);

  testWidgets(
    'the custom title bar shows the file state and drives the window',
    (WidgetTester tester) async {
      final List<MethodCall> calls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('mauna_ranga/window'),
        (MethodCall call) async {
          calls.add(call);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('mauna_ranga/window'),
          null,
        ),
      );
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      final Directory dir = Directory.systemTemp.createTempSync('ranga_title');
      addTearDown(() => dir.deleteSync(recursive: true));
      await tester.pumpWidget(
        RangaApp(
          store: SettingsStore(File('${dir.path}/settings.json')),
          settings: const AppSettings(),
        ),
      );
      await settle(tester);

      expect(find.text('Untitled.fountain'), findsOneWidget);
      expect(
        calls.where((MethodCall c) => c.method == 'setTitle').last.arguments,
        'Untitled.fountain',
      );

      await tester.enterText(
        find.byType(EditableText).first,
        'INT. ROOM - DAY',
      );
      await settle(tester);
      expect(find.text('Untitled.fountain •'), findsOneWidget);
      expect(
        calls.where((MethodCall c) => c.method == 'setTitle').last.arguments,
        'Untitled.fountain •',
      );

      await tester.drag(
        find.byKey(const ValueKey<String>('title-drag-area')),
        const Offset(40, 10),
      );
      await tester.pump();
      expect(calls.map((MethodCall c) => c.method), contains('startMove'));

      await tester.tap(find.byKey(const ValueKey<String>('title-drag-area')));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.byKey(const ValueKey<String>('title-drag-area')));
      await tester.pump(const Duration(milliseconds: 400));
      expect(calls.map((MethodCall c) => c.method), contains('toggleMaximize'));

      await tester.drag(
        find.byKey(const ValueKey<String>('resize-southEast')),
        const Offset(-20, -20),
      );
      await tester.pump();
      final MethodCall resize = calls.firstWhere(
        (MethodCall c) => c.method == 'startResize',
      );
      expect(resize.arguments, 7);
    },
  );

  testWidgets('title bar buttons minimize and close the window', (
    WidgetTester tester,
  ) async {
    final List<String> methods = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('mauna_ranga/window'),
      (MethodCall call) async {
        methods.add(call.method);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('mauna_ranga/window'),
        null,
      ),
    );
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    final Directory dir = Directory.systemTemp.createTempSync('ranga_title');
    addTearDown(() => dir.deleteSync(recursive: true));
    await tester.pumpWidget(
      RangaApp(
        store: SettingsStore(File('${dir.path}/settings.json')),
        settings: const AppSettings(),
      ),
    );
    await settle(tester);

    final Finder minimize = find.bySemanticsLabel('Minimize');
    final Finder close = find.bySemanticsLabel('Close window');
    expect(minimize, findsOneWidget);
    expect(close, findsOneWidget);
    await tester.tap(minimize);
    await tester.tap(close);
    await tester.pump();
    expect(methods, containsAll(<String>['minimize', 'close']));
  });
}
