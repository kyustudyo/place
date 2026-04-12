import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/furniture.dart';
import '../providers/placement_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/isometric_math.dart';
import 'grid_painter.dart';
import 'furniture_renderer.dart';

/// Vertical offset so the item floats above the finger while dragging
const _dragYOffset = -80.0;

/// Magnifier size
const _loupeSize = 120.0;

class IsometricRoom extends ConsumerStatefulWidget {
  const IsometricRoom({super.key});

  @override
  ConsumerState<IsometricRoom> createState() => _IsometricRoomState();
}

class _IsometricRoomState extends ConsumerState<IsometricRoom> {
  String? _draggingId;
  Offset? _dragScreenPos; // raw finger position on screen

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(placementProvider);
    final theme = ref.watch(currentThemeProvider);
    final room = state.room;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth * 0.85;
        final maxH = constraints.maxHeight * 0.65;
        final roomScreenW =
            (room.width + room.depth) * IsometricMath.cosA;
        final roomScreenH =
            (room.width + room.depth) * IsometricMath.sinA + room.height;

        final scaleW = maxW / roomScreenW;
        final scaleH = maxH / roomScreenH;
        IsometricMath.scale = scaleW < scaleH ? scaleW : scaleH;

        IsometricMath.origin = Offset(
          constraints.maxWidth / 2,
          constraints.maxHeight * 0.35 +
              room.height * IsometricMath.scale * 0.5,
        );

        return GestureDetector(
          onTapUp: (details) => _handleTap(details.localPosition, state),
          onPanStart: (details) =>
              _handleDragStart(details.localPosition, state),
          onPanUpdate: (details) =>
              _handleDragUpdate(details.localPosition, state),
          onPanEnd: (_) => _handleDragEnd(),
          child: Stack(
            children: [
              CustomPaint(
                size: Size(constraints.maxWidth, constraints.maxHeight),
                painter: GridPainter(
                  room: room,
                  theme: theme,
                  selectedHeight: state.selectedFurniture?.size.y,
                ),
                foregroundPainter: FurnitureRenderer(
                  items: state.furniture,
                  theme: theme,
                  selectedId: state.selectedId,
                  draggingId: _draggingId,
                ),
              ),
              // Magnifier loupe while dragging
              if (_draggingId != null && _dragScreenPos != null)
                _buildLoupe(state, theme, constraints),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoupe(
      PlacementState state, dynamic theme, BoxConstraints constraints) {
    final item = state.furniture.cast<Furniture?>().firstWhere(
          (f) => f?.id == _draggingId,
          orElse: () => null,
        );
    if (item == null || !item.isPlaced) return const SizedBox.shrink();

    // Position loupe above and to the left of finger
    final fingerPos = _dragScreenPos!;
    var loupeX = fingerPos.dx - _loupeSize / 2;
    var loupeY = fingerPos.dy - _loupeSize - 60;

    // Keep within bounds
    loupeX = loupeX.clamp(8, constraints.maxWidth - _loupeSize - 8);
    loupeY = loupeY.clamp(8, constraints.maxHeight - _loupeSize - 8);

    // Item's isometric center for the loupe content
    final itemCenter = IsometricMath.worldToScreen(
      item.position.x + item.effectiveWidth / 2,
      item.position.y + item.size.y / 2,
      item.position.z + item.effectiveDepth / 2,
    );

    return Positioned(
      left: loupeX,
      top: loupeY,
      child: IgnorePointer(
        child: Container(
          width: _loupeSize,
          height: _loupeSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: item.color.withValues(alpha: 0.7),
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 12,
              ),
            ],
          ),
          child: ClipOval(
            child: CustomPaint(
              size: const Size(_loupeSize, _loupeSize),
              painter: _LoupePainter(
                room: state.room,
                items: state.furniture,
                theme: ref.read(currentThemeProvider),
                focusCenter: itemCenter,
                zoomScale: 2.5,
                draggingId: _draggingId,
              ),
            ),
          ),
        ),
      ),
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
        _dragScreenPos = pos;
      });
      ref.read(placementProvider.notifier).selectFurniture(hit.id);
    }
  }

  void _handleDragUpdate(Offset pos, PlacementState state) {
    if (_draggingId == null) return;
    // Offset upward so item is above the finger
    final offsetPos = Offset(pos.dx, pos.dy + _dragYOffset);
    final worldPos = IsometricMath.screenToWorld(offsetPos);
    ref
        .read(placementProvider.notifier)
        .placeFurniture(_draggingId!, worldPos.dx, worldPos.dy);
    setState(() => _dragScreenPos = pos);
  }

  void _handleDragEnd() {
    setState(() {
      _draggingId = null;
      _dragScreenPos = null;
    });
  }

  Furniture? _hitTest(Offset screenPos, PlacementState state) {
    final placed = state.furniture.where((f) => f.isPlaced).toList()
      ..sort((a, b) {
        final da = a.position.x + a.position.z;
        final db = b.position.x + b.position.z;
        return db.compareTo(da);
      });

    for (final item in placed) {
      final topFace = IsometricMath.getTopFace(
        item.position.x, item.position.y, item.position.z,
        item.effectiveWidth, item.size.y, item.effectiveDepth,
      );
      if (_pointInPolygon(screenPos, topFace)) return item;

      final leftFace = IsometricMath.getLeftFace(
        item.position.x, item.position.y, item.position.z,
        item.effectiveWidth, item.size.y, item.effectiveDepth,
      );
      if (_pointInPolygon(screenPos, leftFace)) return item;

      final rightFace = IsometricMath.getRightFace(
        item.position.x, item.position.y, item.position.z,
        item.effectiveWidth, item.size.y, item.effectiveDepth,
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

/// Paints a zoomed-in view of the isometric room centered on a point
class _LoupePainter extends CustomPainter {
  final dynamic room;
  final List<Furniture> items;
  final dynamic theme;
  final Offset focusCenter;
  final double zoomScale;
  final String? draggingId;

  _LoupePainter({
    required this.room,
    required this.items,
    required this.theme,
    required this.focusCenter,
    required this.zoomScale,
    this.draggingId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Save current isometric state
    final savedScale = IsometricMath.scale;
    final savedOrigin = IsometricMath.origin;

    // Apply zoom: scale up and shift origin so focusCenter is at loupe center
    final loupeCenter = Offset(size.width / 2, size.height / 2);
    IsometricMath.scale = savedScale * zoomScale;

    // Recalculate origin so that the focus point maps to loupe center
    // focusCenter was calculated with savedScale/savedOrigin
    // We need: newOrigin + (focusCenter - savedOrigin) * zoomScale = loupeCenter
    IsometricMath.origin = Offset(
      loupeCenter.dx - (focusCenter.dx - savedOrigin.dx) * zoomScale,
      loupeCenter.dy - (focusCenter.dy - savedOrigin.dy) * zoomScale,
    );

    // Background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = theme.scaffoldBg,
    );

    // Draw grid
    final gridPainter = GridPainter(room: room, theme: theme);
    gridPainter.paint(canvas, size);

    // Draw furniture
    final furniturePainter = FurnitureRenderer(
      items: items,
      theme: theme,
      draggingId: draggingId,
    );
    furniturePainter.paint(canvas, size);

    // Crosshair at center
    final crossPaint = Paint()
      ..color = theme.accent.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(loupeCenter.dx - 8, loupeCenter.dy),
      Offset(loupeCenter.dx + 8, loupeCenter.dy),
      crossPaint,
    );
    canvas.drawLine(
      Offset(loupeCenter.dx, loupeCenter.dy - 8),
      Offset(loupeCenter.dx, loupeCenter.dy + 8),
      crossPaint,
    );

    // Restore
    IsometricMath.scale = savedScale;
    IsometricMath.origin = savedOrigin;
  }

  @override
  bool shouldRepaint(covariant _LoupePainter old) => true;
}
