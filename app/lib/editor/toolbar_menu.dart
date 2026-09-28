import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:mauna/mauna.dart';

const double menuMinWidth = 240;

class MenuEntry {
  const MenuEntry(this.label, this.onSelected, {this.shortcut});

  const MenuEntry.separator() : label = '', onSelected = null, shortcut = null;

  final String label;

  final VoidCallback? onSelected;

  final String? shortcut;

  bool get isSeparator => onSelected == null;
}

class ToolbarMenu extends StatelessWidget {
  const ToolbarMenu({super.key, required this.label, required this.entries});

  final String label;

  final List<MenuEntry> entries;

  Future<void> _open(BuildContext context) async {
    final MaunaThemeData theme = MaunaThemeData.of(context);
    final RenderBox box = context.findRenderObject()! as RenderBox;
    final Offset origin = box.localToGlobal(Offset(0, box.size.height));
    final VoidCallback? selected = await showGeneralDialog<VoidCallback>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close menu',
      barrierColor: theme.bgCanvas.withValues(alpha: 0),
      transitionDuration: theme.motion.fast,
      pageBuilder:
          (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) {
            return Stack(
              children: <Widget>[
                Positioned(
                  left: origin.dx,
                  top: origin.dy + theme.spacing.xs,
                  child: _MenuPanel(entries: entries),
                ),
              ],
            );
          },
      transitionBuilder:
          (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: MaunaMotion.fastCurve,
              ),
              child: child,
            );
          },
    );
    selected?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (BuildContext context) =>
          MaunaToolbarButton(label: label, onPressed: () => _open(context)),
    );
  }
}

class _MenuPanel extends StatelessWidget {
  const _MenuPanel({required this.entries});

  final List<MenuEntry> entries;

  @override
  Widget build(BuildContext context) {
    final MaunaThemeData theme = MaunaThemeData.of(context);
    final int firstRow = entries.indexWhere((MenuEntry e) => !e.isSeparator);
    return MaunaPopup(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: menuMinWidth),
        child: IntrinsicWidth(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: theme.spacing.xs),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (int i = 0; i < entries.length; i++)
                  if (entries[i].isSeparator)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: theme.spacing.xs),
                      child: Container(
                        height: theme.metrics.borderWidth,
                        color: theme.line,
                      ),
                    )
                  else
                    _MenuRow(entry: entries[i], autofocus: i == firstRow),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuRow extends StatefulWidget {
  const _MenuRow({required this.entry, required this.autofocus});

  final MenuEntry entry;

  final bool autofocus;

  @override
  State<_MenuRow> createState() => _MenuRowState();
}

class _MenuRowState extends State<_MenuRow> {
  bool _hovered = false;
  bool _focused = false;

  void _select() {
    Navigator.of(context).pop(widget.entry.onSelected);
  }

  @override
  Widget build(BuildContext context) {
    final MaunaThemeData theme = MaunaThemeData.of(context);
    final bool highlighted = _hovered || _focused;
    final String? shortcut = widget.entry.shortcut;
    return Semantics(
      button: true,
      label: widget.entry.label,
      child: FocusableActionDetector(
        autofocus: widget.autofocus,
        mouseCursor: SystemMouseCursors.click,
        onShowHoverHighlight: (bool value) => setState(() => _hovered = value),
        onShowFocusHighlight: (bool value) => setState(() => _focused = value),
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.arrowDown): NextFocusIntent(),
          SingleActivator(LogicalKeyboardKey.arrowUp): PreviousFocusIntent(),
        },
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (ActivateIntent intent) => _select(),
          ),
        },
        child: GestureDetector(
          onTap: _select,
          child: Container(
            color: highlighted ? theme.bgCanvas : null,
            padding: EdgeInsets.symmetric(
              horizontal: theme.spacing.md,
              vertical: theme.metrics.listItemPaddingY,
            ),
            child: Row(
              spacing: theme.spacing.lg,
              children: <Widget>[
                Expanded(
                  child: Text(
                    widget.entry.label,
                    style: theme.uiStyle.copyWith(
                      color: highlighted
                          ? theme.textPrimary
                          : theme.textSecondary,
                    ),
                  ),
                ),
                if (shortcut != null) Text(shortcut, style: theme.captionStyle),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
