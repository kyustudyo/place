import 'dart:math';
import 'package:flutter/material.dart';
import '../providers/theme_provider.dart';

class IsometricMath {
  // Isometric angle (30 degrees)
  static const double angle = 30 * pi / 180;
  static const double cosA = 0.866025; // cos(30°)
  static const double sinA = 0.5; // sin(30°)

  /// Scale factor: how many pixels per meter
  static double scale = 40.0;

  /// Origin offset (center of canvas)
  static Offset origin = Offset.zero;

  /// Axis mapping — which world axis goes to which visual direction
  static AxisMapping axisMapping = const AxisMapping();

  /// Extract the value for a given world axis from (x, y, z)
  static double _axisValue(WorldAxis axis, double x, double y, double z) =>
      switch (axis) {
        WorldAxis.x => x,
        WorldAxis.y => y,
        WorldAxis.z => z,
      };

  /// World (x, y, z) → Screen (px, py)
  static Offset worldToScreen(double x, double y, double z) {
    final wx = _axisValue(axisMapping.rightDown, x, y, z) * (axisMapping.flipRD ? -1 : 1);
    final wz = _axisValue(axisMapping.leftDown, x, y, z) * (axisMapping.flipLD ? -1 : 1);
    final wy = _axisValue(axisMapping.up, x, y, z) * (axisMapping.flipUp ? -1 : 1);
    final sx = (wx - wz) * cosA * scale;
    final sy = (wx + wz) * sinA * scale - wy * scale;
    return Offset(origin.dx + sx, origin.dy + sy);
  }

  /// Screen → World (floor plane, up-axis=0)
  /// Returns Offset(x, z) in world coords (room width axis, room depth axis)
  static Offset screenToWorld(Offset screen) {
    final dx = screen.dx - origin.dx;
    final dy = screen.dy - origin.dy;

    final sx = dx / (cosA * scale);
    final sy = dy / (sinA * scale);

    var rawRD = (sx + sy) / 2; // right-down visual value
    var rawLD = (sy - sx) / 2; // left-down visual value

    // Un-flip: visual value was flipped, so invert back
    if (axisMapping.flipRD) rawRD = -rawRD;
    if (axisMapping.flipLD) rawLD = -rawLD;

    // Map visual values back to world X and Z
    double worldX = 0, worldZ = 0;
    _setWorldAxis(axisMapping.rightDown, rawRD, (v) => worldX = v, (v) => worldZ = v);
    _setWorldAxis(axisMapping.leftDown, rawLD, (v) => worldX = v, (v) => worldZ = v);
    return Offset(worldX, worldZ);
  }

  static void _setWorldAxis(WorldAxis axis, double value,
      void Function(double) setX, void Function(double) setZ) {
    switch (axis) {
      case WorldAxis.x:
        setX(value);
      case WorldAxis.z:
        setZ(value);
      case WorldAxis.y:
        break; // up axis — not part of floor plane
    }
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
