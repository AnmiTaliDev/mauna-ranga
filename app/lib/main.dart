import 'package:flutter/material.dart';

import 'bridge/generated/frb_generated.dart';
import 'editor/editor_screen.dart';
import 'settings/theme_preset.dart';

Future<void> main(List<String> args) async {
  await RustLib.init();
  runApp(RangaApp(initialPath: args.isEmpty ? null : args.first));
}

class RangaApp extends StatefulWidget {
  const RangaApp({super.key, this.initialPath});

  final String? initialPath;

  @override
  State<RangaApp> createState() => _RangaAppState();
}

class _RangaAppState extends State<RangaApp> {
  ThemePreset _preset = ThemePreset.paper;

  void _setPreset(ThemePreset preset) {
    setState(() => _preset = preset);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mauna Ranga',
      debugShowCheckedModeBanner: false,
      theme: _preset.build().toMaterialTheme(),
      home: EditorScreen(
        preset: _preset,
        onPresetChanged: _setPreset,
        initialPath: widget.initialPath,
      ),
    );
  }
}
