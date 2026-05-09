import '../models/wall_item.dart';
import '../models/wall.dart';

class WallCollisionDetector {
  static bool checkOverlap(WallItem a, WallItem b) {
    return a.x < b.x + b.width &&
        a.x + a.width > b.x &&
        a.y < b.y + b.height &&
        a.y + a.height > b.y;
  }

  static bool isInBounds(WallItem item, Wall wall) {
    return item.x >= 0 &&
        item.y >= 0 &&
        item.x + item.width <= wall.width &&
        item.y + item.height <= wall.height;
  }

  static List<WallItem> updateCollisions(List<WallItem> items, Wall wall) {
    final placed = items.where((i) => i.isPlaced).toList();
    final result = <WallItem>[];

    for (final item in items) {
      if (!item.isPlaced) {
        result.add(item.copyWith(hasCollision: false));
        continue;
      }

      bool collision = !isInBounds(item, wall);
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
