import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/routing/app_navigator.dart';
import 'package:streak/core/utils/cover_storage.dart';
import 'package:streak/features/habits/data/habit_note.dart';
import 'package:streak/features/habits/state/notes_controller.dart';
import 'package:streak/features/habits/widgets/note_widgets.dart';

const _kMaxLength = 500;

class NoteEditorPage extends StatefulWidget {
  const NoteEditorPage({
    super.key,
    required this.habitId,
    required this.dayKey,
    required this.accent,
    this.note,
  });

  final String habitId;
  final String dayKey;
  final Color accent;
  final HabitNote? note;

  @override
  State<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<NoteEditorPage> {
  late final TextEditingController _text =
      TextEditingController(text: widget.note?.text ?? '');
  late NoteType _type = widget.note?.type ?? NoteType.note;
  late TimeOfDay? _time = widget.note?.time;
  late final List<String> _photos = [...?widget.note?.photos];

  bool get _canSave => _text.text.trim().isNotEmpty;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _addPhoto(ImageSource source) async {
    final path = await CoverStorage.store(
      folder: 'journey',
      source: source,
      maxWidth: 1600,
      quality: 85,
    );
    if (path != null && mounted) setState(() => _photos.add(path));
  }

  Future<void> _save() async {
    final notes = context.read<NotesController>();
    final minutes = _time == null ? null : _time!.hour * 60 + _time!.minute;
    final existing = widget.note;
    if (existing == null) {
      await notes.create(
        habitId: widget.habitId,
        dayKey: widget.dayKey,
        type: _type,
        text: _text.text,
        minutes: minutes,
        photos: _photos,
      );
    } else {
      await notes.update(
        existing.copyWith(
          type: _type,
          text: _text.text.trim(),
          minutes: minutes,
          photos: _photos,
          clearMinutes: minutes == null,
        ),
      );
    }
    AppNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final muted = context.tokens.muted;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.note == null ? context.l10n.add_note : context.l10n.edit_note,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft),
            onPressed: () => AppNavigator.pop(),
          ),
          actions: [
            TextButton(
              onPressed: _canSave ? _save : null,
              child: Text(
                context.l10n.save,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _Label(context.l10n.note_type),
              NoteTypeChips(
                selected: _type,
                onChanged: (t) => setState(() => _type = t),
              ),
              const SizedBox(height: 22),
              _Label(context.l10n.notes),
              Container(
                decoration: BoxDecoration(
                  color: context.colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    TextField(
                      controller: _text,
                      autofocus: widget.note == null,
                      maxLines: 5,
                      maxLength: _kMaxLength,
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: (_) => setState(() {}),
                      buildCounter: (_,
                              {required currentLength,
                              required isFocused,
                              maxLength}) =>
                          null,
                      style: TextStyle(
                        fontSize: 15.5,
                        height: 1.4,
                        color: context.colors.onSurface,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: context.l10n.note_hint,
                        hintStyle: TextStyle(color: muted, fontSize: 15.5),
                      ),
                    ),
                    Text(
                      '${_text.text.characters.length}/$_kMaxLength',
                      style: TextStyle(fontSize: 11.5, color: muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              _Label(context.l10n.note_photos),
              _PhotoStrip(
                photos: _photos,
                accent: widget.accent,
                onCamera: () => _addPhoto(ImageSource.camera),
                onGallery: () => _addPhoto(ImageSource.gallery),
                onRemove: (path) => setState(() => _photos.remove(path)),
              ),
              const SizedBox(height: 22),
              _Label(context.l10n.note_time_optional),
              GestureDetector(
                onTap: _pickTime,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
                  decoration: BoxDecoration(
                    color: context.colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(LucideIcons.clock, size: 18, color: muted),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _time == null
                              ? context.l10n.note_time_optional
                              : _time!.format(context),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _time == null
                                ? muted
                                : context.colors.onSurface,
                          ),
                        ),
                      ),
                      if (_time != null)
                        IconButton(
                          icon: Icon(LucideIcons.x, size: 18, color: muted),
                          onPressed: () => setState(() => _time = null),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _canSave ? _save : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: widget.accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    context.l10n.save_note,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: widget.accent.computeLuminance() > 0.6
                          ? Colors.black
                          : Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoStrip extends StatelessWidget {
  const _PhotoStrip({
    required this.photos,
    required this.accent,
    required this.onCamera,
    required this.onGallery,
    required this.onRemove,
  });

  final List<String> photos;
  final Color accent;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _AddTile(
            icon: LucideIcons.camera,
            label: context.l10n.note_take_photo,
            onTap: onCamera,
          ),
          const SizedBox(width: 10),
          _AddTile(
            icon: LucideIcons.image,
            label: context.l10n.note_pick_photo,
            onTap: onGallery,
          ),
          for (final path in photos) ...[
            const SizedBox(width: 10),
            Stack(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: context.colors.surfaceContainerHighest,
                  ),
                  child: File(path).existsSync()
                      ? Image.file(File(path), fit: BoxFit.cover)
                      : null,
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => onRemove(path),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.6),
                      ),
                      child: const Icon(
                        LucideIcons.x,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          color: context.colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: context.tokens.muted),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: context.tokens.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 2, bottom: 10),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: context.tokens.muted,
          ),
        ),
      );
}
