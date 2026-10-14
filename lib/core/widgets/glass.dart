import 'package:flutter/foundation.dart';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:streak/features/settings/state/settings_controller.dart';

class GlassStyle {
  const GlassStyle._();

  static bool _dark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color fill(BuildContext context) => _dark(context)
      ? Colors.white.withValues(alpha: 0.08)
      : Colors.white.withValues(alpha: 0.92);

  static Color edge(BuildContext context) => _dark(context)
      ? Colors.white.withValues(alpha: 0.09)
      : Colors.black.withValues(alpha: 0.06);

  static List<BoxShadow> lift(BuildContext context) => _dark(context)
      ? const []
      : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ];
}

class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.94,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool down) {
    if (_down != down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: _down ? widget.scale : 1,
          duration: Duration(milliseconds: _down ? 90 : 260),
          curve: _down ? Curves.easeOut : Curves.easeOutBack,
          child: widget.child,
        ),
      ),
    );
  }
}

class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.size = 40,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final double size;

  @override
  Widget build(BuildContext context) {
    final button = Semantics(
      button: true,
      label: tooltip,
      child: Pressable(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: GlassStyle.fill(context),
            border: Border.all(color: GlassStyle.edge(context)),
            boxShadow: GlassStyle.lift(context),
          ),
          child: Icon(
            icon,
            size: size * 0.47,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
    final tip = tooltip;
    return tip == null ? button : Tooltip(message: tip, child: button);
  }
}

class GlassPill extends StatelessWidget {
  const GlassPill({
    super.key,
    required this.child,
    required this.onTap,
    this.tint,
    this.height = 40,
  });

  final Widget child;
  final VoidCallback onTap;
  final Color? tint;
  final double height;

  @override
  Widget build(BuildContext context) {
    final tint = this.tint;
    return Semantics(
      button: true,
      child: Pressable(
        onTap: onTap,
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(height / 2),
            color: tint ?? GlassStyle.fill(context),
            border: Border.all(
              color: tint == null
                  ? GlassStyle.edge(context)
                  : Colors.white.withValues(alpha: 0.18),
            ),
            boxShadow: tint == null
                ? GlassStyle.lift(context)
                : [
                    BoxShadow(
                      color: tint.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class EdgeBlur extends StatefulWidget {
  const EdgeBlur({
    super.key,
    required this.height,
    this.top = true,
    this.sigma = 16,
    this.shade = 1,
  });

  final double height;
  final bool top;
  final double sigma;
  final double shade;

  @override
  State<EdgeBlur> createState() => _EdgeBlurState();
}

class _EdgeBlurState extends State<EdgeBlur> {
  static Future<FragmentProgram>? _loading;
  static FragmentProgram? _program;

  final _shaders = <FragmentShader>[];
  List<ImageFilter>? _filters;
  Object? _filtersFor;

  @override
  void initState() {
    super.initState();
    if (_program != null || !ImageFilter.isShaderFilterSupported) return;
    (_loading ??= FragmentProgram.fromAsset('assets/shaders/edge_fade.frag'))
        .then((program) {
      _program = program;
      if (mounted) setState(() {});
    }, onError: (_) {});
  }

  @override
  void dispose() {
    _drop();
    super.dispose();
  }

  void _drop() {
    for (final shader in _shaders) {
      shader.dispose();
    }
    _shaders.clear();
  }

  List<ImageFilter> _layers(FragmentProgram program, double ratio) {
    final key = (widget.height, widget.top, widget.sigma, ratio);
    if (_filters != null && _filtersFor == key) return _filters!;
    _drop();
    ImageFilter layer(double sigma, double from, double to) {
      final shader = program.fragmentShader()
        ..setFloat(2, widget.height * ratio)
        ..setFloat(3, from)
        ..setFloat(4, to)
        ..setFloat(5, widget.top ? 1 : 0);
      _shaders.add(shader);
      return ImageFilter.compose(
        outer: ImageFilter.shader(shader),
        inner: ImageFilter.blur(
          sigmaX: sigma,
          sigmaY: sigma,
          tileMode: TileMode.clamp,
        ),
      );
    }

    _filtersFor = key;
    return _filters = [
      layer(widget.sigma * 0.35, 0.2, 1),
      layer(widget.sigma, 0.08, 0.66),
    ];
  }

  List<Widget> _strips() {
    const count = 6;
    final strip = widget.height * 0.8 / count;
    return [
      for (var i = 0; i < count; i++)
        Positioned(
          left: 0,
          right: 0,
          top: widget.top ? strip * i : widget.height - strip * (i + 1),
          height: strip + 0.5,
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: widget.sigma * (1 - i / count) * 0.7,
                sigmaY: widget.sigma * (1 - i / count) * 0.7,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final tone = Theme.of(context).colorScheme.surface;
    final program = _program;
    final glass = context.select<SettingsController, bool>(
      (settings) => settings.glassEffects,
    );
    return IgnorePointer(
      child: SizedBox(
        height: widget.height,
        child: Stack(
          children: [
            if (!glass)
              const SizedBox.shrink()
            else if (program != null)
              for (final filter
                  in _layers(program, MediaQuery.devicePixelRatioOf(context)))
                Positioned.fill(
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: filter,
                      child: const SizedBox.expand(),
                    ),
                  ),
                )
            else
              ..._strips(),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: widget.top
                        ? Alignment.topCenter
                        : Alignment.bottomCenter,
                    end: widget.top
                        ? Alignment.bottomCenter
                        : Alignment.topCenter,
                    colors: [
                      for (final alpha in const [0.82, 0.62, 0.38, 0.17, 0.05, 0.0])
                        tone.withValues(alpha: alpha * widget.shade),
                    ],
                    stops: const [0, 0.2, 0.42, 0.64, 0.84, 1],
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

class HeaderBlur extends StatelessWidget {
  const HeaderBlur({super.key, required this.scrolled, this.height});

  final ValueListenable<bool> scrolled;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final height = this.height ?? MediaQuery.paddingOf(context).top + 28;
    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      child: ValueListenableBuilder<bool>(
        valueListenable: scrolled,
        builder: (context, on, _) => AnimatedOpacity(
          opacity: on ? 1 : 0,
          duration: const Duration(milliseconds: 220),
          child: EdgeBlur(height: height, sigma: 14),
        ),
      ),
    );
  }
}
