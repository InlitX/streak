import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:streak/features/island/data/island_piece.dart';

class IslandArt {
  const IslandArt(this.tiles, this.sprites, this.shadows);

  final Map<String, ui.Image> tiles;
  final Map<String, ui.Image> sprites;
  final Map<String, ui.Image> shadows;

  static IslandArt? _loaded;
  static Future<IslandArt>? _loading;

  static IslandArt? get ready => _loaded;

  static Future<IslandArt> load() {
    final done = _loaded;
    if (done != null) return Future.value(done);
    return _loading ??= _read();
  }

  static Future<IslandArt> _read() async {
    final tiles = <String, ui.Image>{};
    for (final name in islandTiles.values) {
      for (var flip = 0; flip < 4; flip++) {
        tiles['${name}_$flip'] = await _decode('t_${name}_$flip');
      }
    }
    final sprites = <String, ui.Image>{};
    final shadows = <String, ui.Image>{};
    for (final entry in islandSprites.entries) {
      sprites[entry.key] = await _decode(entry.key);
      final base = entry.value.base;
      if (base.isNotEmpty && !shadows.containsKey(base)) {
        shadows[base] = await _decode('s_$base');
      }
    }
    final art = IslandArt(tiles, sprites, shadows);
    _loaded = art;
    _loading = null;
    return art;
  }

  static Future<ui.Image> _decode(String name) async {
    final data = await rootBundle.load('assets/island/$name.webp');
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  }
}
