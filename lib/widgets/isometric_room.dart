import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/furniture.dart';
import '../providers/placement_provider.dart';
import '../utils/isometric_math.dart';
import 'grid_painter.dart';
import 'furniture_renderer.dart';

class IsometricRoom extends ConsumerStatefulWidget {
  const IsometricRoom({super.key});

  @override
  ConsumerState<IsometricRoom> createState() => _IsometricRoomState();
}

class _IsometricRoomState extends ConsumerState<IsometricRoom> {
  String? _draggingId;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(placementProvider);
    final room = state.room;

    if (room == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.view_in_ar, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'JSON을 붙여넣어 시작하세요',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate scale to fit room in view
        final maxW = constraints.maxWidth * 0.85;
        final maxH = constraints.maxHeight * 0.65;
        final roomScreenW =
            (room.width + room.depth) * IsometricMath.cosA;
        final roomScreenH =
            (room.width + room.depth) * IsometricMath.sinA + room.height;

        final scaleW = maxW / roomScreenW;
        final scaleH = maxH / roomScreenH;
        IsometricMath.scale = scaleW < scaleH ? scaleW : scaleH;

        // Center the room
        IsometricMath.origin = Offset(
          constraints.maxWidth / 2,
          constraints.maxHeight * 0.35 + room.height * IsometricMath.scale * 0.5,
        );

        return GestureDetector(
          onTapUp: (details) => _handleTap(details.localPosition, state),
          onPanStart: (details) =>
              _handleDragStart(details.localPosition, state),
          onPanUpdate: (details) =>
              _handleDragUpdate(details.localPosition, state),
          onPanEnd: (_) => _handleDragEnd(state),
          child: CustomPaint(
            size: Size(constraints.maxWidth, constraints.maxHeight),
            painter: GridPainter(room: room),
            foregroundPainter: FurnitureRenderer(
              items: state.furniture,
              selectedId: state.selectedId,
              draggingId: _draggingId,
            ),
          ),
        );
      },
    );
  }

  void _handleTap(Offset pos, PlacementState state) {
    final hit = _hitTest(pos, state);
    if (hit != null) {
      final notifier = ref.read(placementProvider.notifier);
      if (state.selectedId == hit.id) {
        notifier.rotateFurniture(hit.id);
      } else {
        notifier.selectFurniture(hit.id);
      }
    } else {
      ref.read(placementProvider.notifier).selectFurniture(null);
    }
  }

  void _handleDragStart(Offset pos, PlacementState state) {
    final hit = _hitTest(pos, state);
    if (hit != null) {
      setState(() {
        _draggingId = hit.id;
      });
      ref.read(placementProvider.notifier).selectFurniture(hit.id);
    }
  }

  void _handleDragUpdate(Offset pos, PlacementState state) {
    if (_draggingId == null || state.room == null) return;
    final worldPos = IsometricMath.screenToWorld(pos);
    ref
        .read(placementProvider.notifier)
        .placeFurniture(_draggingId!, worldPos.dx, worldPos.dy);
  }

  void _handleDragEnd(PlacementState state) {
    setState(() {
      _draggingId = null;
    });
  }

  Furniture? _hitTest(Offset screenPos, PlacementState state) {
    // Test from front to back (reverse depth order)
    final placed = state.furniture.where((f) => f.isPlaced).toList()
      ..sort((a, b) {
        final da = a.position.x + a.position.z;
        final db = b.position.x + b.position.z;
        return db.compareTo(da);
      });

    for (final item in placed) {
      final topFace = IsometricMath.getTopFace(
        item.position.x,
        item.position.y,
        item.position.z,
        item.effectiveWidth,
        item.size.y,
        item.effectiveDepth,
      );

      if (_pointInPolygon(screenPos, topFace)) return item;

      final leftFace = IsometricMath.getLeftFace(
        item.position.x,
        item.position.y,
        item.position.z,
        item.effectiveWidth,
        item.size.y,
        item.effectiveDepth,
      );
      if (_pointInPolygon(screenPos, leftFace)) return item;

      final rightFace = IsometricMath.getRightFace(
        item.position.x,
        item.position.y,
        item.position.z,
        item.effectiveWidth,
        item.size.y,
        item.effectiveDepth,
      );
      if (_pointInPolygon(screenPos, rightFace)) return item;
    }
    return null;
  }

  bool _pointInPolygon(Offset point, List<Offset> polygon) {
    bool inside = false;
    int j = polygon.length - 1;
    for (int i = 0; i < polygon.length; i++) {
      if ((polygon[i].dy > point.dy) != (polygon[j].dy > point.dy) &&
          point.dx <
              (polygon[j].dx - polygon[i].dx) *
                      (point.dy - polygon[i].dy) /
                      (polygon[j].dy - polygon[i].dy) +
                  polygon[i].dx) {
        inside = !inside;
      }
      j = i;
    }
    return inside;
  }
}
