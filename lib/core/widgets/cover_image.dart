import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';

double coverBlurSigma(int clarity) => (100 - clarity.clamp(10, 100)) * 0.14;

class CoverImage extends StatelessWidget {
  const CoverImage({
    super.key,
    required this.path,
    this.fit = BoxFit.cover,
    this.clarity = 100,
  });

  final String path;
  final BoxFit fit;
  final int clarity;

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
      builder: (context, box) {
        final image = Image.file(
          File(path),
          fit: fit,
          cacheWidth: box.hasBoundedWidth
              ? (box.maxWidth * ratio).round()
              : (MediaQuery.sizeOf(context).width * ratio).round(),
          gaplessPlayback: true,
        );
        return CoverBlur(clarity: clarity, child: image);
      },
    );
  }
}

class CoverBlur extends StatelessWidget {
  const CoverBlur({super.key, required this.clarity, required this.child});

  final int clarity;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final sigma = coverBlurSigma(clarity);
    if (sigma <= 0) return child;
    return ImageFiltered(
      imageFilter: ImageFilter.blur(
        sigmaX: sigma,
        sigmaY: sigma,
        tileMode: TileMode.clamp,
      ),
      child: child,
    );
  }
}
