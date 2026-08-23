
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_palette.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/extensions/inset_extensions.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/icons/habit_icons.dart';
import 'package:streak/core/routing/app_navigator.dart';
import 'package:streak/core/utils/amount_format.dart';
import 'package:streak/core/utils/app_snackbar.dart';
import 'package:streak/core/utils/cover_storage.dart';
import 'package:streak/core/widgets/app_confirm_dialog.dart';
import 'package:streak/core/widgets/app_text_field.dart';
import 'package:streak/core/widgets/section_label.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/data/reminder.dart';
import 'package:streak/features/habits/data/substep.dart';
import 'package:streak/features/habits/state/habits_controller.dart';
import 'package:streak/features/habits/widgets/color_picker.dart';
import 'package:streak/features/habits/widgets/habit_form_basics.dart';
import 'package:streak/features/focus/widgets/focus_duration_fields.dart';
import 'package:streak/features/habits/widgets/habit_form_kind.dart';
import 'package:streak/features/habits/widgets/habit_form_schedule.dart';
import 'package:streak/features/habits/widgets/habit_time_fields.dart';
import 'package:streak/core/express/express_button.dart';
import 'package:streak/core/express/express_motion.dart';
import 'package:streak/core/express/express_surface.dart';
import 'package:streak/features/habits/widgets/express_form_kit.dart';
import 'package:streak/core/minimal/minimal_kit.dart';
import 'package:streak/core/widgets/sheet_type.dart';
import 'package:streak/features/habits/widgets/minimal_form_fields.dart';
import 'package:streak/features/habits/widgets/minimal_pickers.dart';
import 'package:streak/features/habits/widgets/minimal_substeps.dart';
import 'package:streak/features/habits/widgets/reminder_editor_sheet.dart';
import 'package:streak/features/habits/widgets/reminder_tile.dart';
import 'package:streak/features/settings/state/settings_controller.dart';
import 'package:streak/services/notification_service.dart';

class HabitFormPage extends StatefulWidget {
  const HabitFormPage({super.key, this.habit});

  final Habit? habit;

  bool get isEditing => habit != null;

  @override
  State<HabitFormPage> createState() => _HabitFormPageState();
}

class _HabitFormPageState extends State<HabitFormPage> {
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _unitLabel;
  late final TextEditingController _dailyCost;
  final _scroll = ScrollController();
  final _lookAnchor = GlobalKey();

  String _icon = HabitIcons.defaultIcon;
  String _category = '';
  Color _color = AppPalette.brand;
  HabitInterval _interval = HabitInterval.daily;
  int _frequency = 1;
  List<int> _scheduleWeekdays = const [1, 3, 5];
  int _scheduleEvery = 2;
  String _cover = '';
  late List<Reminder> _reminders;

  HabitKind _kind = HabitKind.positive;
  QuantKind _quantKind = QuantKind.generic;
  double _quantTarget = 8;
  double _quantIncrement = 1;
  String _bookCover = '';
  bool _focusOnly = false;
  int _focusMinutes = 25;
  bool _pomodoro = false;
  int _breakMinutes = 5;
  int _startMinute = -1;
  int _durationMinutes = 0;
  late List<Substep> _substeps;

  bool get _kindLocked => widget.isEditing;

  bool get _planning => context.watch<SettingsController>().planningEnabled;

  bool get _canSave {
    if (_name.text.trim().isEmpty) return false;
    if (_kind == HabitKind.quantitative && _unitLabel.text.trim().isEmpty) {
      return false;
    }
    if (_kind != HabitKind.negative &&
        _interval == HabitInterval.weekdays &&
        _scheduleWeekdays.isEmpty) {
      return false;
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    final habit = widget.habit;
    _name = TextEditingController(text: habit?.name ?? '');
    _description = TextEditingController(text: habit?.description ?? '');
    _unitLabel = TextEditingController(text: habit?.unitLabel ?? '');
    _dailyCost = TextEditingController(
      text: (habit?.dailyCost ?? 0) > 0 ? formatAmount(habit!.dailyCost) : '',
    );
    if (habit != null) {
      _icon = habit.icon;
      _category = habit.category;
      _color = habit.color;
      _interval = habit.interval;
      _frequency = habit.targetFrequency;
      if (habit.scheduleWeekdays.isNotEmpty) {
        _scheduleWeekdays = List.of(habit.scheduleWeekdays);
      }
      _scheduleEvery = habit.scheduleEvery;
      _cover = habit.coverPath;
      _reminders = List.of(habit.reminders);
      _kind = habit.kind;
      _quantKind = habit.quantKind;
      _quantTarget = habit.kind == HabitKind.quantitative ? habit.perDayTarget : 8;
      _quantIncrement = habit.incrementAmount;
      _bookCover = habit.bookCoverPath;
      _focusOnly = habit.focusOnly;
      _focusMinutes = habit.focusMinutes;
      _pomodoro = habit.focusBreakMinutes > 0;
      if (_pomodoro) _breakMinutes = habit.focusBreakMinutes;
      _startMinute = habit.startMinute;
      _durationMinutes = habit.durationMinutes;
      _substeps = List.of(habit.substeps);
    } else {
      _reminders = [];
      _substeps = [];
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _unitLabel.dispose();
    _dailyCost.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _applyQuantPreset(QuantKind preset) {
    setState(() {
      _quantKind = preset;
      switch (preset) {
        case QuantKind.water:
          _unitLabel.text = context.l10n.quant_unit_ml;
          _quantTarget = 2000;
          _quantIncrement = 250;
          break;
        case QuantKind.reading:
          _unitLabel.text = context.l10n.quant_unit_pages;
          _quantTarget = 20;
          _quantIncrement = 1;
          break;
        case QuantKind.time:
          _unitLabel.text = context.l10n.unit_min_short;
          _quantTarget = 30;
          _quantIncrement = 5;
          break;
        case QuantKind.generic:
          break;
      }
    });
  }

  Future<void> _submit() async {
    final controller = context.read<HabitsController>();
    final name = _name.text.trim();
    final description = _description.text.trim();
    final quantitative = _kind == HabitKind.quantitative;
    final negative = _kind == HabitKind.negative;
    final dailyCost = negative
        ? double.tryParse(_dailyCost.text.trim().replaceAll(',', '.')) ?? 0
        : 0.0;
    final interval = negative ? HabitInterval.daily : _interval;
    final frequency = negative ? 1 : _frequency;
    final focusOnly = _kind == HabitKind.positive && _focusOnly;
    final substeps = _kind == HabitKind.positive && !focusOnly
        ? _substeps.where((s) => s.title.trim().isNotEmpty).toList()
        : <Substep>[];

    if (widget.isEditing) {
      await controller.update(
        widget.habit!.copyWith(
          name: name,
          icon: _icon,
          category: _category,
          description: description,
          color: _color,
          interval: interval,
          targetFrequency: frequency,
          scheduleWeekdays: negative ? const [] : _scheduleWeekdays,
          scheduleEvery: negative ? 2 : _scheduleEvery,
          reminders: _reminders,
          coverPath: _cover,
          dailyCost: dailyCost,
          perDayTarget: quantitative ? _quantTarget : widget.habit!.perDayTarget,
          unitLabel: quantitative ? _unitLabel.text.trim() : widget.habit!.unitLabel,
          incrementAmount:
              quantitative ? _quantIncrement : widget.habit!.incrementAmount,
          quantKind: quantitative ? _quantKind : widget.habit!.quantKind,
          bookCoverPath: quantitative ? _bookCover : widget.habit!.bookCoverPath,
          focusOnly: focusOnly,
          focusMinutes: _focusMinutes,
          focusBreakMinutes: _pomodoro ? _breakMinutes : 0,
          startMinute: negative ? -1 : _startMinute,
          durationMinutes: negative ? 0 : _durationMinutes,
          substeps: substeps,
        ),
      );
    } else {
      await controller.create(
        name: name,
        icon: _icon,
        category: _category,
        description: description,
        color: _color.toARGB32(),
        interval: interval,
        targetFrequency: frequency,
        scheduleWeekdays: negative ? const [] : _scheduleWeekdays,
        scheduleEvery: negative ? 2 : _scheduleEvery,
        reminders: _reminders,
        coverPath: _cover,
        kind: _kind,
        dailyCost: dailyCost,
        perDayTarget: quantitative ? _quantTarget : 1,
        unitLabel: quantitative ? _unitLabel.text.trim() : '',
        incrementAmount: quantitative ? _quantIncrement : 1,
        quantKind: quantitative ? _quantKind : QuantKind.generic,
        bookCoverPath: quantitative ? _bookCover : '',
        focusOnly: focusOnly,
        focusMinutes: _focusMinutes,
        focusBreakMinutes: _pomodoro ? _breakMinutes : 0,
        startMinute: negative ? -1 : _startMinute,
        durationMinutes: negative ? 0 : _durationMinutes,
        substeps: substeps,
      );
    }
    AppNavigator.pop();
  }

  Future<void> _pickCover() async {
    final dest = await CoverStorage.pick();
    if (dest != null && mounted) setState(() => _cover = dest);
  }

  Future<void> _pickBookCover() async {
    final dest = await CoverStorage.pick();
    if (dest != null && mounted) setState(() => _bookCover = dest);
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: context.l10n.archive_habit,
      message: context.l10n.archive_habit_body(widget.habit!.name),
      confirmLabel: context.l10n.archive,
      icon: LucideIcons.archive,
    );
    if (confirmed == true && mounted) {
      await context.read<HabitsController>().archive(widget.habit!.id);
      AppNavigator.pop(true);
    }
  }

  Future<void> _addReminder() async {
    final granted = await NotificationService().requestPermissions();
    if (!granted) {
      if (mounted) AppSnackbar.error(context, context.l10n.permission_required);
      return;
    }
    if (!mounted) return;
    final reminder = await showModalBottomSheet<Reminder>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const ReminderEditorSheet(),
    );
    if (reminder != null) setState(() => _reminders.add(reminder));
  }

  Future<void> _editReminder(Reminder reminder) async {
    final updated = await showModalBottomSheet<Reminder>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => ReminderEditorSheet(initial: reminder),
    );
    if (updated == null) return;
    setState(() {
      final index = _reminders.indexWhere((r) => r.id == reminder.id);
      if (index == -1) {
        _reminders.add(updated);
      } else {
        _reminders[index] = updated;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final style = context.watch<SettingsController>();
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      excludeFromSemantics: true,
      child: style.isMinimalStyle
          ? _buildMinimal(context)
          : style.isExpressStyle
              ? _buildExpress(context)
              : _buildClassic(context),
    );
  }

  void _revealLook() {
    final target = _lookAnchor.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: Express.normal,
      curve: Express.emphasized,
      alignment: 0.1,
    );
  }

  Widget _buildExpress(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        leadingWidth: 68,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Center(child: ExpressIconButton(
            icon: LucideIcons.x,
            tooltip: context.l10n.cancel,
            onPressed: () => AppNavigator.pop(),
          )),
        ),
        actions: [
          if (widget.isEditing)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(child: ExpressIconButton(
                icon: LucideIcons.trash2,
                tint: context.tokens.danger,
                background: context.tokens.danger.withValues(alpha: 0.14),
                onPressed: _confirmDelete,
              )),
            ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: ExpressSaveBar(
        label: context.l10n.save,
        onPressed: _canSave ? _submit : null,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            controller: _scroll,
            padding: context.pagePadding(18, 8, 18, 140),
            children: _expressFields(context),
          ),
        ),
      ),
    );
  }

  List<Widget> _expressFields(BuildContext context) {
    final title =
        widget.isEditing ? context.l10n.edit_habit : context.l10n.new_habit;

    return [
      ExpressHeadline(title: title),
      const SizedBox(height: 20),
      ExpressFormHero(
        icon: _icon,
        color: _color,
        cover: _cover,
        controller: _name,
        onChanged: () => setState(() {}),
        onShuffleIcon: _revealLook,
      ),
      const SizedBox(height: 26),
      SectionLabel(context.l10n.habit_kind),
      ExpressKindPills(
        kind: _kind,
        locked: _kindLocked,
        onChanged: (kind) => setState(() => _kind = kind),
      ),
      if (_kindLocked) ...[
        const SizedBox(height: 10),
        NegativeHint(color: _color),
      ],
      if (_kind == HabitKind.quantitative) ...[
        const SizedBox(height: 12),
        QuantitativeFields(
          quantKind: _quantKind,
          unitController: _unitLabel,
          target: _quantTarget,
          increment: _quantIncrement,
          onPresetSelected: _applyQuantPreset,
          onUnitChanged: () => setState(() {}),
          onTargetChanged: (v) => setState(() => _quantTarget = v),
          onIncrementChanged: (v) => setState(() => _quantIncrement = v),
        ),
        if (_quantKind == QuantKind.reading) ...[
          const SizedBox(height: 20),
          SectionLabel(context.l10n.book_cover),
          CoverPicker(
            path: _bookCover,
            color: _color,
            onPick: _pickBookCover,
            onRemove: () => setState(() => _bookCover = ''),
          ),
        ],
      ],
      if (_kind == HabitKind.negative) ...[
        const SizedBox(height: 12),
        CostField(controller: _dailyCost, color: _color),
      ],
      if (_kind == HabitKind.positive) ...[
        const SizedBox(height: 12),
        FocusOnlyToggle(
          value: _focusOnly,
          color: _color,
          onChanged: (v) => setState(() => _focusOnly = v),
        ),
        if (_focusOnly) ...[
          const SizedBox(height: 20),
          SectionLabel(context.l10n.focus_duration),
          FocusDurationChips(
            minutes: _focusMinutes,
            onChanged: (v) => setState(() => _focusMinutes = v),
          ),
          if (_focusMinutes > 0) ...[
            const SizedBox(height: 12),
            FocusPomodoroCard(
              enabled: _pomodoro,
              breakMinutes: _breakMinutes,
              onToggle: (v) => setState(() => _pomodoro = v),
              onBreakChanged: (v) => setState(() => _breakMinutes = v),
            ),
          ],
        ],
        if (!_focusOnly) ...[
          const SizedBox(height: 26),
          SectionLabel(context.l10n.checklist),
          SubstepsEditor(
            substeps: _substeps,
            color: _color,
            onChanged: (list) => _substeps = list,
          ),
        ],
      ],
      const SizedBox(height: 26),
      SectionLabel(context.l10n.description),
      AppTextField(
        hint: context.l10n.description_hint,
        controller: _description,
      ),
      const SizedBox(height: 26),
      SectionLabel(context.l10n.icon, key: _lookAnchor),
      IconPicker(
        selected: _icon,
        color: _color,
        onSelected: (icon) => setState(() => _icon = icon),
      ),
      const SizedBox(height: 26),
      SectionLabel(context.l10n.color),
      ExpressCard(
        padding: const EdgeInsets.all(16),
        child: ColorPicker(
          selected: _color,
          onSelected: (c) => setState(() => _color = c),
        ),
      ),
      const SizedBox(height: 26),
      SectionLabel(context.l10n.category),
      CategoryPicker(
        selected: _category,
        onSelected: (c) => setState(() => _category = c),
      ),
      if (_kind != HabitKind.negative) ...[
        const SizedBox(height: 26),
        SectionLabel(context.l10n.frequency),
        IntervalSelector(
          interval: _interval,
          frequency: _frequency,
          weekdays: _scheduleWeekdays,
          every: _scheduleEvery,
          onIntervalChanged: (interval) => setState(() {
            _interval = interval;
            _frequency = switch (interval) {
              HabitInterval.weekly => 3,
              HabitInterval.monthly => 10,
              _ => 1,
            };
          }),
          onFrequencyChanged: (value) => setState(() => _frequency = value),
          onWeekdaysChanged: (days) => setState(() => _scheduleWeekdays = days),
          onEveryChanged: (v) => setState(() => _scheduleEvery = v),
        ),
      ],
      if (_kind != HabitKind.negative && _planning) ...[
        const SizedBox(height: 26),
        SectionLabel(context.l10n.habit_time),
        HabitTimeFields(
          startMinute: _startMinute,
          durationMinutes: _durationMinutes,
          color: _color,
          onChanged: (start, duration) => setState(() {
            _startMinute = start;
            _durationMinutes = duration;
          }),
        ),
      ],
      const SizedBox(height: 26),
      SectionLabel(context.l10n.reminders),
      for (final reminder in _reminders)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: ReminderTile(
            reminder: reminder,
            onEdit: () => _editReminder(reminder),
            onDelete: () => setState(() => _reminders.remove(reminder)),
          ),
        ),
      AddReminderButton(onTap: _addReminder),
      const SizedBox(height: 26),
      SectionLabel(context.l10n.cover_image),
      CoverPicker(
        path: _cover,
        color: _color,
        onPick: _pickCover,
        onRemove: () => setState(() => _cover = ''),
      ),
    ];
  }

  Widget _buildMinimal(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 52,
        leading: IconButton(
          icon: const Icon(LucideIcons.x),
          onPressed: () => AppNavigator.pop(),
        ),
        actions: [
          if (widget.isEditing)
            IconButton(
              icon: Icon(LucideIcons.trash2, color: context.tokens.danger),
              onPressed: _confirmDelete,
            ),
          TextButton(
            onPressed: _canSave ? _submit : null,
            child: Text(
              context.l10n.save,
              style: sheetActionStyle(context, size: 16),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: context.pagePadding(20, 0, 20, 32),
        children: [
          MinimalTitle(
            title: widget.isEditing
                ? context.l10n.edit_habit
                : context.l10n.new_habit,
          ),
          ..._minimalFields(context),
        ],
      ),
    );
  }

  List<Widget> _minimalFields(BuildContext context) {
    return [
      CompactPreview(icon: _icon, color: _color, name: _name.text.trim()),
      const SizedBox(height: 18),
      SectionLabel(context.l10n.name),
      AppTextField(
        hint: context.l10n.name_hint,
        controller: _name,
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: 16),
      SectionLabel(context.l10n.description),
      AppTextField(
        hint: context.l10n.description_hint,
        controller: _description,
      ),
      const SizedBox(height: 16),
      SectionLabel(context.l10n.habit_kind),
      MinimalSegmented(
        expand: true,
        enabled: !_kindLocked,
        index: HabitKind.values.indexOf(_kind),
        options: [
          context.l10n.kind_positive,
          context.l10n.kind_negative,
          context.l10n.kind_quantitative,
        ],
        onChanged: (i) => setState(() => _kind = HabitKind.values[i]),
      ),
      if (_kindLocked) ...[
        const SizedBox(height: 8),
        CompactNote(text: context.l10n.kind_locked_hint, color: _color),
      ],
      if (_kind == HabitKind.quantitative) ...[
        const SizedBox(height: 10),
        CompactCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  for (final preset in [
                    (QuantKind.water, context.l10n.quant_preset_water),
                    (QuantKind.reading, context.l10n.quant_preset_reading),
                    (QuantKind.time, context.l10n.quant_preset_time),
                    (QuantKind.generic, context.l10n.quant_preset_generic),
                  ]) ...[
                    if (preset.$1 != QuantKind.water) const SizedBox(width: 7),
                    Expanded(
                      child: CompactPill(
                        label: preset.$2,
                        selected: preset.$1 == _quantKind,
                        expand: true,
                        onTap: () => _applyQuantPreset(preset.$1),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 14),
              AppTextField(
                hint: context.l10n.quant_unit_hint,
                controller: _unitLabel,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 10),
              CompactStepperRow(
                label: context.l10n.quant_daily_goal,
                value: _quantTarget,
                unit: _unitLabel.text.trim(),
                step: _quantStep,
                min: _quantStep,
                editable: true,
                decimals: true,
                onChanged: (v) => setState(() => _quantTarget = v),
              ),
              const SizedBox(height: 8),
              CompactStepperRow(
                label: context.l10n.quant_tap_amount,
                value: _quantIncrement,
                unit: _unitLabel.text.trim(),
                step: _quantStep,
                min: _quantStep,
                editable: true,
                decimals: true,
                onChanged: (v) => setState(() => _quantIncrement = v),
              ),
            ],
          ),
        ),
        if (_quantKind == QuantKind.reading) ...[
          const SizedBox(height: 16),
          SectionLabel(context.l10n.book_cover),
          CompactCover(
            path: _bookCover,
            onPick: _pickBookCover,
            onRemove: () => setState(() => _bookCover = ''),
          ),
        ],
      ],
      if (_kind == HabitKind.negative) ...[
        const SizedBox(height: 10),
        CompactNote(text: context.l10n.kind_negative_hint, color: _color),
        const SizedBox(height: 10),
        CostField(controller: _dailyCost, color: _color),
      ],
      if (_kind == HabitKind.positive) ...[
        const SizedBox(height: 16),
        FocusOnlyToggle(
          value: _focusOnly,
          color: _color,
          compact: true,
          onChanged: (v) => setState(() => _focusOnly = v),
        ),
        if (_focusOnly) ...[
          const SizedBox(height: 16),
          SectionLabel(context.l10n.focus_duration),
          FocusDurationChips(
            minutes: _focusMinutes,
            onChanged: (v) => setState(() => _focusMinutes = v),
          ),
          if (_focusMinutes > 0) ...[
            const SizedBox(height: 12),
            FocusPomodoroCard(
              enabled: _pomodoro,
              breakMinutes: _breakMinutes,
              onToggle: (v) => setState(() => _pomodoro = v),
              onBreakChanged: (v) => setState(() => _breakMinutes = v),
            ),
          ],
        ],
        if (!_focusOnly) ...[
          const SizedBox(height: 16),
          SectionLabel(context.l10n.checklist),
          CompactSubstepsEditor(
            substeps: _substeps,
            color: _color,
            onChanged: (list) => _substeps = list,
          ),
        ],
      ],
      const SizedBox(height: 16),
      SectionLabel(context.l10n.icon),
      CompactIconPicker(
        selected: _icon,
        color: _color,
        onSelected: (icon) => setState(() => _icon = icon),
      ),
      const SizedBox(height: 16),
      SectionLabel(context.l10n.color),
      CompactColorPicker(
        selected: _color,
        onSelected: (c) => setState(() => _color = c),
      ),
      const SizedBox(height: 16),
      SectionLabel(context.l10n.cover_image),
      CompactCover(
        path: _cover,
        onPick: _pickCover,
        onRemove: () => setState(() => _cover = ''),
      ),
      const SizedBox(height: 16),
      SectionLabel(context.l10n.category),
      CompactCategoryPicker(
        selected: _category,
        onSelected: (c) => setState(() => _category = c),
      ),
      if (_kind != HabitKind.negative) ...[
        const SizedBox(height: 16),
        SectionLabel(context.l10n.frequency),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            for (final option in HabitInterval.values)
              CompactPill(
                label: _intervalLabel(context, option),
                selected: option == _interval,
                onTap: () => setState(() {
                  _interval = option;
                  _frequency = switch (option) {
                    HabitInterval.weekly => 3,
                    HabitInterval.monthly => 10,
                    _ => 1,
                  };
                }),
              ),
          ],
        ),
        if (_interval == HabitInterval.weekly ||
            _interval == HabitInterval.monthly) ...[
          const SizedBox(height: 10),
          CompactStepperRow(
            label: _interval == HabitInterval.weekly
                ? context.l10n.times_per_week('$_frequency')
                : context.l10n.times_per_month('$_frequency'),
            value: _frequency.toDouble(),
            min: 1,
            max: _interval == HabitInterval.weekly ? 6 : 25,
            onChanged: (v) => setState(() => _frequency = v.round()),
          ),
        ] else if (_interval == HabitInterval.everyXDays) ...[
          const SizedBox(height: 10),
          CompactStepperRow(
            label: context.l10n.every_n_days(_scheduleEvery),
            value: _scheduleEvery.toDouble(),
            min: 2,
            max: 30,
            onChanged: (v) => setState(() => _scheduleEvery = v.round()),
          ),
        ] else if (_interval == HabitInterval.weekdays) ...[
          const SizedBox(height: 12),
          CompactWeekdays(
            selected: _scheduleWeekdays,
            onChanged: (days) => setState(() => _scheduleWeekdays = days),
          ),
        ],
      ],
      if (_kind != HabitKind.negative && _planning) ...[
        const SizedBox(height: 16),
        SectionLabel(context.l10n.habit_time),
        HabitTimeFields(
          startMinute: _startMinute,
          durationMinutes: _durationMinutes,
          color: _color,
          compact: true,
          onChanged: (start, duration) => setState(() {
            _startMinute = start;
            _durationMinutes = duration;
          }),
        ),
      ],
      const SizedBox(height: 16),
      SectionLabel(context.l10n.reminders),
      for (final reminder in _reminders)
        Padding(
          padding: const EdgeInsets.only(bottom: 7),
          child: CompactReminderRow(
            reminder: reminder,
            onEdit: () => _editReminder(reminder),
            onDelete: () => setState(() => _reminders.remove(reminder)),
          ),
        ),
      CompactAddButton(label: context.l10n.add_reminder, onTap: _addReminder),
    ];
  }

  double get _quantStep => switch (_quantKind) {
        QuantKind.water => 50,
        QuantKind.time => 5,
        _ => 1,
      };

  String _intervalLabel(BuildContext context, HabitInterval option) =>
      switch (option) {
        HabitInterval.daily => context.l10n.daily,
        HabitInterval.weekly => context.l10n.weekly,
        HabitInterval.monthly => context.l10n.monthly,
        HabitInterval.weekdays => context.l10n.sched_days,
        HabitInterval.everyXDays => context.l10n.sched_interval,
      };

  Widget _buildClassic(BuildContext context) {
    final title =
        widget.isEditing ? context.l10n.edit_habit : context.l10n.new_habit;
    return Scaffold(
        appBar: AppBar(
          title: Text(title),
          leading: IconButton(
            icon: const Icon(LucideIcons.x),
            onPressed: () => AppNavigator.pop(),
          ),
          actions: [
            if (widget.isEditing)
              IconButton(
                icon: Icon(LucideIcons.trash2, color: context.tokens.danger),
                onPressed: _confirmDelete,
              ),
            TextButton(
              onPressed: _canSave ? _submit : null,
              child: Text(
                context.l10n.save,
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: ListView(
          padding: context.pagePadding(16, 16, 16, 16),
          children: [
            HabitPreview(
              icon: _icon,
              color: _color,
              name: _name.text.trim(),
            ),
            const SizedBox(height: 20),
            SectionLabel(context.l10n.name),
            AppTextField(
              hint: context.l10n.name_hint,
              controller: _name,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 20),
            SectionLabel(context.l10n.description),
            AppTextField(
              hint: context.l10n.description_hint,
              controller: _description,
            ),
            const SizedBox(height: 20),
            SectionLabel(context.l10n.habit_kind),
            KindSelector(
              kind: _kind,
              locked: _kindLocked,
              onChanged: (kind) => setState(() => _kind = kind),
            ),
            if (_kind == HabitKind.quantitative) ...[
              const SizedBox(height: 12),
              QuantitativeFields(
                quantKind: _quantKind,
                unitController: _unitLabel,
                target: _quantTarget,
                increment: _quantIncrement,
                onPresetSelected: _applyQuantPreset,
                onUnitChanged: () => setState(() {}),
                onTargetChanged: (v) => setState(() => _quantTarget = v),
                onIncrementChanged: (v) => setState(() => _quantIncrement = v),
              ),
              if (_quantKind == QuantKind.reading) ...[
                const SizedBox(height: 20),
                SectionLabel(context.l10n.book_cover),
                CoverPicker(
                  path: _bookCover,
                  color: _color,
                  onPick: _pickBookCover,
                  onRemove: () => setState(() => _bookCover = ''),
                ),
              ],
            ],
            if (_kind == HabitKind.negative) ...[
              const SizedBox(height: 12),
              NegativeHint(color: _color),
              const SizedBox(height: 12),
              CostField(controller: _dailyCost, color: _color),
            ],
            if (_kind == HabitKind.positive) ...[
              const SizedBox(height: 20),
              FocusOnlyToggle(
                value: _focusOnly,
                color: _color,
                onChanged: (v) => setState(() => _focusOnly = v),
              ),
              if (_focusOnly) ...[
                const SizedBox(height: 20),
                SectionLabel(context.l10n.focus_duration),
                FocusDurationChips(
                  minutes: _focusMinutes,
                  onChanged: (v) => setState(() => _focusMinutes = v),
                ),
                if (_focusMinutes > 0) ...[
                  const SizedBox(height: 12),
                  FocusPomodoroCard(
                    enabled: _pomodoro,
                    breakMinutes: _breakMinutes,
                    onToggle: (v) => setState(() => _pomodoro = v),
                    onBreakChanged: (v) => setState(() => _breakMinutes = v),
                  ),
                ],
              ],
              if (!_focusOnly) ...[
                const SizedBox(height: 20),
                SectionLabel(context.l10n.checklist),
                SubstepsEditor(
                  substeps: _substeps,
                  color: _color,
                  onChanged: (list) => _substeps = list,
                ),
              ],
            ],
            const SizedBox(height: 20),
            SectionLabel(context.l10n.icon),
            IconPicker(
              selected: _icon,
              color: _color,
              onSelected: (icon) => setState(() => _icon = icon),
            ),
            const SizedBox(height: 20),
            SectionLabel(context.l10n.color),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ColorPicker(
                  selected: _color,
                  onSelected: (c) => setState(() => _color = c),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SectionLabel(context.l10n.cover_image),
            CoverPicker(
              path: _cover,
              color: _color,
              onPick: _pickCover,
              onRemove: () => setState(() => _cover = ''),
            ),
            const SizedBox(height: 20),
            SectionLabel(context.l10n.category),
            CategoryPicker(
              selected: _category,
              onSelected: (c) => setState(() => _category = c),
            ),
            if (_kind != HabitKind.negative) ...[
              const SizedBox(height: 20),
              SectionLabel(context.l10n.frequency),
              IntervalSelector(
                interval: _interval,
                frequency: _frequency,
                weekdays: _scheduleWeekdays,
                every: _scheduleEvery,
                onIntervalChanged: (interval) => setState(() {
                  _interval = interval;
                  _frequency = switch (interval) {
                    HabitInterval.weekly => 3,
                    HabitInterval.monthly => 10,
                    _ => 1,
                  };
                }),
                onFrequencyChanged: (value) =>
                    setState(() => _frequency = value),
                onWeekdaysChanged: (days) =>
                    setState(() => _scheduleWeekdays = days),
                onEveryChanged: (v) => setState(() => _scheduleEvery = v),
              ),
            ],
            if (_kind != HabitKind.negative && _planning) ...[
              const SizedBox(height: 20),
              SectionLabel(context.l10n.habit_time),
              HabitTimeFields(
                startMinute: _startMinute,
                durationMinutes: _durationMinutes,
                color: _color,
                onChanged: (start, duration) => setState(() {
                  _startMinute = start;
                  _durationMinutes = duration;
                }),
              ),
            ],
            const SizedBox(height: 20),
            SectionLabel(context.l10n.reminders),
            for (final reminder in _reminders)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ReminderTile(
                  reminder: reminder,
                  onEdit: () => _editReminder(reminder),
                  onDelete: () =>
                      setState(() => _reminders.remove(reminder)),
                ),
              ),
            AddReminderButton(onTap: _addReminder),
            const SizedBox(height: 24),
          ],
        ),
    );
  }
}
