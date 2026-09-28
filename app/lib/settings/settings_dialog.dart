import 'package:flutter/widgets.dart';
import 'package:mauna/mauna.dart';

import 'theme_preset.dart';

const double settingsBodyHeight = 200;

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({
    super.key,
    required this.preset,
    required this.onPresetChanged,
  });

  final ThemePreset preset;

  final ValueChanged<ThemePreset> onPresetChanged;

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late ThemePreset _preset = widget.preset;

  void _select(int index) {
    final ThemePreset preset = ThemePreset.values[index];
    setState(() => _preset = preset);
    widget.onPresetChanged(preset);
  }

  @override
  Widget build(BuildContext context) {
    return MaunaDialog(
      title: 'Settings',
      child: SizedBox(
        height: settingsBodyHeight,
        child: MaunaSidebar(
          title: 'Theme',
          width: double.infinity,
          items: <String>[
            for (final ThemePreset preset in ThemePreset.values) preset.label,
          ],
          selectedIndex: _preset.index,
          onSelected: _select,
        ),
      ),
    );
  }
}
