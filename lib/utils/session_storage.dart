import 'package:shared_preferences/shared_preferences.dart';
import '../utils/json_parser.dart';
import '../models/room.dart';
import '../models/furniture.dart';

const _key = 'place_session';

class SessionStorage {
  static Future<void> save(Room room, List<Furniture> furniture) async {
    final prefs = await SharedPreferences.getInstance();
    final json = JsonParser.generateFullJson(room, furniture);
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
}
