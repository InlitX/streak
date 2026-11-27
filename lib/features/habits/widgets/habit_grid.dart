import 'package:flutter/material.dart';

int habitColumns(double width) => width >= 1320
    ? 3
    : width >= 700
        ? 2
        : 1;

class GridSpot {
  const GridSpot({
    required this.top,
    required this.bottom,
    required this.start,
    required this.end,
  });

  final bool top;
  final bool bottom;
  final bool start;
  final bool end;

  BorderRadius corners(Radius edge, Radius joint) => BorderRadius.only(
        topLeft: top && start ? edge : joint,
        topRight: top && end ? edge : joint,
        bottomLeft: bottom && start ? edge : joint,
        bottomRight: bottom && end ? edge : joint,
      );
}

class HabitGrid extends StatelessWidget {
  const HabitGrid({
    super.key,
    required this.columns,
    required this.header,
    required this.count,
    required this.cell,
    required this.padding,
    required this.gap,
    this.fold,
    this.moreCount = 0,
  });

  final int columns;
  final Widget header;
  final int count;
  final Widget? fold;
  final int moreCount;
  final EdgeInsets padding;
  final double gap;
  final Widget Function(BuildContext context, bool extra, int slot, GridSpot spot) cell;

  Widget _columns(BuildContext context, bool extra, int length) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var col = 0; col < columns; col++) ...[
          if (col > 0) SizedBox(width: gap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var slot = col; slot < length; slot += columns)
                  Padding(
                    padding: EdgeInsets.only(bottom: gap),
                    child: cell(
                      context,
                      extra,
                      slot,
                      GridSpot(
                        top: slot < columns,
                        bottom: slot + columns >= length,
                        start: true,
                        end: true,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: padding,
      children: [
        header,
        _columns(context, false, count),
        if (fold != null) ...[
          fold!,
          _columns(context, true, moreCount),
        ],
      ],
    );
  }
}
