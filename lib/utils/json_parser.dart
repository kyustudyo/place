import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/room.dart';
import '../models/furniture.dart';
import '../models/placement.dart';

const _furnitureColors = [
  Color(0xFF5B8DEF), // blue
  Color(0xFF5BCA8A), // green
  Color(0xFFE8A838), // amber
  Color(0xFFEF5B7B), // pink
  Color(0xFF9B59B6), // purple
  Color(0xFF1ABC9C), // teal
  Color(0xFFE67E22), // orange
  Color(0xFF3498DB), // sky
  Color(0xFFE74C3C), // red
  Color(0xFF2ECC71), // emerald
];

class JsonParser {
  /// Parse furniture_sizes.json
  static ({Room room, List<Furniture> furniture}) parseInput(String jsonStr) {
    final data = json.decode(jsonStr) as Map<String, dynamic>;
    final room = Room.fromJson(data['room'] as Map<String, dynamic>);
    final furnitureList = (data['furniture'] as List)
        .asMap()
        .entries
        .map((e) => Furniture.fromJson(
              e.value as Map<String, dynamic>,
              _furnitureColors[e.key % _furnitureColors.length],
            ))
        .toList();

    return (room: room, furniture: furnitureList);
  }

  /// Generate placement_result.json
  static String generateOutput(List<Furniture> items) {
    final placements = items
        .where((f) => f.isPlaced)
        .map((f) => PlacementResult(
              id: f.id,
              position: f.position,
              rotation: f.rotation,
            ).toJson())
        .toList();

    return const JsonEncoder.withIndent('  ')
        .convert({'placements': placements});
  }
}
