import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_theme.dart';
import 'package:streak/core/express/express_shapes.dart';
import 'package:streak/core/express/express_type.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/minimal/minimal_type.dart';
import 'package:streak/core/routing/app_navigator.dart';
import 'package:streak/core/utils/app_snackbar.dart';
import 'package:streak/core/utils/share_origin.dart';
import 'package:streak/core/widgets/entrance.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/widgets/color_picker.dart';
import 'package:streak/features/habits/widgets/share_range_pages.dart';
import 'package:streak/features/habits/widgets/share_stat_card.dart';
import 'package:streak/features/settings/state/settings_controller.dart';

const _entrance = Duration(milliseconds: 340);

int _styleOf(BuildContext context) =>
    context.watch<SettingsController>().appStyle;

TextStyle _shareTitle(int style) => switch (style) {
      2 => ExpressType.display.at(24, spacing: -0.4, color: Colors.white),
      1 => MinimalType.display(24, color: Colors.white),
      _ => const TextStyle(
          fontFamily: 'PlayfairDisplay',
          fontStyle: FontStyle.italic,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
    };

TextStyle _shareLabel(int style, double size, Color color) => switch (style) {
      2 => ExpressType.headline.at(size, weight: 800, color: color),
      1 => MinimalType.label(size: size, color: color),
      _ => TextStyle(
          fontSize: size,
          fontWeight: FontWeight.w700,
          color: color,
        ),
    };

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
    final origin = shareOrigin(context);
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
        sharePositionOrigin: origin,
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
    final style = _styleOf(context);

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
                        style: _shareTitle(style),
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
                  style: style,
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
                            style: _shareLabel(
                              style,
                              12,
                              Colors.white.withValues(alpha: 0.4),
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
                  style: style,
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
                        style: style,
                        icon: LucideIcons.share2,
                        label: context.l10n.share,
                        onTap: _busy ? null : _share,
                      ),
                      const SizedBox(width: 40),
                      _CircleAction(
                        style: style,
                        shapeIndex: 3,
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
  const _RangeTabs({
    required this.style,
    required this.range,
    required this.onChanged,
  });

  final int style;
  final ShareRange range;
  final ValueChanged<ShareRange> onChanged;

  Widget _pill(BuildContext context, Map<ShareRange, String> labels) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(style == 2 ? 24 : 14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final entry in labels.entries)
            Semantics(
              button: true,
              selected: range == entry.key,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onChanged(entry.key);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: range == entry.key
                        ? Colors.white
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(style == 2 ? 21 : 11),
                  ),
                  child: Text(
                    entry.value,
                    style: _shareLabel(
                      style,
                      13,
                      range == entry.key
                          ? Colors.black.withValues(alpha: 0.85)
                          : Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final labels = {
      ShareRange.week: context.l10n.week,
      ShareRange.month: context.l10n.month,
      ShareRange.year: context.l10n.year,
    };

    if (style != 0) {
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Center(child: _pill(context, labels)),
      );
    }

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
                      style: DefaultTextStyle.of(context).style.copyWith(
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
    required this.style,
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

  final int style;
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
                style: style,
                icon: LucideIcons.palette,
                label: context.l10n.color,
                selected: image.isEmpty,
                dot: accent,
                onTap: onColor,
              ),
              const SizedBox(width: 8),
              _Toggle(
                style: style,
                icon: LucideIcons.image,
                label: context.l10n.share_photo,
                selected: image.isNotEmpty,
                onTap: image.isEmpty ? onImage : onClearImage,
                badge: image.isEmpty ? null : LucideIcons.x,
              ),
              const SizedBox(width: 8),
              _Toggle(
                style: style,
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
                          style: _shareLabel(
                            style,
                            12,
                            Colors.white.withValues(alpha: 0.7),
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
    required this.style,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.dot,
    this.badge,
  });

  final int style;
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
                borderRadius: BorderRadius.circular(
                  switch (style) { 2 => 22.0, 1 => 10.0, _ => 13.0 },
                ),
                border: Border.all(
                  color: selected
                      ? Colors.white.withValues(alpha: style == 1 ? 0.32 : 0.5)
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
                      style: _shareLabel(style, 12, Colors.white),
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
    required this.style,
    required this.icon,
    required this.label,
    required this.onTap,
    this.shapeIndex = 0,
  });

  final int style;
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final int shapeIndex;

  @override
  State<_CircleAction> createState() => _CircleActionState();
}

class _CircleActionState extends State<_CircleAction> {
  bool _pressed = false;

  void _press(bool value) {
    if (widget.onTap == null) return;
    setState(() => _pressed = value);
  }

  Widget _button() {
    final fill = Colors.white.withValues(alpha: 0.14);
    final icon = Icon(widget.icon, size: 21, color: Colors.white);

    if (widget.style == 2) {
      return ExpressBlob(
        size: 58,
        color: fill,
        shape: ExpressShape.pick(widget.shapeIndex),
        child: icon,
      );
    }

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: fill,
        shape: widget.style == 1 ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: widget.style == 1 ? BorderRadius.circular(17) : null,
      ),
      child: icon,
    );
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
                _button(),
                const SizedBox(height: 6),
                Text(
                  widget.label,
                  style: _shareLabel(
                    widget.style,
                    12,
                    Colors.white.withValues(alpha: 0.7),
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
