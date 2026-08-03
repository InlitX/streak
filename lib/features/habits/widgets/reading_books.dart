import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/utils/cover_storage.dart';
import 'package:streak/core/widgets/cover_image.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/state/habits_controller.dart';
import 'package:streak/features/habits/widgets/check_seal.dart';

class ReadingBooks extends StatelessWidget {
  const ReadingBooks({
    super.key,
    required this.habit,
    required this.ratio,
    required this.count,
  });

  final Habit habit;
  final double ratio;
  final int count;

  Future<void> _editCover(BuildContext context) async {
    final controller = context.read<HabitsController>();
    final path = await CoverStorage.pick();
    if (path != null) {
      controller.update(habit.copyWith(bookCoverPath: path));
    }
  }

  Widget _leaning(double angle, Alignment anchor, Widget child) => Transform(
        alignment: anchor,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0014)
          ..rotateY(angle),
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _leaning(
          0.22,
          Alignment.centerRight,
          _Book.reference(habit: habit, onEditCover: () => _editCover(context)),
        ),
        const SizedBox(width: 20),
        _leaning(
          -0.22,
          Alignment.centerLeft,
          _Book.progress(habit: habit, ratio: ratio, count: count),
        ),
      ],
    );
  }
}

class _Book extends StatelessWidget {
  const _Book.reference({required this.habit, required this.onEditCover})
      : ratio = 0,
        count = 0,
        isProgress = false;

  const _Book.progress({
    required this.habit,
    required this.ratio,
    required this.count,
  })  : onEditCover = null,
        isProgress = true;

  final Habit habit;
  final double ratio;
  final int count;
  final bool isProgress;
  final VoidCallback? onEditCover;

  static const _radius = BorderRadius.only(
    topLeft: Radius.circular(4),
    bottomLeft: Radius.circular(4),
    topRight: Radius.circular(10),
    bottomRight: Radius.circular(10),
  );

  bool get _hasPhoto => CoverImage.exists(habit.bookCoverPath);

  @override
  Widget build(BuildContext context) {
    final done = isProgress && ratio >= 1.0;
    return Semantics(
      button: true,
      label: context.l10n.book_cover,
      child: GestureDetector(
        onTap: onEditCover,
        child: SizedBox(
          width: 96,
          height: 138,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 9,
                right: 3,
                bottom: 0,
                height: 10,
                child: CustomPaint(painter: _GroundShadowPainter()),
              ),
              Positioned(left: 0, right: 0, top: 0, bottom: 7, child: _body()),
              if (done)
                Positioned(
                  right: -2,
                  bottom: 12,
                  child: CheckSeal(color: habit.color),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body() {
    return Stack(
      children: [
        Positioned(
          right: 0,
          top: 5,
          bottom: 5,
          width: 10,
          child: CustomPaint(painter: _PageEdgesPainter()),
        ),
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          right: 6,
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: _radius,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (isProgress)
                  _ProgressCover(color: habit.color, ratio: ratio, count: count)
                else if (_hasPhoto)
                  CoverImage(path: habit.bookCoverPath)
                else
                  _JacketCover(color: habit.color, title: habit.name),
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 10,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.20),
                          Colors.black.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 9.5,
                  top: 5,
                  bottom: 5,
                  width: 1,
                  child:
                      ColoredBox(color: Colors.white.withValues(alpha: 0.25)),
                ),
                if (onEditCover != null)
                  Positioned(
                    right: 5,
                    bottom: 5,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.20),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Icon(
                        LucideIcons.camera,
                        size: 12,
                        color: Colors.black.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _JacketCover extends StatelessWidget {
  const _JacketCover({required this.color, required this.title});

  final Color color;
  final String title;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(color, Colors.white, 0.10)!,
            color,
            Color.lerp(color, Colors.black, 0.14)!,
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 12, 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(7),
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'PlayfairDisplay',
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressCover extends StatelessWidget {
  const _ProgressCover({
    required this.color,
    required this.ratio,
    required this.count,
  });

  final Color color;
  final double ratio;
  final int count;

  Widget _count(Color c) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 14, 12),
        child: Align(
          alignment: const Alignment(0, -0.12),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '$count',
              style: TextStyle(
                fontFamily: 'PlayfairDisplay',
                fontSize: 46,
                fontWeight: FontWeight.w600,
                height: 1,
                letterSpacing: 0.5,
                color: c,
              ),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final pale = Color.lerp(color, Colors.white, 0.82)!;
    final ink = Color.lerp(color, Colors.black, 0.38)!;
    final hi = Color.lerp(color, Colors.white, 0.42)!;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: ratio.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) => Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: pale),
          if (t > 0)
            Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: t,
                widthFactor: 1,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(color: color),
                    Align(
                      alignment: const Alignment(-0.55, 0),
                      child: FractionallySizedBox(
                        heightFactor: 0.92,
                        child: Container(
                          width: 9,
                          decoration: BoxDecoration(
                            color: hi.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.topCenter,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            height: 1,
                            color: hi.withValues(alpha: 0.75),
                          ),
                          Container(
                            height: 5,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  hi.withValues(alpha: 0.28),
                                  color.withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          _count(ink),
          if (t > 0)
            ClipRect(
              clipper: _BottomFractionClipper(t),
              child: _count(Colors.white),
            ),
        ],
      ),
    );
  }
}

class _BottomFractionClipper extends CustomClipper<Rect> {
  _BottomFractionClipper(this.fraction);

  final double fraction;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(0, size.height * (1 - fraction), size.width, size.height);

  @override
  bool shouldReclip(covariant _BottomFractionClipper old) =>
      old.fraction != fraction;
}

class _PageEdgesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final block = Path()
      ..moveTo(0, 1)
      ..lineTo(w - 2.5, 3)
      ..quadraticBezierTo(w, h / 2, w - 2.5, h - 3)
      ..lineTo(0, h - 1)
      ..close();

    canvas.drawPath(
      block,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFE3DBC8), Color(0xFFF7F2E7), Color(0xFFEBE4D3)],
          stops: [0.0, 0.55, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    canvas.save();
    canvas.clipPath(block);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, 3, h),
      Paint()..color = Colors.black.withValues(alpha: 0.12),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PageEdgesPainter old) => false;
}

class _GroundShadowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawOval(
      Offset.zero & size,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
  }

  @override
  bool shouldRepaint(covariant _GroundShadowPainter old) => false;
}
