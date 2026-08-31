import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:streak/features/island/data/island_art.dart';
import 'package:streak/features/island/data/island_piece.dart';

const double _driftX = 0.16;
const double _driftY = 0.48;
const double _shadowAlpha = 0.30;
const double _twistStep = 0.62;
const Color _seaTop = Color(0xFF7ACCEA);
const Color _seaDeep = Color(0xFF2C86B4);

typedef IslandCell = ({
  int gx,
  int gy,
  String tile,
  double level,
  double wall,
});

List<IslandCell> _cellsFor(int turn) {
  final view = IslandTurn(turn);
  final levels = <int, double>{};
  final tiles = <int, String>{};
  for (var gy = 0; gy < islandTerrain.length; gy++) {
    final row = islandTerrain[gy];
    for (var gx = 0; gx < row.length; gx++) {
      final name = islandTiles[row[gx]];
      if (name == null) continue;
      final at = view.cellAt(gx, gy);
      final key = at.$1 * 1000 + at.$2;
      levels[key] = row[gx] == '~'
          ? islandWaterLevel
          : double.parse(islandLevels[gy][gx]);
      tiles[key] = '${name}_${islandTerrainVariant(gx, gy)}';
    }
  }

  final out = <IslandCell>[];
  for (final entry in levels.entries) {
    final gx = entry.key ~/ 1000;
    final gy = entry.key % 1000;
    var drop = 0.0;
    for (final step in const [[1, 1], [1, 0], [0, 1]]) {
      final side = levels[(gx + step[0]) * 1000 + gy + step[1]];
      drop = math.max(drop, entry.value - (side ?? entry.value - 0.75));
    }
    out.add((
      gx: gx,
      gy: gy,
      tile: tiles[entry.key]!,
      level: entry.value,
      wall: drop * islandStep,
    ));
  }
  out.sort((a, b) {
    final depth = (a.gx + a.gy).compareTo(b.gx + b.gy);
    return depth != 0 ? depth : a.gx.compareTo(b.gx);
  });
  return out;
}

final List<List<IslandCell>> islandCells = [
  for (var turn = 0; turn < 4; turn++) _cellsFor(turn),
];

class IslandCanvas extends StatefulWidget {
  const IslandCanvas({
    super.key,
    required this.art,
    required this.owned,
    required this.ghost,
    required this.light,
    required this.turn,
    required this.onPick,
  });

  final IslandArt art;
  final Set<String> owned;
  final Color ghost;
  final List<double>? light;
  final ValueNotifier<int> turn;
  final ValueChanged<IslandPiece> onPick;

  @override
  State<IslandCanvas> createState() => IslandCanvasState();
}

class IslandCanvasState extends State<IslandCanvas>
    with TickerProviderStateMixin {
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  );

  late final AnimationController _swap = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
    value: 1,
  );

  late final AnimationController _glide = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  IslandPiece? _rising;
  ui.Picture? _scene;
  String _sceneKey = '';
  ui.Picture? _leaving;
  Offset _leftAt = Offset.zero;
  double _leftScale = 1;

  double _scale = 0;
  double _fit = 1;
  Offset _origin = Offset.zero;
  Size _viewport = Size.zero;

  double _startScale = 1;
  Offset _startFocal = Offset.zero;
  Offset _startOrigin = Offset.zero;
  double _twist = 0;
  Offset _glideFrom = Offset.zero;
  Offset _glideTo = Offset.zero;

  int get _turn => widget.turn.value;

  List<IslandSpot> get _spots => islandSpots[_turn];

  Rect get _world => islandWorldRects[_turn];

  @override
  void initState() {
    super.initState();
    widget.turn.addListener(_onTurn);
    _glide.addListener(_onGlide);
  }

  @override
  void dispose() {
    widget.turn.removeListener(_onTurn);
    _pop.dispose();
    _swap.dispose();
    _glide.dispose();
    super.dispose();
  }

  void _onGlide() {
    final t = Curves.decelerate.transform(_glide.value);
    setState(() {
      _origin = Offset.lerp(_glideFrom, _glideTo, t)!;
      _clamp();
    });
  }

  void _onTurn() {
    final ratio = _fit == 0 ? 1.0 : _scale / _fit;
    _leaving = _scene;
    _leftAt = _origin;
    _leftScale = _scale;
    setState(() {
      _refit();
      _scale = (_fit * ratio).clamp(_fit * 0.75, _maxScale);
      _centre();
      _clamp();
    });
    _swap.forward(from: 0).whenComplete(() {
      if (mounted) setState(() => _leaving = null);
    });
  }

  void celebrate(IslandPiece piece) {
    setState(() => _rising = piece);
    _pop.forward(from: 0).whenComplete(() {
      if (mounted) setState(() => _rising = null);
    });
  }

  void reveal(IslandPiece piece) {
    if (_viewport.isEmpty) return;
    final spot = _spots.firstWhere((s) => s.piece.id == piece.id);
    final target = spot.bounds.center;
    _glide.stop();
    setState(() {
      _scale = _closeUp;
      _origin = Offset(
        _viewport.width / 2 - target.dx * _scale,
        _viewport.height * 0.38 - target.dy * _scale,
      );
      _clamp();
    });
  }

  double get _maxScale => math.max(_fit * 1.2, 1.05);

  double get _closeUp => math.min(math.max(_fit * 2.6, 0.55), _maxScale);

  double get _homeScale => math.min(_fit * 1.35, _maxScale);

  void _toggleZoom(Offset at) {
    _glide.stop();
    setState(() {
      final next = _scale <= _homeScale * 1.1 ? _closeUp : _homeScale;
      final world = (at - _origin) / _scale;
      _scale = next;
      _origin = at - world * _scale;
      _clamp();
    });
  }

  void _refit() {
    _fit = math.min(
      _viewport.width / _world.width,
      _viewport.height / _world.height,
    );
  }

  void _centre() {
    _origin = Offset(
      (_viewport.width - _world.width * _scale) / 2 - _world.left * _scale,
      (_viewport.height - _world.height * _scale) / 2 - _world.top * _scale,
    );
  }

  void _layout(Size size) {
    if (size == _viewport && _scale > 0) return;
    _viewport = size;
    _refit();
    if (_scale == 0) {
      _scale = _homeScale;
      _centre();
    }
    _clamp();
  }

  void _clamp() {
    if (_viewport.isEmpty) return;
    final world = _world;
    final slackX = _viewport.width * 0.35;
    final slackY = _viewport.height * 0.28;
    _origin = Offset(
      _origin.dx.clamp(
        slackX - world.right * _scale,
        _viewport.width - slackX - world.left * _scale,
      ),
      _origin.dy.clamp(
        slackY - world.bottom * _scale,
        _viewport.height - slackY - world.top * _scale,
      ),
    );
  }

  Offset _toWorld(Offset local) => (local - _origin) / _scale;

  IslandPiece? _hit(Offset world) {
    IslandPiece? loose;
    for (final spot in _spots.reversed) {
      if (!spot.bounds.contains(world)) continue;
      loose ??= spot.piece;
      final y = world.dy + spot.piece.level * islandStep;
      final gx = ((world.dx / (islandTileW / 2) + y / (islandTileH / 2)) / 2)
          .floor();
      final gy = ((y / (islandTileH / 2) - world.dx / (islandTileW / 2)) / 2)
          .floor();
      if (gx >= spot.gx &&
          gx < spot.gx + spot.cols &&
          gy >= spot.gy &&
          gy < spot.gy + spot.rows) {
        return spot.piece;
      }
    }
    return loose;
  }

  ui.Picture _pictureFor(String key) {
    final cached = _scene;
    if (cached != null && key == _sceneKey) return cached;
    final picture = _record();
    _scene = picture;
    _sceneKey = key;
    return picture;
  }

  ui.Picture _record() {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final bounds = _world.inflate(64);

    canvas.saveLayer(bounds, Paint());
    _terrain(canvas);
    canvas.saveLayer(
      bounds,
      Paint()
        ..blendMode = BlendMode.srcATop
        ..color = const Color(0xFF000000).withValues(alpha: _shadowAlpha),
    );
    for (final spot in _spots) {
      if (!widget.owned.contains(spot.piece.id)) continue;
      if (spot.piece.id == _rising?.id || !spot.art.shadow) continue;
      _shadow(canvas, spot);
    }
    canvas.restore();
    canvas.restore();

    for (final spot in _spots) {
      if (spot.piece.id == _rising?.id) continue;
      _sprite(canvas, spot, 1, widget.owned.contains(spot.piece.id));
    }
    return recorder.endRecording();
  }

  void _terrain(Canvas canvas) {
    _beds(canvas);
    final paint = Paint()..filterQuality = FilterQuality.medium;
    for (final cell in islandCells[_turn]) {
      final image = widget.art.tiles[cell.tile];
      if (image == null) continue;
      final full = image.height * islandTileW / image.width;
      final keep = math.min(full, islandTileH + cell.wall);
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(
          0,
          0,
          image.width.toDouble(),
          image.height * keep / full,
        ),
        Rect.fromLTWH(
          (cell.gx - cell.gy) * islandTileW / 2 - islandTileW / 2,
          (cell.gx + cell.gy) * islandTileH / 2 - cell.level * islandStep,
          islandTileW,
          keep,
        ),
        paint,
      );
    }
  }

  void _beds(Canvas canvas) {
    final beds = <String, Path>{};
    for (final cell in islandCells[_turn]) {
      final kind = cell.tile.substring(0, cell.tile.lastIndexOf('_'));
      final cx = (cell.gx - cell.gy) * islandTileW / 2;
      final top = (cell.gx + cell.gy) * islandTileH / 2 - cell.level * islandStep;
      final half = islandTileW / 2;
      final mid = top + islandTileH / 2;
      final foot = top + islandTileH + cell.wall;
      beds.putIfAbsent(kind, Path.new)
        ..moveTo(cx, top)
        ..lineTo(cx + half, mid)
        ..lineTo(cx + half, mid + cell.wall)
        ..lineTo(cx, foot)
        ..lineTo(cx - half, mid + cell.wall)
        ..lineTo(cx - half, mid)
        ..close();
    }
    final order = beds.keys.toList()
      ..sort((a, b) => a == 'water' ? -1 : (b == 'water' ? 1 : 0));
    for (final kind in order) {
      final ink = Color(islandTileInk[kind] ?? 0xFF9C9384);
      canvas
        ..drawPath(beds[kind]!, Paint()..color = ink)
        ..drawPath(
          beds[kind]!,
          Paint()
            ..color = ink
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
    }
  }

  void _shadow(Canvas canvas, IslandSpot spot) {
    final art = spot.art;
    final image = widget.art.shadows[art.base];
    if (image == null) return;
    final foot = spot.footing;
    final ax = art.size.width / 2;
    final ay = art.size.height;
    final matrix = Float64List(16);
    matrix[0] = 1;
    matrix[4] = _driftX;
    matrix[5] = _driftY;
    matrix[10] = 1;
    matrix[12] = foot.dx - ax - ay * _driftX;
    matrix[13] = foot.dy - ay * _driftY;
    matrix[15] = 1;
    canvas.save();
    canvas.transform(matrix);
    if (spot.mirror) {
      canvas.translate(ax, 0);
      canvas.scale(-1, 1);
      canvas.translate(-ax, 0);
    }
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(
        -art.pad,
        -art.pad,
        art.size.width + art.pad * 2,
        art.size.height + art.pad * 2,
      ),
      Paint()..filterQuality = FilterQuality.low,
    );
    canvas.restore();
  }

  void _sprite(Canvas canvas, IslandSpot spot, double opacity, bool owns) {
    final image = widget.art.sprites[spot.piece.art];
    if (image == null) return;
    final paint = Paint()..filterQuality = FilterQuality.medium;
    if (!owns) {
      paint.colorFilter = ColorFilter.mode(
        widget.ghost.withValues(alpha: widget.ghost.a * opacity),
        BlendMode.srcIn,
      );
    } else if (opacity < 1) {
      paint.color = const Color(0xFFFFFFFF).withValues(alpha: opacity);
    }
    final rect = spot.bounds;
    canvas.save();
    if (spot.mirror) {
      canvas.translate(rect.center.dx, 0);
      canvas.scale(-1, 1);
      canvas.translate(-rect.center.dx, 0);
    }
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      rect,
      paint,
    );
    canvas.restore();
  }

  void _onScaleStart(ScaleStartDetails details) {
    _glide.stop();
    _startScale = _scale;
    _startFocal = details.localFocalPoint;
    _startOrigin = _origin;
    _twist = 0;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (details.pointerCount > 1) {
      final swing = details.rotation - _twist;
      if (swing.abs() >= _twistStep) {
        _twist = details.rotation;
        widget.turn.value = (widget.turn.value + (swing > 0 ? 1 : 3)) % 4;
        _startFocal = details.localFocalPoint;
        _startOrigin = _origin;
        _startScale = _scale;
        return;
      }
    }
    setState(() {
      _scale = (_startScale * details.scale).clamp(_fit * 0.75, _maxScale);
      final ratio = _scale / _startScale;
      _origin = details.localFocalPoint - (_startFocal - _startOrigin) * ratio;
      _clamp();
    });
  }

  void _onScaleEnd(ScaleEndDetails details) {
    final speed = details.velocity.pixelsPerSecond;
    if (speed.distance < 220) return;
    _glideFrom = _origin;
    _glideTo = _origin + speed * 0.16;
    _glide.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _layout(constraints.biggest);
        final key = '${widget.owned.length}.${widget.ghost.toARGB32()}'
            '.${_rising?.id ?? ''}.$_turn';
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onScaleStart: _onScaleStart,
          onScaleUpdate: _onScaleUpdate,
          onScaleEnd: _onScaleEnd,
          onTapUp: (details) {
            final piece = _hit(_toWorld(details.localPosition));
            if (piece != null) widget.onPick(piece);
          },
          onDoubleTapDown: (details) => _toggleZoom(details.localPosition),
          onDoubleTap: () {},
          child: AnimatedBuilder(
            animation: Listenable.merge([_pop, _swap]),
            builder: (context, _) => CustomPaint(
              size: Size.infinite,
              painter: _IslandPainter(
                scene: _pictureFor(key),
                origin: _origin,
                scale: _scale,
                rising: _rising == null
                    ? null
                    : _spots.firstWhere((s) => s.piece.id == _rising!.id),
                progress: _pop.value,
                light: widget.light,
                fade: _swap.value,
                leaving: _leaving,
                leftAt: _leftAt,
                leftScale: _leftScale,
                draw: _sprite,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _IslandPainter extends CustomPainter {
  const _IslandPainter({
    required this.scene,
    required this.origin,
    required this.scale,
    required this.rising,
    required this.progress,
    required this.light,
    required this.fade,
    required this.leaving,
    required this.leftAt,
    required this.leftScale,
    required this.draw,
  });

  final ui.Picture scene;
  final Offset origin;
  final double scale;
  final IslandSpot? rising;
  final double progress;
  final List<double>? light;
  final double fade;
  final ui.Picture? leaving;
  final Offset leftAt;
  final double leftScale;
  final void Function(Canvas, IslandSpot, double, bool) draw;

  @override
  void paint(Canvas canvas, Size size) {
    final dim = Curves.easeOut.transform(fade.clamp(0.0, 1.0));
    final tint = light;
    final frame = Offset.zero & size;
    canvas.saveLayer(
      frame,
      Paint()..colorFilter = tint == null ? null : ColorFilter.matrix(tint),
    );
    canvas.drawRect(
      frame,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_seaTop, _seaDeep],
        ).createShader(frame),
    );

    final old = leaving;
    if (old != null && dim < 1) {
      canvas.saveLayer(
        frame,
        Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 1 - dim),
      );
      canvas.save();
      canvas.translate(leftAt.dx, leftAt.dy);
      canvas.scale(leftScale);
      canvas.drawPicture(old);
      canvas.restore();
      canvas.restore();
    }

    canvas.saveLayer(
      frame,
      Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: dim),
    );
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.scale(scale);
    canvas.drawPicture(scene);

    final spot = rising;
    if (spot != null) {
      final t = Curves.easeOutBack.transform(progress.clamp(0.0, 1.0));
      final ring = Curves.easeOutCubic.transform(progress.clamp(0.0, 1.0));
      final foot = spot.footing;
      final width = spot.art.size.width;
      canvas.save();
      canvas.translate(foot.dx, foot.dy);
      canvas.scale(1, 0.5);
      canvas.drawCircle(
        Offset.zero,
        width * (0.25 + ring * 0.75),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6 * (1 - ring) + 1
          ..color = const Color(0xFFFFE08A).withValues(alpha: 0.75 * (1 - ring)),
      );
      canvas.restore();
      final bounds = spot.bounds;
      canvas.save();
      canvas.translate(bounds.center.dx, bounds.bottom);
      canvas.scale(0.55 + 0.45 * t);
      canvas.translate(-bounds.center.dx, -bounds.bottom);
      draw(canvas, spot, (progress * 3).clamp(0.0, 1.0), true);
      canvas.restore();
    }
    canvas.restore();
    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(_IslandPainter old) =>
      old.scene != scene ||
      old.origin != origin ||
      old.scale != scale ||
      old.rising != rising ||
      old.progress != progress ||
      old.light != light ||
      old.fade != fade ||
      old.leaving != leaving;
}
