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
  return [
    ...items.take(cut),
    StatColumns(cards: items.skip(cut + 1).toList()),
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
          (left.length <= right.length ? left : right).addAll(group);
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
