import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/extensions/inset_extensions.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/routing/app_navigator.dart';
import 'package:streak/core/widgets/app_empty_state.dart';
import 'package:streak/core/widgets/section_label.dart';
import 'package:streak/features/settings/state/settings_controller.dart';
import 'package:streak/features/settings/widgets/minimal_settings_widgets.dart';
import 'package:streak/features/settings/widgets/settings_rows.dart';

class QuotesPage extends StatelessWidget {
  const QuotesPage({super.key});

  List<String> _sourceLabels(BuildContext context) => [
        context.l10n.quotes_app,
        context.l10n.quotes_mine,
        context.l10n.quotes_both,
      ];

  Future<void> _add(BuildContext context) async {
    final text = await _askQuote(context, title: context.l10n.quotes_add);
    if (text == null || !context.mounted) return;
    await context.read<SettingsController>().addCustomQuote(text);
  }

  Future<void> _edit(BuildContext context, int index, String current) async {
    final text = await _askQuote(
      context,
      title: context.l10n.quotes_edit,
      initial: current,
    );
    if (text == null || !context.mounted) return;
    await context.read<SettingsController>().editCustomQuote(index, text);
  }

  Future<String?> _askQuote(
    BuildContext context, {
    required String title,
    String initial = '',
  }) =>
      showDialog<String>(
        context: context,
        builder: (_) => _QuoteDialog(title: title, initial: initial),
      );

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final quotes = settings.customQuotes;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => AppNavigator.pop(),
        ),
        title: Text(context.l10n.quotes),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context),
        icon: const Icon(LucideIcons.plus, size: 20),
        label: Text(context.l10n.quotes_add),
      ),
      body: ListView(
        padding: context.pagePadding(16, 12, 16, 96),
        children: [
          Card(
            child: NavRow(
              icon: LucideIcons.sparkles,
              title: context.l10n.quotes_which,
              subtitle: _sourceLabels(context)[settings.quoteSource],
              onTap: () => showOptionSheet(
                context,
                title: context.l10n.quotes_which,
                options: _sourceLabels(context),
                index: settings.quoteSource,
                onSelected: settings.setQuoteSource,
              ),
            ),
          ),
          const SizedBox(height: 24),
          SectionLabel(context.l10n.quotes_my_list),
          if (quotes.isEmpty)
            AppEmptyState(
              icon: LucideIcons.quote,
              title: context.l10n.quotes_empty,
              message: context.l10n.quotes_empty_sub,
            )
          else
            for (var i = 0; i < quotes.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _QuoteTile(
                  text: quotes[i],
                  onEdit: () => _edit(context, i, quotes[i]),
                  onDelete: () =>
                      context.read<SettingsController>().removeCustomQuote(i),
                ),
              ),
        ],
      ),
    );
  }
}

class _QuoteTile extends StatelessWidget {
  const _QuoteTile({
    required this.text,
    required this.onEdit,
    required this.onDelete,
  });

  final String text;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onEdit,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        decoration: BoxDecoration(
          color: context.colors.surfaceContainerHighest.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: context.colors.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: context.l10n.delete,
              icon: Icon(
                LucideIcons.trash2,
                size: 19,
                color: context.tokens.danger,
              ),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuoteDialog extends StatefulWidget {
  const _QuoteDialog({required this.title, required this.initial});

  final String title;
  final String initial;

  @override
  State<_QuoteDialog> createState() => _QuoteDialogState();
}

class _QuoteDialogState extends State<_QuoteDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() => Navigator.of(context).pop(_controller.text);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLines: 3,
        minLines: 1,
        maxLength: 140,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(hintText: context.l10n.quotes_hint),
        onSubmitted: (_) => _save(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.cancel),
        ),
        TextButton(onPressed: _save, child: Text(context.l10n.save)),
      ],
    );
  }
}
