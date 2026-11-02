import 'package:flutter/widgets.dart';
import 'package:mauna/mauna.dart';

import 'window_controls.dart';

const double resizeBorder = 5;
const double resizeCorner = 12;

class TitleBar extends StatelessWidget {
  const TitleBar({super.key, required this.title, this.dimmed = false});

  final String title;

  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final MaunaThemeData theme = MaunaThemeData.of(context);
    return Opacity(
      opacity: dimmed ? theme.metrics.dimmedChromeOpacity : 1,
      child: Container(
        height: theme.metrics.toolbarHeight,
        decoration: BoxDecoration(
          color: theme.bgChrome,
          border: Border(
            bottom: BorderSide(
              color: theme.line,
              width: theme.metrics.borderWidth,
            ),
          ),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: GestureDetector(
                key: const ValueKey<String>('title-drag-area'),
                behavior: HitTestBehavior.opaque,
                onPanStart: (DragStartDetails details) =>
                    WindowControls.startMove(),
                onDoubleTap: WindowControls.toggleMaximize,
                child: Center(
                  child: Text(
                    title,
                    style: theme.uiStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: theme.spacing.xs),
              child: Row(
                spacing: theme.spacing.xs,
                children: <Widget>[
                  MaunaToolbarButton(
                    icon: _minimizeGlyph(),
                    label: 'Minimize',
                    onPressed: WindowControls.minimize,
                  ),
                  MaunaToolbarButton(
                    icon: _maximizeGlyph(),
                    label: 'Maximize',
                    onPressed: WindowControls.toggleMaximize,
                  ),
                  MaunaToolbarButton(
                    icon: MaunaGlyphs.close(),
                    label: 'Close window',
                    onPressed: WindowControls.close,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ResizeHandles extends StatelessWidget {
  const ResizeHandles({super.key});

  Widget _handle(
    ResizeEdge edge,
    MouseCursor cursor, {
    double? left,
    double? top,
    double? right,
    double? bottom,
    double? width,
    double? height,
  }) {
    return Positioned(
      left: left,
      top: top,
      right: right,
      bottom: bottom,
      width: width,
      height: height,
      child: MouseRegion(
        cursor: cursor,
        child: GestureDetector(
          key: ValueKey<String>('resize-${edge.name}'),
          behavior: HitTestBehavior.opaque,
          onPanStart: (DragStartDetails details) =>
              WindowControls.startResize(edge),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        _handle(
          ResizeEdge.north,
          SystemMouseCursors.resizeUp,
          left: resizeCorner,
          right: resizeCorner,
          top: 0,
          height: resizeBorder,
        ),
        _handle(
          ResizeEdge.south,
          SystemMouseCursors.resizeDown,
          left: resizeCorner,
          right: resizeCorner,
          bottom: 0,
          height: resizeBorder,
        ),
        _handle(
          ResizeEdge.west,
          SystemMouseCursors.resizeLeft,
          left: 0,
          top: resizeCorner,
          bottom: resizeCorner,
          width: resizeBorder,
        ),
        _handle(
          ResizeEdge.east,
          SystemMouseCursors.resizeRight,
          right: 0,
          top: resizeCorner,
          bottom: resizeCorner,
          width: resizeBorder,
        ),
        _handle(
          ResizeEdge.northWest,
          SystemMouseCursors.resizeUpLeft,
          left: 0,
          top: 0,
          width: resizeCorner,
          height: resizeCorner,
        ),
        _handle(
          ResizeEdge.northEast,
          SystemMouseCursors.resizeUpRight,
          right: 0,
          top: 0,
          width: resizeCorner,
          height: resizeCorner,
        ),
        _handle(
          ResizeEdge.southWest,
          SystemMouseCursors.resizeDownLeft,
          left: 0,
          bottom: 0,
          width: resizeCorner,
          height: resizeCorner,
        ),
        _handle(
          ResizeEdge.southEast,
          SystemMouseCursors.resizeDownRight,
          right: 0,
          bottom: 0,
          width: resizeCorner,
          height: resizeCorner,
        ),
      ],
    );
  }
}

Path _minimizeGlyph() {
  return Path()
    ..moveTo(6, 12)
    ..lineTo(18, 12);
}

Path _maximizeGlyph() {
  return Path()..addRect(const Rect.fromLTWH(6, 6, 12, 12));
}
