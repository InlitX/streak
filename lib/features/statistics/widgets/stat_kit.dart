import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/features/settings/state/settings_controller.dart';
import 'package:streak/app/theme/app_theme.dart';

TextStyle statNumber(BuildContext context, double size, {Color? color}) =>
    TextStyle(
      fontFamily: AppTheme.isClassic(context) ? AppTheme.classicFont : 'Figtree',
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
      tween: Tween(begin: 0.92, end: 1),
      duration: const Duration(milliseconds: 620),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) => Transform.scale(
        scale: scale,
        child: child,
      ),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: numeric),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutCubic,
        builder: (context, v, _) =>
            Text(v.toStringAsFixed(decimals), style: style),
      ),
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

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final titleSize = MediaQuery.textScalerOf(context).scale(16);
    final titleLines = titleSize > 19 ? 3 : 2;
    final titleHeight = titleSize * 1.25 * titleLines;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: titleHeight > 44 ? titleHeight : 44,
              child: _StatHeader(
                title: title,
                icon: icon,
                color: color,
                lines: titleLines,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _StatHeader extends StatelessWidget {
  const _StatHeader({
    required this.title,
    required this.icon,
    required this.color,
    required this.lines,
  });

  final String title;
  final IconData icon;
  final Color color;
  final int lines;

  @override
  Widget build(BuildContext context) {
    final textColor = context.colors.onSurface;
    final scale = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    final base = DefaultTextStyle.of(context).style;
    TextStyle style(double size) => TextStyle(
          fontSize: size,
          height: 1.25,
          fontWeight: FontWeight.w800,
          color: textColor,
        );
    bool fits(double size, double width) {
      final painter = TextPainter(
        text: TextSpan(text: title, style: base.merge(style(size))),
        maxLines: lines,
        textDirection: direction,
        textScaler: scale,
      )..layout(maxWidth: width);
      var ok = !painter.didExceedMaxLines;
      for (final word in title.split(' ')) {
        if (!ok) break;
        painter
          ..text = TextSpan(text: word, style: base.merge(style(size)))
          ..maxLines = 1
          ..layout();
        ok = painter.width <= width;
      }
      painter.dispose();
      return ok;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final withIcon = fits(16, width - 44);
        var size = 16.0;
        while (!withIcon && size > 10 && !fits(size, width)) {
          size -= 1;
        }
        final text = Text(
          title,
          maxLines: lines,
          overflow: TextOverflow.ellipsis,
          style: style(size),
        );
        if (!withIcon) return text;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: text),
            const SizedBox(width: 8),
            StatIconSquare(icon: icon, color: color),
          ],
        );
      },
    );
  }
}

class StatIconSquare extends StatelessWidget {
  const StatIconSquare({super.key, required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final minimal = context.watch<SettingsController>().isMinimalStyle;
    final tint = minimal ? context.tokens.muted : color;
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: minimal ? 0.10 : 0.16),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: tint, size: 18),
    );
  }
}

class MiniStat extends StatelessWidget {
  const MiniStat({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    this.unit,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final String? unit;

  @override
  Widget build(BuildContext context) {
    final classic = context.watch<SettingsController>().appStyle == 0;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: classic
          ? BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(20),
              border: Border.fromBorderSide(AppTheme.cardEdge(dark)),
              boxShadow: [
                if (!dark)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
              ],
            )
          : BoxDecoration(
              color:
                  context.colors.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (classic)
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 15, color: color),
            )
          else
            Icon(icon, size: 16, color: color),
          const SizedBox(height: 10),
          _StatValue(value: value, unit: unit),
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

class _StatValue extends StatelessWidget {
  const _StatValue({required this.value, required this.unit});

  final String value;
  final String? unit;

  @override
  Widget build(BuildContext context) {
    final unit = this.unit;
    if (unit == null || unit.isEmpty) {
      return AnimatedStatNumber(value: value, style: statNumber(context, 22));
    }
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          AnimatedStatNumber(value: value, style: statNumber(context, 22)),
          const SizedBox(width: 4),
          Text(
            unit,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: context.tokens.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class StatPair extends StatelessWidget {
  const StatPair({super.key, required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: left),
          const SizedBox(width: 12),
          Expanded(child: right),
        ],
      ),
    );
  }
}
