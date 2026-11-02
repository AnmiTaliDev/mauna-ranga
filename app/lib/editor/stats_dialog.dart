import 'package:flutter/widgets.dart';
import 'package:mauna/mauna.dart';

import '../bridge/generated/api/document.dart';

const double statsBodyMaxHeight = 360;
const double statsNumberWidth = 90;

class StatsDialog extends StatelessWidget {
  const StatsDialog({super.key, required this.stats});

  final List<CharacterStat> stats;

  @override
  Widget build(BuildContext context) {
    final MaunaThemeData theme = MaunaThemeData.of(context);
    final TextStyle muted = theme.uiStyle.copyWith(color: theme.textSecondary);
    return MaunaDialog(
      title: 'Statistics',
      child: Padding(
        padding: EdgeInsets.all(theme.spacing.md),
        child: stats.isEmpty
            ? Text('No characters', style: muted)
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _Row(
                    name: 'Character',
                    speeches: 'Speeches',
                    words: 'Words',
                    style: muted,
                  ),
                  SizedBox(height: theme.spacing.xs),
                  Flexible(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxHeight: statsBodyMaxHeight,
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            for (final CharacterStat stat in stats)
                              _Row(
                                name: stat.name,
                                speeches: '${stat.speeches}',
                                words: '${stat.words}',
                                style: theme.uiStyle,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.name,
    required this.speeches,
    required this.words,
    required this.style,
  });

  final String name;

  final String speeches;

  final String words;

  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(name, style: style, overflow: TextOverflow.ellipsis),
        ),
        SizedBox(
          width: statsNumberWidth,
          child: Text(speeches, style: style, textAlign: TextAlign.right),
        ),
        SizedBox(
          width: statsNumberWidth,
          child: Text(words, style: style, textAlign: TextAlign.right),
        ),
      ],
    );
  }
}
