import 'dart:io';

import 'package:flutter/material.dart';

class CoverImage extends StatelessWidget {
  const CoverImage({
    super.key,
    required this.path,
    this.fit = BoxFit.cover,
  });

  final String path;
  final BoxFit fit;

  static final _known = <String, bool>{};

  static bool exists(String path) {
    if (path.isEmpty) return false;
    return _known[path] ??= File(path).existsSync();
  }

  static void forget(String path) => _known.remove(path);

  @override
  Widget build(BuildContext context) {
    if (!exists(path)) return const SizedBox.shrink();
    final ratio = MediaQuery.devicePixelRatioOf(context);
    return LayoutBuilder(
      builder: (context, box) => Image.file(
        File(path),
        fit: fit,
        cacheWidth: box.hasBoundedWidth
            ? (box.maxWidth * ratio).round()
            : (MediaQuery.sizeOf(context).width * ratio).round(),
        gaplessPlayback: true,
      ),
    );
  }
}
