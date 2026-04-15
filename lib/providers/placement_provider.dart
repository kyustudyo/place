import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/furniture.dart';
import '../utils/collision.dart';
import '../utils/json_parser.dart';
import '../models/room.dart';

const _defaultRoom = Room(
  width: 15.0,
  height: 4.0,
  depth: 15.0,
  tileSize: 1.0,
  gridSize: 15,
);

const _furnitureColors = [
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

class PlacementState {
  final Room room;
  final List<Furniture> furniture;
  final String? selectedId;
  final String? error;

  const PlacementState({
    this.room = _defaultRoom,
    this.furniture = const [],
    this.selectedId,
    this.error,
  });

  int get placedCount => furniture.where((f) => f.isPlaced).length;
  int get collisionCount => furniture.where((f) => f.hasCollision).length;
  Furniture? get selectedFurniture =>
      selectedId != null
          ? furniture.cast<Furniture?>().firstWhere(
                (f) => f?.id == selectedId,
                orElse: () => null,
              )
          : null;

  PlacementState copyWith({
    Room? room,
    List<Furniture>? furniture,
    String? selectedId,
    String? error,
    bool clearSelected = false,
    bool clearError = false,
  }) {
    return PlacementState(
      room: room ?? this.room,
      furniture: furniture ?? this.furniture,
      selectedId: clearSelected ? null : (selectedId ?? this.selectedId),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class PlacementNotifier extends Notifier<PlacementState> {
  final List<PlacementState> _undoStack = [];
  final List<PlacementState> _redoStack = [];

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  /// Save current state to undo stack before making changes
  void _saveUndo() {
    _undoStack.add(state);
    _redoStack.clear();
    // Limit stack size
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
  PlacementState build() {
    return const PlacementState(room: _defaultRoom);
  }

  /// Update room dimensions
  void setRoom({
    required double width,
    required double depth,
    required double height,
    required double tileSize,
  }) {
    final gridSize = (width / tileSize).round();
    final room = Room(
      width: width,
      height: height,
      depth: depth,
      tileSize: tileSize,
      gridSize: gridSize,
    );
    // Re-check collisions with new room size
    final checked = CollisionDetector.updateCollisions(state.furniture, room);
    state = state.copyWith(room: room, furniture: checked);
  }

  int _nextNumber = 1;

  /// Add a new furniture piece with given dimensions
  Furniture addFurniture({
    required String name,
    required double x,
    required double y,
    required double z,
  }) {
    _saveUndo();
    final index = state.furniture.length;
    final id = 'item_${DateTime.now().millisecondsSinceEpoch}';
    final color = _furnitureColors[index % _furnitureColors.length];

    // Auto-name: 사물1, 사물2, ...
    final displayName = name.isEmpty ? '사물${_nextNumber++}' : name;

    // Place at center of room
    final posX = (state.room.width / 2 - x / 2);
    final posZ = (state.room.depth / 2 - z / 2);
    final snappedX =
        (posX / state.room.tileSize).round() * state.room.tileSize;
    final snappedZ =
        (posZ / state.room.tileSize).round() * state.room.tileSize;

    final item = Furniture(
      id: id,
      name: displayName,
      size: Vec3(x: x, y: y, z: z),
      position: Vec3(x: snappedX, y: 0.0, z: snappedZ),
      rotation: 0,
      color: color,
      isPlaced: true,
    );

    final updated = [...state.furniture, item];
    final checked = CollisionDetector.updateCollisions(updated, state.room);
    state = state.copyWith(furniture: checked, selectedId: id);
    return item;
  }

  /// Update dimensions of an existing furniture piece
  void updateFurnitureSize(String id, double x, double y, double z) {
    final updated = state.furniture.map((f) {
      if (f.id == id) {
        return Furniture(
          id: f.id,
          name: f.name,
          size: Vec3(x: x, y: y, z: z),
          position: f.position,
          rotation: f.rotation,
          color: f.color,
          isPlaced: f.isPlaced,
        );
      }
      return f;
    }).toList();

    final checked = CollisionDetector.updateCollisions(updated, state.room);
    state = state.copyWith(furniture: checked);
  }

  /// Update name of an existing furniture piece
  void updateFurnitureName(String id, String name) {
    final updated = state.furniture.map((f) {
      if (f.id == id) {
        return Furniture(
          id: f.id,
          name: name,
          size: f.size,
          position: f.position,
          rotation: f.rotation,
          color: f.color,
          isPlaced: f.isPlaced,
        );
      }
      return f;
    }).toList();
    state = state.copyWith(furniture: updated);
  }

  void updateFurnitureColor(String id, Color color) {
    _saveUndo();
    final updated = state.furniture.map((f) {
      if (f.id == id) {
        return Furniture(
          id: f.id,
          name: f.name,
          size: f.size,
          position: f.position,
          rotation: f.rotation,
          color: color,
          isPlaced: f.isPlaced,
        );
      }
      return f;
    }).toList();
    state = state.copyWith(furniture: updated);
  }

  void loadJson(String jsonStr) {
    _saveUndo();
    try {
      final parsed = JsonParser.parseInput(jsonStr);
      final items = parsed.furniture.map((f) {
        if (f.position.x != 0 || f.position.z != 0) {
          return f.copyWith(isPlaced: true);
        }
        return f;
      }).toList();

      final checked = CollisionDetector.updateCollisions(items, parsed.room);
      state = PlacementState(room: parsed.room, furniture: checked);
    } catch (e) {
      state = state.copyWith(error: '잘못된 JSON 형식입니다: $e', clearError: false);
    }
  }

  void selectFurniture(String? id) {
    state = state.copyWith(selectedId: id, clearSelected: id == null);
  }

  /// Move furniture — raw position (no snap), clamped to ±5 tiles
  void placeFurniture(String id, double x, double z) {
    final tileSize = state.room.tileSize;
    final margin = tileSize * 5;

    final clampedX = x.clamp(-margin, state.room.width + margin);
    final clampedZ = z.clamp(-margin, state.room.depth + margin);

    final updated = state.furniture.map((f) {
      if (f.id == id) {
        return f.copyWith(
          position: Vec3(x: clampedX, y: f.position.y, z: clampedZ),
          isPlaced: true,
        );
      }
      return f;
    }).toList();

    final checked = CollisionDetector.updateCollisions(updated, state.room);
    state = state.copyWith(furniture: checked);
  }

  /// Snap furniture to grid + wall edges (call on drag end)
  void snapFurniture(String id) {
    _saveUndo();
    final tileSize = state.room.tileSize;
    final room = state.room;
    final updated = state.furniture.map((f) {
      if (f.id == id && f.isPlaced) {
        final sx = _smartSnap(
            f.position.x, f.effectiveWidth, room.width, tileSize);
        final sz = _smartSnap(
            f.position.z, f.effectiveDepth, room.depth, tileSize);
        return f.copyWith(position: Vec3(x: sx, y: f.position.y, z: sz));
      }
      return f;
    }).toList();

    final checked = CollisionDetector.updateCollisions(updated, state.room);
    state = state.copyWith(furniture: checked);
  }

  /// Smart snap: 1타일 그리드 + 벽 끝맞춤
  double _smartSnap(
      double pos, double itemSize, double roomSize, double tileSize) {
    final wallThreshold = tileSize * 0.6;

    // 벽 끝맞춤: position = roomSize - itemSize
    final endWall = roomSize - itemSize;
    if ((pos - endWall).abs() <= wallThreshold && endWall >= 0) return endWall;

    // 벽 시작맞춤: position = 0
    if (pos.abs() <= wallThreshold) return 0.0;

    // 일반: 1타일 스냅
    return (pos / tileSize).round() * tileSize;
  }

  /// Adjust Y (height) position
  void nudgeHeight(String id, double dy) {
    final updated = state.furniture.map((f) {
      if (f.id == id) {
        final newY = (f.position.y + dy).clamp(0.0, 100.0);
        // Round to 0.1
        final rounded = (newY * 10).round() / 10;
        return f.copyWith(
            position: Vec3(x: f.position.x, y: rounded, z: f.position.z));
      }
      return f;
    }).toList();
    state = state.copyWith(furniture: updated);
  }

  void rotateFurniture(String id) {
    _saveUndo();
    final updated = state.furniture.map((f) {
      if (f.id == id) {
        return f.copyWith(rotation: (f.rotation + 90) % 360);
      }
      return f;
    }).toList();

    final checked = CollisionDetector.updateCollisions(updated, state.room);
    state = state.copyWith(furniture: checked);
  }

  void removeFurniture(String id) {
    _saveUndo();
    final updated = state.furniture.where((f) => f.id != id).toList();
    final checked = CollisionDetector.updateCollisions(updated, state.room);
    state = state.copyWith(furniture: checked, clearSelected: true);
  }

  String exportJson() {
    return JsonParser.generateOutput(state.furniture);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final placementProvider =
    NotifierProvider<PlacementNotifier, PlacementState>(
  PlacementNotifier.new,
);
