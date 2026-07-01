import 'package:flutter/material.dart';

class AppColors {
  // Primary Red (Persona 5 Red)
  static const Color primary = Color(0xFFE60012);
  static const Color primaryLight = Color(0xFFFF3B47);
  static const Color primaryDark = Color(0xFF9E000A);
  static const Color primarySurface = Color(0xFF2C1011);
  static const Color primaryBorder = Color(0xFF5E0007);

  // Semantic
  static const Color green = Color(0xFF00E676);
  static const Color greenSurface = Color(0xFF0C2B1B);
  static const Color amber = Color(0xFFFFAB00);
  static const Color amberSurface = Color(0xFF2B1F0C);
  static const Color red = Color(0xFFE60012);
  static const Color redSurface = Color(0xFF2C1011);
  static const Color violet = Color(0xFFD500F9);
  static const Color violetSurface = Color(0xFF2B0C2A);

  // Neutral
  static const Color ink = Color(0xFFFFFFFF);
  static const Color slate600 = Color(0xFFE0E0E0);
  static const Color slate500 = Color(0xFFB0B0B0);
  static const Color slate400 = Color(0xFF757575);
  static const Color slate300 = Color(0xFF424242);
  static const Color line = Color(0xFF2C2C2E);
  static const Color line2 = Color(0xFF1C1C1E);
  static const Color bg = Color(0xFF000000); // Pure Black Background
  static const Color white = Color(0xFF1A1A1E); // Dark Grey Surface

  // Gradient (Red to Black)
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 1.0],
    colors: [primary, Colors.black],
  );

  // Shadows (Flat solid black offsets)
  static List<BoxShadow> shadowCard = [
    const BoxShadow(
      color: Colors.black,
      blurRadius: 0,
      spreadRadius: 0,
      offset: Offset(4, 4),
    ),
  ];
  static List<BoxShadow> shadowSoft = [
    const BoxShadow(
      color: Colors.black,
      blurRadius: 0,
      spreadRadius: 0,
      offset: Offset(3, 3),
    ),
  ];
  static List<BoxShadow> shadowPrimary = [
    const BoxShadow(
      color: Color(0xFF5E0007),
      blurRadius: 0,
      spreadRadius: 0,
      offset: Offset(4, 4),
    ),
  ];

  // Tone map for FeatureIcon
  static Map<String, List<Color>> tones = {
    'blue': [primarySurface, primary],
    'green': [greenSurface, green],
    'amber': [amberSurface, amber],
    'red': [redSurface, red],
    'violet': [violetSurface, violet],
    'slate': [bg, slate600],
  };

  static List<Color> tone(String name) => tones[name] ?? tones['blue']!;
}
