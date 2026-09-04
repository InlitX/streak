import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player_win/video_player_win.dart';

const focusVideoScenes = <String>[
  'cabin_rain',
  'fireplace_room',
  'girl_study',
  'cat_fireplace',
];

bool get hasVideoScenes => Platform.isWindows;

String get _scenesDir =>
    '${File(Platform.resolvedExecutable).parent.path}/data/scenes';

File focusVideoFile(String name) => File('$_scenesDir/$name.mp4');

File focusVideoPoster(String name) => File('$_scenesDir/$name.jpg');

class FocusVideoPoster extends StatelessWidget {
  const FocusVideoPoster({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final poster = focusVideoPoster(name);
    if (!poster.existsSync()) {
      return const ColoredBox(color: Colors.black);
    }
    return Image.file(poster, fit: BoxFit.cover);
  }
}

class FocusVideoScene extends StatefulWidget {
  const FocusVideoScene({super.key, required this.name});

  final String name;

  @override
  State<FocusVideoScene> createState() => _FocusVideoSceneState();
}

class _FocusVideoSceneState extends State<FocusVideoScene> {
  WinVideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(FocusVideoScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.name == widget.name) return;
    _controller?.dispose();
    _controller = null;
    _load();
  }

  Future<void> _load() async {
    final file = focusVideoFile(widget.name);
    if (!file.existsSync()) return;
    final controller = WinVideoPlayerController.file(file);
    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0);
      await controller.play();
    } catch (e) {
      debugPrint('Could not play the scene: $e');
      await controller.dispose();
      return;
    }
    if (!mounted) {
      await controller.dispose();
      return;
    }
    setState(() => _controller = controller);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return FocusVideoPoster(name: widget.name);
    }
    return FittedBox(
      fit: BoxFit.cover,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: controller.value.size.width,
        height: controller.value.size.height,
        child: WinVideoPlayer(controller),
      ),
    );
  }
}
