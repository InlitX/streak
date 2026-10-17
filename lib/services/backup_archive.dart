import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive_io.dart';

const backupJsonName = 'backup.json';
const _files = 'files';

const backupSettingKeys = {
  'accentColor',
  'appBackground',
  'appStyle',
  'bgImage',
  'cardActivity',
  'celebration',
  'checkStyle',
  'compactCards',
  'consistencyPeriod',
  'currency',
  'customQuotes',
  'dayCutoff',
  'difficultyOption',
  'focusAlert',
  'focusBreakMinutes',
  'focusClockStyle',
  'focusDailyGoal',
  'focusEnabled',
  'focusHold',
  'focusImage',
  'focusImages',
  'focusKeepAwake',
  'focusLeadIn',
  'focusLongBreak',
  'focusMinutes',
  'focusProfiles',
  'focusRepeatOne',
  'focusScene',
  'focusShuffle',
  'focusVolume',
  'focusLabels',
  'focusTrack',
  'focusTracks',
  'focusWholeRounds',
  'heatmapMode',
  'heatmapPath',
  'heatmapRolling',
  'hiddenScenes',
  'hiddenTracks',
  'islandEnabled',
  'islandName',
  'islandOwned',
  'islandSpent',
  'locale',
  'notesEnabled',
  'planTodos',
  'planContent',
  'planMonth',
  'todoPapers',
  'planningEnabled',
  'profileName',
  'profilePhoto',
  'quietWhenDone',
  'quoteSource',
  'readableCopy',
  'showTodayProgress',
  'sortCompletedLast',
  'startView',
  'swipeCards',
  'themeMode',
  'todayOnly',
  'hideDone',
  'pastFirst',
  'hideTracking',
  'todoLowFirst',
  'todosEnabled',
  'trackingOption',
  'vacationAll',
  'vacationAllIds',
  'viewSwitcher',
  'weekStart',
  'widgetBgColor',
  'widgetBorder',
  'widgetOpacity',
};

class BackupArchive {
  const BackupArchive._();

  static Future<void> pack(Map<String, Object?> payload, String target) =>
      Isolate.run(() => _pack(payload, target));

  static Future<String?> unpack(List<int> bytes, String dataDir) =>
      Isolate.run(() => _unpack(bytes, dataDir));

  static Future<void> _pack(Map<String, Object?> payload, String target) async {
    final zip = ZipFileEncoder()..create(target);
    final packed = <String, String>{};

    Object? swap(Object? value) => switch (value) {
          Map() => {
              for (final entry in value.entries) '${entry.key}': swap(entry.value),
            },
          List() => [for (final item in value) swap(item)],
          String() => _packed(value, packed),
          _ => value,
        };

    final json = const JsonEncoder.withIndent('  ').convert(swap(payload));
    for (final entry in packed.entries) {
      await zip.addFile(File(entry.key), entry.value);
    }
    zip.addArchiveFile(ArchiveFile.string(backupJsonName, json));
    await zip.close();
  }

  static String _packed(String value, Map<String, String> packed) {
    final (path, rest) = _split(value);
    if (!_absolute(path) || !File(path).existsSync()) return value;
    final name = packed[path] ??= _nameFor(path, packed.values.toSet());
    return '$name$rest';
  }

  static String _nameFor(String path, Set<String> used) {
    final parts = path.replaceAll(r'\', '/').split('/');
    final folder = parts.length > 1 ? parts[parts.length - 2] : 'other';
    final file = parts.last;
    var name = '$_files/$folder/$file';
    for (var i = 2; used.contains(name); i++) {
      name = '$_files/$folder/${i}_$file';
    }
    return name;
  }

  static Future<String?> _unpack(List<int> bytes, String dataDir) async {
    final archive = ZipDecoder().decodeBytes(bytes);
    final json = archive.findFile(backupJsonName);
    if (json == null) return null;

    final placed = <String, String>{};
    for (final entry in archive.files) {
      final name = entry.name.replaceAll(r'\', '/');
      if (!entry.isFile || !name.startsWith('$_files/')) continue;
      final inside = name.substring(_files.length + 1);
      if (inside.split('/').any((part) => part.isEmpty || part == '..')) {
        continue;
      }
      final content = entry.content as List<int>;
      final dest = _freeSpot(File('$dataDir/$inside'), content.length);
      dest.parent.createSync(recursive: true);
      if (!dest.existsSync()) dest.writeAsBytesSync(content, flush: true);
      placed[name] = dest.path;
    }

    Object? swap(Object? value) => switch (value) {
          Map() => {
              for (final entry in value.entries) '${entry.key}': swap(entry.value),
            },
          List() => [for (final item in value) swap(item)],
          String() => _unpacked(value, placed),
          _ => value,
        };

    final raw = utf8.decode(json.content as List<int>, allowMalformed: true);
    return jsonEncode(swap(jsonDecode(raw)));
  }

  static File _freeSpot(File file, int length) {
    var candidate = file;
    for (var i = 2;
        candidate.existsSync() && candidate.lengthSync() != length;
        i++) {
      final name = file.uri.pathSegments.last;
      candidate = File('${file.parent.path}/${i}_$name');
    }
    return candidate;
  }

  static String _unpacked(String value, Map<String, String> placed) {
    final (path, rest) = _split(value);
    final local = placed[path];
    return local == null ? value : '$local$rest';
  }

  static (String, String) _split(String value) {
    final cut = value.indexOf(RegExp(r'[?|]'));
    return cut < 0
        ? (value, '')
        : (value.substring(0, cut), value.substring(cut));
  }

  static bool _absolute(String path) =>
      path.length > 3 &&
      !path.contains('\n') &&
      (path.startsWith('/') || RegExp(r'^[A-Za-z]:[\\/]').hasMatch(path));
}
