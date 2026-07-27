import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:streak/core/icons/habit_icons.dart';

class WidgetIconService {
  const WidgetIconService._();

  static const _canvas = 96;

  static Directory? _dir;
  static final _paths = <String, String>{};

  static Future<Map<String, String>> resolve(
    Iterable<String> glyphs, {
    bool render = true,
  }) async {
    final out = <String, String>{};
    for (final glyph in glyphs.toSet()) {
      final path = await _pathFor(glyph, render);
      if (path != null) out[glyph] = path;
    }
    return out;
  }

  static Future<String?> _pathFor(String glyph, bool render) async {
    if (glyph.isEmpty) return null;
    final cached = _paths[glyph];
    if (cached != null && File(cached).existsSync()) return cached;

    try {
      final dir = await _iconDir();
      final file = File('${dir.path}/${_keyFor(glyph)}.png');
      if (!file.existsSync()) {
        if (!render) return null;
        final bytes = await _render(glyph);
        if (bytes == null) return null;
        await file.writeAsBytes(bytes);
      }
      _paths[glyph] = file.path;
      return file.path;
    } catch (_) {
      return null;
    }
  }

  static Future<Directory> _iconDir() async {
    final cached = _dir;
    if (cached != null && cached.existsSync()) return cached;
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/widget_icons');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    _dir = dir;
    return dir;
  }

  static String _keyFor(String glyph) {
    if (HabitIcons.isIcon(glyph)) return glyph;
    return glyph.runes.map((r) => r.toRadixString(16)).join('_');
  }

  static Future<List<int>?> _render(String glyph) async {
    final isIcon = HabitIcons.isIcon(glyph);
    final icon = isIcon ? HabitIcons.resolve(glyph) : null;

    final painter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      text: TextSpan(
        text: isIcon ? String.fromCharCode(icon!.codePoint) : glyph,
        style: TextStyle(
          inherit: false,
          color: Colors.white,
          fontSize: _canvas * (isIcon ? 0.86 : 0.78),
          fontFamily: icon?.fontFamily,
          package: icon?.fontPackage,
          height: 1.0,
        ),
      ),
    )..layout();

    final recorder = ui.PictureRecorder();
    painter.paint(
      Canvas(recorder),
      Offset((_canvas - painter.width) / 2, (_canvas - painter.height) / 2),
    );

    final image = await recorder.endRecording().toImage(_canvas, _canvas);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data?.buffer.asUint8List();
  }
}
