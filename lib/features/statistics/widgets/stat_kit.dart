import 'package:flutter/material.dart';
import 'package:streak/app/theme/app_tokens.dart';

TextStyle statNumber(BuildContext context, double size, {Color? color}) =>
    TextStyle(
      fontFamily: 'Figtree',
      fontSize: size,
      fontWeight: FontWeight.w900,
      height: 1,
      letterSpacing: size * -0.04,
      color: color ?? context.colors.onSurface,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

TextStyle statLabel(BuildContext context) => TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: context.tokens.muted,
    );

class AnimatedStatNumber extends StatelessWidget {
  const AnimatedStatNumber({super.key, required this.value, this.style});

  final String value;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final numeric = double.tryParse(value);
    if (numeric == null) {
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
        builder: (context, t, child) => Opacity(opacity: t, child: child),
        child: Text(value, style: style),
      );
    }
    final decimals = value.contains('.') ? 1 : 0;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: numeric),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) =>
          Text(v.toStringAsFixed(decimals), style: style),
    );
  }
}

class StatReveal extends StatefulWidget {
  const StatReveal({super.key, required this.child});

  final Widget child;

  @override
  State<StatReveal> createState() => _StatRevealState();
}

class _StatRevealState extends State<StatReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );

  ScrollPosition? _position;
  bool _shown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _position?.removeListener(_check);
    _position = Scrollable.maybeOf(context)?.position;
    _position?.addListener(_check);
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void dispose() {
    _position?.removeListener(_check);
    _controller.dispose();
    super.dispose();
  }

  void _check() {
    if (_shown || !mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    if (box.localToGlobal(Offset.zero).dy >
        MediaQuery.sizeOf(context).height * 0.92) {
      return;
    }
    setState(() => _shown = true);
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeOutCubic.transform(_controller.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 22),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(key: ValueKey(_shown), child: widget.child),
    );
  }
}

class DotField extends StatelessWidget {
  const DotField({super.key, required this.child, this.spacing = 14});

  final Widget child;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _DotFieldPainter(
              color: context.tokens.muted.withValues(alpha: 0.22),
              spacing: spacing,
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _DotFieldPainter extends CustomPainter {
  const _DotFieldPainter({required this.color, required this.spacing});

  final Color color;
  final double spacing;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (var y = spacing / 2; y < size.height; y += spacing) {
      for (var x = spacing / 2; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), 0.9, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotFieldPainter old) =>
      old.color != color || old.spacing != spacing;
}

class MiniStat extends StatelessWidget {
  const MiniStat({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 10),
          AnimatedStatNumber(value: value, style: statNumber(context, 22)),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: statLabel(context),
          ),
        ],
      ),
    );
  }
}
