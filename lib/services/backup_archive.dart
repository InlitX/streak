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
  'colorTheme',
  'compactCards',
  'consistencyPeriod',
  'currency',
  'customQuotes',
  'dayCutoff',
  'difficultyOption',
  'focusAlert',
  'focusAutoNext',
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

  static Future<String?> unpack(String path, String dataDir) =>
      Isolate.run(() => _unpack(path, dataDir));

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

  static Future<String?> _unpack(String path, String dataDir) async {
    final input = InputFileStream(path);
    final placed = <String, String>{};
    ZipFile? json;
    try {
      for (final header in ZipDirectory.read(input).fileHeaders) {
        final file = header.file!;
        final name = file.filename.replaceAll(r'\', '/');
        if (name == backupJsonName) {
          json = file;
          continue;
        }
        if (name.endsWith('/') || !name.startsWith('$_files/')) continue;
        final inside = name.substring(_files.length + 1);
        if (inside.split('/').any((part) => part.isEmpty || part == '..')) {
          continue;
        }
        final dest =
            _freeSpot(File('$dataDir/$inside'), file.uncompressedSize ?? -1);
        dest.parent.createSync(recursive: true);
        if (!dest.existsSync()) _extract(file, dest.path);
        placed[name] = dest.path;
      }
      if (json == null) return null;
      final raw = utf8.decode(json.content, allowMalformed: true);
      Object? swap(Object? value) => switch (value) {
            Map() => {
                for (final entry in value.entries)
                  '${entry.key}': swap(entry.value),
              },
            List() => [for (final item in value) swap(item)],
            String() => _unpacked(value, placed),
            _ => value,
          };

      return jsonEncode(swap(jsonDecode(raw)));
    } finally {
      input.closeSync();
    }
  }

  static void _extract(ZipFile file, String path) {
    final output = OutputFileStream(path);
    try {
      final raw = file.rawContent!;
      switch (file.compressionMethod) {
        case ZipFile.zipCompressionStore:
          output.writeInputStream(raw);
        case ZipFile.zipCompressionDeflate:
          Inflate.stream(raw, output);
        default:
          output.writeBytes(file.content);
      }
    } finally {
      output.closeSync();
    }
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
