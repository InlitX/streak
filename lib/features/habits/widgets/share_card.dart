import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:streak/app/theme/app_theme.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/routing/app_navigator.dart';
import 'package:streak/core/utils/app_snackbar.dart';
import 'package:streak/core/widgets/entrance.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/widgets/color_picker.dart';
import 'package:streak/features/habits/widgets/share_range_pages.dart';
import 'package:streak/features/habits/widgets/share_stat_card.dart';

const _entrance = Duration(milliseconds: 340);

Future<void> showShareCard(BuildContext context, Habit habit) async {
  AppNavigator.push(SharePage(habit: habit), fullscreenDialog: true);
}

class SharePage extends StatefulWidget {
  const SharePage({super.key, required this.habit});

  final Habit habit;

  @override
  State<SharePage> createState() => _SharePageState();
}

class _SharePageState extends State<SharePage> {
  final _cardKey = GlobalKey();

  ShareRange _range = ShareRange.month;
  bool _stats = true;
  double _blur = 8;
  bool _busy = false;

  late Color _accent = widget.habit.color;
  String _image = '';

  Future<void> _pickColor() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (_, setSheetState) => SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: ColorPicker(
              selected: _accent,
              onSelected: (color) {
                setSheetState(() {});
                setState(() => _accent = color);
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 90,
    );
    if (picked != null && mounted) setState(() => _image = picked.path);
  }

  Future<Uint8List?> _render() async {
    await WidgetsBinding.instance.endOfFrame;
    final boundary =
        _cardKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data?.buffer.asUint8List();
  }

  Future<void> _share() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      HapticFeedback.mediumImpact();
      final bytes = await _render();
      if (bytes == null) throw Exception('encode failed');
      final dir = await Directory.systemTemp.createTemp('streak_share');
      final file = File('${dir.path}/streak_${widget.habit.id}.png');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        subject: widget.habit.name,
      );
    } catch (_) {
      if (mounted) AppSnackbar.error(context, context.l10n.share_failed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      HapticFeedback.mediumImpact();
      final bytes = await _render();
      if (bytes == null) throw Exception('encode failed');
      if (!await Gal.hasAccess(toAlbum: true)) {
        await Gal.requestAccess(toAlbum: true);
      }
      await Gal.putImageBytes(bytes, album: 'Streak');
      if (mounted) AppSnackbar.success(context, context.l10n.share_saved);
    } catch (_) {
      if (mounted) AppSnackbar.error(context, context.l10n.share_save_failed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.sizeOf(context).width - 56)
        .clamp(240.0, 330.0)
        .toDouble();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.systemBars(Brightness.dark),
      child: Scaffold(
        backgroundColor: Color.lerp(_accent, Colors.black, 0.92),
        body: SafeArea(
          child: Column(
            children: [
              Entrance(
                delay: _entrance,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(LucideIcons.x, color: Colors.white),
                      onPressed: () => AppNavigator.pop(),
                    ),
                    Expanded(
                      child: Text(
                        context.l10n.share,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'PlayfairDisplay',
                          fontStyle: FontStyle.italic,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Entrance(
                index: 1,
                delay: _entrance,
                child: _RangeTabs(
                  range: _range,
                  onChanged: (value) => setState(() => _range = value),
                ),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Entrance(
                      index: 2,
                      delay: _entrance,
                      child: Column(
                        children: [
                          RepaintBoundary(
                            key: _cardKey,
                            child: ShareStatCard(
                              habit: widget.habit,
                              accent: _accent,
                              imagePath: _image,
                              blur: _blur,
                              range: _range,
                              showStats: _stats,
                              width: width,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            context.l10n.share_swipe_hint,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Entrance(
                index: 3,
                delay: _entrance,
                child: _Options(
                  accent: _accent,
                  image: _image,
                  blur: _blur,
                  stats: _stats,
                  onColor: _pickColor,
                  onImage: _pickImage,
                  onClearImage: () => setState(() => _image = ''),
                  onBlur: (value) => setState(() => _blur = value),
                  onStats: (value) => setState(() => _stats = value),
                ),
              ),
              Entrance(
                index: 4,
                delay: _entrance,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _CircleAction(
                        icon: LucideIcons.share2,
                        label: context.l10n.share,
                        onTap: _busy ? null : _share,
                      ),
                      const SizedBox(width: 40),
                      _CircleAction(
                        icon: LucideIcons.download,
                        label: context.l10n.share_save,
                        onTap: _busy ? null : _save,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RangeTabs extends StatelessWidget {
  const _RangeTabs({required this.range, required this.onChanged});

  final ShareRange range;
  final ValueChanged<ShareRange> onChanged;

  @override
  Widget build(BuildContext context) {
    final labels = {
      ShareRange.week: context.l10n.week,
      ShareRange.month: context.l10n.month,
      ShareRange.year: context.l10n.year,
    };

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final entry in labels.entries)
          Semantics(
            button: true,
            selected: range == entry.key,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onChanged(entry.key);
              },
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 220),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white
                            .withValues(alpha: range == entry.key ? 1 : 0.42),
                      ),
                      child: Text(entry.value),
                    ),
                    const SizedBox(height: 5),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      width: range == entry.key ? 18 : 0,
                      height: 2,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Options extends StatelessWidget {
  const _Options({
    required this.accent,
    required this.image,
    required this.blur,
    required this.stats,
    required this.onColor,
    required this.onImage,
    required this.onClearImage,
    required this.onBlur,
    required this.onStats,
  });

  final Color accent;
  final String image;
  final double blur;
  final bool stats;
  final VoidCallback onColor;
  final VoidCallback onImage;
  final VoidCallback onClearImage;
  final ValueChanged<double> onBlur;
  final ValueChanged<bool> onStats;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              _Toggle(
                icon: LucideIcons.palette,
                label: context.l10n.color,
                selected: image.isEmpty,
                dot: accent,
                onTap: onColor,
              ),
              const SizedBox(width: 8),
              _Toggle(
                icon: LucideIcons.image,
                label: context.l10n.share_photo,
                selected: image.isNotEmpty,
                onTap: image.isEmpty ? onImage : onClearImage,
                badge: image.isEmpty ? null : LucideIcons.x,
              ),
              const SizedBox(width: 8),
              _Toggle(
                icon: LucideIcons.flame,
                label: context.l10n.share_stats_short,
                selected: stats,
                onTap: () => onStats(!stats),
              ),
            ],
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          child: image.isEmpty
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.droplet,
                        size: 15,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 3,
                            activeTrackColor: Colors.white,
                            inactiveTrackColor:
                                Colors.white.withValues(alpha: 0.2),
                            thumbColor: Colors.white,
                            overlayShape:
                                const RoundSliderOverlayShape(overlayRadius: 14),
                          ),
                          child: Slider(
                            value: blur,
                            max: 24,
                            onChanged: onBlur,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 26,
                        child: Text(
                          blur.round().toString(),
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.dot,
    this.badge,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? dot;
  final IconData? badge;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        child: GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: AnimatedScale(
            scale: selected ? 1 : 0.96,
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutBack,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: selected ? 0.18 : 0.06),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.5)
                      : Colors.transparent,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (dot != null)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: dot,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    )
                  else
                    Icon(icon, size: 14, color: Colors.white),
                  const SizedBox(width: 7),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (badge != null) ...[
                    const SizedBox(width: 5),
                    Icon(badge, size: 13, color: Colors.white),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CircleAction extends StatefulWidget {
  const _CircleAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  State<_CircleAction> createState() => _CircleActionState();
}

class _CircleActionState extends State<_CircleAction> {
  bool _pressed = false;

  void _press(bool value) {
    if (widget.onTap == null) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: widget.onTap == null ? 0.5 : 1,
      duration: const Duration(milliseconds: 200),
      child: Semantics(
        button: true,
        child: GestureDetector(
          onTap: widget.onTap,
          onTapDown: (_) => _press(true),
          onTapUp: (_) => _press(false),
          onTapCancel: () => _press(false),
          child: AnimatedScale(
            scale: _pressed ? 0.9 : 1,
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.14),
                  ),
                  child: Icon(widget.icon, size: 21, color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
