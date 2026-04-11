import 'package:flutter/material.dart';

class AppTheme {
  final String id;
  final String name;
  final String nameKo;
  final Color scaffoldBg;
  final Color headerBg;
  final Color headerBorder;
  final Color panelBg;
  final Color cardBg;
  final Color floorColor;
  final Color gridColor;
  final Color backWallColor;
  final Color leftWallColor;
  final Color wallBorderColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color accent;
  final Color accentSecondary;
  final Brightness brightness;
  final double wallBorderWidth;
  final double gridLineWidth;

  const AppTheme({
    required this.id,
    required this.name,
    required this.nameKo,
    required this.scaffoldBg,
    required this.headerBg,
    required this.headerBorder,
    required this.panelBg,
    required this.cardBg,
    required this.floorColor,
    required this.gridColor,
    required this.backWallColor,
    required this.leftWallColor,
    required this.wallBorderColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.accent,
    required this.accentSecondary,
    required this.brightness,
    this.wallBorderWidth = 1.0,
    this.gridLineWidth = 0.5,
  });
}

const appThemes = <AppTheme>[
  // v1 Clean Minimal
  AppTheme(
    id: 'v1',
    name: 'Clean Minimal',
    nameKo: '클린 미니멀',
    scaffoldBg: Color(0xFFFAFAFA),
    headerBg: Color(0xFFFFFFFF),
    headerBorder: Color(0xFFE5E5E5),
    panelBg: Color(0xFFFFFFFF),
    cardBg: Color(0xFFF5F5F5),
    floorColor: Color(0xFFF0F0F0),
    gridColor: Color(0xFFE0E0E0),
    backWallColor: Color(0xFFEBEBEB),
    leftWallColor: Color(0xFFE0E0E0),
    wallBorderColor: Color(0xFFD0D0D0),
    textPrimary: Color(0xFF1A1A1A),
    textSecondary: Color(0xFF888888),
    accent: Color(0xFF007AFF),
    accentSecondary: Color(0xFF34C759),
    brightness: Brightness.light,
  ),

  // v2 Dark Neon
  AppTheme(
    id: 'v2',
    name: 'Dark Neon',
    nameKo: '다크 네온',
    scaffoldBg: Color(0xFF0F0F23),
    headerBg: Color(0xFF1A1A2E),
    headerBorder: Color(0x10FFFFFF),
    panelBg: Color(0xFF1A1A2E),
    cardBg: Color(0xFF16213E),
    floorColor: Color(0xFF1A1A2E),
    gridColor: Color(0xFF2A2A4E),
    backWallColor: Color(0xFF16213E),
    leftWallColor: Color(0xFF12192E),
    wallBorderColor: Color(0xFF3A3A6E),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0x80FFFFFF),
    accent: Color(0xFF00D4FF),
    accentSecondary: Color(0xFF00FF88),
    brightness: Brightness.dark,
  ),

  // v3 Blueprint
  AppTheme(
    id: 'v3',
    name: 'Blueprint',
    nameKo: '블루프린트',
    scaffoldBg: Color(0xFF0D1B2A),
    headerBg: Color(0xFF1B2838),
    headerBorder: Color(0x30FFFFFF),
    panelBg: Color(0xFF1B2838),
    cardBg: Color(0xFF162232),
    floorColor: Color(0xFF1A3A5C),
    gridColor: Color(0x50FFFFFF),
    backWallColor: Color(0xFF1A3050),
    leftWallColor: Color(0xFF152840),
    wallBorderColor: Color(0x40FFFFFF),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFF8BAFC4),
    accent: Color(0xFF4DA8DA),
    accentSecondary: Color(0xFF6BC5E8),
    brightness: Brightness.dark,
    gridLineWidth: 0.8,
  ),

  // v4 Warm Wood (DEFAULT)
  AppTheme(
    id: 'v4',
    name: 'Warm Wood',
    nameKo: '따뜻한 나무',
    scaffoldBg: Color(0xFF2C1810),
    headerBg: Color(0xFF3D2317),
    headerBorder: Color(0x30C4A37A),
    panelBg: Color(0xFF3D2317),
    cardBg: Color(0xFF4A2E1E),
    floorColor: Color(0xFFC4A37A),
    gridColor: Color(0xFFA8895F),
    backWallColor: Color(0xFFD4BFA0),
    leftWallColor: Color(0xFFBFA888),
    wallBorderColor: Color(0xFF8B7355),
    textPrimary: Color(0xFFF5E6D3),
    textSecondary: Color(0xFFC4A37A),
    accent: Color(0xFFE8A838),
    accentSecondary: Color(0xFFD4783A),
    brightness: Brightness.dark,
  ),

  // v5 Material 3
  AppTheme(
    id: 'v5',
    name: 'Material 3',
    nameKo: '머티리얼 3',
    scaffoldBg: Color(0xFFFEF7FF),
    headerBg: Color(0xFFF3EDF7),
    headerBorder: Color(0xFFE0D4E8),
    panelBg: Color(0xFFF3EDF7),
    cardBg: Color(0xFFE8DEF8),
    floorColor: Color(0xFFECE6F0),
    gridColor: Color(0x60D0BCFF),
    backWallColor: Color(0xFFE8DEF8),
    leftWallColor: Color(0xFFD0BCFF),
    wallBorderColor: Color(0xFFB69DF8),
    textPrimary: Color(0xFF1D1B20),
    textSecondary: Color(0xFF49454F),
    accent: Color(0xFF6750A4),
    accentSecondary: Color(0xFF7D5260),
    brightness: Brightness.light,
  ),

  // v6 Glassmorphism
  AppTheme(
    id: 'v6',
    name: 'Glassmorphism',
    nameKo: '글라스모피즘',
    scaffoldBg: Color(0xFF1A0533),
    headerBg: Color(0x20FFFFFF),
    headerBorder: Color(0x30FFFFFF),
    panelBg: Color(0x15FFFFFF),
    cardBg: Color(0x10FFFFFF),
    floorColor: Color(0x20FFFFFF),
    gridColor: Color(0x25FFFFFF),
    backWallColor: Color(0x15FFFFFF),
    leftWallColor: Color(0x10FFFFFF),
    wallBorderColor: Color(0x35FFFFFF),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xAAFFFFFF),
    accent: Color(0xFFA855F7),
    accentSecondary: Color(0xFF6366F1),
    brightness: Brightness.dark,
  ),

  // v7 Neubrutalism
  AppTheme(
    id: 'v7',
    name: 'Neubrutalism',
    nameKo: '뉴브루탈리즘',
    scaffoldBg: Color(0xFFFFFBEB),
    headerBg: Color(0xFFFFE135),
    headerBorder: Color(0xFF000000),
    panelBg: Color(0xFFFFFFFF),
    cardBg: Color(0xFFFFFFFF),
    floorColor: Color(0xFFFFF8DC),
    gridColor: Color(0xFF000000),
    backWallColor: Color(0xFFFFE135),
    leftWallColor: Color(0xFFFF6B9D),
    wallBorderColor: Color(0xFF000000),
    textPrimary: Color(0xFF000000),
    textSecondary: Color(0xFF333333),
    accent: Color(0xFFFF6B9D),
    accentSecondary: Color(0xFF4ECDC4),
    brightness: Brightness.light,
    wallBorderWidth: 3.0,
    gridLineWidth: 1.0,
  ),

  // v8 Scandinavian
  AppTheme(
    id: 'v8',
    name: 'Scandinavian',
    nameKo: '스칸디나비안',
    scaffoldBg: Color(0xFFF5F0EB),
    headerBg: Color(0xFFE8E2DA),
    headerBorder: Color(0xFFD0C8BD),
    panelBg: Color(0xFFFFFFFF),
    cardBg: Color(0xFFF0EBE4),
    floorColor: Color(0xFFE8E2DA),
    gridColor: Color(0xFFD0C8BD),
    backWallColor: Color(0xFFD5CFC7),
    leftWallColor: Color(0xFFC8C0B5),
    wallBorderColor: Color(0xFFB0A898),
    textPrimary: Color(0xFF3C3C3C),
    textSecondary: Color(0xFF8B9A7E),
    accent: Color(0xFF8B9A7E),
    accentSecondary: Color(0xFFC4A37A),
    brightness: Brightness.light,
  ),

  // v9 Monochrome Pro
  AppTheme(
    id: 'v9',
    name: 'Monochrome Pro',
    nameKo: '모노크롬',
    scaffoldBg: Color(0xFF000000),
    headerBg: Color(0xFF111111),
    headerBorder: Color(0xFF333333),
    panelBg: Color(0xFF111111),
    cardBg: Color(0xFF1A1A1A),
    floorColor: Color(0xFF1A1A1A),
    gridColor: Color(0xFF333333),
    backWallColor: Color(0xFF222222),
    leftWallColor: Color(0xFF1A1A1A),
    wallBorderColor: Color(0xFF444444),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFF888888),
    accent: Color(0xFFFFFFFF),
    accentSecondary: Color(0xFFAAAAAA),
    brightness: Brightness.dark,
  ),

  // v10 Gradient Modern
  AppTheme(
    id: 'v10',
    name: 'Gradient Modern',
    nameKo: '그라데이션 모던',
    scaffoldBg: Color(0xFF0F0A1A),
    headerBg: Color(0xFF1A1030),
    headerBorder: Color(0x20FFFFFF),
    panelBg: Color(0xFF1A1030),
    cardBg: Color(0xFF251840),
    floorColor: Color(0xFF1A1030),
    gridColor: Color(0xFF3A2A5A),
    backWallColor: Color(0xFF251840),
    leftWallColor: Color(0xFF1F1338),
    wallBorderColor: Color(0xFF4A3A7A),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFB8A8D8),
    accent: Color(0xFF8B5CF6),
    accentSecondary: Color(0xFF06B6D4),
    brightness: Brightness.dark,
  ),
];

// Default theme index (v4 Warm Wood)
const defaultThemeIndex = 3;
