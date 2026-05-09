import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/wall.dart';
import '../models/wall_item.dart';

const _wallItemColors = [
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

class WallJsonParser {
  /// Parse wall JSON input
  static ({Wall wall, List<WallItem> items}) parseInput(String jsonStr) {
    final data = json.decode(jsonStr) as Map<String, dynamic>;
    final wallType =
        data['wall'] == 'right' ? WallType.right : WallType.back;
    final wallSize = data['wallSize'] as Map<String, dynamic>;
    final wall = Wall(
      type: wallType,
      width: (wallSize['width'] as num).toDouble(),
      height: (wallSize['height'] as num).toDouble(),
    );

    final itemsList = (data['items'] as List)
        .asMap()
        .entries
        .map((e) {
          final itemJson = e.value as Map<String, dynamic>;
          final color = _wallItemColors[e.key % _wallItemColors.length];
          // Convert negative x to positive internal coordinates
          final pos = itemJson['position'] as Map<String, dynamic>?;
          if (pos != null && pos.containsKey('x')) {
            final xVal = (pos['x'] as num).toDouble();
            if (xVal < 0) pos['x'] = -xVal;
          }
          return WallItem.fromJson(itemJson, color);
        })
        .toList();

    return (wall: wall, items: itemsList);
  }

  /// Generate Unity-format wall JSON
  static String generateOutput(
      WallType type, Wall wall, List<WallItem> items) {
    final placedItems = items
        .where((i) => i.isPlaced)
        .map((i) {
          // Internal positive → export negative
          final exportX = -i.x;
          if (type == WallType.back) {
            return {
              'id': i.id,
              'position': {'x': exportX, 'y': i.y},
              'size': {'width': i.width, 'height': i.height},
            };
          } else {
            return {
              'id': i.id,
              'position': {'z': exportX, 'y': i.y},
              'size': {'width': i.width, 'height': i.height},
            };
          }
        })
        .toList();

    return const JsonEncoder.withIndent('  ').convert({
      'wall': type.name,
      'wallSize': {'width': wall.width, 'height': wall.height},
      'items': placedItems,
    });
  }

  /// Generate JSON for session save (internal coords, positive)
  static Map<String, dynamic> toSessionJson(
      WallType type, List<WallItem> items) {
    return {
      'items': items.map((i) => i.toJson()).toList(),
    };
  }

  /// Parse session JSON
  static List<WallItem> fromSessionJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List? ?? [];
    return itemsList
        .asMap()
        .entries
        .map((e) => WallItem.fromJson(
              e.value as Map<String, dynamic>,
              _wallItemColors[e.key % _wallItemColors.length],
            ))
        .toList();
  }
}
