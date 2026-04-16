import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/furniture.dart';
import '../models/app_theme.dart';
import '../providers/placement_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/isometric_math.dart';
import 'grid_painter.dart';
import 'furniture_renderer.dart';
import 'dimension_dialog.dart';

const _loupeSize = 130.0;

class IsometricRoom extends ConsumerStatefulWidget {
  const IsometricRoom({super.key});

  @override
  ConsumerState<IsometricRoom> createState() => _IsometricRoomState();
}

class _IsometricRoomState extends ConsumerState<IsometricRoom> {
  bool _isDragging = false;
  Offset? _dragScreenPos;
  bool _zoomed = false;
  Offset _zoomFocus = Offset.zero; // world center for zoom

  Offset _itemCenter(Furniture item) => Offset(
        item.position.x + item.effectiveWidth / 2,
        item.position.z + item.effectiveDepth / 2,
      );

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(placementProvider);
    final theme = ref.watch(currentThemeProvider);
    final axisSwapped = ref.watch(axisSwapProvider);
    final guideColor = ref.watch(guideColorProvider);
    final guideOpacity = ref.watch(guideOpacityProvider);
    IsometricMath.swapAxes = axisSwapped;
    final room = state.room;

    return LayoutBuilder(
      builder: (context, constraints) {
        _applyScale(room, constraints);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (d) => _handleTap(d.localPosition, state),
          onPanStart: (d) => _handleDragStart(d.localPosition, state),
          onPanUpdate: (d) => _handleDragUpdate(d.localPosition, state),
          onPanEnd: (_) => _handleDragEnd(),
          child: Stack(
            children: [
              CustomPaint(
                size: Size(constraints.maxWidth, constraints.maxHeight),
                painter: GridPainter(
                  room: room,
                  theme: theme,
                  selectedHeight: state.selectedFurniture != null
                      ? state.selectedFurniture!.position.y +
                          state.selectedFurniture!.size.y
                      : null,
                  axisSwapped: axisSwapped,
                  guideColor: guideColor,
                  guideOpacity: guideOpacity,
                  selX: state.selectedFurniture?.position.x,
                  selZ: state.selectedFurniture?.position.z,
                  selW: state.selectedFurniture?.effectiveWidth,
                  selD: state.selectedFurniture?.effectiveDepth,
                  selY: state.selectedFurniture?.position.y,
                ),
                foregroundPainter: FurnitureRenderer(
                  items: state.furniture,
                  theme: theme,
                  roomWidth: room.width,
                  roomDepth: room.depth,
                  roomHeight: room.height,
                  selectedId: state.selectedId,
                  draggingId: _isDragging ? state.selectedId : null,
                  snapTileSize:
                      _isDragging ? state.room.tileSize : null,
                ),
              ),
              // Loupe while dragging
              if (_isDragging && _dragScreenPos != null)
                _buildLoupe(state, theme, constraints),
              // Zoom toggle button
              Positioned(
                right: 12,
                bottom: 12,
                child: _ZoomBtn(
                  zoomed: _zoomed,
                  theme: theme,
                  onTap: () {
                    setState(() {
                      _zoomed = !_zoomed;
                      if (_zoomed && state.selectedFurniture != null) {
                        _zoomFocus = _itemCenter(state.selectedFurniture!);
                      }
                    });
                  },
                ),
              ),
              // Name + color edit (top-left)
              if (state.selectedId != null && !_isDragging)
                Positioned(
                  left: 12,
                  top: 12,
                  child: _ItemInfoPanel(
                    item: state.selectedFurniture!,
                    theme: theme,
                    onNameChanged: (name) => ref
                        .read(placementProvider.notifier)
                        .updateFurnitureName(state.selectedId!, name),
                    onColorChanged: (color) => ref
                        .read(placementProvider.notifier)
                        .updateFurnitureColor(state.selectedId!, color),
                  ),
                ),
              // Size edit button (top-right)
              if (state.selectedId != null && !_isDragging)
                Positioned(
                  right: 12,
                  top: 12,
                  child: GestureDetector(
                    onTap: () => _showSizeDialog(state.selectedFurniture!),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.headerBg.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: theme.accent.withValues(alpha: 0.2)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.straighten,
                              size: 16, color: theme.accent),
                          const SizedBox(width: 6),
                          Text(
                            '${state.selectedFurniture!.size.x}'
                            '\u00d7${state.selectedFurniture!.size.z}'
                            '\u00d7${state.selectedFurniture!.size.y}',
                            style: TextStyle(
                              color: theme.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              // Fine-tune controls when item selected
              if (state.selectedId != null && !_isDragging)
                Positioned(
                  left: 12,
                  bottom: 12,
                  child: _FineTunePanel(
                    item: state.selectedFurniture!,
                    theme: theme,
                    onNudge: (dx, dy, dz) {
                      final f = state.selectedFurniture!;
                      final notifier =
                          ref.read(placementProvider.notifier);
                      if (dx != 0 || dz != 0) {
                        notifier.placeFurniture(
                          state.selectedId!,
                          f.position.x + dx,
                          f.position.z + dz,
                        );
                      }
                      if (dy != 0) {
                        notifier.nudgeHeight(state.selectedId!, dy);
                      }
                    },
                  ),
                ),
              // Delete button when item selected
              if (state.selectedId != null && !_isDragging)
                Positioned(
                  right: 12,
                  bottom: 62,
                  child: GestureDetector(
                    onTap: () {
                      ref
                          .read(placementProvider.notifier)
                          .removeFurniture(state.selectedId!);
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.red.withValues(alpha: 0.4)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Icon(Icons.delete_outline,
                          size: 22, color: Colors.red.shade400),
                    ),
                  ),
                ),
              // Undo/Redo — fixed position, always visible when history exists
              if (!_isDragging &&
                  (ref.read(placementProvider.notifier).canUndo ||
                      ref.read(placementProvider.notifier).canRedo))
                Positioned(
                  right: 62,
                  bottom: 12,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _UndoRedoBtn(
                        icon: Icons.undo,
                        theme: theme,
                        enabled: ref.read(placementProvider.notifier).canUndo,
                        onTap: () =>
                            ref.read(placementProvider.notifier).undo(),
                      ),
                      const SizedBox(width: 6),
                      _UndoRedoBtn(
                        icon: Icons.redo,
                        theme: theme,
                        enabled: ref.read(placementProvider.notifier).canRedo,
                        onTap: () =>
                            ref.read(placementProvider.notifier).redo(),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _applyScale(dynamic room, BoxConstraints constraints) {
    final zoomFactor = _zoomed ? 2.2 : 1.0;
    final maxW = constraints.maxWidth * 0.85;
    final maxH = constraints.maxHeight * 0.65;
    final roomScreenW = (room.width + room.depth) * IsometricMath.cosA;
    final roomScreenH =
        (room.width + room.depth) * IsometricMath.sinA + room.height;

    final scaleW = maxW / roomScreenW;
    final scaleH = maxH / roomScreenH;
    final baseScale = scaleW < scaleH ? scaleW : scaleH;
    IsometricMath.scale = baseScale * zoomFactor;

    if (_zoomed) {
      // Center on zoom focus point
      final focusScreen = Offset(
        (_zoomFocus.dx - _zoomFocus.dy) * IsometricMath.cosA * IsometricMath.scale,
        (_zoomFocus.dx + _zoomFocus.dy) * IsometricMath.sinA * IsometricMath.scale,
      );
      IsometricMath.origin = Offset(
        constraints.maxWidth / 2 - focusScreen.dx,
        constraints.maxHeight / 2 - focusScreen.dy,
      );
    } else {
      IsometricMath.origin = Offset(
        constraints.maxWidth / 2,
        constraints.maxHeight * 0.35 +
            room.height * IsometricMath.scale * 0.5,
      );
    }
  }

  Widget _buildLoupe(
      PlacementState state, AppTheme theme, BoxConstraints constraints) {
    final item = state.selectedFurniture;
    if (item == null || !item.isPlaced) return const SizedBox.shrink();

    // Fixed at bottom-left corner
    const loupeX = 12.0;
    final loupeY = constraints.maxHeight - _loupeSize - 12;

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
                theme: theme,
                focusCenter: itemCenter,
                zoomScale: 2.5,
                selectedId: state.selectedId,
                draggingId: _isDragging ? state.selectedId : null,
                snapTileSize: _isDragging ? state.room.tileSize : null,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showSizeDialog(Furniture item) async {
    final theme = ref.read(currentThemeProvider);
    final result = await showDialog<DimensionResult>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => DimensionDialog(
        theme: theme,
        initialName: item.name,
        initialX: item.size.x,
        initialY: item.size.y,
        initialZ: item.size.z,
        isEdit: true,
      ),
    );
    if (result == null) return;
    final notifier = ref.read(placementProvider.notifier);
    notifier.updateFurnitureSize(item.id, result.x, result.y, result.z);
    if (result.name.isNotEmpty) {
      notifier.updateFurnitureName(item.id, result.name);
    }
  }

  void _handleTap(Offset pos, PlacementState state) {
    final hit = _hitTest(pos, state);
    final notifier = ref.read(placementProvider.notifier);

    if (hit != null) {
      if (state.selectedId == hit.id) {
        // Tap already-selected item → rotate
        notifier.rotateFurniture(hit.id);
      } else {
        notifier.selectFurniture(hit.id);
      }
      // Update zoom focus
      if (_zoomed) {
        setState(() {
          _zoomFocus = _itemCenter(hit);
        });
      }
    } else if (state.selectedId != null) {
      // Tap empty space with item selected → move item there (only if inside map)
      final worldPos = IsometricMath.screenToWorld(pos);
      final room = state.room;
      if (worldPos.dx >= 0 &&
          worldPos.dx <= room.width &&
          worldPos.dy >= 0 &&
          worldPos.dy <= room.depth) {
        final item =
            state.furniture.firstWhere((f) => f.id == state.selectedId);
        final targetX = worldPos.dx - item.effectiveWidth / 2;
        final targetZ = worldPos.dy - item.effectiveDepth / 2;
        notifier.placeFurniture(state.selectedId!, targetX, targetZ);
        notifier.snapFurniture(state.selectedId!);
        if (_zoomed) {
          setState(() {
            _zoomFocus = Offset(
              worldPos.dx,
              worldPos.dy,
            );
          });
        }
      } else {
        // Tap outside map → deselect
        notifier.selectFurniture(null);
      }
    } else {
      notifier.selectFurniture(null);
    }
  }

  Offset? _lastDragScreen;
  Offset? _dragStartScreen; // initial touch point to detect tap vs drag
  bool _didMove = false;

  void _handleDragStart(Offset pos, PlacementState state) {
    final hit = _hitTest(pos, state);
    final notifier = ref.read(placementProvider.notifier);

    String? dragTarget;
    if (hit != null) {
      dragTarget = hit.id;
      notifier.selectFurniture(hit.id);
    } else if (state.selectedId != null) {
      dragTarget = state.selectedId;
    }

    if (dragTarget != null) {
      final dragItem = state.furniture.firstWhere((f) => f.id == dragTarget);
      setState(() {
        _isDragging = true;
        _didMove = false;
        _dragScreenPos = pos;
        _dragStartScreen = pos;
        _lastDragScreen = pos;
        if (_zoomed) {
          _zoomFocus = _itemCenter(dragItem);
        }
      });
    }
  }

  void _handleDragUpdate(Offset pos, PlacementState state) {
    if (!_isDragging || state.selectedId == null || _lastDragScreen == null) {
      return;
    }

    // Convert screen delta to world delta
    final prevWorld = IsometricMath.screenToWorld(_lastDragScreen!);
    final currWorld = IsometricMath.screenToWorld(pos);
    final deltaX = currWorld.dx - prevWorld.dx;
    final deltaZ = currWorld.dy - prevWorld.dy;

    // Move item by delta
    final item = state.furniture.firstWhere((f) => f.id == state.selectedId);
    final nextX = item.position.x + deltaX;
    final nextZ = item.position.z + deltaZ;
    ref.read(placementProvider.notifier).placeFurniture(
          state.selectedId!,
          nextX,
          nextZ,
        );

    _didMove = true;
    setState(() {
      _dragScreenPos = pos;
      _lastDragScreen = pos;
      if (_zoomed) {
        _zoomFocus = Offset(
          nextX + item.effectiveWidth / 2,
          nextZ + item.effectiveDepth / 2,
        );
      }
    });
  }

  void _handleDragEnd() {
    final state = ref.read(placementProvider);
    final notifier = ref.read(placementProvider.notifier);
    final selectedId = state.selectedId;

    if (!_didMove && _dragStartScreen != null && selectedId != null) {
      // Didn't move → treat as tap-to-move (only inside map)
      final hit = _hitTest(_dragStartScreen!, state);
      if (hit == null) {
        final worldPos = IsometricMath.screenToWorld(_dragStartScreen!);
        final room = state.room;
        if (worldPos.dx >= 0 &&
            worldPos.dx <= room.width &&
            worldPos.dy >= 0 &&
            worldPos.dy <= room.depth) {
          final item =
              state.furniture.firstWhere((f) => f.id == selectedId);
          final targetX = worldPos.dx - item.effectiveWidth / 2;
          final targetZ = worldPos.dy - item.effectiveDepth / 2;
          notifier.placeFurniture(selectedId, targetX, targetZ);
        } else {
          // Tap outside map → deselect
          notifier.selectFurniture(null);
        }
      }
    }

    // Snap to grid on release
    if (selectedId != null && _isDragging) {
      notifier.snapFurniture(selectedId);
    }

    final snappedItem = selectedId == null
        ? null
        : ref
            .read(placementProvider)
            .furniture
            .cast<Furniture?>()
            .firstWhere((f) => f?.id == selectedId, orElse: () => null);

    setState(() {
      _isDragging = false;
      _didMove = false;
      _dragScreenPos = null;
      _dragStartScreen = null;
      _lastDragScreen = null;
      if (_zoomed && snappedItem != null) {
        _zoomFocus = _itemCenter(snappedItem);
      }
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
      const pad = 12.0;

      for (final face in [
        IsometricMath.getTopFace(
          item.position.x, item.position.y, item.position.z,
          item.effectiveWidth, item.size.y, item.effectiveDepth,
        ),
        IsometricMath.getLeftFace(
          item.position.x, item.position.y, item.position.z,
          item.effectiveWidth, item.size.y, item.effectiveDepth,
        ),
        IsometricMath.getRightFace(
          item.position.x, item.position.y, item.position.z,
          item.effectiveWidth, item.size.y, item.effectiveDepth,
        ),
      ]) {
        if (_pointNearPolygon(screenPos, face, pad)) return item;
      }
    }
    return null;
  }

  bool _pointNearPolygon(Offset point, List<Offset> polygon, double pad) {
    double minX = polygon[0].dx, maxX = polygon[0].dx;
    double minY = polygon[0].dy, maxY = polygon[0].dy;
    for (final p in polygon) {
      if (p.dx < minX) minX = p.dx;
      if (p.dx > maxX) maxX = p.dx;
      if (p.dy < minY) minY = p.dy;
      if (p.dy > maxY) maxY = p.dy;
    }
    if (point.dx < minX - pad ||
        point.dx > maxX + pad ||
        point.dy < minY - pad ||
        point.dy > maxY + pad) {
      return false;
    }
    // Check actual polygon
    if (_pointInPolygon(point, polygon)) return true;
    // Check padded bounding box as fallback for small items
    if (maxX - minX < 30 || maxY - minY < 30) {
      return point.dx >= minX - pad &&
          point.dx <= maxX + pad &&
          point.dy >= minY - pad &&
          point.dy <= maxY + pad;
    }
    return false;
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

// ─── Item info panel (name + color) ───
const _itemColors = <Color>[
  Color(0xFF5B8DEF),
  Color(0xFF5BCA8A),
  Color(0xFFE8A838),
  Color(0xFFEF5B7B),
  Color(0xFF9B59B6),
  Color(0xFF1ABC9C),
  Color(0xFFE67E22),
  Color(0xFF3498DB),
  Color(0xFFE74C3C),
  Color(0xFF2ECC71),
  Color(0xFF607D8B),
  Color(0xFF795548),
];

class _ItemInfoPanel extends StatefulWidget {
  final Furniture item;
  final AppTheme theme;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<Color> onColorChanged;

  const _ItemInfoPanel({
    required this.item,
    required this.theme,
    required this.onNameChanged,
    required this.onColorChanged,
  });

  @override
  State<_ItemInfoPanel> createState() => _ItemInfoPanelState();
}

class _ItemInfoPanelState extends State<_ItemInfoPanel> {
  late TextEditingController _ctrl;
  bool _showColors = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.item.name);
  }

  @override
  void didUpdateWidget(covariant _ItemInfoPanel old) {
    super.didUpdateWidget(old);
    if (old.item.id != widget.item.id) {
      _ctrl.text = widget.item.name;
      _showColors = false;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    return Container(
      width: 200,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: t.headerBg.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.accent.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name field
          Row(
            children: [
              // Color dot — tap to toggle palette
              GestureDetector(
                onTap: () => setState(() => _showColors = !_showColors),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: widget.item.color,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Icon(
                    Icons.palette,
                    size: 14,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  maxLength: 10,
                  style: TextStyle(
                    color: t.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    counterText: '',
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 6),
                    filled: true,
                    fillColor: t.cardBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    hintText: '이름 (10자)',
                    hintStyle: TextStyle(
                      color: t.textSecondary.withValues(alpha: 0.5),
                      fontSize: 13,
                    ),
                  ),
                  onChanged: widget.onNameChanged,
                ),
              ),
            ],
          ),
          // Color palette
          if (_showColors) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final c in _itemColors)
                  GestureDetector(
                    onTap: () {
                      widget.onColorChanged(c);
                      setState(() => _showColors = false);
                    },
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: widget.item.color == c
                            ? Border.all(color: t.textPrimary, width: 2.5)
                            : null,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Fine-tune panel (isometric D-pad + Y height) ───
class _FineTunePanel extends StatelessWidget {
  final Furniture item;
  final AppTheme theme;
  final void Function(double dx, double dy, double dz) onNudge;

  const _FineTunePanel({
    required this.item,
    required this.theme,
    required this.onNudge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.headerBg.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.accent.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title
          Text(
            '상세 조정',
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          // Coordinates
          Text(
            'X:${item.position.x.toStringAsFixed(1)}  '
            'Y:${item.position.y.toStringAsFixed(1)}  '
            'Z:${item.position.z.toStringAsFixed(1)}',
            style: TextStyle(
              color: theme.textSecondary,
              fontSize: 10,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 8),
          // All controls in one column
          // X row
          _buildAxisRow('X', theme.accent,
              () => onNudge(-0.1, 0, 0), () => onNudge(0.1, 0, 0),
              item.position.x),
          const SizedBox(height: 6),
          // Z row
          _buildAxisRow('Z', theme.accentSecondary,
              () => onNudge(0, 0, -0.1), () => onNudge(0, 0, 0.1),
              item.position.z),
          const SizedBox(height: 6),
          // Y row
          _buildAxisRow('Y', theme.textSecondary,
              () => onNudge(0, -0.1, 0), () => onNudge(0, 0.1, 0),
              item.position.y),
        ],
      ),
    );
  }

  Widget _buildAxisRow(String label, Color color,
      VoidCallback onMinus, VoidCallback onPlus, double value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 14,
          child: Text(label, style: TextStyle(
            color: color, fontSize: 10, fontWeight: FontWeight.w700,
          )),
        ),
        const SizedBox(width: 4),
        _NudgeBtn(label: '−', theme: theme, onTap: onMinus,
            color: color, small: true),
        Container(
          width: 40,
          alignment: Alignment.center,
          child: Text(
            value.toStringAsFixed(1),
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
            ),
          ),
        ),
        _NudgeBtn(label: '+', theme: theme, onTap: onPlus,
            color: color, small: true),
      ],
    );
  }
}

/// Repeating button — tap or hold to repeat
class _NudgeBtn extends StatefulWidget {
  final String label;
  final AppTheme theme;
  final VoidCallback onTap;
  final Color color;
  final bool small;

  const _NudgeBtn({
    required this.label,
    required this.theme,
    required this.onTap,
    required this.color,
    this.small = false,
  });

  @override
  State<_NudgeBtn> createState() => _NudgeBtnState();
}

class _NudgeBtnState extends State<_NudgeBtn> {
  bool _holding = false;

  void _startHold() {
    _holding = true;
    widget.onTap();
    _repeatLoop();
  }

  Future<void> _repeatLoop() async {
    // Initial delay before repeating
    await Future.delayed(const Duration(milliseconds: 300));
    // Repeat at ~15fps
    while (_holding && mounted) {
      widget.onTap();
      await Future.delayed(const Duration(milliseconds: 66));
    }
  }

  void _stopHold() {
    _holding = false;
  }

  @override
  Widget build(BuildContext context) {
    final sz = widget.small ? 36.0 : 44.0;
    final fs = widget.small ? 12.0 : 11.0;
    return GestureDetector(
      onTapDown: (_) => _startHold(),
      onTapUp: (_) => _stopHold(),
      onTapCancel: _stopHold,
      child: Container(
        width: sz,
        height: sz,
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: widget.color.withValues(alpha: 0.3)),
        ),
        child: Center(
          child: Text(
            widget.label,
            style: TextStyle(
              color: widget.color,
              fontSize: fs,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Undo/Redo button ───
class _UndoRedoBtn extends StatelessWidget {
  final IconData icon;
  final AppTheme theme;
  final VoidCallback onTap;
  final bool enabled;

  const _UndoRedoBtn({
    required this.icon,
    required this.theme,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.25,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.headerBg.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: theme.textSecondary.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 6,
              ),
            ],
          ),
          child: Icon(icon, size: 20, color: theme.textSecondary),
        ),
      ),
    );
  }
}

// ─── Zoom toggle button ───
class _ZoomBtn extends StatelessWidget {
  final bool zoomed;
  final AppTheme theme;
  final VoidCallback onTap;

  const _ZoomBtn({
    required this.zoomed,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: zoomed
              ? theme.accent
              : theme.headerBg.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: zoomed
                ? theme.accent
                : theme.textSecondary.withValues(alpha: 0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
            ),
          ],
        ),
        child: Icon(
          zoomed ? Icons.zoom_out : Icons.zoom_in,
          size: 22,
          color: zoomed ? Colors.white : theme.textSecondary,
        ),
      ),
    );
  }
}

// ─── Loupe painter ───
class _LoupePainter extends CustomPainter {
  final dynamic room;
  final List<Furniture> items;
  final AppTheme theme;
  final Offset focusCenter;
  final double zoomScale;
  final String? selectedId;
  final String? draggingId;
  final double? snapTileSize;

  _LoupePainter({
    required this.room,
    required this.items,
    required this.theme,
    required this.focusCenter,
    required this.zoomScale,
    this.selectedId,
    this.draggingId,
    this.snapTileSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final savedScale = IsometricMath.scale;
    final savedOrigin = IsometricMath.origin;

    final loupeCenter = Offset(size.width / 2, size.height / 2);
    IsometricMath.scale = savedScale * zoomScale;
    IsometricMath.origin = Offset(
      loupeCenter.dx - (focusCenter.dx - savedOrigin.dx) * zoomScale,
      loupeCenter.dy - (focusCenter.dy - savedOrigin.dy) * zoomScale,
    );

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = theme.scaffoldBg,
    );

    GridPainter(room: room, theme: theme).paint(canvas, size);
    FurnitureRenderer(
      items: items,
      theme: theme,
      roomWidth: room.width,
      roomDepth: room.depth,
      roomHeight: room.height,
      selectedId: selectedId,
      draggingId: draggingId,
      snapTileSize: snapTileSize,
    ).paint(canvas, size);

    // Crosshair
    final cp = Paint()
      ..color = theme.accent.withValues(alpha: 0.5)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(loupeCenter.dx - 10, loupeCenter.dy),
        Offset(loupeCenter.dx + 10, loupeCenter.dy), cp);
    canvas.drawLine(Offset(loupeCenter.dx, loupeCenter.dy - 10),
        Offset(loupeCenter.dx, loupeCenter.dy + 10), cp);

    IsometricMath.scale = savedScale;
    IsometricMath.origin = savedOrigin;
  }

  @override
  bool shouldRepaint(covariant _LoupePainter old) => true;
}
