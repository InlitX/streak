import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:streak/features/habits/data/habit.dart';

/// Backup format version, written into every export for future migrations.
const _kBackupVersion = 1;

class BackupService {
  const BackupService._();

  /// Serializa todos los hábitos a JSON y los comparte con la hoja de
  /// compartir nativa del sistema. Devuelve false si el usuario cancela.
  static Future<bool> export(List<Habit> habits) async {
    final payload = {
      'app': 'streak',
      'version': _kBackupVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'habits': habits.map((h) => h.toMap()).toList(),
    };
    final content = const JsonEncoder.withIndent('  ').convert(payload);
    final stamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());

    // Archivo temporal en el cache de la app, listo para compartir.
    final dir = await Directory.systemTemp.createTemp('streak_backup');
    final file = File('${dir.path}/streak_backup_$stamp.json');
    await file.writeAsString(content);

    final result = await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/json')],
      subject: 'Streak backup',
    );
    return result.status == ShareResultStatus.success ||
        result.status == ShareResultStatus.dismissed;
  }

  /// Abre el selector de archivos, valida el esquema y devuelve los hábitos.
  /// Acepta tanto el formato nuevo ({version, habits:[...]}) como el antiguo
  /// (una lista de hábitos directa).
  static Future<List<Habit>> import() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Select a Streak backup file',
      type: FileType.any,
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      throw Exception('No file selected');
    }

    final picked = result.files.single;
    String raw;
    if (picked.bytes != null) {
      raw = utf8.decode(picked.bytes!);
    } else if (picked.path != null) {
      raw = await File(picked.path!).readAsString();
    } else {
      throw Exception('Could not read the selected file');
    }

    dynamic decoded;
    try {
      decoded = json.decode(raw);
    } catch (_) {
      throw Exception('That file is not a valid backup');
    }

    final List<dynamic> entries;
    if (decoded is List) {
      entries = decoded; // formato antiguo
    } else if (decoded is Map && decoded['habits'] is List) {
      entries = decoded['habits'] as List;
    } else {
      throw Exception('Unrecognised backup format');
    }

    final habits = <Habit>[];
    for (final entry in entries) {
      if (entry is! Map) continue;
      try {
        habits.add(Habit.fromMap(Map<String, dynamic>.from(entry)));
      } catch (_) {
        // Salta entradas corruptas en lugar de fallar toda la importación.
      }
    }
    if (habits.isEmpty) throw Exception('No habits found in that file');
    return habits;
  }
}
