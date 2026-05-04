import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/room.dart';
import '../models/furniture.dart';
import '../models/placement.dart';
import '../providers/theme_provider.dart';

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
  /// `room` key is optional — if omitted, returns null and caller keeps current room.
  /// `axisMapping` key is optional — if present, returns the saved mapping.
  static ({Room? room, List<Furniture> furniture, AxisMapping? axisMapping}) parseInput(String jsonStr) {
    final data = json.decode(jsonStr) as Map<String, dynamic>;
    final roomJson = data['room'] as Map<String, dynamic>?;
    final room = roomJson != null ? Room.fromJson(roomJson) : null;
    final furnitureList = (data['furniture'] as List)
        .asMap()
        .entries
        .map((e) => Furniture.fromJson(
              e.value as Map<String, dynamic>,
              _furnitureColors[e.key % _furnitureColors.length],
            ))
        .toList();

    // Parse axis mapping if present
    final axisJson = data['axisMapping'] as Map<String, dynamic>?;
    final axisMapping = axisJson != null ? _parseAxisMapping(axisJson) : null;

    return (room: room, furniture: furnitureList, axisMapping: axisMapping);
  }

  static AxisMapping _parseAxisMapping(Map<String, dynamic> j) {
    WorldAxis parseAxis(String? s) => switch (s) {
      'y' => WorldAxis.y,
      'z' => WorldAxis.z,
      _ => WorldAxis.x,
    };
    return AxisMapping(
      rightDown: parseAxis(j['rightDown'] as String?),
      leftDown: parseAxis(j['leftDown'] as String?),
      up: parseAxis(j['up'] as String?),
      flipRD: j['flipRD'] as bool? ?? false,
      flipLD: j['flipLD'] as bool? ?? false,
      flipUp: j['flipUp'] as bool? ?? false,
    );
  }

  static Map<String, dynamic> _axisToJson(AxisMapping m) {
    String name(WorldAxis a) => switch (a) {
      WorldAxis.x => 'x',
      WorldAxis.y => 'y',
      WorldAxis.z => 'z',
    };
    return {
      'rightDown': name(m.rightDown),
      'leftDown': name(m.leftDown),
      'up': name(m.up),
      'flipRD': m.flipRD,
      'flipLD': m.flipLD,
      'flipUp': m.flipUp,
    };
  }

  /// Remap internal Vec3 to export coordinates based on axis mapping
  /// Internal: x=rightDown, z=leftDown, y=up
  /// Output: each value mapped to the world axis label assigned to that direction
  static Vec3 _remapForExport(Vec3 v, AxisMapping m, {bool applyFlip = false}) {
    double outX = 0, outY = 0, outZ = 0;

    final rdVal = v.x * (applyFlip && m.flipRD ? -1 : 1);
    switch (m.rightDown) {
      case WorldAxis.x: outX = rdVal;
      case WorldAxis.y: outY = rdVal;
      case WorldAxis.z: outZ = rdVal;
    }

    final ldVal = v.z * (applyFlip && m.flipLD ? -1 : 1);
    switch (m.leftDown) {
      case WorldAxis.x: outX = ldVal;
      case WorldAxis.y: outY = ldVal;
      case WorldAxis.z: outZ = ldVal;
    }

    final upVal = v.y * (applyFlip && m.flipUp ? -1 : 1);
    switch (m.up) {
      case WorldAxis.x: outX = upVal;
      case WorldAxis.y: outY = upVal;
      case WorldAxis.z: outZ = upVal;
    }

    return Vec3(x: outX, y: outY, z: outZ);
  }

  /// Generate placement_result.json with axis mapping applied
  /// Position is exported as bottom center of the furniture
  static String generateOutput(List<Furniture> items, {AxisMapping mapping = const AxisMapping()}) {
    final placements = items
        .where((f) => f.isPlaced)
        .map((f) {
          // Convert min corner → bottom center
          final bottomCenter = Vec3(
            x: f.position.x + f.size.x / 2,
            y: f.position.y,
            z: f.position.z + f.size.z / 2,
          );
          final pos = _remapForExport(bottomCenter, mapping, applyFlip: true);
          final size = _remapForExport(f.size, mapping);
          return PlacementResult(
            id: f.id,
            position: pos,
            rotation: f.rotation,
            size: size,
          ).toJson();
        })
        .toList();

    return const JsonEncoder.withIndent('  ')
        .convert({'placements': placements});
  }

  /// Generate full JSON (room + furniture + axisMapping) for saving session
  static String generateFullJson(Room room, List<Furniture> items, {AxisMapping? axisMapping}) {
    final furnitureList = items.map((f) => {
          'id': f.id,
          'name': f.name,
          'size': f.size.toJson(),
          'position': f.position.toJson(),
          'rotation': f.rotation,
        }).toList();

    final map = <String, dynamic>{
      'room': room.toJson(),
      'furniture': furnitureList,
    };
    if (axisMapping != null) {
      map['axisMapping'] = _axisToJson(axisMapping);
    }

    return const JsonEncoder.withIndent('  ').convert(map);
  }
}
