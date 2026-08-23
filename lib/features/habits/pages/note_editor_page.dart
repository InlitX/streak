import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/extensions/inset_extensions.dart';
import 'package:streak/core/express/express_button.dart';
import 'package:streak/core/minimal/minimal_kit.dart';
import 'package:streak/core/widgets/sheet_type.dart';
import 'package:streak/core/express/express_shapes.dart';
import 'package:streak/core/express/express_type.dart';
import 'package:streak/core/express/express_surface.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/routing/app_navigator.dart';
import 'package:streak/core/utils/cover_storage.dart';
import 'package:streak/core/widgets/photo_deck.dart';
import 'package:streak/core/widgets/photo_viewer.dart';
import 'package:streak/features/habits/data/habit_note.dart';
import 'package:streak/features/habits/state/notes_controller.dart';
import 'package:streak/features/habits/widgets/express_form_kit.dart';
import 'package:streak/features/settings/state/settings_controller.dart';
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

  Future<void> _addPhoto({bool fromCamera = false}) async {
    final path = await CoverStorage.store(
      folder: 'journey',
      fromCamera: fromCamera,
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
    final style = context.watch<SettingsController>().appStyle;
    final express = style == 2;
    final minimal = style == 1;
    final title = widget.note == null
        ? context.l10n.add_note
        : context.l10n.edit_note;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      excludeFromSemantics: true,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: express ? 60 : (minimal ? 52 : null),
          leadingWidth: express ? 68 : null,
          title: express || minimal
              ? null
              : Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
          leading: express
              ? Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Center(child: ExpressIconButton(
                    icon: LucideIcons.arrowLeft,
                    onPressed: () => AppNavigator.pop(),
                  )),
                )
              : IconButton(
                  icon: const Icon(LucideIcons.arrowLeft),
                  onPressed: () => AppNavigator.pop(),
                ),
          actions: [
            if (!express)
              TextButton(
                onPressed: _canSave ? _save : null,
                child: Text(
                  context.l10n.save,
                  style: sheetActionStyle(context, size: 16),
                ),
              ),
            const SizedBox(width: 8),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: express
            ? ExpressSaveBar(
                label: context.l10n.save,
                onPressed: _canSave ? _save : null,
              )
            : null,
        body: ListView(
          padding: context.pagePadding(
            minimal ? 22 : 16,
            8,
            minimal ? 22 : 16,
            express ? 120 : 24,
          ),
          children: [
            if (minimal) MinimalTitle(title: title),
            if (express) ...[
              ExpressHeadline(
                title: widget.note == null
                    ? context.l10n.add_note
                    : context.l10n.edit_note,
              ),
              const SizedBox(height: 20),
            ],
            _Label(context.l10n.note_type),
            NoteTypeChips(
              selected: _type,
              onChanged: (t) => setState(() => _type = t),
            ),
            const SizedBox(height: 22),
            _Label(context.l10n.notes),
            Container(
              decoration: BoxDecoration(
                color: minimal
                    ? minimalSurface(context)
                    : context.colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(minimal ? 20 : 16),
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
              onCamera: () => _addPhoto(fromCamera: true),
              onGallery: () => _addPhoto(),
              onRemove: (path) => setState(() => _photos.remove(path)),
            ),
            const SizedBox(height: 22),
            _Label(context.l10n.note_time_optional),
            Semantics(
              button: true,
              child: GestureDetector(
                onTap: _pickTime,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
                  decoration: BoxDecoration(
                    color: minimal
                        ? minimalSurface(context)
                        : context.colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(minimal ? 20 : 16),
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
                          style: sheetOptionStyle(
                            context,
                            size: 15,
                            color: _time == null ? muted : null,
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
            ),
            const SizedBox(height: 28),
            if (!express)
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
                  style: sheetActionStyle(
                    context,
                    size: 16,
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
    return Row(
      children: [
        _AddTile(
          icon: LucideIcons.camera,
          label: context.l10n.note_take_photo,
          accent: accent,
          onTap: onCamera,
        ),
        const SizedBox(width: 10),
        _AddTile(
          icon: LucideIcons.image,
          label: context.l10n.note_pick_photo,
          accent: accent,
          onTap: onGallery,
        ),
        if (photos.isNotEmpty) ...[
          const Spacer(),
          PhotoDeck(
            shots: [for (final path in photos) PhotoShot(path: path)],
            onRemove: (index) => onRemove(photos[index]),
          ),
        ],
      ],
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({
    required this.icon,
    required this.label,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final express = context.watch<SettingsController>().isExpressStyle;
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: express ? null : onTap,
        child: express
            ? ExpressSquish(
                onTap: onTap,
                child: Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ExpressBlob(
                        size: 36,
                        color: accent.withValues(alpha: 0.22),
                        shape: ExpressShape.cookie,
                        child: Icon(icon, size: 17, color: accent),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ExpressType.body.at(
                          11,
                          weight: 800,
                          color: accent,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : Container(
                width: 88,
                height: 88,
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
          style: context.watch<SettingsController>().isExpressStyle
              ? ExpressType.headline.at(
                  15,
                  weight: 800,
                  color: context.colors.primary,
                )
              : sheetLabelStyle(context),
        ),
      );
}
