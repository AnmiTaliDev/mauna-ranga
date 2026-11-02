import 'package:flutter/widgets.dart';
import 'package:mauna/mauna.dart';

import '../bridge/generated/api/document.dart';
import '../l10n/app_localizations.dart';
import '../widgets/app_dialog.dart';

const double notesBodyMaxHeight = 360;

class NotesDialog extends StatelessWidget {
  const NotesDialog({super.key, required this.notes});

  final List<NoteItem> notes;

  @override
  Widget build(BuildContext context) {
    final MaunaThemeData theme = MaunaThemeData.of(context);
    final TextStyle muted = theme.uiStyle.copyWith(color: theme.textSecondary);
    final AppLocalizations l10n = AppLocalizations.of(context);
    return AppDialog(
      title: l10n.notes,
      child: Padding(
        padding: EdgeInsets.all(theme.spacing.md),
        child: notes.isEmpty
            ? Text(l10n.notesEmpty, style: muted)
            : ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: notesBodyMaxHeight,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: theme.spacing.xs,
                    children: <Widget>[
                      for (final NoteItem note in notes)
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => Navigator.of(context).pop(note.offset),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  note.scene ?? l10n.notesBeforeFirstScene,
                                  style: muted,
                                ),
                                Text(note.text, style: theme.uiStyle),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
