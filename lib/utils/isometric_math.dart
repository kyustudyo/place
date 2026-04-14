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

  /// Swap X and Z axes in view
  static bool swapAxes = false;

  /// World (x, y, z) → Screen (px, py)
  static Offset worldToScreen(double x, double y, double z) {
    final wx = swapAxes ? z : x;
    final wz = swapAxes ? x : z;
    final sx = (wx - wz) * cosA * scale;
    final sy = (wx + wz) * sinA * scale - y * scale;
    return Offset(origin.dx + sx, origin.dy + sy);
  }

  /// Screen → World (floor plane, y=0)
  /// Returns (x, z) — already un-swapped
  static Offset screenToWorld(Offset screen) {
    final dx = screen.dx - origin.dx;
    final dy = screen.dy - origin.dy;

    final sx = dx / (cosA * scale);
    final sy = dy / (sinA * scale);

    final rawX = (sx + sy) / 2;
    final rawZ = (sy - sx) / 2;

    // Un-swap so returned values are always in world coords
    return swapAxes ? Offset(rawZ, rawX) : Offset(rawX, rawZ);
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
