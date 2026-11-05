import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streak/core/utils/app_dirs.dart';

void main() {
  if (Platform.isLinux) return;

  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;
  late Directory support;
  late Directory documents;

  Directory inDocuments() => Directory('${documents.path}/$appDataFolder');

  void seed(Directory dir) {
    dir.createSync(recursive: true);
    File('${dir.path}/habits.hive').writeAsStringSync('habits');
  }

  Future<String> resolve() async {
    forgetAppDataDir();
    return (await appDataDir()).path;
  }

  setUp(() {
    root = Directory.systemTemp.createTempSync('streak_dirs');
    support = Directory('${root.path}/support')..createSync();
    documents = Directory('${root.path}/documents')..createSync();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => call.method == 'getApplicationDocumentsDirectory'
          ? documents.path
          : support.path,
    );
  });

  tearDown(() => root.deleteSync(recursive: true));

  test('a new install keeps its data out of Documents', () async {
    expect(await resolve(), support.path);
    expect(inDocuments().existsSync(), isFalse);
  });

  test('data already in Documents stays there', () async {
    seed(inDocuments());
    expect(await resolve(), inDocuments().path);
    expect(File('${support.path}/.documents-used').existsSync(), isTrue);
  });

  test('a Documents user whose folder was deleted gets it back', () async {
    File('${support.path}/.documents-used').createSync();
    expect(await resolve(), inDocuments().path);
    expect(inDocuments().existsSync(), isTrue);
  });

  test('data in the app folder wins over a stray Documents copy', () async {
    seed(support);
    seed(inDocuments());
    expect(await resolve(), support.path);
  });

  test('isMobile is true for ohos', () {
    setOhosForTest(true);
    expect(isMobile, isTrue);
    expect(hasReminders, isFalse);
    expect(hasAppIcons, isFalse);
    expect(hasHomeWidgets, isFalse);
    expect(hasBiometricLock, isFalse);
    setOhosForTest(false);
  });

  test('guards stay inert off-ohos', () {
    setOhosForTest(false);
    expect(hasReminders, isTrue); // host behavior unchanged
    expect(hasBiometricLock, isTrue); // matches !Platform.isLinux on Windows host
  });
}
