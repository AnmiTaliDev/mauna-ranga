import 'dart:io';

import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mauna_ranga/main.dart';
import 'package:mauna_ranga/settings/app_settings.dart';
import 'package:mauna_ranga/settings/settings_store.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'rust_library.dart';

const String script =
    'Title: ПОСЛЕДНИЙ ТРАМВАЙ\n\nEXT. НОЧНАЯ УЛИЦА - НОЧЬ\n\nОдинокий фонарь.\n\nМАКСИМ\nДо вокзала идёт?\n';

class FakeFileSelector extends FileSelectorPlatform
    with MockPlatformInterfaceMixin {
  String path = '';

  @override
  Future<FileSaveLocation?> getSaveLocation({
    List<XTypeGroup>? acceptedTypeGroups,
    SaveDialogOptions options = const SaveDialogOptions(),
  }) async => FileSaveLocation(path);
}

Future<void> settle(WidgetTester tester) async {
  for (int i = 0; i < 3; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump(const Duration(milliseconds: 400));
  }
}

Future<void> exportFromMenu(WidgetTester tester, String item) async {
  await tester.tap(find.text('File'));
  await settle(tester);
  await tester.tap(find.text(item));
  await settle(tester);
}

void main() {
  setUpAll(initRustLibrary);

  testWidgets('File menu exports the typed text to FDX and PDF', (
    WidgetTester tester,
  ) async {
    final Directory dir = Directory.systemTemp.createTempSync('ranga_menu');
    addTearDown(() => dir.deleteSync(recursive: true));
    final FakeFileSelector selector = FakeFileSelector();
    FileSelectorPlatform.instance = selector;
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    await tester.pumpWidget(
      RangaApp(
        store: SettingsStore(File('${dir.path}/settings.json')),
        settings: const AppSettings(font: DocumentFont.jetBrainsMono),
      ),
    );
    await settle(tester);
    await tester.enterText(find.byType(EditableText).first, script);
    await settle(tester);

    selector.path = '${dir.path}/script.fdx';
    await exportFromMenu(tester, 'Export to FDX');
    final String fdx = File(selector.path).readAsStringSync();
    expect(fdx, contains('<Text>EXT. НОЧНАЯ УЛИЦА - НОЧЬ</Text>'));
    expect(fdx, contains('<Text>ПОСЛЕДНИЙ ТРАМВАЙ</Text>'));

    selector.path = '${dir.path}/script.pdf';
    await exportFromMenu(tester, 'Export to PDF');
    expect(File(selector.path).readAsBytesSync().take(5), '%PDF-'.codeUnits);
  });
}
