import 'furniture.dart';

class PlacementResult {
  final String id;
  final Vec3 position;
  final int rotation;
  final Vec3 size;

  const PlacementResult({
    required this.id,
    required this.position,
    required this.rotation,
    required this.size,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'position': position.toJson(),
        'rotation': rotation,
        'size': size.toJson(),
      };
}
