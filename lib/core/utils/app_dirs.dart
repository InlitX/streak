import 'dart:io';

import 'package:path_provider/path_provider.dart';

const appDataFolder = 'Streak';

bool get isMobile => Platform.isAndroid || Platform.isIOS;

Future<Directory> appDataDir() async {
  final root = await getApplicationDocumentsDirectory();
  if (isMobile) return root;
  final dir = Directory('${root.path}/$appDataFolder');
  if (!dir.existsSync()) dir.createSync(recursive: true);
  return dir;
}
