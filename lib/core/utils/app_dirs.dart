import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

const appDataFolder = 'Streak';

bool get isMobile => Platform.isAndroid || Platform.isIOS;

bool get hasAppIcons => isMobile;

bool get hasHomeWidgets =>
    defaultTargetPlatform == TargetPlatform.android ||
    defaultTargetPlatform == TargetPlatform.iOS;

bool get hasBiometricLock => !Platform.isLinux;

Future<Directory> appDataDir() async {
  if (Platform.isLinux) {
    return getApplicationSupportDirectory()
        .timeout(const Duration(seconds: 15));
  }
  final root = await getApplicationDocumentsDirectory()
      .timeout(const Duration(seconds: 15));
  if (isMobile) return root;
  final dir = Directory('${root.path}/$appDataFolder');
  if (!dir.existsSync()) dir.createSync(recursive: true);
  return dir;
}
