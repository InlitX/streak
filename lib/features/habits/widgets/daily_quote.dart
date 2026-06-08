import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:streak/app/theme/app_tokens.dart';

/// A short motivational line that rotates once per day. Stored locally, no
/// network — picked deterministically from the day of the year.
class DailyQuote extends StatelessWidget {
  const DailyQuote({super.key});

  static const _en = [
    'Small steps, every day.',
    'Consistency beats intensity.',
    'Show up for yourself.',
    'One day at a time.',
    'Progress, not perfection.',
    'Done is better than perfect.',
    'Keep the streak alive.',
    'Tiny habits, big change.',
    'Trust the process.',
    'Win the morning.',
    'Discipline equals freedom.',
    'Today counts.',
  ];

  static const _es = [
    'Pasos pequeños, cada día.',
    'La constancia gana.',
    'Hazlo por ti.',
    'Un día a la vez.',
    'Progreso, no perfección.',
    'Hecho supera a perfecto.',
    'Mantén la racha viva.',
    'Hábitos pequeños, gran cambio.',
    'Confía en el proceso.',
    'Gana la mañana.',
    'Disciplina es libertad.',
    'Hoy cuenta.',
  ];

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final list = lang == 'es' ? _es : _en;
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year)).inDays;
    final quote = list[dayOfYear % list.length];

    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Row(
        children: [
          Icon(LucideIcons.sparkles, size: 14, color: context.colors.primary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              quote,
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
    );
  }
}
