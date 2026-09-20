import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_theme.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/express/express_motion.dart';
import 'package:streak/core/express/express_switch.dart';
import 'package:streak/core/express/express_surface.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/widgets/sheet_type.dart';
import 'package:streak/core/routing/app_navigator.dart';
import 'package:streak/core/utils/app_snackbar.dart';
import 'package:streak/core/widgets/app_confirm_dialog.dart';
import 'package:streak/core/utils/cover_storage.dart';
import 'package:streak/core/utils/responsive.dart';
import 'package:streak/core/widgets/delete_sheet.dart';
import 'package:streak/features/focus/data/focus_session.dart';
import 'package:streak/features/focus/state/focus_audio.dart';
import 'package:streak/features/focus/state/focus_actions.dart';
import 'package:streak/features/focus/state/focus_controller.dart';
import 'package:streak/core/widgets/celebration_overlay.dart';
import 'package:streak/features/focus/widgets/focus_backgrounds.dart';
import 'package:streak/features/focus/widgets/focus_end_dialog.dart';
import 'package:streak/features/focus/widgets/focus_island.dart';
import 'package:streak/features/focus/widgets/focus_task_lists.dart';
import 'package:streak/features/focus/widgets/focus_video_scene.dart';
import 'package:streak/features/focus/widgets/music_sheet.dart';
import 'package:streak/features/focus/widgets/timer_clocks.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/state/habits_controller.dart';
import 'package:streak/features/settings/state/settings_controller.dart';
import 'package:streak/services/notification_service.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class FocusPage extends StatefulWidget implements FullWidthPage {
  const FocusPage({
    super.key,
    this.startHabitId,
    this.startMinutes,
    this.breakMinutes,
  });

  final String? startHabitId;
  final int? startMinutes;
  final int? breakMinutes;

  static const routeName = 'focus';

  @override
  State<FocusPage> createState() => _FocusPageState();
}

class _FocusPageState extends State<FocusPage> {
  bool _leaving = false;
  final _confetti = ValueNotifier(0);
  late final FocusController _focus = context.read<FocusController>();

  Timer? _lead;
  int _leadValue = 0;
  bool _immersive = false;
  bool _big = false;

  @override
  void initState() {
    super.initState();
    _focus.completedTick.addListener(_celebrate);
    FocusIsland.pages.value++;
    if (context.read<SettingsController>().focusKeepAwake) {
      WakelockPlus.enable();
    }
    if (widget.startMinutes != null) {
      _leadValue = 3;
      _begin();
    }
  }

  Future<void> _begin() async {
    await NotificationService().requestNotifications();
    if (!mounted) return;
    _runLead(() {
      _focus.start(
        habitId: widget.startHabitId ?? '',
        targetMinutes: widget.startMinutes!,
        breakMinutes: widget.breakMinutes ?? 0,
      );
      unawaited(_startSavedTrack());
    });
  }

  Future<void> _startSavedTrack() async {
    if (FocusAudio.playing.value) return;
    final settings = context.read<SettingsController>();
    final saved = settings.focusTrack;
    if (saved.isEmpty) return;

    final tracks = focusTracksOf(context, settings);
    final index = tracks.indexWhere((track) => track.id == saved);
    if (index == -1) return;
    try {
      await FocusAudio.playQueue(
        tracks,
        shuffle: settings.focusShuffle,
        repeatOne: settings.focusRepeatOne,
        from: tracks[index],
      );
    } catch (e) {
      debugPrint('Could not start the saved track: $e');
    }
  }

  void _runLead(VoidCallback then) {
    _lead?.cancel();
    if (!context.read<SettingsController>().focusLeadIn) {
      setState(() => _leadValue = 0);
      then();
      return;
    }
    setState(() => _leadValue = 3);
    _lead = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _leadValue--);
      if (_leadValue > 0) return;
      timer.cancel();
      then();
    });
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    WakelockPlus.disable();
    _lead?.cancel();
    _confetti.dispose();
    _focus.completedTick.removeListener(_celebrate);
    FocusIsland.pages.value--;
    super.dispose();
  }

  Future<void> _restart() async {
    if (_focus.elapsedSeconds >= 60) {
      final confirmed = await showAppConfirmDialog(
        context,
        title: context.l10n.focus_restart_title,
        message: context.l10n.focus_restart_body,
        confirmLabel: context.l10n.focus_restart,
        icon: LucideIcons.rotateCcw,
      );
      if (confirmed != true || !mounted) return;
    }
    _runLead(_focus.reset);
  }

  void _toggleRunning() {
    if (!_focus.isActive || _leadValue > 0) return;
    if (_focus.isAwaiting) {
      _focus.continueNow();
      return;
    }
    _focus.isRunning ? _focus.pause() : _focus.resume();
  }

  void _toggleBig() {
    setState(() => _big = !_big);
    SystemChrome.setEnabledSystemUIMode(
      _big || _immersive ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
    );
  }

  double _clockSize(BoxConstraints box, bool landscape) {
    if (_big) return landscape ? box.maxHeight : box.maxWidth * 0.94;
    if (landscape) return (box.maxHeight * 0.62).clamp(140.0, 300.0);
    return (box.maxWidth * 0.66).clamp(160.0, 320.0);
  }

  void _toggleImmersive() {
    setState(() => _immersive = !_immersive);
    SystemChrome.setEnabledSystemUIMode(
      _immersive || _big ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
    );
  }

  void _celebrate() {
    if (!mounted) return;
    _confetti.value++;
  }

  Future<void> _confirmStop() async {
    final focus = context.read<FocusController>();
    final habits = context.read<HabitsController>();
    final habit = focus.habitId.isEmpty ? null : habits.byId(focus.habitId);
    final reached = focus.reachedTarget || focus.isFlow;
    final checked =
        habit?.completions[AppClock.now().dayKey]?.steps ?? const <String>{};
    final pending = habit == null
        ? focus.pendingTasks
        : habit.substeps.where((step) => !checked.contains(step.id)).length;

    final lines = <String>[
      if (focus.isFlow)
        context.l10n.focus_end_flow(formatHoursShort(focus.elapsedSeconds))
      else if (reached)
        context.l10n.focus_end_reached
      else
        context.l10n.focus_end_short(formatHoursShort(focus.remainingSeconds)),
      if (pending > 0) context.l10n.focus_end_tasks(pending),
    ];

    final result = await showDialog<String>(
      context: context,
      builder: (dialog) => FocusEndDialog(
        reached: reached,
        addsTime: habit?.isTimeAmount ?? false,
        lines: lines,
        accent: habit?.color ?? Theme.of(dialog).colorScheme.primary,
      ),
    );
    if (result == null || !mounted) return;

    setState(() => _leaving = true);
    final habitId = focus.habitId;
    final completed = reached || result == 'done';
    final session = await focus.stop(completed: completed);
    await FocusAudio.stop();
    if (!mounted) return;

    final target = habitId.isEmpty ? null : habits.byId(habitId);
    final today = AppClock.now();
    if (target != null && target.isTimeAmount) {
      if (session != null) await countFocusTime(habits, focus, session);
    } else if (completed &&
        target != null &&
        target.kind == HabitKind.positive &&
        !target.isCompletedOn(today)) {
      habits.toggle(target.id, today, fromFocus: true);
    }
    if (!mounted) return;

    if (session != null) {
      AppSnackbar.success(
        context,
        context.l10n.focus_saved(formatHoursShort(session.seconds)),
      );
    }
    AppNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final focus = _focus;
    final habits = context.watch<HabitsController>();
    final leading = _leadValue > 0;
    final starting = leading && !focus.isActive;
    final habitId = starting ? (widget.startHabitId ?? '') : focus.habitId;
    final habit = habitId.isEmpty ? null : habits.byId(habitId);
    final leadMinutes =
        starting ? (widget.startMinutes ?? focus.targetMinutes) : focus.targetMinutes;
    final inset = MediaQuery.viewInsetsOf(context).bottom;

    if (!focus.isActive && !_leaving && _leadValue == 0) {
      _leaving = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) AppNavigator.pop();
      });
    }

    final style = ClockStyle
        .values[settings.focusClockStyle.clamp(0, ClockStyle.values.length - 1)];
    final label = focus.isBreak
        ? context.l10n.focus_break
        : (habit?.name ?? context.l10n.focus);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.systemBars(Brightness.dark),
      child: Scaffold(
        backgroundColor: Colors.black,
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
        FocusBackground(
          scene: settings.focusScene,
          imagePath: settings.focusImage,
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _toggleRunning,
                  onDoubleTap: _toggleBig,
                ),
              ),
              SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final landscape = constraints.maxWidth > constraints.maxHeight;
                final typing = inset > 0;

                final listHeight = typing
                    ? (constraints.maxHeight * 0.32).clamp(110.0, 240.0)
                    : 156.0;
                final tasks = habit == null
                    ? FocusFreeTaskList(focus: focus, maxHeight: listHeight)
                    : FocusTaskList(habit: habit, maxHeight: listHeight);

                final header = AnimatedBuilder(
                  animation: focus,
                  builder: (context, _) => _TopBar(
                    immersive: _immersive,
                    onImmersive: _toggleImmersive,
                    title: label,
                    target: leadMinutes <= 0
                        ? context.l10n.focus_flowtime
                        : focus.isPomodoro && !leading
                            ? '${context.l10n.minutes_short('${focus.targetMinutes}')}  ·  ${context.l10n.focus_round(focus.round)}'
                            : context.l10n.minutes_short('$leadMinutes'),
                  ),
                );

                final dial = AnimatedBuilder(
                  animation: focus,
                  builder: (context, _) => FocusClock(
                    style: style,
                    row: landscape,
                    seconds: leading
                        ? (leadMinutes <= 0 ? 0 : leadMinutes * 60)
                        : focus.displaySeconds,
                    progress: leading ? 0 : focus.progress,
                    color: habit?.color ?? context.colors.primary,
                    label: label,
                    size: _clockSize(constraints, landscape),
                  ),
                );

                final clock = GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _toggleRunning,
                  onDoubleTap: _toggleBig,
                  child: dial,
                );

                final controls = AnimatedBuilder(
                  animation: focus,
                  builder: (context, _) => _Controls(
                    running: focus.isRunning,
                    onReset: _restart,
                    awaiting: focus.isAwaiting,
                    onSkip: focus.isBreak ? focus.skipBreak : null,
                    onAddMinute: focus.isFlow ? null : focus.addMinute,
                    onToggle: _toggleRunning,
                    onStop: _confirmStop,
                  ),
                );

                if (_big) {
                  final face = Column(
                    children: [
                      _ZenLabel(
                        text: label,
                        color: habit?.color ?? context.colors.primary,
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: FittedBox(fit: BoxFit.contain, child: clock),
                      ),
                    ],
                  );
                  final rail = AnimatedBuilder(
                    animation: focus,
                    builder: (context, _) => _ZenControls(
                      vertical: landscape,
                      running: focus.isRunning,
                      awaiting: focus.isAwaiting,
                      onToggle: _toggleRunning,
                      onSkip: focus.isBreak ? focus.skipBreak : null,
                      onAddMinute: focus.isFlow ? null : focus.addMinute,
                      onStop: _confirmStop,
                    ),
                  );
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
                    child: landscape
                        ? Row(
                            children: [
                              Expanded(child: face),
                              const SizedBox(width: 16),
                              rail,
                            ],
                          )
                        : Column(
                            children: [
                              Expanded(child: face),
                              const SizedBox(height: 20),
                              rail,
                            ],
                          ),
                  );
                }

                if (landscape) {
                  return Column(
                    children: [
                      header,
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 8, 12, 18),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Flexible(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: clock,
                                      ),
                                    ),
                                    if (!typing) ...[
                                      const SizedBox(height: 24),
                                      controls,
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            Expanded(
                              key: const ValueKey('focus-tasks'),
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.fromLTRB(8, 8, 20, 20),
                                child: Align(
                                  alignment: Alignment.topCenter,
                                  child: ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(maxWidth: 420),
                                    child: tasks,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: inset),
                    ],
                  );
                }

                return Column(
                  children: [
                    header,
                    Expanded(
                      child: Center(
                        child: FittedBox(fit: BoxFit.scaleDown, child: clock),
                      ),
                    ),
                    if (!typing) ...[
                      KeyedSubtree(
                        key: const ValueKey('focus-controls'),
                        child: controls,
                      ),
                      const SizedBox(height: 22),
                    ],
                    Padding(
                      key: const ValueKey('focus-tasks'),
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                      child: tasks,
                    ),
                    SizedBox(height: inset),
                  ],
                );
              },
            ),
          ),
            ],
          ),
        ),
            Positioned.fill(
              child: RepaintBoundary(
                child: ValueListenableBuilder<int>(
                  valueListenable: _confetti,
                  builder: (context, trigger, _) =>
                      IgnorePointer(child: CelebrationOverlay(trigger: trigger)),
                ),
              ),
            ),
            if (_leadValue > 0 && settings.focusLeadIn)
              Positioned.fill(
                child: _LeadIn(value: _leadValue),
              ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.target,
    required this.immersive,
    required this.onImmersive,
  });

  final String title;
  final String target;
  final bool immersive;
  final VoidCallback onImmersive;

  Future<void> _pickStyle(BuildContext context) async {
    final settings = context.read<SettingsController>();
    final labels = [
      context.l10n.focus_style_digital,
      context.l10n.focus_style_flip,
      context.l10n.focus_style_dots,
    ];
    await _sheet(
      context,
      title: context.l10n.focus_style,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < labels.length; i++)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(labels[i]),
              trailing: settings.focusClockStyle == i
                  ? Icon(LucideIcons.check, color: context.colors.primary)
                  : null,
              onTap: () {
                settings.setFocusClockStyle(i);
                Navigator.of(context).pop();
              },
            ),
          const Divider(height: 20),
          Consumer<SettingsController>(
            builder: (_, s, __) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.l10n.focus_countdown),
              onTap: () => s.setFocusLeadIn(!s.focusLeadIn),
              trailing: s.isExpressStyle
                  ? ExpressSwitch(
                      value: s.focusLeadIn,
                      onChanged: s.setFocusLeadIn,
                    )
                  : Switch(value: s.focusLeadIn, onChanged: s.setFocusLeadIn),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickScene(BuildContext context) async {
    final settings = context.read<SettingsController>();

    Future<void> pickImage() async {
      if (settings.focusImages.length >= 10) {
        AppSnackbar.warning(context, context.l10n.focus_images_limit);
        return;
      }
      final dest = await CoverStorage.store(folder: 'focus');
      if (dest == null) return;
      await settings.addFocusImage(dest);
      await settings.setFocusImage(dest);
      await settings.setFocusScene(kCustomScene);
    }

    await _sheet(
      context,
      title: context.l10n.app_background,
      child: Consumer<SettingsController>(
        builder: (sheetContext, s, __) => LayoutBuilder(
          builder: (_, box) {
            const columns = 4;
            const gap = 10.0;
            final tile =
                ((box.maxWidth - gap * (columns - 1)) / columns).floorToDouble();
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
            for (var i = 0; i < focusSceneCount; i++)
              if (!s.isSceneHidden(i) && (i == 0 || !hasVideoScenes))
                SizedBox(
                  width: tile,
                  child: FocusScenePreview(
                    scene: i,
                    imagePath: '',
                    selected: s.focusScene == i && s.focusImage.isEmpty,
                    onTap: () {
                      s.setFocusScene(i);
                      s.setFocusImage('');
                    },
                    onLongPress: i == 0
                        ? null
                        : () async {
                            if (await showDeleteSheet(sheetContext)) {
                              await s.hideScene(i);
                            }
                          },
                  ),
                ),
            if (hasVideoScenes)
              for (var i = 0; i < focusVideoScenes.length; i++)
                if (!s.isSceneHidden(kFirstVideoScene + i))
                  SizedBox(
                    width: tile,
                    child: FocusScenePreview(
                      scene: kFirstVideoScene + i,
                      imagePath: '',
                      selected: s.focusScene == kFirstVideoScene + i &&
                          s.focusImage.isEmpty,
                      onTap: () {
                        s.setFocusScene(kFirstVideoScene + i);
                        s.setFocusImage('');
                      },
                      onLongPress: () async {
                        if (await showDeleteSheet(sheetContext)) {
                          await s.hideScene(kFirstVideoScene + i);
                        }
                      },
                    ),
                  ),
            for (final path in s.focusImages)
              SizedBox(
                width: tile,
                child: AspectRatio(
                  aspectRatio: 0.78,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Semantics(
                          button: true,
                          label: sheetContext.l10n.app_background,
                          child: GestureDetector(
                            onTap: () {
                              s.setFocusImage(path);
                              s.setFocusScene(kCustomScene);
                            },
                            onLongPress: () async {
                              if (await showDeleteSheet(sheetContext)) {
                                await s.removeFocusImage(path);
                              }
                            },
                            child: Container(
                              padding: EdgeInsets.all(
                                s.focusImage == path ? 2.5 : 0,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: s.focusImage == path
                                    ? Border.all(
                                        color: sheetContext.colors.primary,
                                        width: 2.5,
                                      )
                                    : null,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  s.focusImage == path ? 12 : 14,
                                ),
                                child: File(path).existsSync()
                                    ? Image.file(File(path), fit: BoxFit.cover)
                                    : ColoredBox(
                                        color: sheetContext
                                            .colors.surfaceContainerHighest,
                                        child: const SizedBox.expand(),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            SizedBox(
              width: tile,
              child: AspectRatio(
                aspectRatio: 0.78,
                child: Semantics(
                  button: true,
                  label: sheetContext.l10n.add_image,
                  child: GestureDetector(
                    onTap: pickImage,
                    child: Container(
                      decoration: BoxDecoration(
                        color: sheetContext.colors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        LucideIcons.imagePlus,
                        size: 20,
                        color: sheetContext.tokens.muted,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (s.hiddenScenes.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: s.restoreScenes,
                    child: Text(sheetContext.l10n.restore),
                  ),
                ),
              ),
              ],
            );
          },
        ),
      ),
    );
  }

  static Future<void> _sheet(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxWidth: phoneWidth,
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      builder: (sheet) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: sheetTitleStyle(sheet)),
              const SizedBox(height: 16),
              Flexible(child: SingleChildScrollView(child: child)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 4, 6, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(LucideIcons.chevronLeft, color: Colors.white),
            onPressed: () => AppNavigator.pop(),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  target,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
          _TopIcon(
            icon: immersive ? LucideIcons.minimize2 : LucideIcons.maximize2,
            onTap: onImmersive,
          ),
          _TopIcon(
            icon: LucideIcons.music,
            onTap: () => showMusicSheet(context),
          ),
          _TopIcon(
            icon: LucideIcons.layoutPanelTop,
            onTap: () => _pickStyle(context),
          ),
          _TopIcon(
            icon: LucideIcons.image,
            onTap: () => _pickScene(context),
          ),
        ],
      ),
    );
  }
}

class _TopIcon extends StatelessWidget {
  const _TopIcon({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => IconButton(
        onPressed: onTap,
        icon: Icon(icon, size: 19, color: Colors.white.withValues(alpha: 0.85)),
      );
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.running,
    required this.awaiting,
    required this.onReset,
    required this.onSkip,
    required this.onAddMinute,
    required this.onToggle,
    required this.onStop,
  });

  final bool running;
  final bool awaiting;
  final VoidCallback onReset;
  final VoidCallback? onSkip;
  final VoidCallback? onAddMinute;
  final VoidCallback onToggle;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final skip = onSkip;
    final buttons = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _RoundButton(
          icon: skip == null ? LucideIcons.rotateCcw : LucideIcons.skipForward,
          onTap: () {
            (skip ?? onReset)();
          },
        ),
        const SizedBox(width: 18),
        Semantics(
          button: true,
          child: ExpressSquish(
            scale: 0.93,
            onTap: onToggle,
            child: AnimatedContainer(
              duration: Express.normal,
              curve: Express.bouncy,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: running ? 0.16 : 0.24),
                borderRadius: BorderRadius.circular(running ? 20 : 30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    duration: Express.quick,
                    transitionBuilder: (child, animation) => ScaleTransition(
                      scale: animation,
                      child: FadeTransition(opacity: animation, child: child),
                    ),
                    child: Icon(
                      running ? LucideIcons.pause : LucideIcons.play,
                      key: ValueKey(running || awaiting),
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    awaiting
                        ? context.l10n.focus_continue
                        : running
                            ? context.l10n.focus_pause
                            : context.l10n.focus_resume,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 18),
        _RoundButton(icon: LucideIcons.square, onTap: onStop),
      ],
    );

    final addMinute = onAddMinute;
    if (addMinute == null) return buttons;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExpressSquish(
          scale: 0.9,
          onTap: addMinute,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '+${context.l10n.minutes_short('1')}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        buttons,
      ],
    );
  }
}

class _ZenLabel extends StatelessWidget {
  const _ZenLabel({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.72),
            ),
          ),
        ),
      ],
    );
  }
}

class _ZenControls extends StatelessWidget {
  const _ZenControls({
    required this.vertical,
    required this.running,
    required this.awaiting,
    required this.onToggle,
    required this.onSkip,
    required this.onAddMinute,
    required this.onStop,
  });

  final bool vertical;
  final bool running;
  final bool awaiting;
  final VoidCallback onToggle;
  final VoidCallback? onSkip;
  final VoidCallback? onAddMinute;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final skip = onSkip;
    final minute = onAddMinute;
    final items = <Widget>[
      _ZenButton(
        icon: running ? LucideIcons.pause : LucideIcons.play,
        label: awaiting
            ? context.l10n.focus_continue
            : running
                ? context.l10n.focus_pause
                : context.l10n.focus_resume,
        onTap: onToggle,
      ),
      if (skip != null)
        _ZenButton(
          icon: LucideIcons.skipForward,
          label: context.l10n.focus_skip_break,
          onTap: skip,
        )
      else if (minute != null)
        _ZenButton(
          icon: LucideIcons.plus,
          label: '+${context.l10n.minutes_short('1')}',
          onTap: minute,
        ),
      _ZenButton(
        icon: LucideIcons.square,
        label: context.l10n.focus_end,
        onTap: onStop,
      ),
    ];

    final spaced = <Widget>[
      for (final (index, item) in items.indexed) ...[
        if (index > 0)
          SizedBox(width: vertical ? 0 : 14, height: vertical ? 14 : 0),
        item,
      ],
    ];

    return vertical
        ? Column(mainAxisSize: MainAxisSize.min, children: spaced)
        : Row(mainAxisSize: MainAxisSize.min, children: spaced);
  }
}

class _ZenButton extends StatelessWidget {
  const _ZenButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: ExpressSquish(
        scale: 0.9,
        onTap: onTap,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(icon, size: 20, color: Colors.white),
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.l10n.focus_end,
      child: ExpressSquish(
        scale: 0.88,
        onTap: onTap,
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.13),
          ),
          child: Icon(icon, size: 19, color: Colors.white),
        ),
      ),
    );
  }
}

class _LeadIn extends StatelessWidget {
  const _LeadIn({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.72),
      child: Center(
        child: TweenAnimationBuilder<double>(
          key: ValueKey(value),
          tween: Tween(begin: 0.5, end: 1),
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutBack,
          builder: (context, scale, child) => Transform.scale(
            scale: scale,
            child: Opacity(opacity: scale.clamp(0.0, 1.0), child: child),
          ),
          child: Text(
            '$value',
            style: const TextStyle(
              fontSize: 128,
              height: 1,
              fontWeight: FontWeight.w800,
              letterSpacing: -6,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
