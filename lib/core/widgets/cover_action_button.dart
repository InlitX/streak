import 'package:flutter/material.dart';

class CoverActionButton extends StatelessWidget {
  const CoverActionButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 34,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(size * 0.3),
        ),
        child: Icon(icon, color: Colors.white, size: size * 0.5),
      ),
    );
  }
}
