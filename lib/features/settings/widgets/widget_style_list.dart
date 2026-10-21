import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:streak/core/i18n/l10n.dart';

class WidgetStyleList extends StatelessWidget {
  const WidgetStyleList({super.key});

  static const _channel = MethodChannel('streak/app_icon');
  static const _kinds = ['habit', 'today', 'stats', 'heatmap', 'todos', 'focus'];

  static String _name(BuildContext context, String kind) => switch (kind) {
    'today' => context.l10n.widget_kind_today,
    'stats' => context.l10n.widget_kind_stats,
    'heatmap' => context.l10n.widget_kind_heatmap,
    'todos' => context.l10n.widget_kind_todos,
    'focus' => context.l10n.widget_kind_focus,
    _ => context.l10n.widget_kind_habit,
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final kind in _kinds)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _WidgetTile(kind: kind, name: _name(context, kind)),
          ),
      ],
    );
  }
}

class _WidgetTile extends StatefulWidget {
  const _WidgetTile({required this.kind, required this.name});

  final String kind;
  final String name;

  @override
  State<_WidgetTile> createState() => _WidgetTileState();
}

class _WidgetTileState extends State<_WidgetTile> {
  late final _preview = WidgetStyleList._channel.invokeMethod<Uint8List>(
    'widgetPreview',
    {'kind': widget.kind},
  );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => WidgetStyleList._channel.invokeMethod(
          'openWidgetEditor',
          {'kind': widget.kind},
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 132,
                child: FutureBuilder<Uint8List?>(
                  future: _preview,
                  builder: (context, shot) {
                    final bytes = shot.data;
                    if (bytes == null) return const SizedBox.shrink();
                    return Image.memory(
                      bytes,
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Icon(LucideIcons.pencil, size: 18, color: scheme.primary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
