import 'dart:math';
import 'package:flutter/material.dart';

class IsometricMath {
  // Isometric angle (30 degrees)
  static const double angle = 30 * pi / 180;
  static const double cosA = 0.866025; // cos(30°)
  static const double sinA = 0.5; // sin(30°)

  /// Scale factor: how many pixels per meter
  static double scale = 40.0;

  /// Origin offset (center of canvas)
  static Offset origin = Offset.zero;

  /// World (x, y, z) → Screen (px, py)
  static Offset worldToScreen(double x, double y, double z) {
    final sx = (x - z) * cosA * scale;
    final sy = (x + z) * sinA * scale - y * scale;
    return Offset(origin.dx + sx, origin.dy + sy);
  }

  /// Screen → World (floor plane, y=0)
  static Offset screenToWorld(Offset screen) {
    final dx = screen.dx - origin.dx;
    final dy = screen.dy - origin.dy;

    final sx = dx / (cosA * scale);
    final sy = dy / (sinA * scale);

    final x = (sx + sy) / 2;
    final z = (sy - sx) / 2;

    return Offset(x, z);
  }

  /// Snap to grid
  static double snapToGrid(double value, double tileSize) {
    return (value / tileSize).round() * tileSize;
  }

  /// Get isometric polygon for a box face
  static List<Offset> getTopFace(
      double x, double y, double z, double w, double h, double d) {
    return [
      worldToScreen(x, y + h, z),
      worldToScreen(x + w, y + h, z),
      worldToScreen(x + w, y + h, z + d),
      worldToScreen(x, y + h, z + d),
    ];
  }

  static List<Offset> getLeftFace(
      double x, double y, double z, double w, double h, double d) {
    return [
      worldToScreen(x, y, z + d),
      worldToScreen(x + w, y, z + d),
      worldToScreen(x + w, y + h, z + d),
      worldToScreen(x, y + h, z + d),
    ];
  }

  static List<Offset> getRightFace(
      double x, double y, double z, double w, double h, double d) {
    return [
      worldToScreen(x + w, y, z),
      worldToScreen(x + w, y, z + d),
      worldToScreen(x + w, y + h, z + d),
      worldToScreen(x + w, y + h, z),
    ];
  }
}
