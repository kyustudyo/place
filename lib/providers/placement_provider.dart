import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/furniture.dart';
import '../utils/collision.dart';
import '../utils/json_parser.dart';
import '../models/room.dart';

class PlacementState {
  final Room? room;
  final List<Furniture> furniture;
  final String? selectedId;
  final String? error;

  const PlacementState({
    this.room,
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
  @override
  PlacementState build() => const PlacementState();

  void loadJson(String jsonStr) {
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

  void placeFurniture(String id, double x, double z) {
    if (state.room == null) return;
    final tileSize = state.room!.tileSize;
    final snappedX = (x / tileSize).round() * tileSize;
    final snappedZ = (z / tileSize).round() * tileSize;

    final updated = state.furniture.map((f) {
      if (f.id == id) {
        return f.copyWith(
          position: Vec3(x: snappedX, y: f.position.y, z: snappedZ),
          isPlaced: true,
        );
      }
      return f;
    }).toList();

    final checked = CollisionDetector.updateCollisions(updated, state.room!);
    state = state.copyWith(furniture: checked);
  }

  void rotateFurniture(String id) {
    if (state.room == null) return;
    final updated = state.furniture.map((f) {
      if (f.id == id) {
        return f.copyWith(rotation: (f.rotation + 90) % 360);
      }
      return f;
    }).toList();

    final checked = CollisionDetector.updateCollisions(updated, state.room!);
    state = state.copyWith(furniture: checked);
  }

  void unplaceFurniture(String id) {
    if (state.room == null) return;
    final updated = state.furniture.map((f) {
      if (f.id == id) {
        return f.copyWith(
          position: const Vec3(x: 0, y: 0, z: 0),
          isPlaced: false,
          hasCollision: false,
        );
      }
      return f;
    }).toList();

    final checked = CollisionDetector.updateCollisions(updated, state.room!);
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
