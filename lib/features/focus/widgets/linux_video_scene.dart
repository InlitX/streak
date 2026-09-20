import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:streak/features/focus/widgets/focus_video_scene.dart';

class LinuxVideoScene extends StatefulWidget {
  const LinuxVideoScene({super.key, required this.name});

  final String name;

  @override
  State<LinuxVideoScene> createState() => _LinuxVideoSceneState();
}

class _LinuxVideoSceneState extends State<LinuxVideoScene> {
  static const _channel = MethodChannel('streak/video_scene');

  int? _id;
  Size _size = Size.zero;

  @override
  void initState() {
    super.initState();
    _open();
  }

  @override
  void didUpdateWidget(LinuxVideoScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.name == widget.name) return;
    _close();
    _open();
  }

  Future<void> _open() async {
    final file = focusVideoFile(widget.name);
    if (!file.existsSync()) return;
    try {
      final scene = await _channel
          .invokeMapMethod<String, Object?>('open', {'path': file.path});
      if (scene == null) return;
      final id = scene['id'] as int;
      if (!mounted) {
        await _channel.invokeMethod('close', {'id': id});
        return;
      }
      setState(() {
        _id = id;
        _size = Size(
          (scene['width'] as int).toDouble(),
          (scene['height'] as int).toDouble(),
        );
      });
    } catch (e) {
      debugPrint('Could not play the scene: $e');
    }
  }

  void _close() {
    final id = _id;
    if (id == null) return;
    _id = null;
    _channel.invokeMethod('close', {'id': id});
  }

  @override
  void dispose() {
    _close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final id = _id;
    if (id == null) return FocusVideoPoster(name: widget.name);
    return FittedBox(
      fit: BoxFit.cover,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: _size.width,
        height: _size.height,
        child: Texture(textureId: id),
      ),
    );
  }
}
