class Room {
  final double width;
  final double height;
  final double depth;
  final double tileSize;
  final int gridSize;

  const Room({
    required this.width,
    required this.height,
    required this.depth,
    required this.tileSize,
    required this.gridSize,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      depth: (json['depth'] as num).toDouble(),
      tileSize: (json['tileSize'] as num).toDouble(),
      gridSize: (json['gridSize'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'width': width,
        'height': height,
        'depth': depth,
        'tileSize': tileSize,
        'gridSize': gridSize,
      };
}
