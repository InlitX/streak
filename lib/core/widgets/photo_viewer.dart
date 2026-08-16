import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class PhotoShot {
  const PhotoShot({required this.path, this.day = '', this.text = ''});

  final String path;
  final String day;
  final String text;
}

String photoHeroTag(int index, String path) => 'photo:$index:$path';

Future<void> showPhotoViewer(
  BuildContext context,
  List<PhotoShot> shots,
  int start,
) {
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.black,
      transitionDuration: const Duration(milliseconds: 260),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      transitionsBuilder: (_, animation, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      ),
      pageBuilder: (_, __, ___) => _PhotoViewer(shots: shots, start: start),
    ),
  );
}

class _PhotoViewer extends StatefulWidget {
  const _PhotoViewer({required this.shots, required this.start});

  final List<PhotoShot> shots;
  final int start;

  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  late final PageController _pages = PageController(initialPage: widget.start);
  late int _index = widget.start;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shot = widget.shots[_index];
    final hasCaption = shot.day.isNotEmpty || shot.text.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pages,
            itemCount: widget.shots.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (_, i) => InteractiveViewer(
              maxScale: 4,
              child: Center(
                child: Hero(
                  tag: photoHeroTag(i, widget.shots[i].path),
                  child: Image.file(File(widget.shots[i].path)),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(LucideIcons.x, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                if (widget.shots.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(right: 18),
                    child: Text(
                      '${_index + 1} / ${widget.shots.length}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (hasCaption)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
                  color: Colors.black.withValues(alpha: 0.45),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (shot.day.isNotEmpty)
                        Text(
                          shot.day,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                      if (shot.text.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(
                          shot.text,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.35,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
