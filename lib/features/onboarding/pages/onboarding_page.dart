import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/widgets/entrance.dart';
import 'package:streak/features/settings/state/settings_controller.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  static const _last = 3;

  final _controller = PageController();
  int _page = 0;

  void _go(int page) {
    _controller.animateToPage(
      page,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  void _finish() => context.read<SettingsController>().completeOnboarding();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minimal = context.watch<SettingsController>().isMinimalStyle;
    final accent = minimal ? context.colors.onSurface : context.colors.primary;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(child: _Glow(accent: accent)),
          SafeArea(
            child: Column(
              children: [
                _TopBar(
                  page: _page,
                  last: _last,
                  accent: accent,
                  onSkip: _finish,
                ),
                Expanded(
                  child: PageView(
                    controller: _controller,
                    onPageChanged: (page) => setState(() => _page = page),
                    children: [
                      _Welcome(accent: accent),
                      _Step(
                        step: 1,
                        last: _last,
                        title: l10n.onb1_title,
                        body: l10n.onb1_body,
                        child: _StreakPreview(accent: accent),
                      ),
                      _Step(
                        step: 2,
                        last: _last,
                        title: l10n.onb2_title,
                        body: l10n.onb2_body,
                        child: _GridPreview(accent: accent),
                      ),
                      _Step(
                        step: 3,
                        last: _last,
                        title: l10n.onb3_title,
                        body: l10n.onb3_body,
                        child: _BarsPreview(accent: accent),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 22),
                  child: Row(
                    children: [
                      AnimatedSize(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOutCubic,
                        child: _page == 0
                            ? const SizedBox.shrink()
                            : Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: _BackButton(onTap: () => _go(_page - 1)),
                              ),
                      ),
                      Expanded(
                        child: SizedBox(
                          height: 56,
                          child: FilledButton(
                            onPressed: () =>
                                _page == _last ? _finish() : _go(_page + 1),
                            style: FilledButton.styleFrom(
                              backgroundColor: accent,
                              foregroundColor: minimal
                                  ? context.colors.surface
                                  : context.colors.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: Text(
                              _page == _last ? l10n.get_started : l10n.next,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.page,
    required this.last,
    required this.accent,
    required this.onSkip,
  });

  final int page;
  final int last;
  final Color accent;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 12, 0),
      child: Row(
        children: [
          for (var i = 0; i <= last; i++)
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.only(right: 6),
                height: 3,
                decoration: BoxDecoration(
                  color: i <= page
                      ? accent
                      : context.tokens.muted.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          TextButton(
            onPressed: onSkip,
            child: Text(
              context.l10n.skip,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.tokens.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: MaterialLocalizations.of(context).backButtonTooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: context.colors.surfaceContainerHighest,
            shape: BoxShape.circle,
          ),
          child: Icon(
            LucideIcons.arrowLeft,
            size: 20,
            color: context.colors.onSurface,
          ),
        ),
      ),
    );
  }
}

class _Page extends StatelessWidget {
  const _Page({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: box.maxHeight - 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (index, child) in children.indexed)
                child is SizedBox
                    ? child
                    : Entrance(index: index, offset: 22, child: child),
            ],
          ),
        ),
      ),
    );
  }
}

TextStyle _kicker(BuildContext context) => TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.4,
      color: context.tokens.muted,
    );

class _Welcome extends StatelessWidget {
  const _Welcome({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _Page(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.32),
                  blurRadius: 36,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: Image.asset('assets/icon.png', width: 92, height: 92),
            ),
          ),
        ),
        const SizedBox(height: 28),
        Text(l10n.onb_kicker.toUpperCase(), style: _kicker(context)),
        const SizedBox(height: 6),
        Text(
          'Streak',
          style: TextStyle(
            fontSize: 46,
            height: 1,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.2,
            color: context.colors.onSurface,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          l10n.onb_blurb,
          style: TextStyle(
            fontSize: 15.5,
            height: 1.5,
            color: context.tokens.muted,
          ),
        ),
        const SizedBox(height: 26),
        _Promises(
          rows: [
            (LucideIcons.gift, l10n.onb_free_title, l10n.onb_free_body),
            (LucideIcons.shieldCheck, l10n.onb_private_title, l10n.onb_private_body),
            (LucideIcons.hardDriveDownload, l10n.onb_yours_title, l10n.onb_yours_body),
          ],
        ),
      ],
    );
  }
}

class _Promises extends StatelessWidget {
  const _Promises({required this.rows});

  final List<(IconData, String, String)> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          for (final (index, (icon, title, body)) in rows.indexed) ...[
            if (index > 0)
              Divider(
                height: 1,
                indent: 52,
                endIndent: 16,
                color: context.tokens.muted.withValues(alpha: 0.16),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 1, right: 16),
                    child: Icon(icon, size: 20, color: context.tokens.muted),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: context.colors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          body,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: context.tokens.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.step,
    required this.last,
    required this.title,
    required this.body,
    required this.child,
  });

  final int step;
  final int last;
  final String title;
  final String body;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _Page(
      children: [
        Text(
          context.l10n.onb_step(step, last).toUpperCase(),
          style: _kicker(context),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 32,
            height: 1.1,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
            color: context.colors.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          body,
          style: TextStyle(
            fontSize: 15,
            height: 1.5,
            color: context.tokens.muted,
          ),
        ),
        const SizedBox(height: 30),
        Container(
          height: 190,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: context.colors.surfaceContainerHighest.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(26),
          ),
          child: child,
        ),
      ],
    );
  }
}

class _Grow extends StatelessWidget {
  const _Grow({required this.index, required this.builder});

  final int index;
  final Widget Function(double value) builder;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 520 + index * 70),
      curve: Interval(
        (index * 70) / (520 + index * 70),
        1,
        curve: Curves.easeOutBack,
      ),
      builder: (context, value, _) => builder(value),
    );
  }
}

class _StreakPreview extends StatelessWidget {
  const _StreakPreview({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    final onAccent = ThemeData.estimateBrightnessForColor(accent) ==
            Brightness.dark
        ? Colors.white
        : Colors.black;
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(LucideIcons.flame, size: 30, color: accent),
            const SizedBox(width: 8),
            Text(
              context.l10n.count_days(12),
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: context.colors.onSurface,
              ),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var i = 0; i < 7; i++)
              _Grow(
                index: i,
                builder: (value) => Transform.scale(
                  scale: value.clamp(0.0, 1.2),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i < 5
                          ? accent
                          : context.tokens.muted.withValues(alpha: 0.14),
                      border: i == 5
                          ? Border.all(color: accent, width: 2)
                          : null,
                    ),
                    child: i < 5
                        ? Icon(LucideIcons.check, size: 18, color: onAccent)
                        : null,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _GridPreview extends StatelessWidget {
  const _GridPreview({required this.accent});

  final Color accent;

  static const _levels = [
    0, 2, 3, 1, 4, 2, 0, 3, 4, 2, 1, 3, 4, 4,
    2, 0, 3, 4, 1, 2, 4, 3, 4, 2, 4, 3, 1, 4,
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 7,
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
      childAspectRatio: 1.25,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (final (index, level) in _levels.indexed)
          _Grow(
            index: index % 7 + index ~/ 7,
            builder: (value) => Opacity(
              opacity: value.clamp(0.0, 1.0),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: level == 0
                      ? context.tokens.muted.withValues(alpha: 0.12)
                      : accent.withValues(alpha: 0.18 + level * 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _BarsPreview extends StatelessWidget {
  const _BarsPreview({required this.accent});

  final Color accent;

  static const _heights = [0.42, 0.66, 0.5, 0.86, 0.62, 0.78, 1.0];

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final (index, height) in _heights.indexed) ...[
          if (index > 0) const SizedBox(width: 10),
          Expanded(
            child: _Grow(
              index: index,
              builder: (value) => FractionallySizedBox(
                heightFactor: (height * value).clamp(0.02, 1.0),
                alignment: Alignment.bottomCenter,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: index == _heights.length - 1
                        ? accent
                        : accent.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0.95, -0.9),
            radius: 1.1,
            colors: [
              accent.withValues(alpha: 0.16),
              accent.withValues(alpha: 0),
            ],
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-0.9, 0.95),
              radius: 1,
              colors: [
                accent.withValues(alpha: 0.08),
                accent.withValues(alpha: 0),
              ],
            ),
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}
