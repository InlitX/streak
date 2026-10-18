import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/features/settings/state/settings_controller.dart';

typedef ClassicNavItem = ({IconData icon, String label});

class ClassicNavBar extends StatefulWidget {
  const ClassicNavBar({
    super.key,
    required this.items,
    required this.index,
    required this.onSelect,
    required this.compact,
  });

  final List<ClassicNavItem> items;
  final int index;
  final ValueChanged<int> onSelect;
  final ValueListenable<bool> compact;

  @override
  State<ClassicNavBar> createState() => _ClassicNavBarState();
}

class _ClassicNavBarState extends State<ClassicNavBar>
    with TickerProviderStateMixin {
  static const _tall = 64.0;
  static const _short = 50.0;
  static const _pad = 5.0;
  static const _spring = SpringDescription(mass: 1, stiffness: 420, damping: 30);

  late final AnimationController _lens;
  late final AnimationController _press;
  late final AnimationController _fold;
  double _slot = 72;
  double _height = _tall;

  @override
  void initState() {
    super.initState();
    _lens = AnimationController.unbounded(
      vsync: this,
      value: widget.index.toDouble(),
    );
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _fold = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      value: widget.compact.value ? 1 : 0,
    );
    widget.compact.addListener(_refold);
  }

  void _refold() => widget.compact.value ? _fold.forward() : _fold.reverse();

  @override
  void didUpdateWidget(ClassicNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.compact != oldWidget.compact) {
      oldWidget.compact.removeListener(_refold);
      widget.compact.addListener(_refold);
    }
    if (widget.index != oldWidget.index && !_press.isForwardOrCompleted) {
      _glide(widget.index);
    }
  }

  @override
  void dispose() {
    widget.compact.removeListener(_refold);
    _lens.dispose();
    _press.dispose();
    _fold.dispose();
    super.dispose();
  }

  void _glide(int index) => _lens.animateWith(
        SpringSimulation(_spring, _lens.value, index.toDouble(), _lens.velocity),
      );

  double _at(Offset local) =>
      ((local.dx - _pad) / _slot - 0.5).clamp(0, widget.items.length - 1);

  void _hold(LongPressStartDetails details) {
    _press.forward();
    _lens.value = _at(details.localPosition);
  }

  void _drag(LongPressMoveUpdateDetails details) {
    _lens.value = _at(details.localPosition);
  }

  void _drop([LongPressEndDetails? _]) {
    _press.reverse();
    final target = _lens.value.round();
    _glide(target);
    if (target != widget.index) widget.onSelect(target);
  }

  void _tap(TapUpDetails details) {
    final target = _at(details.localPosition).round();
    if (target != widget.index) widget.onSelect(target);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final muted = context.tokens.muted;
    final count = widget.items.length;
    final glass = context.select<SettingsController, bool>(
      (settings) => settings.glassEffects,
    );

    return LayoutBuilder(
      builder: (context, box) => AnimatedBuilder(
        animation: _fold,
        builder: (context, _) {
        final fold = Curves.easeInOutCubic.transform(_fold.value);
        final full = ((box.maxWidth - 32 - _pad * 2) / count).clamp(52.0, 78.0);
        _slot = full * lerpDouble(1, 0.8, fold)!;
        _height = lerpDouble(_tall, _short, fold)!;
        final width = _slot * count + _pad * 2;

        return RawGestureDetector(
          behavior: HitTestBehavior.opaque,
          gestures: {
            TapGestureRecognizer:
                GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
              TapGestureRecognizer.new,
              (tap) => tap.onTapUp = _tap,
            ),
            LongPressGestureRecognizer:
                GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
              () => LongPressGestureRecognizer(
                duration: const Duration(milliseconds: 220),
              ),
              (press) => press
                ..onLongPressStart = _hold
                ..onLongPressMoveUpdate = _drag
                ..onLongPressEnd = _drop
                ..onLongPressCancel = _drop,
            ),
          },
          child: Container(
            width: width,
            height: _height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_height / 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: dark ? 0.45 : 0.12),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: dark ? 0.3 : 0.06),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(_height / 2),
              child: BackdropFilter(
                enabled: glass,
                filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.surface.withValues(
                      alpha: glass ? (dark ? 0.7 : 0.78) : 0.97,
                    ),
                    borderRadius: BorderRadius.circular(_height / 2),
                    border: Border.all(
                      color: dark
                          ? Colors.white.withValues(alpha: 0.09)
                          : Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_lens, _press]),
                    builder: (context, _) {
                      final press = Curves.easeOut.transform(_press.value);
                      final stretch =
                          (_lens.velocity.abs() / 14).clamp(0.0, 0.28);
                      final lensWidth = _slot * (1 + stretch + 0.1 * press);
                      final lensHeight = _height - _pad * 2 + 6 * press;
                      final centre = _pad + _slot * (_lens.value + 0.5);
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            left: centre - lensWidth / 2,
                            top: (_height - lensHeight) / 2,
                            width: lensWidth,
                            height: lensHeight,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.circular(lensHeight / 2),
                                color: Color.lerp(
                                  scheme.primary.withValues(
                                    alpha: dark ? 0.2 : 0.13,
                                  ),
                                  (dark ? Colors.white : Colors.black)
                                      .withValues(alpha: dark ? 0.12 : 0.06),
                                  press,
                                ),
                                border: Border.all(
                                  color: Colors.white.withValues(
                                    alpha: (dark ? 0.06 : 0.5) + 0.25 * press,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned.fill(
                            left: _pad,
                            right: _pad,
                            child: Row(
                              children: [
                                for (final (i, item) in widget.items.indexed)
                                  _Item(
                                    item: item,
                                    width: _slot,
                                    near: (1 - (_lens.value - i).abs())
                                        .clamp(0.0, 1.0),
                                    press: press,
                                    selected: i == widget.index,
                                    fold: fold,
                                    onTap: () => widget.onSelect(i),
                                    active: scheme.primary,
                                    muted: muted,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
        },
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    required this.item,
    required this.width,
    required this.near,
    required this.press,
    required this.selected,
    required this.fold,
    required this.onTap,
    required this.active,
    required this.muted,
  });

  final double fold;

  final ClassicNavItem item;
  final double width;
  final double near;
  final double press;
  final bool selected;
  final VoidCallback onTap;
  final Color active;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    final tint = Color.lerp(muted, active, near)!;
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      excludeSemantics: true,
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: Transform.scale(
          scale: 1 + 0.12 * near * press,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon, size: lerpDouble(21, 22, fold), color: tint),
              ClipRect(
                child: Align(
                  alignment: Alignment.topCenter,
                  heightFactor: 1 - fold,
                  child: Opacity(
                    opacity: (1 - fold * 1.8).clamp(0.0, 1.0),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(3, 3, 3, 0),
                      child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textScaler: TextScaler.noScaling,
                style: TextStyle(
                  fontSize: 10.5,
                  height: 1.1,
                  fontWeight: near > 0.5 ? FontWeight.w700 : FontWeight.w600,
                  color: tint,
                ),
              ),
                      ),
                    ),
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
