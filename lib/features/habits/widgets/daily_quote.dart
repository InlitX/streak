import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/features/habits/widgets/today_intro.dart';
import 'package:streak/features/settings/state/settings_controller.dart';

class DailyQuote extends StatefulWidget {
  const DailyQuote({super.key});

  static List<String> appQuotes(BuildContext context) => [
        context.l10n.quote_1,
        context.l10n.quote_2,
        context.l10n.quote_3,
        context.l10n.quote_4,
        context.l10n.quote_5,
        context.l10n.quote_6,
        context.l10n.quote_7,
        context.l10n.quote_8,
        context.l10n.quote_9,
        context.l10n.quote_10,
        context.l10n.quote_11,
        context.l10n.quote_12,
      ];

  static List<String> quotesOf(BuildContext context, SettingsController s) =>
      switch (s.quoteSource) {
        1 => s.customQuotes,
        2 => [...appQuotes(context), ...s.customQuotes],
        3 => const [],
        _ => appQuotes(context),
      };

  static final _random = math.Random();
  static int _index = -1;

  @override
  State<DailyQuote> createState() => _DailyQuoteState();
}

class _DailyQuoteState extends State<DailyQuote> {
  late bool _picked;

  @override
  void initState() {
    super.initState();
    TodayIntro.tick.addListener(_shuffle);
    _picked = DailyQuote._index >= 0 && !TodayIntro.claim(DailyQuote);
  }

  @override
  void dispose() {
    TodayIntro.tick.removeListener(_shuffle);
    super.dispose();
  }

  void _shuffle() {
    if (!mounted || !TodayIntro.claim(DailyQuote)) return;
    setState(() => _picked = false);
  }

  void _pick(int count) {
    if (count < 2) {
      DailyQuote._index = 0;
      return;
    }
    final next = DailyQuote._random.nextInt(count - 1);
    DailyQuote._index = next >= DailyQuote._index ? next + 1 : next;
  }

  @override
  Widget build(BuildContext context) {
    final quotes =
        DailyQuote.quotesOf(context, context.watch<SettingsController>());
    if (quotes.isEmpty) return const SizedBox.shrink();

    if (!_picked || DailyQuote._index >= quotes.length) {
      _pick(quotes.length);
      _picked = true;
    }
    final index = DailyQuote._index;

    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 650),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: Row(
          key: ValueKey(quotes[index]),
          children: [
            Icon(LucideIcons.sparkles, size: 14, color: context.colors.primary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                quotes[index],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: context.tokens.muted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
