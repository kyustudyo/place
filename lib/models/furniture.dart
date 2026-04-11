import 'dart:ui';

class Vec3 {
  final double x;
  final double y;
  final double z;

  const Vec3({required this.x, required this.y, required this.z});

  factory Vec3.fromJson(Map<String, dynamic> json) {
    return Vec3(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      z: (json['z'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {'x': x, 'y': y, 'z': z};
}

class Furniture {
  final String id;
  final String name;
  final Vec3 size;
  Vec3 position;
  int rotation; // 0, 90, 180, 270
  final Color color;
  bool isPlaced;
  bool hasCollision;

  Furniture({
    required this.id,
    required this.name,
    required this.size,
    required this.position,
    required this.rotation,
    required this.color,
    this.isPlaced = false,
    this.hasCollision = false,
  });

  /// Effective footprint considering rotation
  double get effectiveWidth =>
      (rotation == 90 || rotation == 270) ? size.z : size.x;
  double get effectiveDepth =>
      (rotation == 90 || rotation == 270) ? size.x : size.z;

  factory Furniture.fromJson(Map<String, dynamic> json, Color color) {
    return Furniture(
      id: json['id'] as String,
      name: json['name'] as String,
      size: Vec3.fromJson(json['size'] as Map<String, dynamic>),
      position: json['position'] != null
          ? Vec3.fromJson(json['position'] as Map<String, dynamic>)
          : const Vec3(x: 0, y: 0, z: 0),
      rotation: (json['rotation'] as num?)?.toInt() ?? 0,
      color: color,
      isPlaced: json['position'] != null,
    );
  }

  Furniture copyWith({
    Vec3? position,
    int? rotation,
    bool? isPlaced,
    bool? hasCollision,
  }) {
    return Furniture(
      id: id,
      name: name,
      size: size,
      position: position ?? this.position,
      rotation: rotation ?? this.rotation,
      color: color,
      isPlaced: isPlaced ?? this.isPlaced,
      hasCollision: hasCollision ?? this.hasCollision,
    );
  }
}
