import 'dart:ui';

import 'package:streak/features/island/data/island_catalog.dart';

export 'package:streak/features/island/data/island_catalog.dart';

enum IslandGroup {
  pueblo,
  cala,
  huerta,
  mirador,
  terrazas,
  faro,
  puerto,
  vega,
  astillero,
  ermita,
  caleta,
  cabo,
  molino,
}

class IslandSprite {
  const IslandSprite({
    required this.cols,
    required this.rows,
    required this.size,
    required this.anchor,
    this.shadow = true,
    this.flat = false,
    this.base = '',
    this.pad = 0,
  });

  final int cols;
  final int rows;
  final Size size;
  final Offset anchor;
  final bool shadow;
  final bool flat;
  final String base;
  final double pad;
}

class IslandPiece {
  const IslandPiece(
    this.id,
    this.art,
    this.gx,
    this.gy,
    this.level,
    this.price,
    this.group, {
    this.mirror = false,
  });

  final String id;
  final String art;
  final int gx;
  final int gy;
  final int level;
  final int price;
  final IslandGroup group;
  final bool mirror;

  IslandSprite get sprite => islandSprites[art]!;

  String get kind => art.split('__').first;

}

final int islandTotalPrice =
    islandPieces.fold(0, (sum, piece) => sum + piece.price);

List<IslandPiece> islandGroupPieces(IslandGroup group) =>
    islandPieces.where((piece) => piece.group == group).toList()
      ..sort((a, b) => a.price.compareTo(b.price));

int islandTerrainVariant(int gx, int gy) =>
    (gx * 7 + gy * 13 + gx * gy * 3) % 4;

class IslandTurn {
  const IslandTurn(this.index);

  final int index;

  Rect get world => islandWorldRects[index];

  bool get flipped => index >= 2;

  (int, int) cellAt(int gx, int gy) => switch (index) {
    0 => (gx, gy),
    1 => (gy, islandGrid - gx - 1),
    2 => (islandGrid - gx - 1, islandGrid - gy - 1),
    _ => (islandGrid - gy - 1, gx),
  };
}

class IslandSpot {
  IslandSpot(this.piece, this.turn) {
    final art = piece.sprite;
    final odd = turn.index.isOdd;
    cols = odd ? art.rows : art.cols;
    rows = odd ? art.cols : art.rows;
    final placed = switch (turn.index) {
      0 => (piece.gx, piece.gy),
      1 => (piece.gy, islandGrid - piece.gx - art.cols),
      2 => (islandGrid - piece.gx - art.cols, islandGrid - piece.gy - art.rows),
      _ => (islandGrid - piece.gy - art.rows, piece.gx),
    };
    gx = placed.$1;
    gy = placed.$2;
    mirror = piece.mirror != turn.flipped;
  }

  final IslandPiece piece;
  final IslandTurn turn;
  late final int gx;
  late final int gy;
  late final int cols;
  late final int rows;
  late final bool mirror;

  IslandSprite get art => piece.sprite;

  int get depth => (gx + cols - 1) + (gy + rows - 1);

  double get _slide =>
      turn.index.isOdd ? (art.rows - art.cols) * islandTileW / 2 : 0;

  Offset get corner => Offset(
    (gx - gy) * islandTileW / 2 + _slide,
    (gx + gy) * islandTileH / 2 - piece.level * islandStep,
  );

  Rect get bounds {
    final anchorX = mirror ? art.size.width - art.anchor.dx : art.anchor.dx;
    return Rect.fromLTWH(
      corner.dx - anchorX,
      corner.dy - art.anchor.dy,
      art.size.width,
      art.size.height,
    );
  }

  Offset get footing {
    var y = (gx + cols / 2 + gy + rows / 2) * islandTileH / 2 -
        piece.level * islandStep;
    if (art.flat) y += (cols + rows) * islandTileH / 4;
    return Offset((gx + cols / 2 - gy - rows / 2) * islandTileW / 2, y);
  }
}

final List<List<IslandSpot>> islandSpots = [
  for (var turn = 0; turn < 4; turn++)
    [for (final piece in islandPieces) IslandSpot(piece, IslandTurn(turn))]
      ..sort((a, b) => a.depth.compareTo(b.depth)),
];
