enum WallType { back, right }

class Wall {
  final WallType type;
  final double width;
  final double height;
  final double tileSize;

  const Wall({
    required this.type,
    required this.width,
    required this.height,
    this.tileSize = 0.5,
  });

  factory Wall.fromRoom({
    required WallType type,
    required double roomWidth,
    required double roomDepth,
    required double roomHeight,
  }) {
    return Wall(
      type: type,
      width: type == WallType.back ? roomWidth : roomDepth,
      height: roomHeight,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'width': width,
        'height': height,
        'tileSize': tileSize,
      };

  factory Wall.fromJson(Map<String, dynamic> json) {
    return Wall(
      type: json['type'] == 'right' ? WallType.right : WallType.back,
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      tileSize: (json['tileSize'] as num?)?.toDouble() ?? 0.5,
    );
  }
}
