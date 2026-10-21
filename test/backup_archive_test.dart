import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streak/services/backup_archive.dart';

void main() {
  late Directory phone;
  late Directory other;

  setUp(() async {
    phone = await Directory.systemTemp.createTemp('streak_phone');
    other = await Directory.systemTemp.createTemp('streak_other');
  });

  tearDown(() {
    phone.deleteSync(recursive: true);
    other.deleteSync(recursive: true);
  });

  File make(String path, List<int> bytes) =>
      File('${phone.path}/$path')
        ..createSync(recursive: true)
        ..writeAsBytesSync(bytes);

  test('every file travels in the zip and comes back pointing at the new phone',
      () async {
    final cover = make('covers/1.jpg', [1, 2, 3]);
    final photo = make('todos/2.png', [4, 5]);
    final track = make('tracks/3.mp3', [6, 7, 8, 9]);
    final payload = {
      'habits': [
        {'id': 'h1', 'coverPath': cover.path, 'name': 'Read /not/a/file'},
      ],
      'todos': [
        {
          'id': 't1',
          'photos': [photo.path, '${photo.path}?v=2'],
        },
      ],
      'settings': {
        'focusTracks': ['${track.path}|My song'],
        'profileName': 'Ana',
      },
    };

    final zip = '${phone.path}/backup.zip';
    await BackupArchive.pack(payload, zip);
    final raw = await BackupArchive.unpack(zip, other.path);
    final back = jsonDecode(raw!) as Map<String, dynamic>;

    final habit = (back['habits'] as List).single as Map;
    expect(habit['coverPath'], File('${other.path}/covers/1.jpg').path);
    expect(habit['name'], 'Read /not/a/file');
    expect(File(habit['coverPath'] as String).readAsBytesSync(), [1, 2, 3]);

    final photos = ((back['todos'] as List).single as Map)['photos'] as List;
    expect(photos.first, File('${other.path}/todos/2.png').path);
    expect(photos.last, '${File('${other.path}/todos/2.png').path}?v=2');

    final settings = back['settings'] as Map;
    final song = (settings['focusTracks'] as List).single as String;
    expect(song, '${File('${other.path}/tracks/3.mp3').path}|My song');
    expect(File(song.split('|').first).readAsBytesSync(), [6, 7, 8, 9]);
    expect(settings['profileName'], 'Ana');
  });

  test('a file with the same name but other content is not overwritten',
      () async {
    final cover = make('covers/1.jpg', [1, 2, 3]);
    File('${other.path}/covers/1.jpg')
      ..createSync(recursive: true)
      ..writeAsBytesSync([9]);

    final zip = '${phone.path}/backup.zip';
    await BackupArchive.pack({'coverPath': cover.path}, zip);
    final raw = await BackupArchive.unpack(zip, other.path);
    final path = (jsonDecode(raw!) as Map)['coverPath'] as String;

    expect(File('${other.path}/covers/1.jpg').readAsBytesSync(), [9]);
    expect(File(path).readAsBytesSync(), [1, 2, 3]);
  });

  test('a zip from another app is not taken for a Streak backup', () async {
    final path = '${phone.path}/other.zip';
    final zip = ZipFileEncoder()..create(path);
    zip.addArchiveFile(ArchiveFile.string('habits.csv', 'name,date'));
    await zip.close();

    expect(
      await BackupArchive.unpack(path, other.path),
      isNull,
    );
  });
}
