import 'package:flutter/material.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/utils/responsive.dart';
import 'package:streak/core/widgets/sheet_type.dart';

class BriefRows extends InheritedWidget {
  const BriefRows({super.key, required super.child});

  static bool on(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<BriefRows>() != null;

  @override
  bool updateShouldNotify(BriefRows oldWidget) => false;
}

class SheetNote {
  const SheetNote._();

  static String? _next;

  static VoidCallback? wrap(String? note, VoidCallback? onTap) {
    if (onTap == null || note == null) return onTap;
    return () {
      _next = note;
      try {
        onTap();
      } finally {
        _next = null;
      }
    };
  }

  static String? take() {
    final note = _next;
    _next = null;
    return note;
  }
}

Widget sheetNote(BuildContext context, String note) => Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 6),
      child: Text(note, style: sheetBodyStyle(context, size: 14.5)),
    );

class SettingInfo extends StatefulWidget {
  const SettingInfo({
    super.key,
    required this.icon,
    required this.title,
    required this.text,
    required this.control,
    required this.builder,
  });

  final IconData icon;
  final String title;
  final String text;
  final Widget control;
  final Widget Function(BuildContext context, VoidCallback open) builder;

  @override
  State<SettingInfo> createState() => _SettingInfoState();
}

class _SettingInfoState extends State<SettingInfo> {
  late final _live = ValueNotifier<Widget>(widget.control);

  @override
  void didUpdateWidget(SettingInfo oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.control;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _live.value = next;
    });
  }

  @override
  void dispose() {
    _live.dispose();
    super.dispose();
  }

  void _open() {
    final accent = context.colors.primary;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: phoneWidth),
      builder: (sheet) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(widget.icon, size: 19, color: accent),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(widget.title, style: sheetTitleStyle(sheet)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(widget.text, style: sheetBodyStyle(sheet, size: 14.5)),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.fromLTRB(18, 12, 14, 12),
                decoration: BoxDecoration(
                  color: sheet.colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: sheetHeadingStyle(sheet),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: ValueListenableBuilder<Widget>(
                            valueListenable: _live,
                            builder: (context, control, _) => control,
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _open);
}
