import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/features/settings/state/settings_controller.dart';

const heatmapPathGap = 6.0;

bool heatmapPathOn(BuildContext context) =>
    context.watch<SettingsController>().heatmapPath;

Color heatmapPathColor(BuildContext context, Color habit) => Color.alphaBlend(
      habit.withValues(alpha: 0.55),
      context.colors.surfaceContainerHighest,
    );

Widget withHeatmapPath({
  required bool on,
  required int columns,
  required int rows,
  required double cell,
  required double gap,
  required Color? Function(int column, int row) inkFor,
  required Widget child,
  bool byRows = false,
  double top = 0,
}) {
  if (!on) return child;
  return CustomPaint(
    painter: _HeatmapPathPainter(
      columns: columns,
      rows: rows,
      cell: cell,
      gap: gap,
      top: top,
      byRows: byRows,
      inkFor: inkFor,
    ),
    child: child,
  );
}

class _HeatmapPathPainter extends CustomPainter {
  const _HeatmapPathPainter({
    required this.columns,
    required this.rows,
    required this.cell,
    required this.gap,
    required this.top,
    required this.byRows,
    required this.inkFor,
  });

  final int columns;
  final int rows;
  final double cell;
  final double gap;
  final double top;
  final bool byRows;
  final Color? Function(int column, int row) inkFor;

  List<(int, int)> get _walk {
    final walk = <(int, int)>[];
    if (byRows) {
      for (var row = 0; row < rows; row++) {
        for (var i = 0; i < columns; i++) {
          walk.add((row.isEven ? i : columns - 1 - i, row));
        }
      }
    } else {
      for (var column = 0; column < columns; column++) {
        for (var i = 0; i < rows; i++) {
          walk.add((column, column.isEven ? i : rows - 1 - i));
        }
      }
    }
    return walk;
  }

  Offset _centre(int column, int row) {
    final step = cell + gap;
    return Offset(column * step + cell / 2, top + row * step + cell / 2);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final walk = _walk;

    for (var i = 0; i < walk.length - 1; i++) {
      final (fromColumn, fromRow) = walk[i];
      final (toColumn, toRow) = walk[i + 1];
      final fromInk = inkFor(fromColumn, fromRow);
      final toInk = inkFor(toColumn, toRow);
      if (fromInk == null && toInk == null) continue;

      final from = _centre(fromColumn, fromRow);
      final to = _centre(toColumn, toRow);
      final stepX = (to.dx - from.dx).sign * cell / 2;
      final stepY = (to.dy - from.dy).sign * cell / 2;
      final edgeFrom = Offset(from.dx + stepX, from.dy + stepY);
      final edgeTo = Offset(to.dx - stepX, to.dy - stepY);
      final middle = Offset(
        (edgeFrom.dx + edgeTo.dx) / 2,
        (edgeFrom.dy + edgeTo.dy) / 2,
      );

      if (fromInk != null) {
        canvas.drawLine(edgeFrom, middle, _pathPaint(fromInk));
      }
      if (toInk != null) {
        canvas.drawLine(middle, edgeTo, _pathPaint(toInk));
      }
    }
  }

  @override
  bool shouldRepaint(_HeatmapPathPainter old) =>
      old.columns != columns ||
      old.rows != rows ||
      old.cell != cell ||
      old.gap != gap ||
      old.top != top ||
      old.byRows != byRows ||
      old.inkFor != inkFor;
}

Paint _pathPaint(Color color) => Paint()
  ..color = color
  ..strokeWidth = 3;
