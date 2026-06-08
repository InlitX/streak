import 'package:flutter/material.dart';

class AppPalette {
  const AppPalette._();

  /// Primary brand violet (HabitKit-style).
  static const brand = Color(0xFF7C3AED);
  static const brandDark = Color(0xFF5B21B6);
  static const brandSoft = Color(0xFFA78BFA);

  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);
  static const info = Color(0xFF3B82F6);

  /// Pure-black dark surfaces.
  static const darkBackground = Color(0xFF0D0D0D);
  static const darkSurface = Color(0xFF141414);
  static const darkCard = Color(0xFF1A1A1A);
  static const darkElevated = Color(0xFF232326);
  static const darkBorder = Color(0xFF2C2C2E);
  static const textSecondary = Color(0xFF8E8E93);

  /// Habit swatches ordered along the visible spectrum so the picker
  /// reads as a clean gradient rather than a random scatter.
  static const List<Color> habitColors = [
    // Rojos / rosas
    Color(0xFFFF3B30),
    Color(0xFFFF6B6B),
    Color(0xFFC0392B),
    Color(0xFFFF375F),
    Color(0xFFFF2D92),
    // Naranjas
    Color(0xFFFF9500),
    Color(0xFFFF6D00),
    Color(0xFFFF8C42),
    Color(0xFFE67E22),
    // Amarillos
    Color(0xFFFFCC00),
    Color(0xFFFFD60A),
    Color(0xFFF4D03F),
    // Verdes lima
    Color(0xFFA8E063),
    Color(0xFF7ED321),
    // Verdes
    Color(0xFF30D158),
    Color(0xFF34C759),
    Color(0xFF00C853),
    Color(0xFF2ECC71),
    Color(0xFF1ABC9C),
    // Turquesas
    Color(0xFF4ECDC4),
    Color(0xFF26C6DA),
    Color(0xFF00BCD4),
    Color(0xFF5AC8FA),
    // Azules
    Color(0xFF0A84FF),
    Color(0xFF007AFF),
    Color(0xFF2196F3),
    Color(0xFF3498DB),
    // Índigo / violeta
    Color(0xFF5856D6),
    Color(0xFF7C3AED), // brand
    Color(0xFF9B59B6),
    Color(0xFF6C3483),
    // Rosas suaves
    Color(0xFFBF5AF2),
    Color(0xFFE91E8C),
    Color(0xFFFF6EB4),
    // Marrones
    Color(0xFFA0522D),
    Color(0xFF8B6914),
    // Grises
    Color(0xFF8E8E93),
    Color(0xFF636366),
    Color(0xFF48484A),
    // Blanco / negro
    Color(0xFFFFFFFF),
    Color(0xFF1C1C1E),
  ];
}
