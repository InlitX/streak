import 'package:flutter/material.dart';
import 'package:streak/app/theme/app_palette.dart';
import 'package:streak/core/database/local_store.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/utils/cover_storage.dart';
import 'package:streak/core/utils/money_format.dart';
import 'package:streak/core/widgets/celebration_overlay.dart';
import 'package:streak/services/app_icon_service.dart';
import 'package:streak/services/backup_service.dart';
import 'package:streak/services/home_widget_service.dart';

Locale localeFromCode(String code) {
  final parts = code.split(RegExp('[_-]'));
  String? script;
  String? country;
  for (final part in parts.skip(1)) {
    if (part.length == 4) {
      script = part;
    } else if (part.isNotEmpty) {
      country = part;
    }
  }
  return Locale.fromSubtags(
    languageCode: parts.first,
    scriptCode: script,
    countryCode: country,
  );
}

class SettingsController extends ChangeNotifier {
  static const int defaultWidgetBg = 0xFF101014;

  SettingsController() {
    _load();
    if (_autoBackup > 0) Future.microtask(runAutoBackup);
  }

  Future<void> reloadFromStore() async {
    _load();
    notifyListeners();
  }

  void _load() {
    _themeMode = ThemeMode.values[LocalStore.setting('themeMode', 0)];
    _weekStart = LocalStore.setting('weekStart', 1);
    _onboardingDone = LocalStore.setting('onboardingDone', false);
    _localeCode = LocalStore.setting('locale', '');
    _appBackground = LocalStore.setting('appBackground', 2);
    _bgImage = LocalStore.setting('bgImage', '');
    _checkStyle = LocalStore.setting('checkStyle', 0);
    _profileName = LocalStore.setting('profileName', '');
    _currency = LocalStore.setting('currency', defaultCurrencySymbol());
    _profilePhoto = LocalStore.setting('profilePhoto', '');
    _appIcon = LocalStore.setting('appIcon', 0);
    _accentColor = LocalStore.setting('accentColor', AppPalette.brand.toARGB32());
    _heatmapMode = LocalStore.setting('heatmapMode', 0);
    _startView = LocalStore.setting('startView', 0);
    _planningEnabled = LocalStore.setting('planningEnabled', false);
    _cardActivity = LocalStore.setting('cardActivity', true);
    _viewSwitcher = LocalStore.setting('viewSwitcher', true);
    _compactCards = LocalStore.setting('compactCards', false);
    _todosEnabled = LocalStore.setting('todosEnabled', true);
    _sortCompletedLast = LocalStore.setting('sortCompletedLast', true);
    _todayOnly = LocalStore.setting('todayOnly', false);
    _notesEnabled = LocalStore.setting('notesEnabled', true);
    _quoteSource = LocalStore.setting('quoteSource', 0);
    _customQuotes =
        List<String>.from(LocalStore.setting('customQuotes', const <String>[]));
    _focusEnabled = LocalStore.setting('focusEnabled', true);
    _focusClockStyle = LocalStore.setting('focusClockStyle', 0);
    _focusScene = LocalStore.setting('focusScene', 0);
    _focusImage = LocalStore.setting('focusImage', '');
    _focusTracks =
        List<String>.from(LocalStore.setting('focusTracks', const <String>[]));
    _focusShuffle = LocalStore.setting('focusShuffle', false);
    _focusDailyGoal = LocalStore.setting('focusDailyGoal', 0);
    _focusKeepAwake = LocalStore.setting('focusKeepAwake', true);
    _focusImages =
        List<String>.from(LocalStore.setting('focusImages', const <String>[]));
    _hiddenScenes =
        List<int>.from(LocalStore.setting('hiddenScenes', const <int>[]));
    _hiddenTracks =
        List<String>.from(LocalStore.setting('hiddenTracks', const <String>[]));
    _appStyle = LocalStore.setting(
      'appStyle',
      LocalStore.setting('homeLayout', 0),
    );
    _celebration = CelebrationStyle.values[LocalStore.setting('celebration', 0)
        .clamp(0, CelebrationStyle.values.length - 1)];
    _appLock = LocalStore.setting('appLock', false);
    _appLockDelay = LocalStore.setting('appLockDelay', 0);
    _dayCutoff = LocalStore.setting('dayCutoff', 0);
    AppClock.cutoffHour = _dayCutoff;
    _autoBackup = LocalStore.setting('autoBackup', 0);
    _autoBackupAt = LocalStore.setting('autoBackupAt', '');
    _autoBackupFolder = LocalStore.setting('autoBackupFolder', '');
    _widgetBgColor = LocalStore.setting('widgetBgColor', defaultWidgetBg);
    _widgetOpacity = LocalStore.setting('widgetOpacity', 100);
    _widgetBorder = LocalStore.setting('widgetBorder', false);
    _syncWidgetStyle();
  }

  late ThemeMode _themeMode;
  late int _weekStart;
  late bool _onboardingDone;
  late String _localeCode;
  late int _appBackground;
  late String _bgImage;
  late int _checkStyle;
  late String _profileName;
  late String _currency;
  late String _profilePhoto;
  late int _appIcon;
  late int _accentColor;
  late int _heatmapMode;
  late int _startView;
  late bool _planningEnabled;
  late bool _cardActivity;
  late bool _viewSwitcher;
  late bool _compactCards;
  late bool _todosEnabled;
  late int _appStyle;
  late bool _sortCompletedLast;
  late bool _todayOnly;
  late bool _notesEnabled;
  late int _quoteSource;
  late List<String> _customQuotes;
  late bool _focusEnabled;
  late int _focusClockStyle;
  late int _focusScene;
  late String _focusImage;
  late List<String> _focusTracks;
  late bool _focusShuffle;
  late int _focusDailyGoal;
  late bool _focusKeepAwake;
  late List<String> _focusImages;
  late List<int> _hiddenScenes;
  late List<String> _hiddenTracks;
  late CelebrationStyle _celebration;
  late bool _appLock;
  late int _appLockDelay;
  late int _dayCutoff;
  late int _autoBackup;
  late String _autoBackupAt;
  late String _autoBackupFolder;
  late int _widgetBgColor;
  late int _widgetOpacity;
  late bool _widgetBorder;

  ThemeMode get themeMode => _themeMode;
  int get weekStart => _weekStart;
  bool get onboardingDone => _onboardingDone;
  String get localeCode => _localeCode;
  Locale? get locale => _localeCode.isEmpty ? null : localeFromCode(_localeCode);

  int get appBackground => _appBackground;

  String get bgImage => _bgImage;

  int get checkStyle => _checkStyle;
  bool get isCircleCheck => _checkStyle == 1;

  String get currency => _currency;

  Future<void> setCurrency(String value) async {
    _currency = value;
    await LocalStore.writeSetting('currency', value);
    notifyListeners();
  }

  String get profileName => _profileName;
  String get profilePhoto => _profilePhoto;

  int get appIcon => _appIcon;

  Color get accentColor => Color(_accentColor);

  Future<void> setAccentColor(Color color) async {
    _accentColor = color.toARGB32();
    await LocalStore.writeSetting('accentColor', _accentColor);
    notifyListeners();
  }

  int get heatmapMode => _heatmapMode;

  Future<void> setHeatmapMode(int value) async {
    _heatmapMode = value;
    await LocalStore.writeSetting('heatmapMode', value);
    notifyListeners();
  }

  int get startView => _startView;

  int get openingMode => _startView == 0 ? _heatmapMode : _startView - 1;

  Future<void> setStartView(int value) async {
    _startView = value;
    await LocalStore.writeSetting('startView', value);
    notifyListeners();
  }

  bool get planningEnabled => _planningEnabled;

  Future<void> setPlanningEnabled(bool value) async {
    _planningEnabled = value;
    await LocalStore.writeSetting('planningEnabled', value);
    notifyListeners();
  }

  bool get cardActivity => _cardActivity;

  Future<void> setCardActivity(bool value) async {
    _cardActivity = value;
    await LocalStore.writeSetting('cardActivity', value);
    notifyListeners();
  }

  bool get viewSwitcher => _viewSwitcher;

  Future<void> setViewSwitcher(bool value) async {
    _viewSwitcher = value;
    await LocalStore.writeSetting('viewSwitcher', value);
    notifyListeners();
  }

  bool get compactCards => _compactCards;

  Future<void> setCompactCards(bool value) async {
    _compactCards = value;
    await LocalStore.writeSetting('compactCards', value);
    notifyListeners();
  }

  bool get todosEnabled => _todosEnabled;

  Future<void> setTodosEnabled(bool value) async {
    _todosEnabled = value;
    await LocalStore.writeSetting('todosEnabled', value);
    notifyListeners();
  }

  bool get sortCompletedLast => _sortCompletedLast;
  bool get todayOnly => _todayOnly;
  bool get notesEnabled => _notesEnabled;

  bool get focusEnabled => _focusEnabled;
  int get focusClockStyle => _focusClockStyle;
  int get focusScene => _focusScene;
  String get focusImage => _focusImage;

  Future<void> setFocusEnabled(bool value) async {
    _focusEnabled = value;
    await LocalStore.writeSetting('focusEnabled', value);
    notifyListeners();
  }

  Future<void> setFocusClockStyle(int value) async {
    _focusClockStyle = value;
    await LocalStore.writeSetting('focusClockStyle', value);
    notifyListeners();
  }

  Future<void> setFocusScene(int value) async {
    _focusScene = value;
    await LocalStore.writeSetting('focusScene', value);
    notifyListeners();
  }

  Future<void> setFocusImage(String path) async {
    _focusImage = path;
    await LocalStore.writeSetting('focusImage', path);
    notifyListeners();
  }
  List<String> get focusTracks => List.unmodifiable(_focusTracks);
  bool get focusShuffle => _focusShuffle;
  int get focusDailyGoal => _focusDailyGoal;
  bool get focusKeepAwake => _focusKeepAwake;
  List<String> get focusImages => List.unmodifiable(_focusImages);

  List<int> get hiddenScenes => List.unmodifiable(_hiddenScenes);

  List<String> get hiddenTracks => List.unmodifiable(_hiddenTracks);

  bool isSceneHidden(int scene) => _hiddenScenes.contains(scene);

  bool isTrackHidden(String id) => _hiddenTracks.contains(id);

  Future<void> hideScene(int scene) async {
    if (scene <= 0 || _hiddenScenes.contains(scene)) return;
    _hiddenScenes = [..._hiddenScenes, scene];
    await LocalStore.writeSetting('hiddenScenes', _hiddenScenes);
    if (_focusScene == scene) {
      _focusScene = 0;
      await LocalStore.writeSetting('focusScene', 0);
    }
    notifyListeners();
  }

  Future<void> hideTrack(String id) async {
    if (_hiddenTracks.contains(id)) return;
    _hiddenTracks = [..._hiddenTracks, id];
    await LocalStore.writeSetting('hiddenTracks', _hiddenTracks);
    notifyListeners();
  }

  Future<void> restoreScenes() async {
    _hiddenScenes = const [];
    await LocalStore.writeSetting('hiddenScenes', _hiddenScenes);
    notifyListeners();
  }

  Future<void> restoreTracks() async {
    _hiddenTracks = const [];
    await LocalStore.writeSetting('hiddenTracks', _hiddenTracks);
    notifyListeners();
  }

  Future<void> setFocusDailyGoal(int minutes) async {
    _focusDailyGoal = minutes;
    await LocalStore.writeSetting('focusDailyGoal', minutes);
    notifyListeners();
  }

  int get appLockDelay => _appLockDelay;

  Future<void> setAppLockDelay(int seconds) async {
    _appLockDelay = seconds;
    await LocalStore.writeSetting('appLockDelay', seconds);
    notifyListeners();
  }

  CelebrationStyle get celebration => _celebration;

  Future<void> setCelebration(int index) async {
    _celebration = CelebrationStyle.values[index];
    await LocalStore.writeSetting('celebration', index);
    notifyListeners();
  }

  Future<void> setFocusKeepAwake(bool value) async {
    _focusKeepAwake = value;
    await LocalStore.writeSetting('focusKeepAwake', value);
    notifyListeners();
  }

  Future<void> addFocusImage(String path) async {
    if (_focusImages.length >= 10) return;
    _focusImages = [..._focusImages, path];
    await LocalStore.writeSetting('focusImages', _focusImages);
    notifyListeners();
  }

  Future<void> removeFocusImage(String path) async {
    _focusImages = _focusImages.where((p) => p != path).toList();
    await LocalStore.writeSetting('focusImages', _focusImages);
    if (_focusImage == path) {
      _focusImage = '';
      await LocalStore.writeSetting('focusImage', '');
      _focusScene = 0;
      await LocalStore.writeSetting('focusScene', 0);
    }
    notifyListeners();
    await CoverStorage.forget(path);
  }

  bool get appLock => _appLock;

  Future<void> setAppLock(bool value) async {
    _appLock = value;
    await LocalStore.writeSetting('appLock', value);
    notifyListeners();
  }

  int get dayCutoff => _dayCutoff;

  Future<void> setDayCutoff(int hour) async {
    _dayCutoff = hour.clamp(0, 6);
    AppClock.cutoffHour = _dayCutoff;
    await LocalStore.writeSetting('dayCutoff', _dayCutoff);
    notifyListeners();
    await HomeWidgetService.sync(LocalStore.readHabits());
  }

  int get autoBackup => _autoBackup;
  DateTime? get autoBackupAt => DateTime.tryParse(_autoBackupAt);
  String get autoBackupFolder => _autoBackupFolder;

  Future<void> setAutoBackup(int value) async {
    if (_autoBackup == value) return;
    _autoBackup = value;
    await LocalStore.writeSetting('autoBackup', value);
    notifyListeners();
    if (value > 0) await runAutoBackup(force: true);
  }

  Future<void> setAutoBackupFolder(String path) async {
    _autoBackupFolder = path;
    await LocalStore.writeSetting('autoBackupFolder', path);
    notifyListeners();
  }

  Future<bool> runAutoBackup({bool force = false}) async {
    if (_autoBackup == 0) return false;
    final last = autoBackupAt;
    if (!force && last != null) {
      final due = _autoBackup == 1
          ? last.add(const Duration(days: 1))
          : last.add(const Duration(days: 7));
      if (DateTime.now().isBefore(due)) return false;
    }
    final path = await BackupService.runAuto(folder: _autoBackupFolder);
    if (path == null) return false;
    _autoBackupAt = DateTime.now().toIso8601String();
    await LocalStore.writeSetting('autoBackupAt', _autoBackupAt);
    notifyListeners();
    return true;
  }

  Future<void> addFocusTrack(String encoded) async {
    if (_focusTracks.length >= 10) return;
    _focusTracks = [..._focusTracks, encoded];
    await LocalStore.writeSetting('focusTracks', _focusTracks);
    notifyListeners();
  }

  Future<void> removeFocusTrack(String encoded) async {
    _focusTracks = _focusTracks.where((t) => t != encoded).toList();
    await LocalStore.writeSetting('focusTracks', _focusTracks);
    notifyListeners();
  }

  Future<void> setFocusShuffle(bool value) async {
    _focusShuffle = value;
    await LocalStore.writeSetting('focusShuffle', value);
    notifyListeners();
  }

  Future<void> setNotesEnabled(bool value) async {
    _notesEnabled = value;
    await LocalStore.writeSetting('notesEnabled', value);
    notifyListeners();
  }

  int get quoteSource => _quoteSource;

  List<String> get customQuotes => List.unmodifiable(_customQuotes);

  Future<void> setQuoteSource(int value) async {
    _quoteSource = value;
    await LocalStore.writeSetting('quoteSource', value);
    notifyListeners();
  }

  Future<void> addCustomQuote(String text) async {
    final quote = text.trim();
    if (quote.isEmpty || _customQuotes.contains(quote)) return;
    _customQuotes = [..._customQuotes, quote];
    await LocalStore.writeSetting('customQuotes', _customQuotes);
    notifyListeners();
  }

  Future<void> editCustomQuote(int index, String text) async {
    final quote = text.trim();
    if (index < 0 || index >= _customQuotes.length || quote.isEmpty) return;
    _customQuotes = [..._customQuotes]..[index] = quote;
    await LocalStore.writeSetting('customQuotes', _customQuotes);
    notifyListeners();
  }

  Future<void> removeCustomQuote(int index) async {
    if (index < 0 || index >= _customQuotes.length) return;
    _customQuotes = [..._customQuotes]..removeAt(index);
    await LocalStore.writeSetting('customQuotes', _customQuotes);
    notifyListeners();
  }

  int get appStyle => _appStyle;
  bool get isMinimalStyle => _appStyle == 1;

  Future<void> setAppStyle(int value) async {
    _appStyle = value;
    await LocalStore.writeSetting('appStyle', value);
    notifyListeners();
  }

  Future<void> setSortCompletedLast(bool value) async {
    _sortCompletedLast = value;
    await LocalStore.writeSetting('sortCompletedLast', value);
    notifyListeners();
  }

  Future<void> setTodayOnly(bool value) async {
    _todayOnly = value;
    await LocalStore.writeSetting('todayOnly', value);
    notifyListeners();
  }

  Future<void> setLanguage(String code) async {
    _localeCode = code;
    await LocalStore.writeSetting('locale', code);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await LocalStore.writeSetting('themeMode', mode.index);
    notifyListeners();
  }

  Future<void> setWeekStart(int weekday) async {
    _weekStart = weekday;
    await LocalStore.writeSetting('weekStart', weekday);
    notifyListeners();
  }

  Future<void> setAppBackground(int value) async {
    _appBackground = value;
    await LocalStore.writeSetting('appBackground', value);
    notifyListeners();
  }

  Future<void> setBackgroundImage(String path) async {
    _bgImage = path;
    await LocalStore.writeSetting('bgImage', path);
    notifyListeners();
  }

  Future<void> setCheckStyle(int value) async {
    _checkStyle = value;
    await LocalStore.writeSetting('checkStyle', value);
    notifyListeners();
  }

  Future<void> setProfileName(String name) async {
    _profileName = name.trim();
    await LocalStore.writeSetting('profileName', _profileName);
    notifyListeners();
  }

  Future<void> setProfilePhoto(String path) async {
    _profilePhoto = path;
    await LocalStore.writeSetting('profilePhoto', path);
    notifyListeners();
  }

  Future<void> setAppIcon(int index) async {
    _appIcon = index;
    await LocalStore.writeSetting('appIcon', index);
    notifyListeners();
    await AppIconService.apply(index);
  }

  Color get widgetBgColor => Color(_widgetBgColor);

  int get widgetOpacity => _widgetOpacity;

  bool get widgetBorder => _widgetBorder;

  Future<void> setWidgetBgColor(Color color) async {
    _widgetBgColor = color.toARGB32();
    await LocalStore.writeSetting('widgetBgColor', _widgetBgColor);
    notifyListeners();
    await _syncWidgetStyle();
  }

  Future<void> setWidgetOpacity(int percent) async {
    _widgetOpacity = percent.clamp(0, 100);
    await LocalStore.writeSetting('widgetOpacity', _widgetOpacity);
    notifyListeners();
    await _syncWidgetStyle();
  }

  Future<void> setWidgetBorder(bool value) async {
    _widgetBorder = value;
    await LocalStore.writeSetting('widgetBorder', value);
    notifyListeners();
    await _syncWidgetStyle();
  }

  Future<void> _syncWidgetStyle() => HomeWidgetService.syncWidgetStyle(
        bgColor: _widgetBgColor,
        opacity: _widgetOpacity,
        border: _widgetBorder,
      );

  Future<void> completeOnboarding() async {
    _onboardingDone = true;
    await LocalStore.writeSetting('onboardingDone', true);
    notifyListeners();
  }
}
