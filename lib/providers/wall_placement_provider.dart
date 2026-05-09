import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/wall.dart';
import '../models/wall_item.dart';
import '../models/room.dart';
import '../utils/wall_collision.dart';

const _defaultBackWall = Wall(type: WallType.back, width: 15.0, height: 4.0);
const _defaultRightWall = Wall(type: WallType.right, width: 15.0, height: 4.0);

const _wallItemColors = [
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
];

class WallPlacementState {
  final WallType currentWall;
  final Map<WallType, Wall> walls;
  final Map<WallType, List<WallItem>> items;
  final String? selectedId;
  final String? error;

  const WallPlacementState({
    this.currentWall = WallType.back,
    this.walls = const {
      WallType.back: _defaultBackWall,
      WallType.right: _defaultRightWall,
    },
    this.items = const {
      WallType.back: [],
      WallType.right: [],
    },
    this.selectedId,
    this.error,
  });

  Wall get currentWallData => walls[currentWall]!;
  List<WallItem> get currentItems => items[currentWall] ?? [];

  int get placedCount => currentItems.where((i) => i.isPlaced).length;
  int get collisionCount => currentItems.where((i) => i.hasCollision).length;

  WallItem? get selectedItem =>
      selectedId != null
          ? currentItems.cast<WallItem?>().firstWhere(
                (i) => i?.id == selectedId,
                orElse: () => null,
              )
          : null;

  WallPlacementState copyWith({
    WallType? currentWall,
    Map<WallType, Wall>? walls,
    Map<WallType, List<WallItem>>? items,
    String? selectedId,
    String? error,
    bool clearSelected = false,
    bool clearError = false,
  }) {
    return WallPlacementState(
      currentWall: currentWall ?? this.currentWall,
      walls: walls ?? this.walls,
      items: items ?? this.items,
      selectedId: clearSelected ? null : (selectedId ?? this.selectedId),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class WallPlacementNotifier extends Notifier<WallPlacementState> {
  final List<WallPlacementState> _undoStack = [];
  final List<WallPlacementState> _redoStack = [];

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  void _saveUndo() {
    _undoStack.add(state);
    _redoStack.clear();
    if (_undoStack.length > 50) _undoStack.removeAt(0);
  }

  void undo() {
    if (!canUndo) return;
    _redoStack.add(state);
    state = _undoStack.removeLast();
  }

  void redo() {
    if (!canRedo) return;
    _undoStack.add(state);
    state = _redoStack.removeLast();
  }

  @override
  WallPlacementState build() {
    return const WallPlacementState();
  }

  void switchWall(WallType type) {
    state = state.copyWith(currentWall: type, clearSelected: true);
  }

  /// Update wall sizes from room dimensions
  void updateFromRoom(Room room) {
    final walls = {
      WallType.back: Wall.fromRoom(
        type: WallType.back,
        roomWidth: room.width,
        roomDepth: room.depth,
        roomHeight: room.height,
      ),
      WallType.right: Wall.fromRoom(
        type: WallType.right,
        roomWidth: room.width,
        roomDepth: room.depth,
        roomHeight: room.height,
      ),
    };

    // Re-check collisions for both walls
    final updatedItems = <WallType, List<WallItem>>{};
    for (final type in WallType.values) {
      final wall = walls[type]!;
      final itemList = state.items[type] ?? [];
      updatedItems[type] =
          WallCollisionDetector.updateCollisions(itemList, wall);
    }

    state = state.copyWith(walls: walls, items: updatedItems);
  }

  int _nextNumber = 1;

  WallItem addItem({
    required String name,
    required double width,
    required double height,
  }) {
    _saveUndo();
    final wall = state.currentWallData;
    final currentList = state.currentItems;
    final index = currentList.length;
    final id = 'wall_${DateTime.now().millisecondsSinceEpoch}';
    final color = _wallItemColors[index % _wallItemColors.length];

    final displayName = name.isEmpty ? '사물${_nextNumber++}' : name;

    // Place at center of wall
    final posX = (wall.width / 2 - width / 2);
    final posY = 0.0; // Default to floor
    final snappedX =
        (posX / wall.tileSize).round() * wall.tileSize;

    final item = WallItem(
      id: id,
      name: displayName,
      x: snappedX,
      y: posY,
      width: width,
      height: height,
      color: color,
      isPlaced: true,
    );

    final updated = [...currentList, item];
    final checked = WallCollisionDetector.updateCollisions(updated, wall);
    final newItems = Map<WallType, List<WallItem>>.from(state.items);
    newItems[state.currentWall] = checked;

    state = state.copyWith(items: newItems, selectedId: id);
    return item;
  }

  void updateItemSize(String id, double width, double height) {
    final wall = state.currentWallData;
    final updated = state.currentItems.map((i) {
      if (i.id == id) {
        return i.copyWith(width: width, height: height);
      }
      return i;
    }).toList();

    final checked = WallCollisionDetector.updateCollisions(updated, wall);
    final newItems = Map<WallType, List<WallItem>>.from(state.items);
    newItems[state.currentWall] = checked;
    state = state.copyWith(items: newItems);
  }

  void updateItemName(String id, String name) {
    final updated = state.currentItems.map((i) {
      if (i.id == id) return i.copyWith(name: name);
      return i;
    }).toList();

    final newItems = Map<WallType, List<WallItem>>.from(state.items);
    newItems[state.currentWall] = updated;
    state = state.copyWith(items: newItems);
  }

  void updateItemColor(String id, Color color) {
    final updated = state.currentItems.map((i) {
      if (i.id == id) return i.copyWith(color: color);
      return i;
    }).toList();

    final newItems = Map<WallType, List<WallItem>>.from(state.items);
    newItems[state.currentWall] = updated;
    state = state.copyWith(items: newItems);
  }

  void selectItem(String? id) {
    state = state.copyWith(selectedId: id, clearSelected: id == null);
  }

  /// Move item — raw position, no snap
  void placeItem(String id, double x, double y) {
    final wall = state.currentWallData;
    final margin = wall.tileSize * 5;

    final clampedX = x.clamp(-margin, wall.width + margin);
    final clampedY = y.clamp(-margin, wall.height + margin);

    final updated = state.currentItems.map((i) {
      if (i.id == id) {
        return i.copyWith(x: clampedX, y: clampedY, isPlaced: true);
      }
      return i;
    }).toList();

    final checked = WallCollisionDetector.updateCollisions(updated, wall);
    final newItems = Map<WallType, List<WallItem>>.from(state.items);
    newItems[state.currentWall] = checked;
    state = state.copyWith(items: newItems);
  }

  /// Snap to grid + wall edges
  void snapItem(String id) {
    _saveUndo();
    final wall = state.currentWallData;
    final ts = wall.tileSize;

    final updated = state.currentItems.map((i) {
      if (i.id == id && i.isPlaced) {
        final sx = _smartSnap(i.x, i.width, wall.width, ts);
        final sy = _smartSnap(i.y, i.height, wall.height, ts);
        return i.copyWith(x: sx, y: sy);
      }
      return i;
    }).toList();

    final checked = WallCollisionDetector.updateCollisions(updated, wall);
    final newItems = Map<WallType, List<WallItem>>.from(state.items);
    newItems[state.currentWall] = checked;
    state = state.copyWith(items: newItems);
  }

  double _smartSnap(
      double pos, double itemSize, double wallSize, double tileSize) {
    final wallThreshold = tileSize * 0.6;

    // Wall end snap
    final endWall = wallSize - itemSize;
    if ((pos - endWall).abs() <= wallThreshold && endWall >= 0) return endWall;

    // Wall start snap (position = 0)
    if (pos.abs() <= wallThreshold) return 0.0;

    // General grid snap
    return (pos / tileSize).round() * tileSize;
  }

  /// Nudge position by delta (for fine-tune +/- buttons)
  void nudgePosition(String id, double dx, double dy) {
    _saveUndo();
    final wall = state.currentWallData;

    final updated = state.currentItems.map((i) {
      if (i.id == id) {
        final newX = (i.x + dx);
        final newY = (i.y + dy);
        final roundedX = (newX * 10).round() / 10;
        final roundedY = (newY * 10).round() / 10;
        return i.copyWith(x: roundedX, y: roundedY);
      }
      return i;
    }).toList();

    final checked = WallCollisionDetector.updateCollisions(updated, wall);
    final newItems = Map<WallType, List<WallItem>>.from(state.items);
    newItems[state.currentWall] = checked;
    state = state.copyWith(items: newItems);
  }

  void duplicateItem(String id) {
    _saveUndo();
    final source = state.currentItems.firstWhere((i) => i.id == id);
    final newId = 'wall_${DateTime.now().millisecondsSinceEpoch}';
    final index = state.currentItems.length;
    final color = _wallItemColors[index % _wallItemColors.length];

    final numRegex = RegExp(r'^(.+?)(\d+)$');
    final match = numRegex.firstMatch(source.name);
    final baseName = match != null ? match.group(1)! : source.name;
    int maxNum = 0;
    for (final i in state.currentItems) {
      final m = numRegex.firstMatch(i.name);
      if (m != null && m.group(1) == baseName) {
        final n = int.tryParse(m.group(2)!) ?? 0;
        if (n > maxNum) maxNum = n;
      }
    }
    final copyName = '$baseName${maxNum + 1}';

    final ts = state.currentWallData.tileSize;
    final copy = WallItem(
      id: newId,
      name: copyName,
      x: source.x + ts,
      y: source.y,
      width: source.width,
      height: source.height,
      color: color,
      isPlaced: true,
    );

    final updated = [...state.currentItems, copy];
    final wall = state.currentWallData;
    final checked = WallCollisionDetector.updateCollisions(updated, wall);
    final newItems = Map<WallType, List<WallItem>>.from(state.items);
    newItems[state.currentWall] = checked;
    state = state.copyWith(items: newItems, selectedId: newId);
  }

  void removeItem(String id) {
    _saveUndo();
    final updated = state.currentItems.where((i) => i.id != id).toList();
    final wall = state.currentWallData;
    final checked = WallCollisionDetector.updateCollisions(updated, wall);
    final newItems = Map<WallType, List<WallItem>>.from(state.items);
    newItems[state.currentWall] = checked;
    state = state.copyWith(items: newItems, clearSelected: true);
  }

  /// Load wall items for a specific wall type
  void loadWallItems(WallType type, List<WallItem> wallItems) {
    _saveUndo();
    final wall = state.walls[type]!;
    final checked =
        WallCollisionDetector.updateCollisions(wallItems, wall);
    final newItems = Map<WallType, List<WallItem>>.from(state.items);
    newItems[type] = checked;
    state = state.copyWith(items: newItems);
  }

  void reset() {
    _undoStack.clear();
    _redoStack.clear();
    _nextNumber = 1;
    state = const WallPlacementState();
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final wallPlacementProvider =
    NotifierProvider<WallPlacementNotifier, WallPlacementState>(
  WallPlacementNotifier.new,
);
