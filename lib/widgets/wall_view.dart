import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/wall.dart';
import '../models/wall_item.dart';
import '../models/app_theme.dart';
import '../providers/wall_placement_provider.dart';
import '../providers/theme_provider.dart';
import 'dimension_dialog.dart';

class WallView extends ConsumerStatefulWidget {
  const WallView({super.key});

  @override
  ConsumerState<WallView> createState() => _WallViewState();
}

class _WallViewState extends ConsumerState<WallView> {
  bool _isDragging = false;
  Offset? _lastDragScreen;
  Offset? _dragStartScreen;
  bool _didMove = false;

  // Rendering state
  double _scale = 1.0;
  Offset _origin = Offset.zero; // bottom-left corner of wall in screen coords

  void _applyScale(Wall wall, BoxConstraints constraints) {
    final maxW = constraints.maxWidth * 0.85;
    final maxH = constraints.maxHeight * 0.80;

    final scaleW = maxW / wall.width;
    final scaleH = maxH / wall.height;
    _scale = scaleW < scaleH ? scaleW : scaleH;

    // Center the wall, origin at bottom-left
    final wallScreenW = wall.width * _scale;
    final wallScreenH = wall.height * _scale;
    _origin = Offset(
      (constraints.maxWidth - wallScreenW) / 2,
      (constraints.maxHeight + wallScreenH) / 2,
    );
  }

  Offset wallToScreen(double x, double y) {
    return Offset(
      _origin.dx + x * _scale,
      _origin.dy - y * _scale,
    );
  }

  Offset screenToWall(Offset screen) {
    return Offset(
      (screen.dx - _origin.dx) / _scale,
      (_origin.dy - screen.dy) / _scale,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(wallPlacementProvider);
    final theme = ref.watch(currentThemeProvider);
    final wall = state.currentWallData;
    final items = state.currentItems;

    return LayoutBuilder(
      builder: (context, constraints) {
        _applyScale(wall, constraints);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (d) => _handleTap(d.localPosition, state),
          onLongPressStart: (d) =>
              _handleLongPress(d.globalPosition, d.localPosition, state),
          onPanStart: (d) => _handleDragStart(d.localPosition, state),
          onPanUpdate: (d) => _handleDragUpdate(d.localPosition, state),
          onPanEnd: (_) => _handleDragEnd(),
          child: Stack(
            children: [
              CustomPaint(
                size: Size(constraints.maxWidth, constraints.maxHeight),
                painter: _WallGridPainter(
                  wall: wall,
                  theme: theme,
                  origin: _origin,
                  scale: _scale,
                ),
                foregroundPainter: _WallItemPainter(
                  items: items,
                  theme: theme,
                  origin: _origin,
                  scale: _scale,
                  selectedId: state.selectedId,
                  isDragging: _isDragging,
                ),
              ),
              // Wall type label
              Positioned(
                left: 12,
                top: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.headerBg.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: theme.textSecondary.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    state.currentWall == WallType.back ? '뒷벽' : '오른벽',
                    style: TextStyle(
                      color: theme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              // Item info panel (below wall label)
              if (state.selectedId != null && !_isDragging)
                Positioned(
                  left: 12,
                  top: 50,
                  child: _WallItemInfoPanel(
                    item: state.selectedItem!,
                    theme: theme,
                    onNameChanged: (name) => ref
                        .read(wallPlacementProvider.notifier)
                        .updateItemName(state.selectedId!, name),
                    onColorChanged: (color) => ref
                        .read(wallPlacementProvider.notifier)
                        .updateItemColor(state.selectedId!, color),
                  ),
                ),
              // Size edit button (top-right)
              if (state.selectedId != null && !_isDragging)
                Positioned(
                  right: 12,
                  top: 12,
                  child: GestureDetector(
                    onTap: () => _showSizeDialog(state.selectedItem!),
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
                            '${state.selectedItem!.width}'
                            '\u00d7${state.selectedItem!.height}',
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
              // Fine-tune controls
              if (state.selectedId != null && !_isDragging)
                Positioned(
                  left: 12,
                  bottom: 12,
                  child: _WallFineTunePanel(
                    item: state.selectedItem!,
                    theme: theme,
                    onNudge: (dx, dy) {
                      ref
                          .read(wallPlacementProvider.notifier)
                          .nudgePosition(state.selectedId!, dx, dy);
                    },
                  ),
                ),
              // Delete button
              if (state.selectedId != null && !_isDragging)
                Positioned(
                  right: 12,
                  bottom: 62,
                  child: GestureDetector(
                    onTap: () {
                      ref
                          .read(wallPlacementProvider.notifier)
                          .removeItem(state.selectedId!);
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
              // Undo/Redo
              if (!_isDragging &&
                  (ref.read(wallPlacementProvider.notifier).canUndo ||
                      ref.read(wallPlacementProvider.notifier).canRedo))
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _WallUndoRedoBtn(
                        icon: Icons.undo,
                        theme: theme,
                        enabled:
                            ref.read(wallPlacementProvider.notifier).canUndo,
                        onTap: () =>
                            ref.read(wallPlacementProvider.notifier).undo(),
                      ),
                      const SizedBox(width: 6),
                      _WallUndoRedoBtn(
                        icon: Icons.redo,
                        theme: theme,
                        enabled:
                            ref.read(wallPlacementProvider.notifier).canRedo,
                        onTap: () =>
                            ref.read(wallPlacementProvider.notifier).redo(),
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

  Future<void> _showSizeDialog(WallItem item) async {
    final theme = ref.read(currentThemeProvider);
    final result = await showDialog<DimensionResult>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => DimensionDialog(
        theme: theme,
        initialName: item.name,
        initialX: item.width,
        initialY: item.height,
        initialZ: 0,
        isEdit: true,
        hideZ: true,
      ),
    );
    if (result == null) return;
    final notifier = ref.read(wallPlacementProvider.notifier);
    notifier.updateItemSize(item.id, result.x, result.y);
    if (result.name.isNotEmpty) {
      notifier.updateItemName(item.id, result.name);
    }
  }

  WallItem? _hitTest(Offset screenPos, WallPlacementState state) {
    final items = state.currentItems.where((i) => i.isPlaced).toList();
    // Reverse order: last added on top
    for (final item in items.reversed) {
      final topLeft = wallToScreen(item.x, item.y + item.height);
      final bottomRight = wallToScreen(item.x + item.width, item.y);
      final rect = Rect.fromLTRB(
        topLeft.dx - 8,
        topLeft.dy - 8,
        bottomRight.dx + 8,
        bottomRight.dy + 8,
      );
      if (rect.contains(screenPos)) return item;
    }
    return null;
  }

  void _handleTap(Offset pos, WallPlacementState state) {
    final hit = _hitTest(pos, state);
    final notifier = ref.read(wallPlacementProvider.notifier);

    if (hit != null) {
      notifier.selectItem(hit.id);
    } else if (state.selectedId != null) {
      // Tap empty space → move item there
      final wallPos = screenToWall(pos);
      final wall = state.currentWallData;
      if (wallPos.dx >= 0 &&
          wallPos.dx <= wall.width &&
          wallPos.dy >= 0 &&
          wallPos.dy <= wall.height) {
        final item =
            state.currentItems.firstWhere((i) => i.id == state.selectedId);
        final targetX = wallPos.dx - item.width / 2;
        final targetY = wallPos.dy - item.height / 2;
        notifier.placeItem(state.selectedId!, targetX, targetY);
        notifier.snapItem(state.selectedId!);
      } else {
        notifier.selectItem(null);
      }
    } else {
      notifier.selectItem(null);
    }
  }

  void _handleLongPress(
      Offset globalPos, Offset localPos, WallPlacementState state) {
    if (_isDragging) return;
    final hit = _hitTest(localPos, state);
    if (hit == null) return;

    final theme = ref.read(currentThemeProvider);
    final notifier = ref.read(wallPlacementProvider.notifier);
    notifier.selectItem(hit.id);

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        globalPos.dx, globalPos.dy, globalPos.dx, globalPos.dy,
      ),
      color: theme.headerBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        PopupMenuItem<String>(
          value: 'duplicate',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.copy_rounded, size: 18, color: theme.accent),
              const SizedBox(width: 8),
              Text('복제하기',
                  style: TextStyle(color: theme.textPrimary, fontSize: 14)),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.delete_outline,
                  size: 18, color: Colors.red.shade400),
              const SizedBox(width: 8),
              Text('삭제하기',
                  style:
                      TextStyle(color: Colors.red.shade400, fontSize: 14)),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == 'duplicate') {
        notifier.duplicateItem(hit.id);
      } else if (value == 'delete') {
        notifier.removeItem(hit.id);
      }
    });
  }

  void _handleDragStart(Offset pos, WallPlacementState state) {
    final hit = _hitTest(pos, state);
    final notifier = ref.read(wallPlacementProvider.notifier);

    String? dragTarget;
    if (hit != null) {
      dragTarget = hit.id;
      notifier.selectItem(hit.id);
    } else if (state.selectedId != null) {
      dragTarget = state.selectedId;
    }

    if (dragTarget != null) {
      setState(() {
        _isDragging = true;
        _didMove = false;
        _dragStartScreen = pos;
        _lastDragScreen = pos;
      });
    }
  }

  void _handleDragUpdate(Offset pos, WallPlacementState state) {
    if (!_isDragging || state.selectedId == null || _lastDragScreen == null) {
      return;
    }

    final prevWall = screenToWall(_lastDragScreen!);
    final currWall = screenToWall(pos);
    final deltaX = currWall.dx - prevWall.dx;
    final deltaY = currWall.dy - prevWall.dy;

    final item =
        state.currentItems.firstWhere((i) => i.id == state.selectedId);
    ref.read(wallPlacementProvider.notifier).placeItem(
          state.selectedId!,
          item.x + deltaX,
          item.y + deltaY,
        );

    _didMove = true;
    setState(() {
      _lastDragScreen = pos;
    });
  }

  void _handleDragEnd() {
    final state = ref.read(wallPlacementProvider);
    final notifier = ref.read(wallPlacementProvider.notifier);
    final selectedId = state.selectedId;

    if (!_didMove && _dragStartScreen != null && selectedId != null) {
      final hit = _hitTest(_dragStartScreen!, state);
      if (hit == null) {
        final wallPos = screenToWall(_dragStartScreen!);
        final wall = state.currentWallData;
        if (wallPos.dx >= 0 &&
            wallPos.dx <= wall.width &&
            wallPos.dy >= 0 &&
            wallPos.dy <= wall.height) {
          final item =
              state.currentItems.firstWhere((i) => i.id == selectedId);
          notifier.placeItem(
              selectedId, wallPos.dx - item.width / 2, wallPos.dy - item.height / 2);
        } else {
          notifier.selectItem(null);
        }
      }
    }

    if (selectedId != null && _isDragging) {
      notifier.snapItem(selectedId);
    }

    setState(() {
      _isDragging = false;
      _didMove = false;
      _dragStartScreen = null;
      _lastDragScreen = null;
    });
  }
}

// ─── Wall Grid Painter ───
class _WallGridPainter extends CustomPainter {
  final Wall wall;
  final AppTheme theme;
  final Offset origin;
  final double scale;

  _WallGridPainter({
    required this.wall,
    required this.theme,
    required this.origin,
    required this.scale,
  });

  Offset _w2s(double x, double y) =>
      Offset(origin.dx + x * scale, origin.dy - y * scale);

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = theme.scaffoldBg,
    );

    // Wall rectangle
    final wallColor =
        wall.type == WallType.back ? theme.backWallColor : theme.leftWallColor;
    final topLeft = _w2s(0, wall.height);
    final bottomRight = _w2s(wall.width, 0);
    final wallRect = Rect.fromLTRB(
        topLeft.dx, topLeft.dy, bottomRight.dx, bottomRight.dy);

    canvas.drawRect(wallRect, Paint()..color = wallColor);

    // Grid lines
    final gridPaint = Paint()
      ..color = theme.gridColor.withValues(alpha: 0.3)
      ..strokeWidth = theme.gridLineWidth;

    final ts = wall.tileSize;
    // Vertical lines
    for (double x = ts; x < wall.width; x += ts) {
      final top = _w2s(x, wall.height);
      final bottom = _w2s(x, 0);
      canvas.drawLine(top, bottom, gridPaint);
    }
    // Horizontal lines
    for (double y = ts; y < wall.height; y += ts) {
      final left = _w2s(0, y);
      final right = _w2s(wall.width, y);
      canvas.drawLine(left, right, gridPaint);
    }

    // Wall border
    final borderPaint = Paint()
      ..color = theme.wallBorderColor
      ..strokeWidth = theme.wallBorderWidth
      ..style = PaintingStyle.stroke;
    canvas.drawRect(wallRect, borderPaint);

    // Floor line label
    final floorLabel = TextPainter(
      text: TextSpan(
        text: '바닥',
        style: TextStyle(
          color: theme.textSecondary.withValues(alpha: 0.5),
          fontSize: 10,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    floorLabel.paint(
      canvas,
      Offset(bottomRight.dx + 6, bottomRight.dy - floorLabel.height / 2),
    );

    // Dimension labels
    final widthLabel = TextPainter(
      text: TextSpan(
        text: '${wall.width}m',
        style: TextStyle(
          color: theme.textSecondary.withValues(alpha: 0.6),
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    widthLabel.paint(
      canvas,
      Offset(
        (topLeft.dx + bottomRight.dx) / 2 - widthLabel.width / 2,
        bottomRight.dy + 8,
      ),
    );

    final heightLabel = TextPainter(
      text: TextSpan(
        text: '${wall.height}m',
        style: TextStyle(
          color: theme.textSecondary.withValues(alpha: 0.6),
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    heightLabel.paint(
      canvas,
      Offset(
        topLeft.dx - heightLabel.width - 8,
        (topLeft.dy + bottomRight.dy) / 2 - heightLabel.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _WallGridPainter old) => true;
}

// ─── Wall Item Painter ───
class _WallItemPainter extends CustomPainter {
  final List<WallItem> items;
  final AppTheme theme;
  final Offset origin;
  final double scale;
  final String? selectedId;
  final bool isDragging;

  _WallItemPainter({
    required this.items,
    required this.theme,
    required this.origin,
    required this.scale,
    this.selectedId,
    this.isDragging = false,
  });

  Offset _w2s(double x, double y) =>
      Offset(origin.dx + x * scale, origin.dy - y * scale);

  @override
  void paint(Canvas canvas, Size size) {
    for (final item in items.where((i) => i.isPlaced)) {
      final topLeft = _w2s(item.x, item.y + item.height);
      final bottomRight = _w2s(item.x + item.width, item.y);
      final rect = Rect.fromLTRB(
          topLeft.dx, topLeft.dy, bottomRight.dx, bottomRight.dy);

      // Fill
      final fillColor = item.color.withValues(alpha: 0.6);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(3)),
        Paint()..color = fillColor,
      );

      // Border
      final isSelected = item.id == selectedId;
      final borderColor = item.hasCollision
          ? Colors.red
          : isSelected
              ? theme.accent
              : item.color.withValues(alpha: 0.8);
      final borderWidth = isSelected ? 2.5 : 1.5;
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(3)),
        Paint()
          ..color = borderColor
          ..strokeWidth = borderWidth
          ..style = PaintingStyle.stroke,
      );

      // Collision diagonal lines
      if (item.hasCollision) {
        canvas.save();
        canvas.clipRect(rect);
        final diagPaint = Paint()
          ..color = Colors.red.withValues(alpha: 0.15)
          ..strokeWidth = 1.0;
        for (double d = -rect.height; d < rect.width; d += 8) {
          canvas.drawLine(
            Offset(rect.left + d, rect.bottom),
            Offset(rect.left + d + rect.height, rect.top),
            diagPaint,
          );
        }
        canvas.restore();
      }

      // Name label
      final label = TextPainter(
        text: TextSpan(
          text: item.name,
          style: TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 2,
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '..',
      )..layout(maxWidth: rect.width - 4);

      if (rect.width > 20 && rect.height > 16) {
        label.paint(
          canvas,
          Offset(
            rect.center.dx - label.width / 2,
            rect.center.dy - label.height / 2,
          ),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WallItemPainter old) => true;
}

// ─── Fine-tune panel for wall mode (X/Y only) ───
class _WallFineTunePanel extends StatelessWidget {
  final WallItem item;
  final AppTheme theme;
  final void Function(double dx, double dy) onNudge;

  const _WallFineTunePanel({
    required this.item,
    required this.theme,
    required this.onNudge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.headerBg.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: theme.textSecondary.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildAxisRow('X', const Color(0xFFEF5350), () => onNudge(-0.1, 0),
              () => onNudge(0.1, 0), item.x),
          const SizedBox(height: 4),
          _buildAxisRow('Y', const Color(0xFF66BB6A), () => onNudge(0, -0.1),
              () => onNudge(0, 0.1), item.y),
        ],
      ),
    );
  }

  Widget _buildAxisRow(String label, Color color, VoidCallback onMinus,
      VoidCallback onPlus, double value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 14,
          child: Text(label,
              style: TextStyle(
                  color: color, fontSize: 10, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 4),
        _WallNudgeBtn(
            label: '−', theme: theme, onTap: onMinus, color: color),
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
        _WallNudgeBtn(
            label: '+', theme: theme, onTap: onPlus, color: color),
      ],
    );
  }
}

// ─── Repeating nudge button ───
class _WallNudgeBtn extends StatefulWidget {
  final String label;
  final AppTheme theme;
  final VoidCallback onTap;
  final Color color;

  const _WallNudgeBtn({
    required this.label,
    required this.theme,
    required this.onTap,
    required this.color,
  });

  @override
  State<_WallNudgeBtn> createState() => _WallNudgeBtnState();
}

class _WallNudgeBtnState extends State<_WallNudgeBtn> {
  bool _holding = false;

  void _startHold() {
    _holding = true;
    widget.onTap();
    _repeatLoop();
  }

  Future<void> _repeatLoop() async {
    await Future.delayed(const Duration(milliseconds: 300));
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
    return GestureDetector(
      onTapDown: (_) => _startHold(),
      onTapUp: (_) => _stopHold(),
      onTapCancel: _stopHold,
      child: Container(
        width: 36,
        height: 36,
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
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Undo/Redo button ───
class _WallUndoRedoBtn extends StatelessWidget {
  final IconData icon;
  final AppTheme theme;
  final VoidCallback onTap;
  final bool enabled;

  const _WallUndoRedoBtn({
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
            border:
                Border.all(color: theme.textSecondary.withValues(alpha: 0.3)),
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

// ─── Item info panel ───
class _WallItemInfoPanel extends StatefulWidget {
  final WallItem item;
  final AppTheme theme;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<Color> onColorChanged;

  const _WallItemInfoPanel({
    required this.item,
    required this.theme,
    required this.onNameChanged,
    required this.onColorChanged,
  });

  @override
  State<_WallItemInfoPanel> createState() => _WallItemInfoPanelState();
}

class _WallItemInfoPanelState extends State<_WallItemInfoPanel> {
  late TextEditingController _ctrl;
  bool _showColorPicker = false;

  static const _colors = [
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
    Color(0xFF34495E),
    Color(0xFF95A5A6),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.item.name);
  }

  @override
  void didUpdateWidget(covariant _WallItemInfoPanel old) {
    super.didUpdateWidget(old);
    if (old.item.id != widget.item.id) {
      _ctrl.text = widget.item.name;
      _showColorPicker = false;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: widget.theme.headerBg.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: widget.theme.textSecondary.withValues(alpha: 0.15)),
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
          Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _showColorPicker = !_showColorPicker),
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: widget.item.color,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white24),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  maxLength: 10,
                  style: TextStyle(
                    color: widget.theme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 4),
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(
                          color: widget.theme.textSecondary
                              .withValues(alpha: 0.2)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(
                          color: widget.theme.textSecondary
                              .withValues(alpha: 0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide:
                          BorderSide(color: widget.theme.accent, width: 1.5),
                    ),
                  ),
                  onChanged: widget.onNameChanged,
                ),
              ),
            ],
          ),
          if (_showColorPicker) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: _colors.map((c) {
                final selected = c.toARGB32() == widget.item.color.toARGB32();
                return GestureDetector(
                  onTap: () => widget.onColorChanged(c),
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: c,
                      borderRadius: BorderRadius.circular(6),
                      border: selected
                          ? Border.all(color: Colors.white, width: 2)
                          : Border.all(color: Colors.white24),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
