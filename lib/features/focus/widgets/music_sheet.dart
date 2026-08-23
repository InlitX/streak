import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/widgets/sheet_type.dart';
import 'package:streak/core/utils/responsive.dart';
import 'package:streak/core/widgets/delete_sheet.dart';
import 'package:streak/core/utils/app_snackbar.dart';
import 'package:streak/features/focus/state/focus_audio.dart';
import 'package:streak/features/settings/state/settings_controller.dart';

List<FocusTrack> focusTracksOf(BuildContext context, SettingsController s) => [
      for (final entry in builtInTracks.entries)
        if (!s.isTrackHidden(entry.key))
          FocusTrack(id: entry.key, name: entry.value, asset: true),
      for (final raw in s.focusTracks)
        if (FocusTrack.decode(raw) != null) FocusTrack.decode(raw)!,
    ];

Future<void> showMusicSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    constraints: BoxConstraints(
      maxWidth: phoneWidth,
      maxHeight: MediaQuery.sizeOf(context).height * 0.85,
    ),
    builder: (_) => const _MusicSheet(),
  );
}

class _MusicSheet extends StatelessWidget {
  const _MusicSheet();

  Future<void> _import(BuildContext context) async {
    final settings = context.read<SettingsController>();
    if (settings.focusTracks.length >= FocusAudio.maxTracks) {
      AppSnackbar.warning(context, context.l10n.focus_track_limit);
      return;
    }
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: FocusAudio.trackExtensions,
    );
    final file = result?.files.single;
    if (file?.path == null) return;

    final minutes = await FocusAudio.durationOf(file!.path!);
    if (!context.mounted) return;
    if (minutes != null && minutes >= FocusAudio.maxTrackMinutes) {
      AppSnackbar.warning(context, context.l10n.focus_track_too_long);
      return;
    }
    await settings.addFocusTrack('${file.path}|${file.name}');
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final tracks = focusTracksOf(context, settings);
    final userCount = settings.focusTracks.length;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 2, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n.focus_sound,
                    style: sheetTitleStyle(context),
                  ),
                ),
                _ModeToggle(
                  shuffle: settings.focusShuffle,
                  onChanged: (value) async {
                    await settings.setFocusShuffle(value);
                    if (FocusAudio.playing.value) {
                      await FocusAudio.playQueue(tracks, shuffle: value);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final track in tracks)
                    _TrackRow(
                      track: track,
                      tracks: tracks,
                      shuffle: settings.focusShuffle,
                      onDelete: track.asset
                          ? () => settings.hideTrack(track.id)
                          : () => settings.removeFocusTrack(
                                '${track.id}|${track.name}',
                              ),
                    ),
                ],
              ),
            ),
            if (settings.hiddenTracks.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: settings.restoreTracks,
                  child: Text(context.l10n.restore),
                ),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: userCount >= FocusAudio.maxTracks
                    ? null
                    : () => _import(context),
                icon: const Icon(LucideIcons.plus, size: 17),
                label: Text(
                  '${context.l10n.focus_add_track}  '
                  '($userCount/${FocusAudio.maxTracks})',
                  style: sheetActionStyle(context, size: 14.5),
                ),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
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

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.shuffle, required this.onChanged});

  final bool shuffle;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: shuffle,
      child: GestureDetector(
        onTap: () => onChanged(!shuffle),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: context.colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                shuffle ? LucideIcons.shuffle : LucideIcons.repeat,
                size: 15,
                color: context.colors.primary,
              ),
              const SizedBox(width: 7),
              Text(
                shuffle ? context.l10n.focus_shuffle : context.l10n.focus_loop,
                style: sheetLabelStyle(
                  context,
                  size: 12.5,
                  color: context.colors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrackRow extends StatelessWidget {
  const _TrackRow({
    required this.track,
    required this.tracks,
    required this.shuffle,
    required this.onDelete,
  });

  final FocusTrack track;
  final List<FocusTrack> tracks;
  final bool shuffle;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: FocusAudio.current,
      builder: (context, currentId, _) {
        final active = currentId == track.id;
        return ValueListenableBuilder<bool>(
          valueListenable: FocusAudio.playing,
          builder: (context, playing, __) {
            final isPlaying = active && playing;
            return Semantics(
              button: true,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onLongPress: onDelete == null
                    ? null
                    : () async {
                        if (await showDeleteSheet(context)) onDelete!();
                      },
                onTap: () async {
                  final settings = context.read<SettingsController>();
                  if (isPlaying) {
                    await FocusAudio.pause();
                    await settings.setFocusTrack('');
                  } else if (active) {
                    await FocusAudio.resume();
                    await settings.setFocusTrack(track.id);
                  } else {
                    await FocusAudio.playQueue(
                      tracks,
                      shuffle: shuffle,
                      from: track,
                    );
                    await settings.setFocusTrack(track.id);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: active
                              ? context.colors.primary.withValues(alpha: 0.16)
                              : context.colors.surfaceContainerHighest,
                        ),
                        child: Icon(
                          isPlaying ? LucideIcons.pause : LucideIcons.play,
                          size: 15,
                          color: active
                              ? context.colors.primary
                              : context.tokens.muted,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          track.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: sheetOptionStyle(
                            context,
                            size: 15,
                            selected: active,
                            color: active ? context.colors.primary : null,
                          ),
                        ),
                      ),
                      if (track.asset)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            context.l10n.focus_built_in,
                            style: sheetLabelStyle(context, size: 11),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
