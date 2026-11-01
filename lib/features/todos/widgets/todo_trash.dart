import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/utils/app_snackbar.dart';
import 'package:streak/core/widgets/app_confirm_dialog.dart';
import 'package:streak/features/settings/state/settings_controller.dart';
import 'package:streak/features/todos/data/todo.dart';
import 'package:streak/features/todos/state/todos_controller.dart';

const _binWidth = 118.0;
const _binHeight = 128.0;
const _stagger = 0.07;

typedef TrashCard = ({Rect from, Widget card});

void discardTodos(BuildContext context, List<Todo> todos) {
  if (todos.isEmpty) return;
  final controller = context.read<TodosController>();
  for (final todo in todos) {
    controller.discard(todo.id);
  }
  AppSnackbar.action(
    context,
    todos.length == 1
        ? context.l10n.todo_deleted
        : context.l10n.todo_deleted_many(todos.length),
    label: context.l10n.undo,
    onPressed: () {
      for (final todo in todos) {
        controller.restore(todo);
      }
    },
  );
}

void discardTodo(BuildContext context, Todo todo) =>
    discardTodos(context, [todo]);

Future<bool> confirmTrash(BuildContext context, int count) async =>
    await showAppConfirmDialog(
      context,
      title: context.l10n.todo_delete_title(count),
      message: context.l10n.todo_delete_body,
      confirmLabel: context.l10n.delete,
    ) ==
    true;

Future<void> throwInTrash(
  BuildContext context, {
  required List<TrashCard> cards,
  required VoidCallback onThrown,
}) {
  final done = Completer<void>();
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _Trash(
      cards: cards,
      onThrown: onThrown,
      onEnd: () {
        entry.remove();
        done.complete();
      },
    ),
  );
  Overlay.of(context, rootOverlay: true).insert(entry);
  return done.future;
}

class _Trash extends StatefulWidget {
  const _Trash({
    required this.cards,
    required this.onThrown,
    required this.onEnd,
  });

  final List<TrashCard> cards;
  final VoidCallback onThrown;
  final VoidCallback onEnd;

  @override
  State<_Trash> createState() => _TrashState();
}

class _TrashState extends State<_Trash> with SingleTickerProviderStateMixin {
  late final int _count = math.min(widget.cards.length, 6);
  late final AnimationController _time = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: 1250 + 70 * (_count - 1)),
  );
  bool _thrown = false;

  @override
  void initState() {
    super.initState();
    _time.addListener(() {
      if (!_thrown && _time.value >= 0.42) {
        _thrown = true;
        widget.onThrown();
      }
    });
    _time.forward().whenComplete(widget.onEnd);
  }

  @override
  void dispose() {
    _time.dispose();
    super.dispose();
  }

  static double _span(double t, double from, double to) =>
      ((t - from) / (to - from)).clamp(0.0, 1.0);

  static Offset _bezier(Offset a, Offset b, Offset c, double t) {
    final u = 1 - t;
    return a * (u * u) + b * (2 * u * t) + c * (t * t);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final bin = Rect.fromCenter(
      center: Offset(
        media.size.width / 2,
        media.size.height - media.padding.bottom - 180,
      ),
      width: _binWidth,
      height: _binHeight,
    );
    final spread = _stagger * (_count - 1);

    return IgnorePointer(
      child: Material(
        type: MaterialType.transparency,
        child: AnimatedBuilder(
          animation: _time,
          builder: (context, _) {
            final t = _time.value;
            final appear = Curves.easeOutBack.transform(_span(t, 0, 0.3));
            final sink = Curves.easeInCubic.transform(
              _span(t, 0.62 + spread * 0.4, 0.8 + spread * 0.4),
            );
            final land = _span(t, 0.78 + spread * 0.4, 0.92);
            final leave = Curves.easeInCubic.transform(_span(t, 0.9, 1));
            final squash = math.sin(land * math.pi);

            final papers = <Widget>[
              for (var i = 0; i < widget.cards.length; i++)
                _paper(widget.cards[i], math.min(i, _count - 1), t, bin, sink),
            ];

            Widget layer(Widget child) => Positioned.fromRect(
                  rect: bin,
                  child: Opacity(
                    opacity: appear.clamp(0.0, 1.0),
                    child: Transform(
                      alignment: Alignment.bottomCenter,
                      transform: Matrix4.identity()
                        ..translateByDouble(0, 44 * (1 - appear), 0, 1)
                        ..scaleByDouble(
                          1 + 0.06 * squash,
                          1 - 0.08 * squash,
                          1,
                          1,
                        ),
                      child: child,
                    ),
                  ),
                );

            return Opacity(
              opacity: 1 - leave,
              child: Transform.translate(
                offset: Offset(0, 26 * leave),
                child: Stack(
                  children: [
                    layer(const _BinBack()),
                    ...papers,
                    layer(const _BinFront()),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _paper(TrashCard entry, int index, double t, Rect bin, double sink) {
    final from = entry.from;
    final lift = Curves.easeOutCubic.transform(_span(t, 0, 0.14));
    final fly = Curves.easeInOutCubic.transform(
      _span(t, 0.12 + index * _stagger, 0.56 + index * _stagger),
    );

    final wide = bin.width * 0.66;
    final tall = wide * from.height / from.width;
    final fit = tall > bin.height * 0.9 ? bin.height * 0.9 / tall : 1.0;
    final size = Size(wide * fit, tall * fit);
    final stack = Offset(bin.center.dx, bin.top - size.height * 0.18 - index * 4);
    final inside = Offset(bin.center.dx, bin.top + bin.height * 0.58);

    final peak = Offset(
      (from.center.dx + stack.dx) / 2,
      math.min(from.center.dy, stack.dy) - 70,
    );
    final flown = _bezier(from.center, peak, stack, fly);
    final center = Offset.lerp(flown, inside, sink)!;

    final scale = 1 + 0.04 * lift * (1 - fly);
    final width = ui.lerpDouble(from.width, size.width, fly)! * scale;
    final height = ui.lerpDouble(from.height, size.height, fly)! * scale;
    final turn = (index.isEven ? 1 : -1) * (0.07 + index * 0.025);
    final shrink = 1 - 0.18 * sink;

    return Positioned(
      left: center.dx - width / 2,
      top: center.dy - height / 2,
      width: width,
      height: height,
      child: Transform.rotate(
        angle: turn * fly + 0.12 * sink * (index.isEven ? 1 : -1),
        child: Transform.scale(
          scale: shrink,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22 * (1 - sink)),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: FittedBox(
              fit: BoxFit.fill,
              child: SizedBox(
                width: from.width,
                height: from.height,
                child: entry.card,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Path _silhouette(Size size) {
  final w = size.width;
  final h = size.height;
  return Path()
    ..moveTo(0, h * 0.1)
    ..lineTo(w * 0.12, h * 0.9)
    ..quadraticBezierTo(w * 0.14, h, w * 0.25, h)
    ..lineTo(w * 0.75, h)
    ..quadraticBezierTo(w * 0.86, h, w * 0.88, h * 0.9)
    ..lineTo(w, h * 0.1);
}

Rect _rim(Size size) => Rect.fromLTWH(0, 0, size.width, size.height * 0.2);

class _BinBack extends StatelessWidget {
  const _BinBack();

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return CustomPaint(painter: _Back(dark: dark));
  }
}

class _Back extends CustomPainter {
  const _Back({required this.dark});

  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height + 3),
        width: size.width * 0.86,
        height: 14,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: dark ? 0.5 : 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
    );
    final body = _silhouette(size)..arcTo(_rim(size), 0, -math.pi, false);
    canvas.drawPath(
      body..close(),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: dark
              ? const [Color(0xFF45454B), Color(0xFF2A2A2F)]
              : const [Color(0xFF3A3A3E), Color(0xFF232326)],
        ).createShader(rect),
    );
    final mouth = _rim(size).deflate(4);
    canvas.drawOval(
      mouth,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: dark
              ? const [Color(0xFF2E2E33), Color(0xFF4A4A50)]
              : const [Color(0xFF2B2B2F), Color(0xFF45454A)],
        ).createShader(mouth),
    );
    _paintRim(canvas, size, dark, front: false);
  }

  @override
  bool shouldRepaint(_Back old) => old.dark != dark;
}

Color _paintRim(Canvas canvas, Size size, bool dark, {required bool front}) {
  final rim = _rim(size);
  final edge = Colors.white.withValues(alpha: dark ? 0.6 : 0.85);
  final start = front ? 0.0 : math.pi;
  canvas.drawArc(
    rim.deflate(1.6),
    start,
    math.pi,
    false,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          edge.withValues(alpha: 0.3),
          edge.withValues(alpha: 0.55),
          edge,
        ],
      ).createShader(rim),
  );
  canvas.drawArc(
    rim.deflate(3.6),
    start,
    math.pi,
    false,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = Colors.black.withValues(alpha: 0.35),
  );
  return edge;
}

class _BinFront extends StatelessWidget {
  const _BinFront();

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipPath(
          clipper: _FrontClip(),
          child: BackdropFilter(
            enabled: context.select<SettingsController, bool>(
              (settings) => settings.glassEffects,
            ),
            filter: ui.ImageFilter.blur(sigmaX: 2.2, sigmaY: 2.2),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(
                  color: (dark
                          ? const Color(0xFFA0A0A8)
                          : const Color(0xFF85858C))
                      .withValues(alpha: 0.24),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.12, 0.4, 0.62, 1],
                      colors: [
                        Colors.white.withValues(alpha: 0.24),
                        Colors.white.withValues(alpha: 0.02),
                        Colors.black.withValues(alpha: 0),
                        Colors.black.withValues(alpha: 0.6),
                      ],
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      stops: const [0, 0.16, 0.84, 1],
                      colors: [
                        Colors.black.withValues(alpha: 0.42),
                        Colors.black.withValues(alpha: 0),
                        Colors.black.withValues(alpha: 0),
                        Colors.black.withValues(alpha: 0.48),
                      ],
                    ),
                  ),
                ),
                const Align(
                  alignment: Alignment(-0.52, 0.2),
                  child: FractionallySizedBox(
                    widthFactor: 0.07,
                    heightFactor: 0.62,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(6)),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x40FFFFFF), Color(0x00FFFFFF)],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        CustomPaint(painter: _Rim(dark: dark)),
      ],
    );
  }
}

class _FrontClip extends CustomClipper<Path> {
  @override
  Path getClip(Size size) =>
      (_silhouette(size)..arcTo(_rim(size), 0, math.pi, false))..close();

  @override
  bool shouldReclip(_FrontClip old) => false;
}

class _Rim extends CustomPainter {
  const _Rim({required this.dark});

  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final edge = _paintRim(canvas, size, dark, front: true);
    canvas.drawPath(
      _silhouette(size),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.1, 0.75],
          colors: [edge, edge.withValues(alpha: 0)],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_Rim old) => old.dark != dark;
}
