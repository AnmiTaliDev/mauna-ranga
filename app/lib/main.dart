import 'dart:async';

import 'package:flutter/material.dart';

import 'bridge/generated/frb_generated.dart';
import 'editor/editor_screen.dart';
import 'recovery/recovery_store.dart';
import 'settings/app_settings.dart';
import 'settings/settings_store.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();
  final SettingsStore store = SettingsStore.forUser();
  final AppSettings settings = await store.load();
  runApp(
    RangaApp(
      store: store,
      settings: settings,
      initialPath: args.isEmpty ? null : args.first,
      recovery: RecoveryStore.forUser(),
    ),
  );
}

class RangaApp extends StatefulWidget {
  const RangaApp({
    super.key,
    required this.store,
    required this.settings,
    this.initialPath,
    this.recovery,
  });

  final SettingsStore store;

  final AppSettings settings;

  final String? initialPath;

  final RecoveryStore? recovery;

  @override
  State<RangaApp> createState() => _RangaAppState();
}

class _RangaAppState extends State<RangaApp> {
  late AppSettings _settings = widget.settings;

  void _setSettings(AppSettings settings) {
    setState(() => _settings = settings);
    unawaited(widget.store.save(settings));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mauna Ranga',
      debugShowCheckedModeBanner: false,
      theme: _settings.theme().toMaterialTheme(),
      home: EditorScreen(
        settings: _settings,
        onSettingsChanged: _setSettings,
        initialPath: widget.initialPath,
        recovery: widget.recovery,
      ),
    );
  }
}
