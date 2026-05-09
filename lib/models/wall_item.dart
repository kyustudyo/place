import 'dart:ui';

class WallItem {
  final String id;
  final String name;
  final double x;
  final double y;
  final double width;
  final double height;
  final Color color;
  final bool isPlaced;
  final bool hasCollision;

  const WallItem({
    required this.id,
    required this.name,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.color,
    this.isPlaced = false,
    this.hasCollision = false,
  });

  WallItem copyWith({
    double? x,
    double? y,
    double? width,
    double? height,
    String? name,
    Color? color,
    bool? isPlaced,
    bool? hasCollision,
  }) {
    return WallItem(
      id: id,
      name: name ?? this.name,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      color: color ?? this.color,
      isPlaced: isPlaced ?? this.isPlaced,
      hasCollision: hasCollision ?? this.hasCollision,
    );
  }

  factory WallItem.fromJson(Map<String, dynamic> json, Color color) {
    final pos = json['position'] as Map<String, dynamic>?;
    final size = json['size'] as Map<String, dynamic>;
    return WallItem(
      id: json['id'] as String,
      name: json['name'] as String? ?? json['id'] as String,
      x: (pos?['x'] as num?)?.toDouble() ?? 0,
      y: (pos?['y'] as num?)?.toDouble() ?? 0,
      width: (size['width'] as num).toDouble(),
      height: (size['height'] as num).toDouble(),
      color: color,
      isPlaced: pos != null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'position': {'x': x, 'y': y},
        'size': {'width': width, 'height': height},
      };
}
