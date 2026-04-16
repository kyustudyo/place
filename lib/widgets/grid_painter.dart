import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/room.dart';
import '../models/app_theme.dart';
import '../utils/isometric_math.dart';

class GridPainter extends CustomPainter {
  final Room room;
  final AppTheme theme;
  final double? selectedHeight;
  final bool axisSwapped;
  final Color guideColor;
  // Selected item position/size for wall projection
  final double? selX;
  final double? selZ;
  final double? selW;
  final double? selD;
  final double? selY; // position.y (base height)
  final double guideOpacity;

  GridPainter({
    required this.room,
    required this.theme,
    this.selectedHeight,
    this.axisSwapped = false,
    this.guideColor = const Color(0xFFE74C3C),
    this.guideOpacity = 1.0,
    this.selX,
    this.selZ,
    this.selW,
    this.selD,
    this.selY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawFloor(canvas);
    _drawGrid(canvas);
    _drawWalls(canvas);
    if (selX != null) _drawPositionGuides(canvas);
    _drawAxisLabels(canvas);
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

  /// Draw projection lines from selected item to both walls
  void _drawPositionGuides(Canvas canvas) {
    final x = selX!;
    final z = selZ!;
    final w = selW ?? 0;
    final d = selD ?? 0;
    final baseY = selY ?? 0; // position.y (bottom of item)
    final h = selectedHeight ?? 0; // position.y + size.y (top of item)

    // Semi-transparent fill on wall
    final guideFill = Paint()
      ..color = guideColor.withValues(alpha: 0.08 * guideOpacity)
      ..style = PaintingStyle.fill;

    // Clamp projection to wall range
    final wz1 = z.clamp(0.0, room.depth);
    final wz2 = (z + d).clamp(0.0, room.depth);
    final wx1 = x.clamp(0.0, room.width);
    final wx2 = (x + w).clamp(0.0, room.width);

    // Soft horizontal lines only (no vertical Y-axis lines)
    final softPaint = Paint()
      ..color = guideColor.withValues(alpha: 0.5 * guideOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Left wall (x=0): horizontal lines at floor, baseY, top
    if (wz2 > wz1) {
      // Fill
      final leftRect = Path()
        ..moveTo(IsometricMath.worldToScreen(0, 0, wz1).dx,
            IsometricMath.worldToScreen(0, 0, wz1).dy)
        ..lineTo(IsometricMath.worldToScreen(0, 0, wz2).dx,
            IsometricMath.worldToScreen(0, 0, wz2).dy)
        ..lineTo(IsometricMath.worldToScreen(0, h, wz2).dx,
            IsometricMath.worldToScreen(0, h, wz2).dy)
        ..lineTo(IsometricMath.worldToScreen(0, h, wz1).dx,
            IsometricMath.worldToScreen(0, h, wz1).dy)
        ..close();
      canvas.drawPath(leftRect, guideFill);

      // Bottom (floor)
      _drawDashedLine(canvas,
          IsometricMath.worldToScreen(0, 0, wz1),
          IsometricMath.worldToScreen(0, 0, wz2), softPaint);
      // Top
      _drawDashedLine(canvas,
          IsometricMath.worldToScreen(0, h, wz1),
          IsometricMath.worldToScreen(0, h, wz2), softPaint);
      // BaseY (item bottom) if elevated
      if (baseY > 0.01) {
        _drawDashedLine(canvas,
            IsometricMath.worldToScreen(0, baseY, wz1),
            IsometricMath.worldToScreen(0, baseY, wz2), softPaint);
      }
    }

    // Back wall (z=0): horizontal lines at floor, baseY, top
    if (wx2 > wx1) {
      final backRect = Path()
        ..moveTo(IsometricMath.worldToScreen(wx1, 0, 0).dx,
            IsometricMath.worldToScreen(wx1, 0, 0).dy)
        ..lineTo(IsometricMath.worldToScreen(wx2, 0, 0).dx,
            IsometricMath.worldToScreen(wx2, 0, 0).dy)
        ..lineTo(IsometricMath.worldToScreen(wx2, h, 0).dx,
            IsometricMath.worldToScreen(wx2, h, 0).dy)
        ..lineTo(IsometricMath.worldToScreen(wx1, h, 0).dx,
            IsometricMath.worldToScreen(wx1, h, 0).dy)
        ..close();
      canvas.drawPath(backRect, guideFill);

      _drawDashedLine(canvas,
          IsometricMath.worldToScreen(wx1, 0, 0),
          IsometricMath.worldToScreen(wx2, 0, 0), softPaint);
      _drawDashedLine(canvas,
          IsometricMath.worldToScreen(wx1, h, 0),
          IsometricMath.worldToScreen(wx2, h, 0), softPaint);
      if (baseY > 0.01) {
        _drawDashedLine(canvas,
            IsometricMath.worldToScreen(wx1, baseY, 0),
            IsometricMath.worldToScreen(wx2, baseY, 0), softPaint);
      }
    }

    // Floor projection lines to walls
    final floorGuide = Paint()
      ..color = guideColor.withValues(alpha: 0.3 * guideOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    // Item → left wall (clamped to map range)
    if (x > 0) {
      _drawDashedLine(canvas,
          IsometricMath.worldToScreen(x.clamp(0.0, room.width), 0, wz1),
          IsometricMath.worldToScreen(0, 0, wz1), floorGuide);
      _drawDashedLine(canvas,
          IsometricMath.worldToScreen(x.clamp(0.0, room.width), 0, wz2),
          IsometricMath.worldToScreen(0, 0, wz2), floorGuide);
    }

    // Item → back wall (clamped to map range)
    if (z > 0) {
      _drawDashedLine(canvas,
          IsometricMath.worldToScreen(wx1, 0, z.clamp(0.0, room.depth)),
          IsometricMath.worldToScreen(wx1, 0, 0), floorGuide);
      _drawDashedLine(canvas,
          IsometricMath.worldToScreen(wx2, 0, z.clamp(0.0, room.depth)),
          IsometricMath.worldToScreen(wx2, 0, 0), floorGuide);
    }

    // Floor shadow when elevated (Y > 0) — shows where item is on the floor
    if (baseY > 0.01) {
      final shadowPaint = Paint()
        ..color = guideColor.withValues(alpha: 0.3 * guideOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      final shadowFill = Paint()
        ..color = guideColor.withValues(alpha: 0.06 * guideOpacity)
        ..style = PaintingStyle.fill;

      final cx = x.clamp(-room.width, room.width * 2);
      final cz = z.clamp(-room.depth, room.depth * 2);

      final shadowPath = Path()
        ..moveTo(IsometricMath.worldToScreen(cx, 0, cz).dx,
            IsometricMath.worldToScreen(cx, 0, cz).dy)
        ..lineTo(IsometricMath.worldToScreen(cx + w, 0, cz).dx,
            IsometricMath.worldToScreen(cx + w, 0, cz).dy)
        ..lineTo(IsometricMath.worldToScreen(cx + w, 0, cz + d).dx,
            IsometricMath.worldToScreen(cx + w, 0, cz + d).dy)
        ..lineTo(IsometricMath.worldToScreen(cx, 0, cz + d).dx,
            IsometricMath.worldToScreen(cx, 0, cz + d).dy)
        ..close();

      canvas.drawPath(shadowPath, shadowFill);
      final pts = [
        IsometricMath.worldToScreen(cx, 0, cz),
        IsometricMath.worldToScreen(cx + w, 0, cz),
        IsometricMath.worldToScreen(cx + w, 0, cz + d),
        IsometricMath.worldToScreen(cx, 0, cz + d),
      ];
      for (int i = 0; i < 4; i++) {
        _drawDashedLine(canvas, pts[i], pts[(i + 1) % 4], shadowPaint);
      }
    }
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

  void _drawAxisLabels(Canvas canvas) {
    final xLabel = axisSwapped ? 'Z' : 'X';
    final zLabel = axisSwapped ? 'X' : 'Z';

    // X axis: outer edge (z=depth side, bottom-right of floor)
    final xMid = IsometricMath.worldToScreen(
        room.width * 0.5, 0, room.depth);
    final xAngle = atan2(IsometricMath.sinA, IsometricMath.cosA);
    _drawRotatedLabel(
        canvas, xLabel, xMid + const Offset(0, 14), xAngle, theme.accent);

    // Z axis: outer edge (x=width side, bottom-left of floor)
    final zMid = IsometricMath.worldToScreen(
        room.width, 0, room.depth * 0.5);
    final zAngle = atan2(IsometricMath.sinA, -IsometricMath.cosA);
    _drawRotatedLabel(
        canvas, zLabel, zMid + const Offset(0, 14), zAngle, theme.accentSecondary);

    // Y axis: upright text at top of left wall corner
    final yTop = IsometricMath.worldToScreen(0, room.height, 0);
    _drawFlatLabel(canvas, 'Y', yTop + const Offset(-16, -6), theme.textSecondary);
  }

  void _drawRotatedLabel(
      Canvas canvas, String text, Offset pos, double angle, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          shadows: [
            Shadow(
                color: theme.scaffoldBg.withValues(alpha: 0.9),
                blurRadius: 4),
          ],
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();

    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(angle);
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
    canvas.restore();
  }

  void _drawFlatLabel(Canvas canvas, String text, Offset pos, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          shadows: [
            Shadow(
                color: theme.scaffoldBg.withValues(alpha: 0.9),
                blurRadius: 4),
          ],
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) => true;
}
