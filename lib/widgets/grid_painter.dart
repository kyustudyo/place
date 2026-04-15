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

  GridPainter({
    required this.room,
    required this.theme,
    this.selectedHeight,
    this.axisSwapped = false,
    this.guideColor = const Color(0xFFE74C3C),
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

  /// Draw projection lines from selected item to both walls
  void _drawPositionGuides(Canvas canvas) {
    final x = selX!;
    final z = selZ!;
    final w = selW ?? 0;
    final d = selD ?? 0;
    final baseY = selY ?? 0; // position.y (bottom of item)
    final h = selectedHeight ?? 0; // position.y + size.y (top of item)

    // Wall projection — visible on wall surface
    final guidePaint = Paint()
      ..color = guideColor.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Semi-transparent fill on wall
    final guideFill = Paint()
      ..color = guideColor.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    // Left wall (x=0): rectangle showing z range × height
    final leftRect = Path()
      ..moveTo(IsometricMath.worldToScreen(0, baseY, z).dx,
          IsometricMath.worldToScreen(0, baseY, z).dy)
      ..lineTo(IsometricMath.worldToScreen(0, baseY, z + d).dx,
          IsometricMath.worldToScreen(0, baseY, z + d).dy)
      ..lineTo(IsometricMath.worldToScreen(0, h, z + d).dx,
          IsometricMath.worldToScreen(0, h, z + d).dy)
      ..lineTo(IsometricMath.worldToScreen(0, h, z).dx,
          IsometricMath.worldToScreen(0, h, z).dy)
      ..close();
    canvas.drawPath(leftRect, guideFill);
    _drawDashedLine(canvas,
        IsometricMath.worldToScreen(0, baseY, z),
        IsometricMath.worldToScreen(0, baseY, z + d), guidePaint);
    _drawDashedLine(canvas,
        IsometricMath.worldToScreen(0, h, z),
        IsometricMath.worldToScreen(0, h, z + d), guidePaint);
    _drawDashedLine(canvas,
        IsometricMath.worldToScreen(0, baseY, z),
        IsometricMath.worldToScreen(0, h, z), guidePaint);
    _drawDashedLine(canvas,
        IsometricMath.worldToScreen(0, baseY, z + d),
        IsometricMath.worldToScreen(0, h, z + d), guidePaint);

    // Back wall (z=0): rectangle showing x range × height
    final backRect = Path()
      ..moveTo(IsometricMath.worldToScreen(x, baseY, 0).dx,
          IsometricMath.worldToScreen(x, baseY, 0).dy)
      ..lineTo(IsometricMath.worldToScreen(x + w, baseY, 0).dx,
          IsometricMath.worldToScreen(x + w, baseY, 0).dy)
      ..lineTo(IsometricMath.worldToScreen(x + w, h, 0).dx,
          IsometricMath.worldToScreen(x + w, h, 0).dy)
      ..lineTo(IsometricMath.worldToScreen(x, h, 0).dx,
          IsometricMath.worldToScreen(x, h, 0).dy)
      ..close();
    canvas.drawPath(backRect, guideFill);
    _drawDashedLine(canvas,
        IsometricMath.worldToScreen(x, baseY, 0),
        IsometricMath.worldToScreen(x + w, baseY, 0), guidePaint);
    _drawDashedLine(canvas,
        IsometricMath.worldToScreen(x, h, 0),
        IsometricMath.worldToScreen(x + w, h, 0), guidePaint);
    _drawDashedLine(canvas,
        IsometricMath.worldToScreen(x, baseY, 0),
        IsometricMath.worldToScreen(x, h, 0), guidePaint);
    _drawDashedLine(canvas,
        IsometricMath.worldToScreen(x + w, baseY, 0),
        IsometricMath.worldToScreen(x + w, h, 0), guidePaint);

    // Floor projection lines to walls
    final floorGuide = Paint()
      ..color = guideColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    // Item → left wall
    _drawDashedLine(canvas,
        IsometricMath.worldToScreen(x, 0, z),
        IsometricMath.worldToScreen(0, 0, z), floorGuide);
    _drawDashedLine(canvas,
        IsometricMath.worldToScreen(x, 0, z + d),
        IsometricMath.worldToScreen(0, 0, z + d), floorGuide);

    // Item → back wall
    _drawDashedLine(canvas,
        IsometricMath.worldToScreen(x, 0, z),
        IsometricMath.worldToScreen(x, 0, 0), floorGuide);
    _drawDashedLine(canvas,
        IsometricMath.worldToScreen(x + w, 0, z),
        IsometricMath.worldToScreen(x + w, 0, 0), floorGuide);
  }

  void _drawHeightGuide(Canvas canvas, double h) {
    final overflows = h > room.height;
    final heightColor = overflows
        ? Colors.red.withValues(alpha: 0.7)
        : guideColor.withValues(alpha: 0.6);

    final dashPaint = Paint()
      ..color = heightColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Draw ghost wall extension if overflows
    if (overflows) {
      _drawGhostWalls(canvas, h);
    }

    // Dashed line at actual height (or clamped to room if not overflowing)
    final drawH = overflows ? h : h;

    // Left wall dashed line
    final leftFrom = IsometricMath.worldToScreen(0, drawH, 0);
    final leftTo = IsometricMath.worldToScreen(0, drawH, room.depth);
    _drawDashedLine(canvas, leftFrom, leftTo, dashPaint);

    // Back wall dashed line
    final backFrom = IsometricMath.worldToScreen(0, drawH, 0);
    final backTo = IsometricMath.worldToScreen(room.width, drawH, 0);
    _drawDashedLine(canvas, backFrom, backTo, dashPaint);

    // Also draw the room ceiling line when overflowing
    if (overflows) {
      final ceilPaint = Paint()
        ..color = theme.wallBorderColor.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      final ceilLeftFrom = IsometricMath.worldToScreen(0, room.height, 0);
      final ceilLeftTo =
          IsometricMath.worldToScreen(0, room.height, room.depth);
      _drawDashedLine(canvas, ceilLeftFrom, ceilLeftTo, ceilPaint);
      final ceilBackTo =
          IsometricMath.worldToScreen(room.width, room.height, 0);
      _drawDashedLine(canvas, ceilLeftFrom, ceilBackTo, ceilPaint);
    }

    // Label
    final labelPos = IsometricMath.worldToScreen(0, drawH, 0);
    final pctText = '${(h / room.height * 100).round()}%';
    final heightText = overflows
        ? '${h.toStringAsFixed(1)} (넘침!)'
        : h.toStringAsFixed(1);

    final tp = TextPainter(
      text: TextSpan(
        text: '$heightText  $pctText',
        style: TextStyle(
          color: heightColor,
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

  void _drawGhostWalls(Canvas canvas, double h) {
    final ghostFill = Paint()
      ..color = Colors.red.withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;

    final ghostBorder = Paint()
      ..color = Colors.red.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Left ghost wall extension (from room.height to h)
    final leftGhost = Path()
      ..moveTo(
          IsometricMath.worldToScreen(0, room.height, 0).dx,
          IsometricMath.worldToScreen(0, room.height, 0).dy)
      ..lineTo(
          IsometricMath.worldToScreen(0, room.height, room.depth).dx,
          IsometricMath.worldToScreen(0, room.height, room.depth).dy)
      ..lineTo(
          IsometricMath.worldToScreen(0, h, room.depth).dx,
          IsometricMath.worldToScreen(0, h, room.depth).dy)
      ..lineTo(
          IsometricMath.worldToScreen(0, h, 0).dx,
          IsometricMath.worldToScreen(0, h, 0).dy)
      ..close();

    canvas.drawPath(leftGhost, ghostFill);

    // Left ghost vertical dashed edges
    _drawDashedLine(
      canvas,
      IsometricMath.worldToScreen(0, room.height, 0),
      IsometricMath.worldToScreen(0, h, 0),
      ghostBorder,
    );
    _drawDashedLine(
      canvas,
      IsometricMath.worldToScreen(0, room.height, room.depth),
      IsometricMath.worldToScreen(0, h, room.depth),
      ghostBorder,
    );

    // Back ghost wall extension (from room.height to h)
    final backGhost = Path()
      ..moveTo(
          IsometricMath.worldToScreen(0, room.height, 0).dx,
          IsometricMath.worldToScreen(0, room.height, 0).dy)
      ..lineTo(
          IsometricMath.worldToScreen(room.width, room.height, 0).dx,
          IsometricMath.worldToScreen(room.width, room.height, 0).dy)
      ..lineTo(
          IsometricMath.worldToScreen(room.width, h, 0).dx,
          IsometricMath.worldToScreen(room.width, h, 0).dy)
      ..lineTo(
          IsometricMath.worldToScreen(0, h, 0).dx,
          IsometricMath.worldToScreen(0, h, 0).dy)
      ..close();

    canvas.drawPath(backGhost, ghostFill);

    // Back ghost vertical dashed edges
    _drawDashedLine(
      canvas,
      IsometricMath.worldToScreen(room.width, room.height, 0),
      IsometricMath.worldToScreen(room.width, h, 0),
      ghostBorder,
    );
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
