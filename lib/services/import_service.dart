import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Color;

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:file_picker/file_picker.dart';
import 'package:streak/app/theme/app_palette.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/features/habits/data/completion.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:uuid/uuid.dart';

const _kDatabaseHint =
    'That looks like a database file. In Loop Habit Tracker open Settings, '
    'choose "Export as CSV", and pick the zip it creates.';

class ImportOutcome {
  ImportOutcome({
    required this.habits,
    required this.source,
    required this.entries,
    required this.skipped,
  });

  final List<Habit> habits;
  final String source;
  final int entries;
  final int skipped;
}

class _RawHabit {
  _RawHabit(
    this.name, {
    this.color,
    this.kind = HabitKind.positive,
    this.target = 1,
    this.unit = '',
  });
  final String name;
  final int? color;
  final HabitKind kind;
  final int target;
  final String unit;
  final Map<DateTime, int> days = {};

  void mark(DateTime day, int count) {
    final d = DateTime(day.year, day.month, day.day);
    final v = count <= 0 ? 0 : count;
    if (v <= 0) return;
    final prev = days[d] ?? 0;
    if (v > prev) days[d] = v;
  }
}

class ImportService {
  const ImportService._();

  static const _uuid = Uuid();

  static Future<ImportOutcome?> pickAndParse() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Select an export from your habit app',
      type: FileType.any,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;

    final picked = result.files.single;
    final name = picked.name.toLowerCase();

    if (name.endsWith('.db') || name.endsWith('.sqlite')) {
      throw const ImportException(_kDatabaseHint);
    }

    List<int>? bytes = picked.bytes;
    if (bytes == null && picked.path != null) {
      try {
        bytes = await File(picked.path!).readAsBytes();
      } catch (e) {
        debugPrint('Could not read ${picked.path}: $e');
        throw const ImportException(
          'That file could not be read. Copy it to your phone first, then try '
          'again.',
        );
      }
    }
    if (bytes == null) {
      throw const ImportException('Could not read the selected file.');
    }

    return parseBytes(bytes, fileName: name);
  }

  static ImportOutcome parseBytes(List<int> bytes, {String fileName = ''}) {
    final name = fileName.toLowerCase();

    if (looksLikeSqlite(bytes)) throw const ImportException(_kDatabaseHint);

    if (name.endsWith('.zip') || looksLikeZip(bytes)) {
      final raw = _parseLoopZip(bytes);
      return _build(raw, 'Loop Habit Tracker');
    }

    final text = _decode(bytes);
    final trimmed = text.trimLeft();

    if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
      final decoded = _decodeJson(text);
      if (decoded != null) {
        if (_isStreakBackup(decoded)) {
          return _buildFromStreak(decoded);
        }
        if (_isHabitKit(decoded)) {
          return _build(_parseHabitKit(decoded), 'HabitKit');
        }
        final raw = _parseHabitica(decoded);
        if (raw.isNotEmpty) return _build(raw, 'Habitica');
        throw const ImportException('No habit history found in that file.');
      }
    }

    final delimiter = _detectDelimiter(text);
    final rows = _parseCsv(text, delimiter)
        .where((r) => r.any((c) => c.trim().isNotEmpty))
        .toList();
    if (rows.length < 2) {
      throw const ImportException(
        'That file has no rows to import. Expected a CSV, JSON or zip export.',
      );
    }

    final header = rows.first.map((c) => c.trim()).toList();
    final lower = header.map((c) => c.toLowerCase()).toList();

    if (lower.contains('habitname') && lower.contains('date')) {
      return _build(_parseHabitBull(header, rows.skip(1)), 'HabitBull');
    }
    if (_looksLikeLoopCsv(lower)) {
      return _build(_parseMatrix(header, rows.skip(1)), 'Loop Habit Tracker');
    }
    final habitCol = _indexOfAny(lower, const ['habit', 'name', 'habitname']);
    final dateCol = _indexOfAny(lower, const ['date', 'fecha', 'day', 'día', 'timestamp']);
    if (habitCol != null && dateCol != null && habitCol != dateCol) {
      return _build(_parseLong(lower, rows.skip(1)), 'CSV');
    }
    return _build(_parseMatrix(header, rows.skip(1)), 'CSV');
  }

  static ImportOutcome _build(List<_RawHabit> raw, String source) {
    final habits = <Habit>[];
    var totalEntries = 0;
    for (var i = 0; i < raw.length; i++) {
      final r = raw[i];
      final completions = <String, Completion>{};
      r.days.forEach((day, count) {
        final key = day.dayKey;
        completions[key] = Completion(date: key, count: count.toDouble());
      });
      totalEntries += completions.length;

      final createdAt = r.days.isEmpty
          ? DateTime.now()
          : r.days.keys.reduce((a, b) => a.isBefore(b) ? a : b);
      final measurable = r.kind == HabitKind.quantitative;
      habits.add(
        Habit(
          id: _uuid.v4(),
          name: r.name.trim().isEmpty ? 'Imported habit' : r.name.trim(),
          color: r.color != null
              ? Color(r.color!)
              : AppPalette.habitColors[i % AppPalette.habitColors.length],
          order: i,
          kind: r.kind,
          perDayTarget: measurable ? (r.target < 1 ? 1 : r.target).toDouble() : 1,
          unitLabel: measurable ? r.unit : '',
          completions: completions,
          createdAt: createdAt,
        ),
      );
    }
    if (habits.isEmpty) {
      throw const ImportException('No habits found in that file.');
    }
    return ImportOutcome(
      habits: habits,
      source: source,
      entries: totalEntries,
      skipped: 0,
    );
  }

  static ImportOutcome _buildFromStreak(dynamic decoded) {
    final list = decoded is List
        ? decoded
        : (decoded is Map && decoded['habits'] is List
            ? decoded['habits'] as List
            : const []);
    final habits = <Habit>[];
    for (final e in list) {
      if (e is! Map) continue;
      try {
        habits.add(Habit.fromMap(Map<String, dynamic>.from(e)));
      } catch (error) {
        debugPrint('Skipped a habit while importing: $error');
      }
    }
    if (habits.isEmpty) {
      throw const ImportException('No habits found in that backup.');
    }
    final entries =
        habits.fold<int>(0, (a, h) => a + h.completions.length);
    return ImportOutcome(
      habits: habits,
      source: 'Streak',
      entries: entries,
      skipped: 0,
    );
  }

  static List<_RawHabit> _parseLoopZip(List<int> bytes) {
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (e) {
      debugPrint('Could not open that zip: $e');
      throw const ImportException(
        'That zip could not be opened. In Loop Habit Tracker use '
        '"Export as CSV" and pick the zip it creates.',
      );
    }
    final files = <String, List<int>>{};
    for (final f in archive.files) {
      final content = f.isFile ? f.content : null;
      if (content is List<int>) {
        files[f.name.replaceAll('\\', '/')] = content;
      }
    }

    final habitsCsv = _entry(files, 'habits.csv');
    final byName = <String, _RawHabit>{};
    final ordered = <_RawHabit>[];
    final byPosition = <String, _RawHabit>{};

    if (habitsCsv != null) {
      final rows = _rows(_decode(habitsCsv));
      if (rows.length >= 2) {
        final lower = rows.first.map((c) => c.trim().toLowerCase()).toList();
        final nameIdx = lower.indexOf('name');
        final posIdx = lower.indexOf('position');
        final colorIdx = lower.indexOf('color');
        final typeIdx = lower.indexOf('type');
        final unitIdx = lower.indexOf('unit');
        final targetIdx = lower.indexOf('target value');
        String cell(List<String> row, int idx) =>
            idx >= 0 && row.length > idx ? row[idx].trim() : '';
        for (final row in rows.skip(1)) {
          if (nameIdx < 0 || row.length <= nameIdx) continue;
          final name = row[nameIdx].trim();
          if (name.isEmpty) continue;
          final numerical = cell(row, typeIdx).toUpperCase() == 'NUMERICAL';
          final target = numerical
              ? (double.tryParse(cell(row, targetIdx))?.round() ?? 1)
              : 1;
          final h = _RawHabit(
            name,
            color: _parseHexColor(cell(row, colorIdx)),
            kind: numerical ? HabitKind.quantitative : HabitKind.positive,
            target: target < 1 ? 1 : target,
            unit: cell(row, unitIdx),
          );
          ordered.add(h);
          byName[name] = h;
          if (posIdx >= 0 && row.length > posIdx) {
            byPosition[row[posIdx].trim()] = h;
          }
        }
      }
    }

    final topCheck = _entry(files, 'checkmarks.csv', topLevelOnly: true);
    if (topCheck != null) {
      final rows = _rows(_decode(topCheck));
      if (rows.length >= 2) {
        final header = rows.first.map((c) => c.trim()).toList();
        for (final row in rows.skip(1)) {
          if (row.isEmpty) continue;
          final date = _parseDate(row.first);
          if (date == null) continue;
          for (var i = 1; i < row.length && i < header.length; i++) {
            final name = header[i];
            if (name.isEmpty) continue;
            final h = byName.putIfAbsent(name, () {
              final n = _RawHabit(name);
              ordered.add(n);
              return n;
            });
            final v = _truthyCount(row[i]);
            if (v > 0) h.mark(date, v);
          }
        }
      }
    }

    for (final path in files.keys) {
      final lower = path.toLowerCase();
      if (!lower.endsWith('/checkmarks.csv')) continue;
      final folder = path.substring(0, path.length - '/checkmarks.csv'.length);
      final position = folder.split(' ').first.trim();
      final target = byPosition[position];
      if (target == null || target.days.isNotEmpty) continue;
      final rows = _rows(_decode(files[path]!));
      for (final row in rows.skip(1)) {
        if (row.length < 2) continue;
        final date = _parseDate(row[0]);
        if (date == null) continue;
        final v = _truthyCount(row[1]);
        if (v > 0) target.mark(date, v);
      }
    }

    if (ordered.isEmpty) {
      throw const ImportException(
        'No habits found in that zip. Use Loop\'s "Export as CSV".',
      );
    }
    return ordered;
  }

  static List<int>? _entry(Map<String, List<int>> files, String basename,
      {bool topLevelOnly = false}) {
    for (final e in files.entries) {
      final name = e.key.toLowerCase();
      if (topLevelOnly && name != basename) continue;
      if (name == basename || name.endsWith('/$basename')) return e.value;
    }
    return null;
  }

  static List<List<String>> _rows(String text) {
    final delimiter = _detectDelimiter(text);
    return _parseCsv(text, delimiter)
        .where((r) => r.any((c) => c.trim().isNotEmpty))
        .toList();
  }

  static int? _parseHexColor(String raw) {
    var s = raw.trim();
    if (s.startsWith('#')) s = s.substring(1);
    if (s.toLowerCase().startsWith('0x')) s = s.substring(2);
    if (s.length == 3) {
      s = s.split('').map((c) => '$c$c').join();
    }
    if (s.length == 6) s = 'FF$s';
    if (s.length != 8) return null;
    return int.tryParse(s, radix: 16);
  }

  static bool _looksLikeLoopCsv(List<String> lowerHeader) {
    if (lowerHeader.isEmpty) return false;
    final first = lowerHeader.first;
    return (first == 'date' || first == 'fecha') && lowerHeader.length >= 2;
  }

  static List<_RawHabit> _parseHabitBull(
      List<String> header, Iterable<List<String>> rows) {
    final lower = header.map((c) => c.toLowerCase()).toList();
    final nameIdx = lower.indexOf('habitname');
    final dateIdx = lower.indexOf('date');
    final valueIdx = lower.indexOf('value');
    final byName = <String, _RawHabit>{};
    for (final row in rows) {
      if (row.length <= nameIdx || row.length <= dateIdx) continue;
      final name = row[nameIdx].trim();
      if (name.isEmpty) continue;
      final date = _parseDate(row[dateIdx]);
      if (date == null) continue;
      final value = valueIdx >= 0 && row.length > valueIdx
          ? (int.tryParse(row[valueIdx].trim()) ?? 0)
          : 1;
      if (value <= 0) continue;
      byName.putIfAbsent(name, () => _RawHabit(name)).mark(date, value);
    }
    return byName.values.toList();
  }

  static bool _isHabitKit(dynamic decoded) =>
      decoded is Map &&
      decoded['habits'] is List &&
      (decoded['completions'] is List ||
          decoded['intervals'] is List ||
          (decoded['habits'] as List).any(
            (h) => h is Map && (h.containsKey('iconName') ||
                h.containsKey('orderIndex')),
          ));

  static List<_RawHabit> _parseHabitKit(dynamic decoded) {
    final habitsJson = decoded['habits'];
    if (habitsJson is! List) return const [];

    final targetById = <String, int>{};
    final intervals = decoded['intervals'];
    if (intervals is List) {
      for (final it in intervals) {
        if (it is Map && it['habitId'] != null) {
          final t = it['requiredNumberOfCompletionsPerDay'];
          if (t is num) targetById[it['habitId'].toString()] = t.toInt();
        }
      }
    }

    final byId = <String, _RawHabit>{};
    final ordered = <({int order, _RawHabit habit})>[];
    var archived = 0;
    for (var i = 0; i < habitsJson.length; i++) {
      final h = habitsJson[i];
      if (h is! Map) continue;
      if (h['archived'] == true) {
        archived++;
        continue;
      }
      final id = h['id']?.toString();
      if (id == null) continue;
      final target = targetById[id] ?? 1;
      final measurable = target > 1;
      final index = h['orderIndex'];
      final raw = _RawHabit(
        (h['name'] ?? '').toString(),
        color: _habitKitColor(h['color']?.toString()),
        kind: measurable ? HabitKind.quantitative : HabitKind.positive,
        target: measurable ? target : 1,
      );
      byId[id] = raw;
      ordered.add((order: index is num ? index.toInt() : i, habit: raw));
    }

    if (byId.isEmpty && archived > 0) {
      throw const ImportException(
        'Every habit in that file is archived. Un-archive the ones you want '
        'in HabitKit and export again.',
      );
    }

    final completions = decoded['completions'];
    if (completions is List) {
      for (final c in completions) {
        if (c is! Map) continue;
        final raw = byId[c['habitId']?.toString()];
        if (raw == null) continue;
        final date =
            _habitKitDate(c['date'], c['timezoneOffsetInMinutes']);
        if (date == null) continue;
        final amount = c['amountOfCompletions'];
        final n = amount is num ? amount.toInt() : 1;
        raw.mark(date, n <= 0 ? 1 : n);
      }
    }
    ordered.sort((a, b) => a.order.compareTo(b.order));
    return [for (final entry in ordered) entry.habit];
  }

  static DateTime? _habitKitDate(dynamic dateRaw, dynamic offsetRaw) {
    if (dateRaw is! String) return null;
    final utc = DateTime.tryParse(dateRaw);
    if (utc == null) return null;
    final offset = offsetRaw is num ? offsetRaw.toInt() : 0;
    final local = utc.toUtc().add(Duration(minutes: offset));
    return DateTime(local.year, local.month, local.day);
  }

  static int? _habitKitColor(String? name) {
    if (name == null || name.trim().isEmpty) return null;
    final hex = _parseHexColor(name);
    if (hex != null) return hex;
    const m = {
      'red': 0xFFF44336, 'pink': 0xFFE91E63, 'purple': 0xFF9C27B0,
      'deeppurple': 0xFF673AB7, 'indigo': 0xFF3F51B5, 'blue': 0xFF2196F3,
      'lightblue': 0xFF03A9F4, 'cyan': 0xFF00BCD4, 'teal': 0xFF009688,
      'green': 0xFF4CAF50, 'lightgreen': 0xFF8BC34A, 'lime': 0xFFCDDC39,
      'yellow': 0xFFFDD835, 'amber': 0xFFFFC107, 'orange': 0xFFFF9800,
      'deeporange': 0xFFFF5722, 'brown': 0xFF795548, 'gray': 0xFF9E9E9E,
      'grey': 0xFF9E9E9E, 'bluegray': 0xFF607D8B, 'bluegrey': 0xFF607D8B,
    };
    return m[name.toLowerCase().replaceAll(' ', '').replaceAll('_', '')];
  }

  static List<_RawHabit> _parseHabitica(dynamic decoded) {
    final tasks = _findTasks(decoded);
    final out = <_RawHabit>[];
    for (final t in tasks) {
      if (t is! Map) continue;
      final type = t['type'];
      if (type != 'daily' && type != 'habit') continue;
      final name = (t['text'] ?? t['notes'] ?? '').toString();
      final history = t['history'];
      if (history is! List) continue;
      final raw = _RawHabit(name);
      num? last;
      for (final h in history) {
        if (h is! Map) continue;
        final date = _epochOrDate(h['date']);
        if (date == null) continue;
        bool done;
        if (h['completed'] is bool) {
          done = h['completed'] == true;
        } else {
          final v = h['value'];
          if (v is num) {
            done = last == null ? v > 0 : v > last;
            last = v;
          } else {
            done = false;
          }
        }
        if (done) raw.mark(date, 1);
      }
      if (raw.days.isNotEmpty) out.add(raw);
    }
    return out;
  }

  static List<dynamic> _findTasks(dynamic decoded) {
    if (decoded is List) return decoded;
    if (decoded is Map) {
      if (decoded['tasks'] is List) return decoded['tasks'] as List;
      final data = decoded['data'];
      if (data is Map && data['tasks'] is List) return data['tasks'] as List;
      final collected = <dynamic>[];
      for (final key in const ['dailys', 'dailies', 'habits']) {
        final v = (data is Map ? data[key] : decoded[key]);
        if (v is List) collected.addAll(v);
      }
      if (collected.isNotEmpty) return collected;
    }
    return const [];
  }

  static List<_RawHabit> _parseMatrix(
      List<String> header, Iterable<List<String>> rows) {
    final habits = <_RawHabit?>[];
    for (var i = 0; i < header.length; i++) {
      habits.add(i == 0 || header[i].trim().isEmpty
          ? null
          : _RawHabit(header[i].trim()));
    }
    for (final row in rows) {
      if (row.isEmpty) continue;
      final date = _parseDate(row.first);
      if (date == null) continue;
      for (var i = 1; i < row.length && i < habits.length; i++) {
        final v = _truthyCount(row[i]);
        if (v > 0) habits[i]?.mark(date, v);
      }
    }
    return habits.whereType<_RawHabit>().toList();
  }

  static List<_RawHabit> _parseLong(
      List<String> lowerHeader, Iterable<List<String>> rows) {
    final habitCol = _indexOfAny(lowerHeader, const ['habit', 'name', 'habitname'])!;
    final dateCol =
        _indexOfAny(lowerHeader, const ['date', 'fecha', 'day', 'día', 'timestamp'])!;
    final valueCol =
        _indexOfAny(lowerHeader, const ['value', 'count', 'amount', 'done', 'completed']);
    final byName = <String, _RawHabit>{};
    for (final row in rows) {
      if (row.length <= habitCol || row.length <= dateCol) continue;
      final name = row[habitCol].trim();
      if (name.isEmpty) continue;
      final date = _parseDate(row[dateCol]);
      if (date == null) continue;
      final v = valueCol != null && row.length > valueCol
          ? _truthyCount(row[valueCol])
          : 1;
      if (v <= 0) continue;
      byName.putIfAbsent(name, () => _RawHabit(name)).mark(date, v);
    }
    return byName.values.toList();
  }

  static bool _isStreakBackup(dynamic decoded) {
    if (decoded is Map && decoded['app'] == 'streak') return true;
    if (decoded is Map && decoded['habits'] is List) {
      final list = decoded['habits'] as List;
      return list.isNotEmpty &&
          list.first is Map &&
          (list.first as Map).containsKey('numberOfCompletionsPerDay');
    }
    return false;
  }

  static int? _indexOfAny(List<String> lower, List<String> names) {
    for (final n in names) {
      final i = lower.indexOf(n);
      if (i >= 0) return i;
    }
    return null;
  }

  static int _truthyCount(String cell) {
    final s = cell.trim().toLowerCase();
    if (s.isEmpty) return 0;
    final n = num.tryParse(s.replaceAll(',', '.'));
    if (n != null) return n > 0 ? n.round() : 0;
    const truthy = {
      'yes', 'y', 'true', 't', 'x', '✓', '✔', 'v', 'done', 'complete',
      'completed', 'si', 'sí', 'ok',
    };
    return truthy.contains(s) ? 1 : 0;
  }

  static DateTime? _epochOrDate(dynamic raw) {
    if (raw is num) {
      final n = raw.toInt();

      return DateTime.fromMillisecondsSinceEpoch(
          n >= 100000000000 ? n : n * 1000);
    }
    if (raw is String) {
      final ms = int.tryParse(raw);
      if (ms != null) return _epochOrDate(ms);
      return _parseDate(raw);
    }
    return null;
  }

  static DateTime? _parseDate(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return null;

    final iso = DateTime.tryParse(s);
    if (iso != null) return DateTime(iso.year, iso.month, iso.day);

    final datePart = s.split(RegExp(r'[ T]')).first;
    final sep = datePart.contains('/')
        ? '/'
        : datePart.contains('-')
            ? '-'
            : datePart.contains('.')
                ? '.'
                : '';
    if (sep.isEmpty) return null;
    final parts = datePart.split(sep);
    if (parts.length != 3) return null;
    final a = int.tryParse(parts[0]);
    final b = int.tryParse(parts[1]);
    final c = int.tryParse(parts[2]);
    if (a == null || b == null || c == null) return null;

    int y, m, d;
    if (parts[0].length == 4) {
      y = a;
      m = b;
      d = c;
    } else if (parts[2].length == 4) {
      y = c;
      if (a > 12 && b <= 12) {
        d = a;
        m = b;
      } else if (b > 12 && a <= 12) {
        m = a;
        d = b;
      } else {
        d = a;
        m = b;
      }
    } else {
      return null;
    }
    if (m < 1 || m > 12 || d < 1 || d > 31) return null;
    return DateTime(y, m, d);
  }

  static dynamic _decodeJson(String text) {
    try {
      return json.decode(text);
    } on FormatException {
      return null;
    }
  }

  static bool looksLikeSqlite(List<int> bytes) {
    const header = 'SQLite format 3';
    if (bytes.length < header.length) return false;
    for (var i = 0; i < header.length; i++) {
      if (bytes[i] != header.codeUnitAt(i)) return false;
    }
    return true;
  }

  static bool looksLikeZip(List<int> bytes) =>
      bytes.length >= 4 &&
      bytes[0] == 0x50 &&
      bytes[1] == 0x4B &&
      (bytes[2] == 0x03 || bytes[2] == 0x05 || bytes[2] == 0x07);

  static String _decode(List<int> bytes) {
    try {
      return utf8.decode(bytes, allowMalformed: false);
    } catch (_) {
      return const Utf8Decoder(allowMalformed: true).convert(bytes);
    }
  }

  static String _detectDelimiter(String text) {
    final firstLine = text.split('\n').firstWhere(
          (l) => l.trim().isNotEmpty,
          orElse: () => '',
        );
    final counts = {
      ',': ','.allMatches(firstLine).length,
      ';': ';'.allMatches(firstLine).length,
      '\t': '\t'.allMatches(firstLine).length,
    };
    var best = ',';
    var bestCount = -1;
    counts.forEach((k, v) {
      if (v > bestCount) {
        bestCount = v;
        best = k;
      }
    });
    return best;
  }

  static List<List<String>> _parseCsv(String input, String delimiter) {
    final rows = <List<String>>[];
    var field = StringBuffer();
    var row = <String>[];
    var inQuotes = false;
    var sawField = false;

    void endField() {
      row.add(field.toString());
      field = StringBuffer();
      sawField = true;
    }

    void endRow() {
      endField();
      rows.add(row);
      row = <String>[];
      sawField = false;
    }

    for (var i = 0; i < input.length; i++) {
      final ch = input[i];
      if (inQuotes) {
        if (ch == '"') {
          if (i + 1 < input.length && input[i + 1] == '"') {
            field.write('"');
            i++;
          } else {
            inQuotes = false;
          }
        } else {
          field.write(ch);
        }
      } else if (ch == '"') {
        inQuotes = true;
      } else if (ch == delimiter) {
        endField();
      } else if (ch == '\n') {
        endRow();
      } else if (ch == '\r') {
      } else {
        field.write(ch);
      }
    }
    if (sawField || field.isNotEmpty || row.isNotEmpty) endRow();
    return rows;
  }
}

class ImportException implements Exception {
  const ImportException(this.message);
  final String message;
  @override
  String toString() => message;
}
