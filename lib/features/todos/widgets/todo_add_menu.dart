import 'package:flutter/material.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/widgets/sheet_type.dart';

typedef TodoAddOption = ({IconData icon, String label});

Future<int?> showTodoAddMenu(
  BuildContext context, {
  required Rect anchor,
  required List<TodoAddOption> options,
}) =>
    showGeneralDialog<int>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).closeButtonLabel,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (menu, animation, _) => _AddMenu(
        anchor: anchor,
        options: options,
        animation: animation,
      ),
    );

class _AddMenu extends StatelessWidget {
  const _AddMenu({
    required this.anchor,
    required this.options,
    required this.animation,
  });

  final Rect anchor;
  final List<TodoAddOption> options;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final count = options.length;
    return Stack(
      children: [
        Positioned(
          right: screen.width - anchor.right,
          bottom: screen.height - anchor.top + 12,
          left: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final (index, option) in options.indexed) ...[
                if (index > 0) const SizedBox(height: 10),
                _Pill(
                  option: option,
                  animation: CurvedAnimation(
                    parent: animation,
                    curve: Interval(
                      0.12 * (count - 1 - index),
                      1,
                      curve: Curves.easeOutCubic,
                    ),
                    reverseCurve: Curves.easeInCubic,
                  ),
                  onTap: () => Navigator.of(context).pop(index),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.option,
    required this.animation,
    required this.onTap,
  });

  final TodoAddOption option;
  final Animation<double> animation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.4),
          end: Offset.zero,
        ).animate(animation),
        child: Material(
          color: scheme.surfaceContainerHighest,
          elevation: 6,
          shadowColor: Colors.black.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 13, 20, 13),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(option.icon, size: 20, color: scheme.onSurface),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      option.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: sheetOptionStyle(context, selected: true),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
