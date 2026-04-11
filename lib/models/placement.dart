import 'furniture.dart';

class PlacementResult {
  final String id;
  final Vec3 position;
  final int rotation;

  const PlacementResult({
    required this.id,
    required this.position,
    required this.rotation,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'position': position.toJson(),
        'rotation': rotation,
      };
}
