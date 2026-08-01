import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/widgets/share_range_pages.dart';

class ShareStatCard extends StatelessWidget {
  const ShareStatCard({
    super.key,
    required this.habit,
    required this.accent,
    required this.range,
    required this.showStats,
    required this.width,
    this.imagePath = '',
    this.blur = 8,
  });

  final Habit habit;
  final Color accent;
  final String imagePath;
  final double blur;
  final ShareRange range;
  final bool showStats;
  final double width;

  double get _aspect => switch (range) {
        ShareRange.week => showStats ? 1.06 : 1.32,
        ShareRange.month => 0.92,
        ShareRange.year => showStats ? 1.12 : 1.36,
      };

  bool get _hasImage => imagePath.isNotEmpty && File(imagePath).existsSync();

  @override
  Widget build(BuildContext context) {
    final pad = width * 0.055;

    return Container(
      width: width,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(width * 0.085),
        color: _hasImage ? Colors.black : accent,
      ),
      child: AspectRatio(
        aspectRatio: _aspect,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_hasImage) ...[
              blur < 0.5
                  ? Image.file(File(imagePath), fit: BoxFit.cover)
                  : ImageFiltered(
                      imageFilter:
                          ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                      child: Image.file(File(imagePath), fit: BoxFit.cover),
                    ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.26),
                      Colors.black.withValues(alpha: 0.46),
                    ],
                  ),
                ),
              ),
            ],
            Padding(
              padding: EdgeInsets.all(pad),
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding:
                          EdgeInsets.all(_hasImage ? pad * 0.25 : pad * 0.95),
                      decoration: _hasImage
                          ? null
                          : BoxDecoration(
                              color: const Color(0xFF111113)
                                  .withValues(alpha: 0.93),
                              borderRadius:
                                  BorderRadius.circular(width * 0.062),
                            ),
                      child: _Panel(
                        key: ValueKey(range),
                        habit: habit,
                        accent: accent,
                        range: range,
                        showStats: showStats,
                        width: width,
                      ),
                    ),
                  ),
                  SizedBox(height: pad * 0.7),
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: Image.asset(
                          'assets/icon.png',
                          width: width * 0.052,
                          height: width * 0.052,
                          fit: BoxFit.cover,
                        ),
                      ),
                      SizedBox(width: width * 0.025),
                      Text(
                        'Streak',
                        style: TextStyle(
                          fontFamily: 'PlayfairDisplay',
                          fontStyle: FontStyle.italic,
                          fontSize: width * 0.04,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.92),
                        ),
                      ),
                    ],
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

class _Panel extends StatefulWidget {
  const _Panel({
    super.key,
    required this.habit,
    required this.accent,
    required this.range,
    required this.showStats,
    required this.width,
  });

  final Habit habit;
  final Color accent;
  final ShareRange range;
  final bool showStats;
  final double width;

  @override
  State<_Panel> createState() => _PanelState();
}

class _PanelState extends State<_Panel> {
  static const _base = 600;

  final _pages = PageController(initialPage: _base);

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pages,
            itemCount: _base + 1,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final offset = index - _base;
              return switch (widget.range) {
                ShareRange.month => ShareMonthPage(
                    habit: widget.habit,
                    accent: widget.accent,
                    width: widget.width,
                    offset: offset,
                  ),
                ShareRange.week => ShareWeekPage(
                    habit: widget.habit,
                    accent: widget.accent,
                    width: widget.width,
                    offset: offset,
                  ),
                ShareRange.year => ShareYearPage(
                    habit: widget.habit,
                    accent: widget.accent,
                    width: widget.width,
                    offset: offset,
                  ),
              };
            },
          ),
        ),
        if (widget.showStats) ...[
          SizedBox(height: widget.width * 0.04),
          Row(
            children: [
              _Stat(
                value: '${widget.habit.currentStreak}',
                label: context.l10n.current_streak,
                width: widget.width,
              ),
              _Stat(
                value: '${widget.habit.longestStreak}',
                label: context.l10n.best,
                width: widget.width,
              ),
              _Stat(
                value: '${widget.habit.totalCompletions}',
                label: widget.habit.kind == HabitKind.negative
                    ? context.l10n.relapses
                    : context.l10n.total,
                width: widget.width,
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.value,
    required this.label,
    required this.width,
  });

  final String value;
  final String label;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: width * 0.052,
              height: 1,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          SizedBox(height: width * 0.012),
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: width * 0.025,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: Colors.white.withValues(alpha: 0.42),
            ),
          ),
        ],
      ),
    );
  }
}
