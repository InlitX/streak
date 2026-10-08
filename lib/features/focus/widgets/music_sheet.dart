import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:streak/features/settings/widgets/minimal_settings_widgets.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/widgets/sheet_type.dart';
import 'package:streak/core/utils/responsive.dart';
import 'package:streak/core/widgets/delete_sheet.dart';
import 'package:streak/core/utils/app_snackbar.dart';
import 'package:streak/core/utils/cover_storage.dart';
import 'package:streak/features/focus/state/focus_audio.dart';
import 'package:streak/features/focus/widgets/focus_backgrounds.dart';
import 'package:streak/features/focus/widgets/focus_video_scene.dart';
import 'package:streak/features/settings/state/settings_controller.dart';
import 'package:streak/core/widgets/glass.dart';

class _SceneArt extends StatelessWidget {
  const _SceneArt();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final video = videoSceneIndex(settings.focusScene);
    if (video >= 0) return FocusVideoPoster(name: focusVideoScenes[video]);
    return FocusBackground(
      scene: settings.focusScene,
      imagePath: settings.focusImage,
      thumbnail: true,
      child: const SizedBox.expand(),
    );
  }
}

List<FocusTrack> focusTracksOf(BuildContext context, SettingsController s) => [
      for (final entry in builtInTracks.entries)
        if (!s.isTrackHidden(entry.key))
          FocusTrack(
            id: entry.key,
            name: switch (entry.key) {
              'brown_noise.mp3' => context.l10n.focus_track_brown,
              'fire.mp3' => context.l10n.focus_track_fire,
              'ticking.mp3' => context.l10n.focus_track_ticking,
              _ => entry.value,
            },
            asset: true,
          ),
      for (final raw in s.focusTracks)
        if (FocusTrack.decode(raw) != null) FocusTrack.decode(raw)!,
    ];

Future<void> showMusicSheet(BuildContext context) async {
  await context.read<SettingsController>().pruneFocusTracks();
  if (!context.mounted) return;
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
    final kept = await FocusTrack.store(file.path!);
    await CoverStorage.clearPickerCache();
    await settings.addFocusTrack('$kept|${file.name}');
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final tracks = focusTracksOf(context, settings);
    final userCount = settings.focusTracks.length;

    return SafeArea(
      top: false,
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 2, 20, 0),
        child: ListView(
          shrinkWrap: true,
          padding: EdgeInsets.only(
            bottom: 16 + MediaQuery.paddingOf(context).bottom,
          ),
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
                  mode: settings.focusShuffle
                      ? 2
                      : settings.focusRepeatOne
                          ? 1
                          : 0,
                  onChanged: (mode) async {
                    await settings.setFocusMode(
                      shuffle: mode == 2,
                      repeatOne: mode == 1,
                    );
                    await FocusAudio.setMode(
                      shuffle: mode == 2,
                      repeatOne: mode == 1,
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),
            _NowPlaying(tracks: tracks),
            _VolumeRow(onDone: settings.setFocusVolume),
            const SizedBox(height: 10),
            _TrackList(
                count: tracks.length,
                children: [
                  for (final track in tracks)
                    _TrackRow(
                      track: track,
                      tracks: tracks,
                      shuffle: settings.focusShuffle,
                      repeatOne: settings.focusRepeatOne,
                      onDelete: track.asset
                          ? () => settings.hideTrack(track.id)
                          : () => settings.removeFocusTrack(
                                '${track.id}|${track.name}',
                              ),
                    ),
                ],
              ),
            if (settings.hiddenTracks.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: settings.restoreTracks,
                  child: Text(context.l10n.restore),
                ),
              ),
            const SizedBox(height: 10),
            Center(
              child: TextButton.icon(
                onPressed: userCount >= FocusAudio.maxTracks
                    ? null
                    : () => _import(context),
                icon: const Icon(LucideIcons.plus, size: 16),
                label: Text(
                  '${context.l10n.focus_add_track}  '
                  '($userCount/${FocusAudio.maxTracks})',
                  style: sheetActionStyle(context, size: 14),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  backgroundColor:
                      context.colors.primary.withValues(alpha: 0.12),
                  shape: const StadiumBorder(),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              decoration: BoxDecoration(
                color: context.colors.surfaceContainerHighest
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: _AlertRow(settings: settings),
            ),
          ],
        ),
      ),
    );
  }
}

class _VolumeRow extends StatelessWidget {
  const _VolumeRow({required this.onDone});

  final ValueChanged<double> onDone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 4, 6, 4),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: ValueListenableBuilder<double>(
        valueListenable: FocusAudio.volume,
        builder: (context, volume, _) => Row(
          children: [
            Icon(
              volume == 0
                  ? LucideIcons.volumeX
                  : volume < 0.5
                      ? LucideIcons.volume1
                      : LucideIcons.volume2,
              size: 19,
              color: context.colors.onSurface,
            ),
            Expanded(
              child: Semantics(
                label: context.l10n.focus_volume,
                child: Slider(
                  value: volume,
                  onChanged: FocusAudio.setVolume,
                  onChangeEnd: onDone,
                ),
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 38),
              child: Text(
                '${(volume * 100).round()}%',
                textAlign: TextAlign.end,
                maxLines: 1,
                softWrap: false,
                style: sheetLabelStyle(context, size: 12),
              ),
            ),
            const SizedBox(width: 10),
          ],
        ),
      ),
    );
  }
}

class _TrackList extends StatelessWidget {
  const _TrackList({required this.count, required this.children});

  static const _row = 62.0;
  static const _shown = 4.5;

  final int count;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (count <= 4) return Column(children: children);
    return SizedBox(
      height: _row * _shown,
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (bounds) => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Colors.white, Colors.transparent],
          stops: [0, 0.86, 1],
        ).createShader(bounds),
        child: ListView(
          padding: const EdgeInsets.only(bottom: _row / 2),
          children: children,
        ),
      ),
    );
  }
}

class _AlertRow extends StatelessWidget {
  const _AlertRow({required this.settings});

  final SettingsController settings;

  String _label(BuildContext context) {
    final alert = settings.focusAlert;
    if (alert == FocusAudio.silentAlert) return context.l10n.focus_alert_none;
    if (alert.isEmpty) return context.l10n.focus_alert_chime;
    return alert.split(RegExp(r'[\\/]')).last;
  }

  Future<void> _pick(BuildContext context) async {
    final alert = settings.focusAlert;
    await showOptionSheet(
      context,
      title: context.l10n.focus_alert,
      options: [
        context.l10n.focus_alert_chime,
        context.l10n.focus_alert_custom,
        context.l10n.focus_alert_none,
      ],
      index: alert.isEmpty
          ? 0
          : alert == FocusAudio.silentAlert
              ? 2
              : 1,
      onSelected: (index) async {
        if (index == 0) return settings.setFocusAlert('');
        if (index == 2) return settings.setFocusAlert(FocusAudio.silentAlert);
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: FocusAudio.trackExtensions,
        );
        final path = result?.files.single.path;
        if (path == null) return;
        final kept = await FocusTrack.store(path, folder: 'alerts');
        await CoverStorage.clearPickerCache();
        await settings.setFocusAlert(kept);
        await FocusAudio.alert(kept);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(LucideIcons.bellRing, color: context.colors.onSurface),
          title: Text(context.l10n.focus_alert, style: sheetOptionStyle(context)),
          subtitle: Text(
            _label(context),
            style: TextStyle(fontSize: 12.5, color: context.tokens.muted),
          ),
          onTap: () => _pick(context),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: settings.focusHold,
          onChanged: settings.setFocusHold,
          title: Text(context.l10n.focus_hold, style: sheetOptionStyle(context)),
          subtitle: Text(
            context.l10n.focus_hold_sub,
            style: TextStyle(fontSize: 12.5, color: context.tokens.muted),
          ),
        ),
      ],
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.mode, required this.onChanged});

  final int mode;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final (icon, label) = switch (mode) {
      1 => (LucideIcons.repeat1, context.l10n.focus_repeat_one),
      2 => (LucideIcons.shuffle, context.l10n.focus_shuffle),
      _ => (LucideIcons.repeat, context.l10n.focus_loop),
    };

    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: () => onChanged((mode + 1) % 3),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: context.colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: context.colors.primary),
              const SizedBox(width: 7),
              Text(
                label,
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
    required this.repeatOne,
    required this.onDelete,
  });

  final FocusTrack track;
  final List<FocusTrack> tracks;
  final bool shuffle;
  final bool repeatOne;
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
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(vertical: 2),
                decoration: BoxDecoration(
                  color: active
                      ? context.colors.primary.withValues(alpha: 0.08)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: InkWell(
                borderRadius: BorderRadius.circular(18),
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
                      repeatOne: repeatOne,
                      from: track,
                    );
                    await settings.setFocusTrack(track.id);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 9, 8, 9),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 260),
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: active
                              ? context.colors.primary.withValues(alpha: 0.16)
                              : context.colors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          !active
                              ? LucideIcons.music
                              : isPlaying
                                  ? LucideIcons.pause
                                  : LucideIcons.play,
                          size: 17,
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
              ),
            );
          },
        );
      },
    );
  }
}

class _NowPlaying extends StatelessWidget {
  const _NowPlaying({required this.tracks});

  final List<FocusTrack> tracks;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: FocusAudio.current,
      builder: (context, currentId, _) {
        final track = tracks.where((t) => t.id == currentId).firstOrNull;
        return AnimatedSize(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: track == null
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _PlayerCard(track: track),
                ),
        );
      },
    );
  }
}

class _PlayerCard extends StatelessWidget {
  const _PlayerCard({required this.track});

  final FocusTrack track;

  Future<void> _toggle(BuildContext context, bool playing) async {
    final settings = context.read<SettingsController>();
    if (playing) {
      await FocusAudio.pause();
      await settings.setFocusTrack('');
    } else {
      await FocusAudio.resume();
      await settings.setFocusTrack(track.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                child: const _SceneArt(),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.28),
                    Colors.black.withValues(alpha: 0.55),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Column(
              children: [
                Row(
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: const SizedBox.square(
                          dimension: 62,
                          child: _SceneArt(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            track.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: sheetOptionStyle(
                              context,
                              size: 17,
                              selected: true,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            track.asset
                                ? context.l10n.focus_built_in
                                : context.l10n.focus_sound,
                            style: sheetLabelStyle(
                              context,
                              size: 12.5,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const _Scrubber(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () => FocusAudio.skip(-1),
                      icon: const Icon(
                        LucideIcons.skipBack,
                        size: 22,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 18),
                    ValueListenableBuilder<bool>(
                      valueListenable: FocusAudio.playing,
                      builder: (context, playing, _) => Pressable(
                        onTap: () => _toggle(context, playing),
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            transitionBuilder: (child, animation) =>
                                ScaleTransition(scale: animation, child: child),
                            child: Icon(
                              playing ? LucideIcons.pause : LucideIcons.play,
                              key: ValueKey(playing),
                              size: 24,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 18),
                    IconButton(
                      onPressed: () => FocusAudio.skip(1),
                      icon: const Icon(
                        LucideIcons.skipForward,
                        size: 22,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Scrubber extends StatefulWidget {
  const _Scrubber();

  @override
  State<_Scrubber> createState() => _ScrubberState();
}

class _ScrubberState extends State<_Scrubber> {
  double? _dragging;

  static String _clock(Duration at) {
    final seconds = (at.inSeconds % 60).toString().padLeft(2, '0');
    return '${at.inMinutes}:$seconds';
  }

  Future<void> _seek(double value, int total) async {
    await FocusAudio.seek(Duration(milliseconds: (value * total).round()));
    if (mounted) setState(() => _dragging = null);
  }

  @override
  Widget build(BuildContext context) {
    final label = sheetLabelStyle(
      context,
      size: 11.5,
      color: Colors.white.withValues(alpha: 0.7),
    );
    return ValueListenableBuilder<Duration>(
      valueListenable: FocusAudio.length,
      builder: (context, length, _) => ValueListenableBuilder<Duration>(
        valueListenable: FocusAudio.position,
        builder: (context, position, _) {
          final total = length.inMilliseconds;
          final shown = _dragging ??
              (total <= 0 ? 0.0 : position.inMilliseconds / total);
          return Column(
            children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 4,
                  activeTrackColor: Colors.white,
                  inactiveTrackColor: Colors.white.withValues(alpha: 0.25),
                  thumbColor: Colors.white,
                  overlayShape: SliderComponentShape.noOverlay,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                ),
                child: Slider(
                  value: shown.clamp(0.0, 1.0),
                  onChanged: total <= 0
                      ? null
                      : (value) => setState(() => _dragging = value),
                  onChangeEnd: (value) => _seek(value, total),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _clock(Duration(milliseconds: (shown * total).round())),
                    style: label,
                  ),
                  Text(_clock(length), style: label),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

