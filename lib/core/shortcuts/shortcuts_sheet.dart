import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/shortcuts/app_shortcuts.dart';
import 'package:streak/core/widgets/sheet_type.dart';

Future<void> showShortcutsSheet(NavigatorState navigator) {
  return navigator.push<void>(
    DialogRoute<void>(
      context: navigator.context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (_) => const _ShortcutsDialog(),
    ),
  );
}

typedef _Combo = List<String>;

class _Item {
  const _Item(this.label, this.combos);

  final String label;
  final List<_Combo> combos;
}

class _Group {
  const _Group(this.title, this.items);

  final String title;
  final List<_Item> items;
}

List<_Group> _groups(BuildContext context) {
  final l10n = context.l10n;
  final p = AppShortcuts.primaryLabel;
  return [
    _Group(l10n.shortcuts_group_nav, [
      _Item(l10n.shortcuts_go_tab, [
        [p, '1 - 5'],
      ]),
      _Item(l10n.shortcuts_next_tab, [
        [p, 'Tab'],
        [p, 'PgDn'],
      ]),
      _Item(l10n.shortcuts_prev_tab, [
        [p, 'Shift', 'Tab'],
        [p, 'PgUp'],
      ]),
      _Item(l10n.shortcuts_settings, [
        [p, ','],
      ]),
      _Item(l10n.shortcuts_back, [
        ['Esc'],
        ['Alt', '←'],
      ]),
      _Item(l10n.shortcuts_help, [
        ['F1'],
        [p, '/'],
      ]),
    ]),
    _Group(l10n.shortcuts_group_create, [
      _Item(l10n.shortcuts_new, [
        [p, 'N'],
      ]),
      _Item(l10n.shortcuts_new_project, [
        [p, 'Shift', 'N'],
      ]),
      _Item(l10n.shortcuts_search, [
        [p, 'F'],
      ]),
      _Item(l10n.shortcuts_save, [
        [p, 'S'],
      ]),
    ]),
    _Group(l10n.shortcuts_group_focus, [
      _Item(l10n.shortcuts_toggle, [
        ['Space'],
      ]),
      _Item(l10n.shortcuts_start, [
        [p, 'Enter'],
      ]),
    ]),
  ];
}

class _ShortcutsDialog extends StatelessWidget {
  const _ShortcutsDialog();

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final groups = _groups(context);
    final size = MediaQuery.sizeOf(context);
    return Focus(
      autofocus: true,
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
          Navigator.of(context).pop();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Dialog(
        constraints: const BoxConstraints(minWidth: 280, maxWidth: 620),
        backgroundColor: scheme.surface,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 620,
            maxHeight: size.height * 0.86,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        LucideIcons.keyboard,
                        color: scheme.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.shortcuts_title,
                            style: sheetTitleStyle(context, size: 20),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            context.l10n.shortcuts_hint(
                              'F1 · ${AppShortcuts.primaryLabel} + /',
                            ),
                            style: sheetBodyStyle(context, size: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final group in groups) ...[
                          Padding(
                            padding: const EdgeInsets.only(top: 6, bottom: 8),
                            child: Text(
                              group.title.toUpperCase(),
                              style: sheetLabelStyle(context, size: 12),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainerHighest
                                  .withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 4,
                            ),
                            child: Column(
                              children: [
                                for (final (index, item)
                                    in group.items.indexed) ...[
                                  if (index > 0)
                                    Divider(
                                      height: 1,
                                      thickness: 1,
                                      color: scheme.outlineVariant
                                          .withValues(alpha: 0.35),
                                    ),
                                  _Row(item: item),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: scheme.surfaceContainerHighest,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    context.l10n.close,
                    style: sheetActionStyle(context, color: scheme.onSurface),
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

class _Row extends StatelessWidget {
  const _Row({required this.item});

  final _Item item;

  @override
  Widget build(BuildContext context) {
    final muted = context.tokens.muted;
    final label = Text(
      item.label,
      style: sheetOptionStyle(context, size: 14),
    );
    final keys = Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 4,
      children: [
        for (final (index, combo) in item.combos.indexed) ...[
          if (index > 0) Text('·', style: TextStyle(fontSize: 20, height: 1, color: muted)),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (at, key) in combo.indexed) ...[
                if (at > 0) const SizedBox(width: 4),
                _Keycap(label: key),
              ],
            ],
          ),
        ],
      ],
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: LayoutBuilder(
        builder: (context, box) => box.maxWidth < 380
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [label, const SizedBox(height: 8), keys],
              )
            : Row(
                children: [
                  Expanded(child: label),
                  const SizedBox(width: 12),
                  Flexible(child: keys),
                ],
              ),
      ),
    );
  }
}

class _Keycap extends StatelessWidget {
  const _Keycap({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    return Container(
      constraints: const BoxConstraints(minWidth: 28),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.7),
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.18),
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
          height: 1.15,
        ),
      ),
    );
  }
}
