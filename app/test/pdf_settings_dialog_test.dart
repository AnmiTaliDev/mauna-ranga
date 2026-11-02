import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mauna_ranga/main.dart';
import 'package:mauna_ranga/settings/app_settings.dart';
import 'package:mauna_ranga/settings/settings_store.dart';

import 'rust_library.dart';

Future<void> settle(WidgetTester tester) async {
  for (int i = 0; i < 8; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 40)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUpAll(initRustLibrary);

  testWidgets('the Document tab edits the PDF settings and saves them', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    final Directory dir = Directory.systemTemp.createTempSync('ranga_pdf_ui');
    addTearDown(() => dir.deleteSync(recursive: true));
    final File file = File('${dir.path}/settings.json');
    await tester.pumpWidget(
      RangaApp(store: SettingsStore(file), settings: const AppSettings()),
    );
    await settle(tester);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.comma);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Document'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('PDF WATERMARK'), findsOneWidget);

    await tester.enterText(find.byType(EditableText).at(1), 'DRAFT');
    await tester.pump();
    await tester.ensureVisible(find.text('PDF TITLE PAGE'));
    await tester.tap(
      find.descendant(
        of: find
            .ancestor(
              of: find.text('PDF TITLE PAGE'),
              matching: find.byType(Column),
            )
            .first,
        matching: find.text('Off'),
      ),
    );
    await settle(tester);

    final AppSettings saved =
        await tester.runAsync(SettingsStore(file).load) as AppSettings;
    expect(saved.pdfWatermark, 'DRAFT');
    expect(saved.pdfTitlePage, isFalse);
    expect(saved.pdfPageNumbers, isTrue);
  });
}
