import 'package:flutter/widgets.dart';
import 'package:mauna/mauna.dart';

import '../widgets/dialog_text_field.dart';
import 'app_settings.dart';

const double settingsBodyHeight = 360;
const double settingsNavWidth = 140;
const double swatchSize = 16;
const List<double> minutesPerPageChoices = <double>[0.75, 1.0, 1.25, 1.5];
const String fontSample = 'INT. HOUSE - DAY';

enum _Section {
  appearance('Appearance'),
  document('Document'),
  editor('Editor'),
  about('About');

  const _Section(this.label);

  final String label;
}

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({
    super.key,
    required this.settings,
    required this.onChanged,
  });

  final AppSettings settings;

  final ValueChanged<AppSettings> onChanged;

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late AppSettings _settings = widget.settings;
  _Section _section = _Section.appearance;

  void _update(AppSettings settings) {
    setState(() => _settings = settings);
    widget.onChanged(settings);
  }

  Widget _panel() {
    switch (_section) {
      case _Section.appearance:
        return _AppearancePanel(settings: _settings, onChanged: _update);
      case _Section.document:
        return _DocumentPanel(settings: _settings, onChanged: _update);
      case _Section.editor:
        return _EditorPanel(settings: _settings, onChanged: _update);
      case _Section.about:
        return const _AboutPanel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final MaunaThemeData theme = MaunaThemeData.of(context);
    return MaunaDialog(
      title: 'Settings',
      child: SizedBox(
        height: settingsBodyHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            MaunaSidebar(
              width: settingsNavWidth,
              items: <String>[
                for (final _Section section in _Section.values) section.label,
              ],
              selectedIndex: _section.index,
              onSelected: (int index) =>
                  setState(() => _section = _Section.values[index]),
            ),
            Expanded(
              child: ColoredBox(
                color: theme.bgCanvas,
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(theme.spacing.md),
                  child: _panel(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppearancePanel extends StatelessWidget {
  const _AppearancePanel({required this.settings, required this.onChanged});

  final AppSettings settings;

  final ValueChanged<AppSettings> onChanged;

  @override
  Widget build(BuildContext context) {
    final MaunaThemeData theme = MaunaThemeData.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: theme.spacing.lg,
      children: <Widget>[
        _Group(
          label: 'Theme',
          child: _Grid(
            children: <Widget>[
              for (final ThemePreset preset in ThemePreset.values)
                _ChoiceTile(
                  selected: settings.preset == preset,
                  onTap: () => onChanged(settings.copyWith(preset: preset)),
                  builder: (bool strong) => _SwatchLabel(
                    color: settings.copyWith(preset: preset).theme().bgCanvas,
                    label: preset.label,
                    detail: preset.isLight ? 'Light' : 'Dark',
                    strong: strong,
                  ),
                ),
            ],
          ),
        ),
        _Group(
          label: 'Accent color',
          child: _Grid(
            children: <Widget>[
              for (final AccentChoice accent in AccentChoice.values)
                _ChoiceTile(
                  selected: settings.accent == accent,
                  onTap: () => onChanged(settings.copyWith(accent: accent)),
                  builder: (bool strong) {
                    final Color color = settings.preset.isLight
                        ? accent.value.light
                        : accent.value.dark;
                    return _SwatchLabel(
                      color: color,
                      label: accent.label,
                      detail: _hex(color),
                      strong: strong,
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DocumentPanel extends StatelessWidget {
  const _DocumentPanel({required this.settings, required this.onChanged});

  final AppSettings settings;

  final ValueChanged<AppSettings> onChanged;

  @override
  Widget build(BuildContext context) {
    final MaunaThemeData theme = MaunaThemeData.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: theme.spacing.lg,
      children: <Widget>[
        _Group(
          label: 'Font',
          description: 'Used in the editor and in PDF export.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: theme.spacing.xs,
            children: <Widget>[
              for (final DocumentFont font in DocumentFont.values)
                _ChoiceTile(
                  selected: settings.font == font,
                  onTap: () => onChanged(settings.copyWith(font: font)),
                  builder: (bool strong) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        fontSample,
                        style: theme.docStyle.copyWith(
                          fontFamily: font.family,
                          color: strong
                              ? theme.textPrimary
                              : theme.textSecondary,
                        ),
                      ),
                      Text(
                        '${font.family} · ${font.coverage}',
                        style: theme.captionStyle,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        _Group(
          label: 'PDF title page',
          description: 'Print the title page as the first page.',
          child: _OnOff(
            value: settings.pdfTitlePage,
            onChanged: (bool value) =>
                onChanged(settings.copyWith(pdfTitlePage: value)),
          ),
        ),
        _Group(
          label: 'PDF page numbers',
          description: 'Print the page number on every page except the first.',
          child: _OnOff(
            value: settings.pdfPageNumbers,
            onChanged: (bool value) =>
                onChanged(settings.copyWith(pdfPageNumbers: value)),
          ),
        ),
        _Group(
          label: 'PDF notes page',
          description: 'Add a last page that lists the notes of the document.',
          child: _OnOff(
            value: settings.pdfNotesPage,
            onChanged: (bool value) =>
                onChanged(settings.copyWith(pdfNotesPage: value)),
          ),
        ),
        _Group(
          label: 'PDF watermark',
          description: 'Diagonal text on every page. Leave empty for none.',
          child: _WatermarkField(
            text: settings.pdfWatermark,
            onChanged: (String value) =>
                onChanged(settings.copyWith(pdfWatermark: value)),
          ),
        ),
        _Group(
          label: 'Runtime estimate',
          description: 'Screen minutes per page.',
          child: _Grid(
            columns: minutesPerPageChoices.length,
            children: <Widget>[
              for (final double minutes in minutesPerPageChoices)
                _ChoiceTile(
                  selected: settings.minutesPerPage == minutes,
                  onTap: () =>
                      onChanged(settings.copyWith(minutesPerPage: minutes)),
                  builder: (bool strong) => _CenteredLabel(
                    label: _minutes(minutes),
                    strong: strong,
                    selected: settings.minutesPerPage == minutes,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OnOff extends StatelessWidget {
  const _OnOff({required this.value, required this.onChanged});

  final bool value;

  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return _Grid(
      children: <Widget>[
        for (final bool choice in <bool>[true, false])
          _ChoiceTile(
            selected: value == choice,
            onTap: () => onChanged(choice),
            builder: (bool strong) => _CenteredLabel(
              label: choice ? 'On' : 'Off',
              strong: strong,
              selected: value == choice,
            ),
          ),
      ],
    );
  }
}

class _WatermarkField extends StatefulWidget {
  const _WatermarkField({required this.text, required this.onChanged});

  final String text;

  final ValueChanged<String> onChanged;

  @override
  State<_WatermarkField> createState() => _WatermarkFieldState();
}

class _WatermarkFieldState extends State<_WatermarkField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.text,
  );
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DialogTextField(
      controller: _controller,
      focusNode: _focusNode,
      placeholder: 'No watermark',
      onChanged: widget.onChanged,
    );
  }
}

class _EditorPanel extends StatelessWidget {
  const _EditorPanel({required this.settings, required this.onChanged});

  final AppSettings settings;

  final ValueChanged<AppSettings> onChanged;

  @override
  Widget build(BuildContext context) {
    return _Group(
      label: 'Dim panels while typing',
      description:
          'Toolbar, sidebar and status bar lose contrast while you type and return when the pointer moves.',
      child: _Grid(
        children: <Widget>[
          for (final bool value in <bool>[true, false])
            _ChoiceTile(
              selected: settings.dimWhileTyping == value,
              onTap: () => onChanged(settings.copyWith(dimWhileTyping: value)),
              builder: (bool strong) => _CenteredLabel(
                label: value ? 'On' : 'Off',
                strong: strong,
                selected: settings.dimWhileTyping == value,
              ),
            ),
        ],
      ),
    );
  }
}

class _AboutPanel extends StatelessWidget {
  const _AboutPanel();

  @override
  Widget build(BuildContext context) {
    final MaunaThemeData theme = MaunaThemeData.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: theme.spacing.lg,
      children: <Widget>[
        _Group(
          label: 'Mauna Ranga',
          child: Text(
            'Version 0.1.0. Fountain screenplay editor.',
            style: theme.uiStyle,
          ),
        ),
        _Group(
          label: 'Components',
          child: Text(
            'Mauna Ranga engine, mauna design system, Courier Prime, JetBrains Mono, Inter.',
            style: theme.uiStyle,
          ),
        ),
        _Group(
          label: 'License',
          child: Text('Apache License 2.0.', style: theme.uiStyle),
        ),
      ],
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.label, required this.child, this.description});

  final String label;

  final String? description;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final MaunaThemeData theme = MaunaThemeData.of(context);
    final String? description = this.description;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: theme.spacing.xs,
      children: <Widget>[
        Text(label.toUpperCase(), style: theme.labelStyle),
        if (description != null) Text(description, style: theme.captionStyle),
        child,
      ],
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({required this.children, this.columns = 2});

  final List<Widget> children;

  final int columns;

  @override
  Widget build(BuildContext context) {
    final MaunaThemeData theme = MaunaThemeData.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: theme.spacing.xs,
      children: <Widget>[
        for (int row = 0; row < children.length; row += columns)
          Row(
            spacing: theme.spacing.xs,
            children: <Widget>[
              for (int i = row; i < row + columns; i++)
                Expanded(
                  child: i < children.length
                      ? children[i]
                      : const SizedBox.shrink(),
                ),
            ],
          ),
      ],
    );
  }
}

class _SwatchLabel extends StatelessWidget {
  const _SwatchLabel({
    required this.color,
    required this.label,
    required this.detail,
    required this.strong,
  });

  final Color color;

  final String label;

  final String detail;

  final bool strong;

  @override
  Widget build(BuildContext context) {
    final MaunaThemeData theme = MaunaThemeData.of(context);
    return Row(
      spacing: theme.spacing.sm,
      children: <Widget>[
        Container(
          width: swatchSize,
          height: swatchSize,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(
              color: theme.line,
              width: theme.metrics.borderWidth,
            ),
            borderRadius: BorderRadius.circular(theme.radiusSm),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: theme.captionStyle.copyWith(
                  color: strong ? theme.textPrimary : theme.textSecondary,
                ),
              ),
              Text(detail, style: theme.captionStyle),
            ],
          ),
        ),
      ],
    );
  }
}

class _CenteredLabel extends StatelessWidget {
  const _CenteredLabel({
    required this.label,
    required this.strong,
    required this.selected,
  });

  final String label;

  final bool strong;

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final MaunaThemeData theme = MaunaThemeData.of(context);
    return Center(
      child: Text(
        label,
        style: theme.uiStyle.copyWith(
          color: strong ? theme.textPrimary : theme.textSecondary,
          fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
        ),
      ),
    );
  }
}

class _ChoiceTile extends StatefulWidget {
  const _ChoiceTile({
    required this.selected,
    required this.onTap,
    required this.builder,
  });

  final bool selected;

  final VoidCallback onTap;

  final Widget Function(bool strong) builder;

  @override
  State<_ChoiceTile> createState() => _ChoiceTileState();
}

class _ChoiceTileState extends State<_ChoiceTile> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final MaunaThemeData theme = MaunaThemeData.of(context);
    final bool strong = widget.selected || _hovered || _focused;
    final Color borderColor = widget.selected
        ? theme.accent
        : (_hovered || _focused)
        ? theme.textSecondary
        : theme.line;
    return Semantics(
      button: true,
      selected: widget.selected,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onShowHoverHighlight: (bool value) => setState(() => _hovered = value),
        onShowFocusHighlight: (bool value) => setState(() => _focused = value),
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (ActivateIntent intent) => widget.onTap(),
          ),
        },
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: theme.motion.fast,
            curve: MaunaMotion.fastCurve,
            padding: EdgeInsets.symmetric(
              horizontal: theme.spacing.sm,
              vertical: theme.metrics.listItemPaddingY,
            ),
            decoration: BoxDecoration(
              color: widget.selected ? theme.bgCanvas : theme.bgChrome,
              border: Border.all(
                color: borderColor,
                width: widget.selected
                    ? theme.metrics.focusRingWidth
                    : theme.metrics.borderWidth,
              ),
              borderRadius: BorderRadius.circular(theme.radiusSm),
            ),
            child: widget.builder(strong),
          ),
        ),
      ),
    );
  }
}

String _hex(Color color) {
  final int rgb = color.toARGB32() & 0xFFFFFF;
  return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

String _minutes(double minutes) {
  final String value = minutes == minutes.roundToDouble()
      ? minutes.toStringAsFixed(0)
      : minutes.toString();
  return '$value min';
}
