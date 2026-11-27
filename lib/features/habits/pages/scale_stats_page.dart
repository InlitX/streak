import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/express/express_page.dart';
import 'package:streak/core/express/express_shapes.dart';
import 'package:streak/core/express/express_surface.dart';
import 'package:streak/core/express/express_tabs.dart';
import 'package:streak/core/express/express_type.dart';
import 'package:streak/core/extensions/color_extensions.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/extensions/inset_extensions.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/minimal/minimal_kit.dart';
import 'package:streak/core/routing/app_navigator.dart';
import 'package:streak/core/widgets/top_fade.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/state/habits_controller.dart';
import 'package:streak/features/habits/widgets/scale_faces.dart';
import 'package:streak/features/settings/state/settings_controller.dart';
import 'package:streak/features/settings/widgets/settings_rows.dart';
import 'package:streak/features/statistics/widgets/express_stat_kit.dart';
import 'package:streak/features/statistics/widgets/stat_kit.dart';

class ScaleStatsPage extends StatefulWidget {
  const ScaleStatsPage({super.key, required this.habitId});

  final String habitId;

  @override
  State<ScaleStatsPage> createState() => _ScaleStatsPageState();
}

class _ScaleSummary {
  _ScaleSummary(Habit habit, int span) {
    final today = AppClock.today();
    final start = today.addDays(-(span - 1));
    for (var i = 0; i < span; i++) {
      final day = start.addDays(i);
      final level = scaleLevelOf(habit.completions[day.dayKey]?.count ?? 0);
      if (level == 0) continue;
      faces[level - 1]++;
      sum += level;
      days++;
      weekdaySum[day.weekday - 1] += level;
      weekdayDays[day.weekday - 1]++;
    }
  }

  final faces = List.filled(scaleLevels, 0);
  final weekdaySum = List.filled(7, 0);
  final weekdayDays = List.filled(7, 0);
  var sum = 0;
  var days = 0;

  double get average => days == 0 ? 0 : sum / days;

  double weekdayAverage(int weekday) => weekdayDays[weekday - 1] == 0
      ? 0
      : weekdaySum[weekday - 1] / weekdayDays[weekday - 1];
}

class _ScaleStatsPageState extends State<ScaleStatsPage> {
  static const _spans = [7, 30, 365];
  int _range = 1;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final habit = context.watch<HabitsController>().byId(widget.habitId);
    if (habit == null) return const SizedBox.shrink();
    final express = settings.isExpressStyle;
    final minimal = settings.isMinimalStyle;
    final summary = _ScaleSummary(habit, _spans[_range]);
    final tint = habit.color.shownIn(context);
    final labels = [
      context.l10n.week,
      context.l10n.month,
      context.l10n.year,
    ];
    void pick(int index) => setState(() => _range = index);

    final selector = express
        ? ExpressTabs(labels: labels, index: _range, onChanged: pick)
        : minimal
            ? MinimalSegmented(options: labels, index: _range, onChanged: pick)
            : Align(
                alignment: Alignment.centerLeft,
                child: Segmented(
                  options: labels,
                  index: _range,
                  onChanged: pick,
                ),
              );

    Widget section(
      String title,
      IconData icon,
      ExpressShape shape,
      Widget child,
    ) {
      if (express) {
        return ExpressStatPanel(
          title: title,
          icon: icon,
          tint: tint,
          shape: shape,
          child: child,
        );
      }
      if (minimal) {
        return MinimalSection(title: title, child: MinimalCard(child: child));
      }
      return StatCard(title: title, icon: icon, color: tint, child: child);
    }

    final sections = [
      section(
        context.l10n.scale_average,
        LucideIcons.activity,
        ExpressShape.flower,
        _AverageHero(summary: summary, express: express),
      ),
      section(
        context.l10n.scale_by_face,
        LucideIcons.chartBarBig,
        ExpressShape.gem,
        _FaceBars(summary: summary),
      ),
      section(
        context.l10n.scale_by_weekday,
        LucideIcons.calendarDays,
        ExpressShape.clover,
        _WeekdayFaces(summary: summary, weekStart: settings.weekStart),
      ),
    ];
    final gap = minimal ? 0.0 : (express ? 20.0 : 12.0);
    final children = [
      selector,
      SizedBox(height: express ? 20 : 16),
      for (final (i, child) in sections.indexed) ...[
        if (i > 0) SizedBox(height: gap),
        child,
      ],
    ];

    if (express) {
      return Scaffold(
        appBar: expressBar(),
        body: ScrollTopFade(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView(
                padding: context.pagePadding(18, 0, 18, 40),
                children: [
                  ExpressHeadline(title: habit.name),
                  const SizedBox(height: 20),
                  ...children,
                ],
              ),
            ),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: minimal ? 52 : null,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => AppNavigator.pop(),
        ),
        title: minimal ? null : Text(habit.name),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: minimal ? 720 : 760),
          child: ListView(
            padding: context.pagePadding(
              minimal ? 20 : 16,
              minimal ? 0 : 8,
              minimal ? 20 : 16,
              32,
            ),
            children: [
              if (minimal) MinimalTitle(title: habit.name),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

String _decimal(BuildContext context, double value) =>
    NumberFormat('0.0', Localizations.localeOf(context).toString())
        .format(value);

class _AverageHero extends StatelessWidget {
  const _AverageHero({required this.summary, required this.express});

  final _ScaleSummary summary;
  final bool express;

  @override
  Widget build(BuildContext context) {
    final muted = context.tokens.muted;
    final empty = summary.days == 0;
    final level = empty ? 0 : summary.average.round();
    final big = express
        ? ExpressType.display.at(34, height: 1.05, spacing: -1)
        : TextStyle(
            fontSize: 32,
            height: 1.05,
            fontWeight: FontWeight.w800,
            color: context.colors.onSurface,
          );
    return Row(
      children: [
        ScaleFace(level: level, size: 64),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                empty ? context.l10n.no_data_yet : scaleLabel(context, level),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: empty ? muted : scaleColor(level),
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  empty ? '-' : '${_decimal(context, summary.average)} / $scaleLevels',
                  style: big,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${context.l10n.quant_logged_days}: ${summary.days}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12.5, color: muted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FaceBars extends StatelessWidget {
  const _FaceBars({required this.summary});

  final _ScaleSummary summary;

  @override
  Widget build(BuildContext context) {
    final muted = context.tokens.muted;
    final most = summary.faces.fold(0, (a, b) => a > b ? a : b);
    return Column(
      children: [
        for (var level = scaleLevels; level >= 1; level--) ...[
          if (level < scaleLevels) const SizedBox(height: 10),
          Row(
            children: [
              ScaleFace(level: level, size: 26),
              const SizedBox(width: 10),
              SizedBox(
                width: 64,
                child: Text(
                  scaleLabel(context, level),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.colors.onSurface,
                  ),
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    height: 12,
                    color: muted.withValues(alpha: 0.14),
                    alignment: AlignmentDirectional.centerStart,
                    child: FractionallySizedBox(
                      widthFactor:
                          most == 0 ? 0 : summary.faces[level - 1] / most,
                      child: Container(color: scaleColor(level)),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 40,
                child: Text(
                  '${summary.faces[level - 1]}',
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: context.colors.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _WeekdayFaces extends StatelessWidget {
  const _WeekdayFaces({required this.summary, required this.weekStart});

  final _ScaleSummary summary;
  final int weekStart;

  @override
  Widget build(BuildContext context) {
    final muted = context.tokens.muted;
    final locale = Localizations.localeOf(context).toString();
    return Row(
      children: [
        for (var i = 0; i < 7; i++)
          Builder(
            builder: (context) {
              final weekday = (weekStart - 1 + i) % 7 + 1;
              final average = summary.weekdayAverage(weekday);
              final name = DateFormat.E(locale).format(DateTime(2024, 1, weekday));
              return Expanded(
                child: Column(
                  children: [
                    ScaleFace(level: average.round(), size: 30),
                    const SizedBox(height: 6),
                    Text(
                      name.characters.first.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: context.colors.onSurface,
                      ),
                    ),
                    Text(
                      average == 0 ? '-' : _decimal(context, average),
                      style: TextStyle(fontSize: 11.5, color: muted),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
