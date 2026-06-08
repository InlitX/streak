import 'package:flutter/material.dart';
import 'package:streak/app/theme/app_palette.dart';
import 'package:streak/core/database/local_store.dart';
import 'package:streak/services/app_icon_service.dart';

class SettingsController extends ChangeNotifier {
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

  ThemeMode get themeMode => _themeMode;
  int get weekStart => _weekStart;
  bool get onboardingDone => _onboardingDone;
  String get localeCode => _localeCode;
  Locale? get locale => _localeCode.isEmpty ? null : Locale(_localeCode);

  /// 0 = solid, 1 = gradient, 2 = dots, 3 = OLED black, 4 = custom image.
  int get appBackground => _appBackground;

  /// Background image path, used when [appBackground] == 4.
  String get bgImage => _bgImage;

  /// 0 = square (rounded), 1 = circle.
  int get checkStyle => _checkStyle;
  bool get isCircleCheck => _checkStyle == 1;

  /// Empty until the user sets one. Used to personalize notifications.
  String get profileName => _profileName;
  String get profilePhoto => _profilePhoto;

  /// 0 = default, 1 = neutral, 2 = accent.
  int get appIcon => _appIcon;

  /// User-chosen accent (primary) colour for the whole app.
  Color get accentColor => Color(_accentColor);

  Future<void> setAccentColor(Color color) async {
    _accentColor = color.toARGB32();
    await LocalStore.writeSetting('accentColor', _accentColor);
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

  Future<void> completeOnboarding() async {
    _onboardingDone = true;
    await LocalStore.writeSetting('onboardingDone', true);
    notifyListeners();
  }
}
