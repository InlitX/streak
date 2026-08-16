import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/widgets/cover_image.dart';
import 'package:streak/core/widgets/photo_viewer.dart';

const _shift = Duration(milliseconds: 320);
const _curve = Curves.easeOutCubic;
const _visible = 3;

class PhotoDeck extends StatefulWidget {
  const PhotoDeck({
    super.key,
    required this.shots,
    this.size = 88,
    this.swipe = true,
    this.onRemove,
  });

  final List<PhotoShot> shots;
  final double size;
  final bool swipe;
  final ValueChanged<int>? onRemove;

  @override
  State<PhotoDeck> createState() => _PhotoDeckState();
}

class _PhotoDeckState extends State<PhotoDeck> {
  int _top = 0;

  @override
  void didUpdateWidget(PhotoDeck oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_top >= widget.shots.length) _top = 0;
  }

  int _slot(int index) =>
      (index - _top + widget.shots.length) % widget.shots.length;

  void _bringToFront(int index) {
    HapticFeedback.selectionClick();
    setState(() => _top = index);
  }

  void _cycle(int step) {
    final count = widget.shots.length;
    if (count > 1) _bringToFront((_top + step + count) % count);
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.shots.length;
    if (count == 0) return const SizedBox.shrink();

    final depth = math.min(count, _visible) - 1;
    final order = [for (var i = 0; i < count; i++) i]
      ..sort((a, b) => _slot(b).compareTo(_slot(a)));

    return Semantics(
      button: true,
      label: context.l10n.note_photos,
      child: GestureDetector(
        onHorizontalDragEnd: widget.swipe
            ? (details) => _cycle((details.primaryVelocity ?? 0) < 0 ? 1 : -1)
            : null,
        child: SizedBox(
          width: widget.size * (1 + 0.09 * depth),
          height: widget.size * (1 + 0.06 * depth),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (final index in order) _card(context, index),
              if (count > 1) _counter(count),
              if (widget.onRemove != null) _removeButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(BuildContext context, int index) {
    final slot = _slot(index);
    final buried = slot >= _visible;
    final depth = math.min(slot, _visible - 1).toDouble();

    return AnimatedSlide(
      key: ValueKey(widget.shots[index].path),
      duration: _shift,
      curve: _curve,
      offset: Offset(depth * 0.09, depth * 0.06),
      child: AnimatedRotation(
        duration: _shift,
        curve: _curve,
        turns: depth * 0.008,
        child: AnimatedScale(
          duration: _shift,
          curve: _curve,
          scale: 1 - depth * 0.05,
          child: AnimatedOpacity(
            duration: _shift,
            opacity: buried ? 0 : 1,
            child: IgnorePointer(
              ignoring: buried,
              child: GestureDetector(
                onTap: slot == 0
                    ? () => showPhotoViewer(context, widget.shots, index)
                    : () => _bringToFront(index),
                child: _photo(context, index, slot == 0),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _photo(BuildContext context, int index, bool front) {
    final card = Container(
      width: widget.size,
      height: widget.size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(widget.size * 0.17),
        border: Border.all(color: context.colors.surface, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 9,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: CoverImage(path: widget.shots[index].path),
    );
    if (!front) return card;
    return Hero(
      tag: photoHeroTag(index, widget.shots[index].path),
      child: card,
    );
  }

  Widget _counter(int count) {
    final font = math.max(9.5, widget.size * 0.13);
    return Positioned(
      left: widget.size * 0.075,
      top: widget.size * 0.925 - font * 2,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: font * 0.6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(font),
        ),
        child: Text(
          '${_top + 1}/$count',
          style: TextStyle(
            fontSize: font,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _removeButton(BuildContext context) {
    final button = math.max(20.0, widget.size * 0.25);
    return Positioned(
      left: widget.size - button - 5,
      top: 5,
      child: Semantics(
        button: true,
        label: context.l10n.delete,
        child: GestureDetector(
          onTap: () => widget.onRemove!(_top),
          child: Container(
            width: button,
            height: button,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.6),
            ),
            child: Icon(
              LucideIcons.x,
              size: button * 0.58,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
