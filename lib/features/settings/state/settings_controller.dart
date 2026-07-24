import 'package:flutter/material.dart';
import 'package:streak/app/theme/app_palette.dart';
import 'package:streak/core/database/local_store.dart';
import 'package:streak/services/app_icon_service.dart';
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
    _themeMode = ThemeMode.values[LocalStore.setting('themeMode', 0)];
    _weekStart = LocalStore.setting('weekStart', 1);
    _onboardingDone = LocalStore.setting('onboardingDone', false);
    _localeCode = LocalStore.setting('locale', '');
    _appBackground = LocalStore.setting('appBackground', 0);
    _bgImage = LocalStore.setting('bgImage', '');
    _checkStyle = LocalStore.setting('checkStyle', 0);
    _profileName = LocalStore.setting('profileName', '');
    _profilePhoto = LocalStore.setting('profilePhoto', '');
    _appIcon = LocalStore.setting('appIcon', 0);
    _accentColor = LocalStore.setting('accentColor', AppPalette.brand.toARGB32());
    _heatmapMode = LocalStore.setting('heatmapMode', 0);
    _sortCompletedLast = LocalStore.setting('sortCompletedLast', true);
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
  late String _profilePhoto;
  late int _appIcon;
  late int _accentColor;
  late int _heatmapMode;
  late bool _sortCompletedLast;
  late int _widgetBgColor;
  late int _widgetOpacity;
  late bool _widgetBorder;

  ThemeMode get themeMode => _themeMode;
  int get weekStart => _weekStart;
  bool get onboardingDone => _onboardingDone;
  String get localeCode => _localeCode;
  Locale? get locale => _localeCode.isEmpty ? null : localeFromCode(_localeCode);

  // 0 solid, 1 gradient, 2 dots, 3 OLED black, 4 custom image.
  int get appBackground => _appBackground;

  String get bgImage => _bgImage;

  int get checkStyle => _checkStyle;
  bool get isCircleCheck => _checkStyle == 1;

  String get profileName => _profileName;
  String get profilePhoto => _profilePhoto;

  // 0 default, 1 neutral, 2 accent.
  int get appIcon => _appIcon;

  Color get accentColor => Color(_accentColor);

  Future<void> setAccentColor(Color color) async {
    _accentColor = color.toARGB32();
    await LocalStore.writeSetting('accentColor', _accentColor);
    notifyListeners();
  }

  // 0 week, 1 month, 2 year.
  int get heatmapMode => _heatmapMode;

  Future<void> setHeatmapMode(int value) async {
    _heatmapMode = value;
    await LocalStore.writeSetting('heatmapMode', value);
    notifyListeners();
  }

  bool get sortCompletedLast => _sortCompletedLast;

  Future<void> setSortCompletedLast(bool value) async {
    _sortCompletedLast = value;
    await LocalStore.writeSetting('sortCompletedLast', value);
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
