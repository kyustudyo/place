import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/furniture.dart';
import '../utils/collision.dart';
import '../utils/json_parser.dart';
import '../models/room.dart';
import '../providers/theme_provider.dart';

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

  /// Add a wall-attached furniture piece (door, window, etc.)
  /// [isBackWall] true = z=0 wall (back), false = x=0 wall (left)
  Furniture addWallFurniture({
    required String name,
    required double x,
    required double y,
    required double z,
    required bool isBackWall,
  }) {
    _saveUndo();
    final index = state.furniture.length;
    final id = 'item_${DateTime.now().millisecondsSinceEpoch}';
    final color = _furnitureColors[index % _furnitureColors.length];
    final displayName = name.isEmpty ? '사물${_nextNumber++}' : name;
    final ts = state.room.tileSize;

    final size = Vec3(x: x, y: y, z: z);
    final Vec3 position;

    if (isBackWall) {
      // Back wall (z=0): center along X axis
      final posX = (state.room.width / 2 - x / 2);
      final snappedX = (posX / ts).round() * ts;
      position = Vec3(x: snappedX, y: 0.0, z: 0.0);
    } else {
      // Left wall (x=0): center along Z axis
      final posZ = (state.room.depth / 2 - z / 2);
      final snappedZ = (posZ / ts).round() * ts;
      position = Vec3(x: 0.0, y: 0.0, z: snappedZ);
    }

    final item = Furniture(
      id: id,
      name: displayName,
      size: size,
      position: position,
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

  /// Load JSON and return the saved axis mapping (if any)
  AxisMapping? loadJson(String jsonStr) {
    _saveUndo();
    try {
      final parsed = JsonParser.parseInput(jsonStr);
      final room = parsed.room ?? state.room;
      final items = parsed.furniture.map((f) {
        if (f.position.x != 0 || f.position.z != 0) {
          return f.copyWith(isPlaced: true);
        }
        return f;
      }).toList();

      final checked = CollisionDetector.updateCollisions(items, room);
      state = PlacementState(room: room, furniture: checked);
      return parsed.axisMapping;
    } catch (e) {
      state = state.copyWith(error: '잘못된 JSON 형식입니다: $e', clearError: false);
      return null;
    }
  }

  void selectFurniture(String? id) {
    state = state.copyWith(selectedId: id, clearSelected: id == null);
  }

  /// Move furniture with Y — for wall items dragged along wall
  void placeFurnitureXYZ(String id, double x, double y, double z) {
    final tileSize = state.room.tileSize;
    final margin = tileSize * 5;

    final clampedX = x.clamp(-margin, state.room.width + margin);
    final clampedY = y.clamp(0.0, 100.0);
    final clampedZ = z.clamp(-margin, state.room.depth + margin);

    final room = state.room;
    final updated = state.furniture.map((f) {
      if (f.id == id) {
        final isOnBackWall = f.position.z < 0.01 && f.size.z < 0.2;
        final isOnLeftWall = f.position.x < 0.01 && f.size.x < 0.2;

        double finalX = clampedX;
        double finalY = clampedY;
        double finalZ = clampedZ;

        if (isOnBackWall) {
          finalZ = 0.0;
          // Clamp within back wall bounds
          finalX = finalX.clamp(0.0, room.width - f.effectiveWidth);
          finalY = finalY.clamp(0.0, room.height - f.size.y);
        } else if (isOnLeftWall) {
          finalX = 0.0;
          // Clamp within left wall bounds
          finalZ = finalZ.clamp(0.0, room.depth - f.effectiveDepth);
          finalY = finalY.clamp(0.0, room.height - f.size.y);
        }

        return f.copyWith(
          position: Vec3(x: finalX, y: finalY, z: finalZ),
          isPlaced: true,
        );
      }
      return f;
    }).toList();

    final checked = CollisionDetector.updateCollisions(updated, state.room);
    state = state.copyWith(furniture: checked);
  }

  /// Move furniture — raw position (no snap), clamped to ±5 tiles
  void placeFurniture(String id, double x, double z) {
    final tileSize = state.room.tileSize;
    final margin = tileSize * 5;

    final clampedX = x.clamp(-margin, state.room.width + margin);
    final clampedZ = z.clamp(-margin, state.room.depth + margin);

    final updated = state.furniture.map((f) {
      if (f.id == id) {
        // Wall-attached items: keep on wall during drag
        final isOnBackWall = f.position.z < 0.01 && f.size.z < 0.2;
        final isOnLeftWall = f.position.x < 0.01 && f.size.x < 0.2;

        final finalX = isOnLeftWall ? 0.0 : clampedX;
        final finalZ = isOnBackWall ? 0.0 : clampedZ;

        return f.copyWith(
          position: Vec3(x: finalX, y: f.position.y, z: finalZ),
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
    _saveUndo();
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

  /// Nudge position by delta (for fine-tune panel +/- buttons)
  void nudgePosition(String id, double dx, double dz) {
    _saveUndo();
    final updated = state.furniture.map((f) {
      if (f.id == id) {
        final newX = (f.position.x + dx);
        final newZ = (f.position.z + dz);
        final roundedX = (newX * 10).round() / 10;
        final roundedZ = (newZ * 10).round() / 10;
        return f.copyWith(
          position: Vec3(x: roundedX, y: f.position.y, z: roundedZ),
        );
      }
      return f;
    }).toList();
    final checked = CollisionDetector.updateCollisions(updated, state.room);
    state = state.copyWith(furniture: checked);
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

  void duplicateFurniture(String id) {
    _saveUndo();
    final source = state.furniture.firstWhere((f) => f.id == id);
    final newId = 'item_${DateTime.now().millisecondsSinceEpoch}';
    final index = state.furniture.length;
    final color = _furnitureColors[index % _furnitureColors.length];

    // Strip trailing number from base name, then find next number
    final numRegex = RegExp(r'^(.+?)(\d+)$');
    final match = numRegex.firstMatch(source.name);
    final baseName = match != null ? match.group(1)! : source.name;
    int maxNum = 0;
    for (final f in state.furniture) {
      final m = numRegex.firstMatch(f.name);
      if (m != null && m.group(1) == baseName) {
        final n = int.tryParse(m.group(2)!) ?? 0;
        if (n > maxNum) maxNum = n;
      }
    }
    final copyName = '$baseName${maxNum + 1}';

    // Offset position by 1 tile
    final tile = state.room.tileSize;
    final copy = Furniture(
      id: newId,
      name: copyName,
      size: Vec3(x: source.size.x, y: source.size.y, z: source.size.z),
      position: Vec3(
        x: source.position.x + tile,
        y: source.position.y,
        z: source.position.z + tile,
      ),
      rotation: source.rotation,
      color: color,
      isPlaced: true,
    );

    final updated = [...state.furniture, copy];
    final checked = CollisionDetector.updateCollisions(updated, state.room);
    state = state.copyWith(furniture: checked, selectedId: newId);
  }

  void removeFurniture(String id) {
    _saveUndo();
    final updated = state.furniture.where((f) => f.id != id).toList();
    final checked = CollisionDetector.updateCollisions(updated, state.room);
    state = state.copyWith(furniture: checked, clearSelected: true);
  }

  String exportJson({AxisMapping mapping = const AxisMapping()}) {
    return JsonParser.generateOutput(state.furniture, mapping: mapping);
  }

  void reset() {
    _undoStack.clear();
    _redoStack.clear();
    _nextNumber = 1;
    state = const PlacementState(room: _defaultRoom);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final placementProvider =
    NotifierProvider<PlacementNotifier, PlacementState>(
  PlacementNotifier.new,
);
