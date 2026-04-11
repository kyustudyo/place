import '../models/furniture.dart';
import '../models/room.dart';

class CollisionDetector {
  /// Check if two furniture items overlap on the floor plane
  static bool checkOverlap(Furniture a, Furniture b) {
    final aMinX = a.position.x;
    final aMaxX = a.position.x + a.effectiveWidth;
    final aMinZ = a.position.z;
    final aMaxZ = a.position.z + a.effectiveDepth;

    final bMinX = b.position.x;
    final bMaxX = b.position.x + b.effectiveWidth;
    final bMinZ = b.position.z;
    final bMaxZ = b.position.z + b.effectiveDepth;

    return aMinX < bMaxX && aMaxX > bMinX && aMinZ < bMaxZ && aMaxZ > bMinZ;
  }

  /// Check if furniture is within room bounds
  static bool isInBounds(Furniture f, Room room) {
    return f.position.x >= 0 &&
        f.position.z >= 0 &&
        f.position.x + f.effectiveWidth <= room.width &&
        f.position.z + f.effectiveDepth <= room.depth;
  }

  /// Update collision state for all furniture
  static List<Furniture> updateCollisions(
      List<Furniture> items, Room room) {
    final placed = items.where((f) => f.isPlaced).toList();
    final result = <Furniture>[];

    for (final item in items) {
      if (!item.isPlaced) {
        result.add(item.copyWith(hasCollision: false));
        continue;
      }

      bool collision = !isInBounds(item, room);
      if (!collision) {
        for (final other in placed) {
          if (other.id != item.id && checkOverlap(item, other)) {
            collision = true;
            break;
          }
        }
      }
      result.add(item.copyWith(hasCollision: collision));
    }

    return result;
  }
}
