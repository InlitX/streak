import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/utils/responsive.dart';
import 'package:streak/core/widgets/sheet_type.dart';
import 'package:streak/services/reminder_sounds.dart';

const defaultReminderSound = ReminderSound('', '');

Future<void> pickReminderSound(
  BuildContext context, {
  required String uri,
  required ValueChanged<ReminderSound> onChanged,
}) async {
  final sounds = await ReminderSounds.list();
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    constraints: BoxConstraints(
      maxWidth: phoneWidth,
      maxHeight: MediaQuery.sizeOf(context).height * 0.85,
    ),
    builder: (sheet) => _SoundSheet(
      sounds: sounds,
      initial: uri,
      onChanged: onChanged,
    ),
  );
  await ReminderSounds.stop();
}

class _SoundSheet extends StatefulWidget {
  const _SoundSheet({
    required this.sounds,
    required this.initial,
    required this.onChanged,
  });

  final List<ReminderSound> sounds;
  final String initial;
  final ValueChanged<ReminderSound> onChanged;

  @override
  State<_SoundSheet> createState() => _SoundSheetState();
}

class _SoundSheetState extends State<_SoundSheet> {
  late String _uri = widget.initial;

  void _choose(ReminderSound sound) {
    setState(() => _uri = sound.uri);
    ReminderSounds.play(sound.uri);
    widget.onChanged(sound);
  }

  @override
  Widget build(BuildContext context) {
    final options = [defaultReminderSound, ...widget.sounds];
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 4, 22, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n.reminder_sound, style: sheetTitleStyle(context)),
            const SizedBox(height: 4),
            Text(
              context.l10n.reminder_sound_hint,
              style: TextStyle(color: context.tokens.muted, fontSize: 13),
            ),
            const SizedBox(height: 10),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, i) => _SoundRow(
                  label: options[i].uri.isEmpty
                      ? context.l10n.reminder_sound_default
                      : options[i].title,
                  selected: options[i].uri == _uri,
                  onTap: () => _choose(options[i]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoundRow extends StatelessWidget {
  const _SoundRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = context.colors.primary;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              Icon(
                selected ? LucideIcons.volume2 : LucideIcons.music2,
                size: 18,
                color: selected ? accent : context.tokens.muted,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: sheetOptionStyle(
                    context,
                    selected: selected,
                    color: selected ? accent : null,
                  ),
                ),
              ),
              if (selected) Icon(LucideIcons.check, size: 18, color: accent),
            ],
          ),
        ),
      ),
    );
  }
}

class ReminderSoundRow extends StatelessWidget {
  const ReminderSoundRow({
    super.key,
    required this.name,
    required this.onTap,
    this.compact = false,
  });

  final String name;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final value = name.isEmpty ? context.l10n.reminder_sound_default : name;
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: compact
              ? const EdgeInsets.fromLTRB(14, 12, 12, 12)
              : const EdgeInsets.fromLTRB(16, 15, 14, 15),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(compact ? 13 : 16),
          ),
          child: Row(
            children: [
              Icon(
                LucideIcons.music2,
                size: compact ? 16 : 18,
                color: compact ? context.tokens.muted : scheme.primary,
              ),
              SizedBox(width: compact ? 11 : 12),
              Text(
                context.l10n.reminder_sound,
                style: sheetHeadingStyle(context, size: compact ? 14 : 15),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: context.tokens.muted,
                    fontSize: compact ? 13 : 14,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                LucideIcons.chevronRight,
                size: 16,
                color: context.tokens.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
