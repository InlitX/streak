import 'package:flutter/material.dart';
import 'package:streak/core/utils/responsive.dart';
import 'package:streak/core/widgets/section_label.dart';

class SpanEnd extends StatelessWidget {
  const SpanEnd({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

List<Widget> spanned(BuildContext context, List<Widget> items) {
  final cut = items.indexWhere((item) => item is SpanEnd);
  if (cut == -1) {
    return isWideLayout(context) ? [StatColumns(cards: items)] : items;
  }
  if (!isWideLayout(context)) return [...items]..removeAt(cut);
  final rest = items.skip(cut + 1).toList();
  final lead = <Widget>[];
  while (rest.isNotEmpty && rest.first is SizedBox) {
    lead.add(rest.removeAt(0));
  }
  return [
    ...items.take(cut),
    ...lead,
    StatColumns(cards: rest),
  ];
}

class StatColumns extends StatelessWidget {
  const StatColumns({super.key, required this.cards});

  final List<Widget> cards;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        if (box.maxWidth < columnsWidth) {
          return Column(mainAxisSize: MainAxisSize.min, children: cards);
        }
        final left = <Widget>[];
        final right = <Widget>[];
        var group = <Widget>[];
        for (final card in cards) {
          group.add(card);
          if (card is SizedBox || card is SectionLabel) continue;
          final column = left.length <= right.length ? left : right;
          if (column.isEmpty) {
            while (group.isNotEmpty && group.first is SizedBox) {
              group.removeAt(0);
            }
          }
          column.addAll(group);
          group = <Widget>[];
        }
        left.addAll(group);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: left,
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: right,
              ),
            ),
          ],
        );
      },
    );
  }
}
