import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:streak/core/express/express_button.dart';
import 'package:streak/core/express/express_motion.dart';
import 'package:streak/core/express/express_surface.dart';
import 'package:streak/core/extensions/inset_extensions.dart';
import 'package:streak/core/routing/app_navigator.dart';

class ExpressReveal extends StatefulWidget {
  const ExpressReveal({
    super.key,
    this.index = 0,
    this.rise = 18,
    required this.child,
  });

  final int index;
  final double rise;
  final Widget child;

  @override
  State<ExpressReveal> createState() => _ExpressRevealState();
}

class _ExpressRevealState extends State<ExpressReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: Express.slow,
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(
      Duration(milliseconds: 45 * widget.index.clamp(0, 8)),
      () {
        if (mounted) _enter.forward();
      },
    );
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    return AnimatedBuilder(
      animation: _enter,
      builder: (context, child) {
        final settle = Express.springy.transform(_enter.value);
        return Opacity(
          opacity: _enter.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, widget.rise * (1 - settle)),
            child: Transform.scale(scale: 0.97 + 0.03 * settle, child: child),
          ),
        );
      },
      child: widget.child,
    );
  }
}

PreferredSizeWidget expressBar({
  List<Widget> actions = const [],
  VoidCallback? onBack,
  IconData icon = LucideIcons.arrowLeft,
}) {
  return AppBar(
    toolbarHeight: 60,
    leadingWidth: 68,
    leading: Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Center(
        child: ExpressIconButton(
          icon: icon,
          onPressed: onBack ?? AppNavigator.pop,
        ),
      ),
    ),
    actions: [
      for (final action in actions)
        Padding(padding: const EdgeInsets.only(right: 8), child: action),
      const SizedBox(width: 8),
    ],
  );
}

Widget expressBody({
  required String title,
  String? subtitle,
  required Widget child,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
        child: ExpressReveal(
          child: ExpressHeadline(title: title, subtitle: subtitle),
        ),
      ),
      Expanded(child: child),
    ],
  );
}

class ExpressScaffold extends StatelessWidget {
  const ExpressScaffold({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.actions = const [],
    this.leadingIcon = LucideIcons.arrowLeft,
    this.onBack,
    this.floatingActionButton,
    this.bottomPadding = 40,
    this.reveal = true,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;
  final List<Widget> actions;
  final IconData leadingIcon;
  final VoidCallback? onBack;
  final Widget? floatingActionButton;
  final double bottomPadding;
  final bool reveal;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 60,
        leadingWidth: 68,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Center(
            child: ExpressIconButton(
              icon: leadingIcon,
              onPressed: onBack ?? AppNavigator.pop,
            ),
          ),
        ),
        actions: [
          for (final action in actions)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: action,
            ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: floatingActionButton,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: context.pagePadding(18, 0, 18, bottomPadding),
            children: [
              ExpressHeadline(title: title, subtitle: subtitle),
              const SizedBox(height: 22),
              for (var i = 0; i < children.length; i++)
                reveal
                    ? ExpressReveal(index: i, child: children[i])
                    : children[i],
            ],
          ),
        ),
      ),
    );
  }
}
