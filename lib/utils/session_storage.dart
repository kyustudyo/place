import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/json_parser.dart';
import '../models/room.dart';
import '../models/furniture.dart';
import '../providers/theme_provider.dart';

const _key = 'place_session';
const _roomsKey = 'place_saved_rooms';

class SessionStorage {
  static Future<void> save(Room room, List<Furniture> furniture, {AxisMapping? axisMapping}) async {
    final prefs = await SharedPreferences.getInstance();
    final json = JsonParser.generateFullJson(room, furniture, axisMapping: axisMapping);
    await prefs.setString(_key, json);
  }

  static Future<String?> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  static Future<bool> hasSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_key);
  }

  /// Get all saved room names (ordered by save time)
  static Future<List<String>> getSavedRoomNames() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_roomsKey);
    if (raw == null) return [];
    final map = json.decode(raw) as Map<String, dynamic>;
    // Sort by saved timestamp (newest first)
    final entries = map.entries.toList()
      ..sort((a, b) {
        final aTime = (a.value as Map<String, dynamic>)['savedAt'] as int? ?? 0;
        final bTime = (b.value as Map<String, dynamic>)['savedAt'] as int? ?? 0;
        return bTime.compareTo(aTime);
      });
    return entries.map((e) => e.key).toList();
  }

  /// Save current room+furniture with a name
  static Future<void> saveRoom(
      String name, Room room, List<Furniture> furniture, {AxisMapping? axisMapping}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_roomsKey);
    final map =
        raw != null ? json.decode(raw) as Map<String, dynamic> : <String, dynamic>{};
    map[name] = {
      'data': JsonParser.generateFullJson(room, furniture, axisMapping: axisMapping),
      'savedAt': DateTime.now().millisecondsSinceEpoch,
    };
    await prefs.setString(_roomsKey, json.encode(map));
  }

  /// Load a saved room by name
  static Future<String?> loadRoom(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_roomsKey);
    if (raw == null) return null;
    final map = json.decode(raw) as Map<String, dynamic>;
    final entry = map[name] as Map<String, dynamic>?;
    return entry?['data'] as String?;
  }

  /// Delete a saved room by name
  static Future<void> deleteRoom(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_roomsKey);
    if (raw == null) return;
    final map = json.decode(raw) as Map<String, dynamic>;
    map.remove(name);
    await prefs.setString(_roomsKey, json.encode(map));
  }
}
