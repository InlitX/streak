import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:streak/core/i18n/app_strings.dart';
import 'package:streak/core/icons/habit_glyph.dart';
import 'package:streak/core/utils/app_snackbar.dart';
import 'package:streak/features/habits/data/habit.dart';

/// Opens a bottom sheet that previews a polished, shareable card for [habit]
/// and lets the user export it as an image.
Future<void> showShareCard(BuildContext context, Habit habit) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _ShareSheet(habit: habit),
  );
}

class _ShareSheet extends StatefulWidget {
  const _ShareSheet({required this.habit});

  final Habit habit;

  @override
  State<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<_ShareSheet> {
  final _cardKey = GlobalKey();
  bool _busy = false;

  Future<void> _share() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      HapticFeedback.mediumImpact();
      // Let the current frame settle so the card is fully painted.
      await WidgetsBinding.instance.endOfFrame;
      final boundary =
          _cardKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw Exception('encode failed');

      final dir = await Directory.systemTemp.createTemp('streak_share');
      final file = File('${dir.path}/streak_${widget.habit.id}.png');
      await file.writeAsBytes(data.buffer.asUint8List());

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        subject: widget.habit.name,
      );
    } catch (_) {
      if (mounted) AppSnackbar.error(context, context.tr('share_failed'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width =
        (MediaQuery.of(context).size.width - 72).clamp(260.0, 360.0).toDouble();
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RepaintBoundary(
              key: _cardKey,
              child: ShareCard(habit: widget.habit, width: width),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _busy ? null : _share,
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(LucideIcons.share2, size: 18),
                label: Text(context.tr('share')),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
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

/// The shareable card — a self-contained dark graphic built from the habit's colour.
class ShareCard extends StatelessWidget {
  const ShareCard({super.key, required this.habit, this.width = 360});

  final Habit habit;
  final double width;

  @override
  Widget build(BuildContext context) {
    final color = habit.color;
    final white60 = Colors.white.withValues(alpha: 0.6);

    return Container(
      width: width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(color, const Color(0xFF111114), 0.66)!,
            const Color(0xFF09090B),
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.20),
            blurRadius: 44,
            spreadRadius: -10,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(34),
        child: Stack(
          children: [
            // Corner glow.
            Positioned(top: -90, right: -70, child: _Glow(color: color)),
            Padding(
              padding: const EdgeInsets.fromLTRB(26, 24, 26, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Branding pill.
                  Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              color,
                              Color.lerp(color, Colors.black, 0.3)!,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(LucideIcons.flame,
                            size: 15, color: Colors.white),
                      ),
                      const SizedBox(width: 9),
                      const Text(
                        'Streak',
                        style: TextStyle(
                          fontFamily: 'PlayfairDisplay',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Habit identity.
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: color.withValues(alpha: 0.35),
                            width: 1,
                          ),
                        ),
                        child:
                            HabitGlyph(glyph: habit.icon, color: color, size: 24),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              habit.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                habit.category.isNotEmpty
                                    ? habit.category
                                    : context.tr('app_tagline'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: white60, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),

                  // Hero streak number.
                  Center(
                    child: Column(
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            ShaderMask(
                              shaderCallback: (rect) => LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.white,
                                  Color.lerp(color, Colors.white, 0.55)!,
                                ],
                              ).createShader(rect),
                              child: Text(
                                '${habit.currentStreak}',
                                style: const TextStyle(
                                  fontFamily: 'PlayfairDisplay',
                                  fontSize: 96,
                                  height: 1.0,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: Icon(LucideIcons.flame,
                                  size: 34, color: color),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.tr('current_streak').toUpperCase(),
                          style: TextStyle(
                            color: white60,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),

                  // Secondary stats.
                  Row(
                    children: [
                      _StatChip(
                        value: '${habit.longestStreak}',
                        label: context.tr('best'),
                        color: color,
                      ),
                      const SizedBox(width: 10),
                      _StatChip(
                        value: '${habit.totalCompletions}',
                        label: context.tr('total'),
                        color: color,
                      ),
                      const SizedBox(width: 10),
                      _StatChip(
                        value: '${(habit.strength * 100).round()}%',
                        label: context.tr('strength'),
                        color: color,
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  _MiniGrid(habit: habit, color: color),
                  const SizedBox(height: 20),

                  Divider(color: Colors.white.withValues(alpha: 0.07), height: 1),
                  const SizedBox(height: 14),

                  // Footer: date + tagline.
                  Row(
                    children: [
                      Text(
                        _formattedDate(context),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        context.tr('app_tagline'),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
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

  String _formattedDate(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMMMMd(locale).format(DateTime.now());
  }
}

/// Radial glow in the card corner.
class _Glow extends StatelessWidget {
  const _Glow({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      height: 240,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: 0.30),
            color.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Column(
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Last 35 days as a compact heatmap, oldest (top-left) to today (bottom-right).
class _MiniGrid extends StatelessWidget {
  const _MiniGrid({required this.habit, required this.color});

  final Habit habit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    const cols = 7;
    const rows = 5;
    const gap = 5.0;
    final today = DateTime.now();

    return LayoutBuilder(
      builder: (context, constraints) {
        final cell = ((constraints.maxWidth - gap * (cols - 1)) / cols)
            .clamp(0.0, 34.0);
        return Column(
          children: [
            for (var r = 0; r < rows; r++) ...[
              if (r > 0) const SizedBox(height: gap),
              Row(
                children: [
                  for (var c = 0; c < cols; c++) ...[
                    if (c > 0) const SizedBox(width: gap),
                    Builder(builder: (_) {
                      final index = r * cols + c;
                      final date = today
                          .subtract(Duration(days: (rows * cols - 1) - index));
                      final done = habit.isCompletedOn(date);
                      return Container(
                        width: cell,
                        height: cell,
                        decoration: BoxDecoration(
                          color: done
                              ? color
                              : Colors.white.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: done
                              ? [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.45),
                                    blurRadius: 6,
                                  ),
                                ]
                              : null,
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}
