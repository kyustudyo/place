import 'package:flutter/material.dart';
import '../models/furniture.dart';
import '../models/app_theme.dart';
import '../utils/isometric_math.dart';

class FurnitureRenderer extends CustomPainter {
  final List<Furniture> items;
  final String? selectedId;
  final String? draggingId;
  final AppTheme theme;

  FurnitureRenderer({
    required this.items,
    required this.theme,
    this.selectedId,
    this.draggingId,
  });

  @override
  void paint(Canvas canvas, Size size) {
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

    // Top face (lightest)
    final topColor = isDragging
        ? baseColor.withValues(alpha: 0.6)
        : Color.lerp(baseColor, Colors.white, 0.3)!;
    final topFace = IsometricMath.getTopFace(x, y, z, w, h, d);
    _drawFace(canvas, topFace, topColor);

    // Left face (medium)
    final leftColor = isDragging
        ? baseColor.withValues(alpha: 0.5)
        : Color.lerp(baseColor, Colors.black, 0.1)!;
    final leftFace = IsometricMath.getLeftFace(x, y, z, w, h, d);
    _drawFace(canvas, leftFace, leftColor);

    // Right face (darkest)
    final rightColor = isDragging
        ? baseColor.withValues(alpha: 0.4)
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

  @override
  bool shouldRepaint(covariant FurnitureRenderer oldDelegate) => true;
}
