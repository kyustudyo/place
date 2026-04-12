import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/room.dart';
import '../models/app_theme.dart';
import '../utils/isometric_math.dart';

class GridPainter extends CustomPainter {
  final Room room;
  final AppTheme theme;
  final double? selectedHeight; // height of selected furniture

  GridPainter({
    required this.room,
    required this.theme,
    this.selectedHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawFloor(canvas);
    _drawGrid(canvas);
    _drawWalls(canvas);
    if (selectedHeight != null && selectedHeight! > 0) {
      _drawHeightGuide(canvas, selectedHeight!);
    }
  }

  void _drawFloor(Canvas canvas) {
    final paint = Paint()
      ..color = theme.floorColor
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(
          IsometricMath.worldToScreen(0, 0, 0).dx,
          IsometricMath.worldToScreen(0, 0, 0).dy)
      ..lineTo(
          IsometricMath.worldToScreen(room.width, 0, 0).dx,
          IsometricMath.worldToScreen(room.width, 0, 0).dy)
      ..lineTo(
          IsometricMath.worldToScreen(room.width, 0, room.depth).dx,
          IsometricMath.worldToScreen(room.width, 0, room.depth).dy)
      ..lineTo(
          IsometricMath.worldToScreen(0, 0, room.depth).dx,
          IsometricMath.worldToScreen(0, 0, room.depth).dy)
      ..close();

    canvas.drawPath(path, paint);
  }

  void _drawGrid(Canvas canvas) {
    final paint = Paint()
      ..color = theme.gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = theme.gridLineWidth;

    for (int i = 0; i <= room.gridSize; i++) {
      final x = i * room.tileSize;
      final from = IsometricMath.worldToScreen(x, 0, 0);
      final to = IsometricMath.worldToScreen(x, 0, room.depth);
      canvas.drawLine(from, to, paint);
    }

    for (int i = 0; i <= room.gridSize; i++) {
      final z = i * room.tileSize;
      final from = IsometricMath.worldToScreen(0, 0, z);
      final to = IsometricMath.worldToScreen(room.width, 0, z);
      canvas.drawLine(from, to, paint);
    }
  }

  void _drawWalls(Canvas canvas) {
    final wallBorderPaint = Paint()
      ..color = theme.wallBorderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = theme.wallBorderWidth;

    // Left wall
    final leftWallPaint = Paint()
      ..color = theme.leftWallColor
      ..style = PaintingStyle.fill;

    final leftWall = Path()
      ..moveTo(
          IsometricMath.worldToScreen(0, 0, 0).dx,
          IsometricMath.worldToScreen(0, 0, 0).dy)
      ..lineTo(
          IsometricMath.worldToScreen(0, 0, room.depth).dx,
          IsometricMath.worldToScreen(0, 0, room.depth).dy)
      ..lineTo(
          IsometricMath.worldToScreen(0, room.height, room.depth).dx,
          IsometricMath.worldToScreen(0, room.height, room.depth).dy)
      ..lineTo(
          IsometricMath.worldToScreen(0, room.height, 0).dx,
          IsometricMath.worldToScreen(0, room.height, 0).dy)
      ..close();

    canvas.drawPath(leftWall, leftWallPaint);
    canvas.drawPath(leftWall, wallBorderPaint);

    // Back wall
    final backWallPaint = Paint()
      ..color = theme.backWallColor
      ..style = PaintingStyle.fill;

    final backWall = Path()
      ..moveTo(
          IsometricMath.worldToScreen(0, 0, 0).dx,
          IsometricMath.worldToScreen(0, 0, 0).dy)
      ..lineTo(
          IsometricMath.worldToScreen(room.width, 0, 0).dx,
          IsometricMath.worldToScreen(room.width, 0, 0).dy)
      ..lineTo(
          IsometricMath.worldToScreen(room.width, room.height, 0).dx,
          IsometricMath.worldToScreen(room.width, room.height, 0).dy)
      ..lineTo(
          IsometricMath.worldToScreen(0, room.height, 0).dx,
          IsometricMath.worldToScreen(0, room.height, 0).dy)
      ..close();

    canvas.drawPath(backWall, backWallPaint);
    canvas.drawPath(backWall, wallBorderPaint);
  }

  void _drawHeightGuide(Canvas canvas, double h) {
    final clampedH = h.clamp(0.0, room.height);
    final ratio = clampedH / room.height;
    final overflows = h > room.height;

    // Dashed line color
    final guideColor = overflows
        ? Colors.red.withValues(alpha: 0.7)
        : theme.accent.withValues(alpha: 0.6);

    final dashPaint = Paint()
      ..color = guideColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Left wall: horizontal dashed line at height h
    final leftFrom = IsometricMath.worldToScreen(0, clampedH, 0);
    final leftTo = IsometricMath.worldToScreen(0, clampedH, room.depth);
    _drawDashedLine(canvas, leftFrom, leftTo, dashPaint);

    // Back wall: horizontal dashed line at height h
    final backFrom = IsometricMath.worldToScreen(0, clampedH, 0);
    final backTo = IsometricMath.worldToScreen(room.width, clampedH, 0);
    _drawDashedLine(canvas, backFrom, backTo, dashPaint);

    // Height label on left wall edge
    final labelPos = IsometricMath.worldToScreen(0, clampedH, 0);
    final pctText = '${(ratio * 100).round()}%';
    final heightText = overflows
        ? '${h.toStringAsFixed(1)} (넘침!)'
        : h.toStringAsFixed(1);

    final tp = TextPainter(
      text: TextSpan(
        text: '$heightText  $pctText',
        style: TextStyle(
          color: guideColor,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          shadows: [
            Shadow(
              color: theme.scaffoldBg.withValues(alpha: 0.8),
              blurRadius: 3,
            ),
          ],
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();

    tp.paint(canvas, labelPos + Offset(-tp.width - 8, -tp.height / 2));
  }

  void _drawDashedLine(
      Canvas canvas, Offset from, Offset to, Paint paint) {
    const dashLen = 6.0;
    const gapLen = 4.0;
    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;
    final dist = (Offset(dx, dy)).distance;
    if (dist == 0) return;

    final unitX = dx / dist;
    final unitY = dy / dist;
    var drawn = 0.0;

    while (drawn < dist) {
      final start = Offset(
        from.dx + unitX * drawn,
        from.dy + unitY * drawn,
      );
      final end = Offset(
        from.dx + unitX * (drawn + dashLen).clamp(0, dist),
        from.dy + unitY * (drawn + dashLen).clamp(0, dist),
      );
      canvas.drawLine(start, end, paint);
      drawn += dashLen + gapLen;
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) =>
      oldDelegate.theme.id != theme.id ||
      oldDelegate.selectedHeight != selectedHeight;
}
