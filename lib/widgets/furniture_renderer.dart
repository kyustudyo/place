import 'package:flutter/material.dart';
import '../models/furniture.dart';
import '../models/app_theme.dart';
import '../utils/isometric_math.dart';

class FurnitureRenderer extends CustomPainter {
  final List<Furniture> items;
  final String? selectedId;
  final String? draggingId;
  final AppTheme theme;
  final double? snapTileSize;
  final double roomWidth;
  final double roomDepth;
  final double roomHeight;

  FurnitureRenderer({
    required this.items,
    required this.theme,
    this.roomWidth = 15.0,
    this.roomDepth = 15.0,
    this.roomHeight = 4.0,
    this.selectedId,
    this.draggingId,
    this.snapTileSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw snap ghost first (below everything)
    if (draggingId != null && snapTileSize != null) {
      final dragging = items.cast<Furniture?>().firstWhere(
            (f) => f?.id == draggingId,
            orElse: () => null,
          );
      if (dragging != null && dragging.isPlaced) {
        _drawSnapGhost(canvas, dragging, snapTileSize!);
      }
    }

    // Sort by depth (z + x) for correct overlap
    final sorted = items.where((f) => f.isPlaced).toList()
      ..sort((a, b) {
        final da = a.position.x + a.position.z;
        final db = b.position.x + b.position.z;
        return da.compareTo(db);
      });

    for (final item in sorted) {
      _drawFurniture(canvas, item);
    }
  }

  void _drawFurniture(Canvas canvas, Furniture f) {
    final x = f.position.x;
    final y = f.position.y;
    final z = f.position.z;
    final w = f.effectiveWidth;
    final h = f.size.y;
    final d = f.effectiveDepth;

    final isDragging = f.id == draggingId;
    final isSelected = f.id == selectedId;
    final baseColor = f.color;

    // Top face (lightest) — more transparent when dragging
    final topColor = isDragging
        ? baseColor.withValues(alpha: 0.3)
        : Color.lerp(baseColor, Colors.white, 0.3)!;
    final topFace = IsometricMath.getTopFace(x, y, z, w, h, d);
    _drawFace(canvas, topFace, topColor);

    // Left face (medium)
    final leftColor = isDragging
        ? baseColor.withValues(alpha: 0.25)
        : Color.lerp(baseColor, Colors.black, 0.1)!;
    final leftFace = IsometricMath.getLeftFace(x, y, z, w, h, d);
    _drawFace(canvas, leftFace, leftColor);

    // Right face (darkest)
    final rightColor = isDragging
        ? baseColor.withValues(alpha: 0.2)
        : Color.lerp(baseColor, Colors.black, 0.25)!;
    final rightFace = IsometricMath.getRightFace(x, y, z, w, h, d);
    _drawFace(canvas, rightFace, rightColor);

    // Collision border
    if (f.hasCollision) {
      final borderPaint = Paint()
        ..color = Colors.red
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      _drawOutline(canvas, topFace, leftFace, rightFace, borderPaint);
    }

    // Selection border
    if (isSelected && !f.hasCollision) {
      final selectPaint = Paint()
        ..color = theme.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      _drawOutline(canvas, topFace, leftFace, rightFace, selectPaint);
    }

    // Label on top face
    _drawLabel(canvas, f.name, topFace);
  }

  void _drawFace(Canvas canvas, List<Offset> points, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    path.close();
    canvas.drawPath(path, paint);

    // Edge
    final edgePaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    canvas.drawPath(path, edgePaint);
  }

  void _drawOutline(Canvas canvas, List<Offset> top, List<Offset> left,
      List<Offset> right, Paint paint) {
    final outline = Path()
      ..moveTo(top[0].dx, top[0].dy)
      ..lineTo(top[1].dx, top[1].dy)
      ..lineTo(right[1].dx, right[1].dy)
      ..lineTo(left[1].dx, left[1].dy)
      ..lineTo(left[0].dx, left[0].dy)
      ..lineTo(top[3].dx, top[3].dy)
      ..close();
    canvas.drawPath(outline, paint);
  }

  void _drawLabel(Canvas canvas, String name, List<Offset> topFace) {
    final center = Offset(
      topFace.map((p) => p.dx).reduce((a, b) => a + b) / 4,
      topFace.map((p) => p.dy).reduce((a, b) => a + b) / 4,
    );

    final textPainter = TextPainter(
      text: TextSpan(
        text: name,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          shadows: [Shadow(color: Colors.black54, blurRadius: 2)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      center - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  void _drawSnapGhost(Canvas canvas, Furniture f, double tileSize) {
    final sx = (f.position.x / tileSize).round() * tileSize;
    final sz = (f.position.z / tileSize).round() * tileSize;
    final w = f.effectiveWidth;
    final h = f.size.y;
    final d = f.effectiveDepth;

    final ghostFill = Paint()
      ..color = f.color.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;

    final ghostBorder = Paint()
      ..color = f.color.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // ── Floor footprint (solid fill + dashed border) ──
    final floorPoints = [
      IsometricMath.worldToScreen(sx, 0, sz),
      IsometricMath.worldToScreen(sx + w, 0, sz),
      IsometricMath.worldToScreen(sx + w, 0, sz + d),
      IsometricMath.worldToScreen(sx, 0, sz + d),
    ];

    final floorPath = Path()..moveTo(floorPoints[0].dx, floorPoints[0].dy);
    for (int i = 1; i < floorPoints.length; i++) {
      floorPath.lineTo(floorPoints[i].dx, floorPoints[i].dy);
    }
    floorPath.close();
    canvas.drawPath(floorPath, ghostFill);
    _drawDashedPath(canvas, floorPoints, ghostBorder);

    // ── Height wireframe ──
    final topPoints = [
      IsometricMath.worldToScreen(sx, h, sz),
      IsometricMath.worldToScreen(sx + w, h, sz),
      IsometricMath.worldToScreen(sx + w, h, sz + d),
      IsometricMath.worldToScreen(sx, h, sz + d),
    ];

    // Top face
    final topFill = Paint()
      ..color = f.color.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;
    final topPath = Path()..moveTo(topPoints[0].dx, topPoints[0].dy);
    for (int i = 1; i < topPoints.length; i++) {
      topPath.lineTo(topPoints[i].dx, topPoints[i].dy);
    }
    topPath.close();
    canvas.drawPath(topPath, topFill);
    _drawDashedPath(canvas, topPoints, ghostBorder);

    // Vertical edges
    for (int i = 0; i < 4; i++) {
      _drawDashedLine(canvas, floorPoints[i], topPoints[i], ghostBorder);
    }

    // ── Wall height guide lines ──
    final wallGuide = Paint()
      ..color = f.color.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Left wall (x=0): horizontal dashed line at height h
    final leftFrom = IsometricMath.worldToScreen(0, h, 0);
    final leftTo = IsometricMath.worldToScreen(0, h, roomDepth);
    _drawDashedLine(canvas, leftFrom, leftTo, wallGuide);

    // Back wall (z=0): horizontal dashed line at height h
    final backFrom = IsometricMath.worldToScreen(0, h, 0);
    final backTo = IsometricMath.worldToScreen(roomWidth, h, 0);
    _drawDashedLine(canvas, backFrom, backTo, wallGuide);
  }

  void _drawDashedLine(Canvas canvas, Offset from, Offset to, Paint paint) {
    const dash = 5.0;
    const gap = 3.0;
    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;
    final dist = Offset(dx, dy).distance;
    if (dist == 0) return;
    final ux = dx / dist;
    final uy = dy / dist;
    var drawn = 0.0;
    while (drawn < dist) {
      final s = Offset(from.dx + ux * drawn, from.dy + uy * drawn);
      final e = Offset(
        from.dx + ux * (drawn + dash).clamp(0, dist),
        from.dy + uy * (drawn + dash).clamp(0, dist),
      );
      canvas.drawLine(s, e, paint);
      drawn += dash + gap;
    }
  }

  void _drawDashedPath(Canvas canvas, List<Offset> points, Paint paint) {
    const dash = 5.0;
    const gap = 3.0;
    for (int i = 0; i < points.length; i++) {
      final from = points[i];
      final to = points[(i + 1) % points.length];
      final dx = to.dx - from.dx;
      final dy = to.dy - from.dy;
      final dist = Offset(dx, dy).distance;
      if (dist == 0) continue;
      final ux = dx / dist;
      final uy = dy / dist;
      var drawn = 0.0;
      while (drawn < dist) {
        final s = Offset(from.dx + ux * drawn, from.dy + uy * drawn);
        final e = Offset(
          from.dx + ux * (drawn + dash).clamp(0, dist),
          from.dy + uy * (drawn + dash).clamp(0, dist),
        );
        canvas.drawLine(s, e, paint);
        drawn += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant FurnitureRenderer oldDelegate) => true;
}
