import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_theme.dart';

const _kThemeKey = 'theme_index';

class ThemeNotifier extends Notifier<int> {
  @override
  int build() {
    _load();
    return defaultThemeIndex;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt(_kThemeKey);
    if (saved != null && saved >= 0 && saved < appThemes.length) {
      state = saved;
    }
  }

  void setTheme(int index) {
    if (index >= 0 && index < appThemes.length) {
      state = index;
      SharedPreferences.getInstance().then((p) => p.setInt(_kThemeKey, index));
    }
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, int>(
  ThemeNotifier.new,
);

/// Convenience provider for the current AppTheme
final currentThemeProvider = Provider<AppTheme>((ref) {
  final index = ref.watch(themeProvider);
  return appThemes[index];
});

/// World axis enum for axis mapping
enum WorldAxis { x, y, z }

/// Axis mapping — which world axis maps to each visual direction
class AxisMapping {
  /// Right-down visual direction (southeast on isometric floor)
  final WorldAxis rightDown;
  /// Left-down visual direction (southwest on isometric floor)
  final WorldAxis leftDown;
  /// Up visual direction (vertical)
  final WorldAxis up;
  /// Whether each direction's + is flipped (reversed)
  final bool flipRD;
  final bool flipLD;
  final bool flipUp;

  const AxisMapping({
    this.rightDown = WorldAxis.x,
    this.leftDown = WorldAxis.z,
    this.up = WorldAxis.y,
    this.flipRD = false,
    this.flipLD = false,
    this.flipUp = false,
  });

  /// Whether this is a valid mapping (each axis used exactly once)
  bool get isValid {
    final used = {rightDown, leftDown, up};
    return used.length == 3;
  }

  /// Get the world axis name string
  static String axisName(WorldAxis axis) => switch (axis) {
    WorldAxis.x => 'X',
    WorldAxis.y => 'Y',
    WorldAxis.z => 'Z',
  };

  AxisMapping copyWith({
    WorldAxis? rightDown,
    WorldAxis? leftDown,
    WorldAxis? up,
    bool? flipRD,
    bool? flipLD,
    bool? flipUp,
  }) {
    return AxisMapping(
      rightDown: rightDown ?? this.rightDown,
      leftDown: leftDown ?? this.leftDown,
      up: up ?? this.up,
      flipRD: flipRD ?? this.flipRD,
      flipLD: flipLD ?? this.flipLD,
      flipUp: flipUp ?? this.flipUp,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AxisMapping &&
      rightDown == other.rightDown &&
      leftDown == other.leftDown &&
      up == other.up &&
      flipRD == other.flipRD &&
      flipLD == other.flipLD &&
      flipUp == other.flipUp;

  @override
  int get hashCode => Object.hash(rightDown, leftDown, up, flipRD, flipLD, flipUp);
}

const _kAxisMappingKey = 'axis_mapping';

/// Axis mapping notifier with persistence
class AxisMappingNotifier extends Notifier<AxisMapping> {
  static const _axisValues = WorldAxis.values;

  @override
  AxisMapping build() {
    _load();
    return const AxisMapping();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kAxisMappingKey);
    if (saved == null) return;
    final parts = saved.split(',');
    if (parts.length != 6) return;
    final rd = int.tryParse(parts[0]);
    final ld = int.tryParse(parts[1]);
    final up = int.tryParse(parts[2]);
    if (rd == null || ld == null || up == null) return;
    if (rd < 0 || rd > 2 || ld < 0 || ld > 2 || up < 0 || up > 2) return;
    final mapping = AxisMapping(
      rightDown: _axisValues[rd],
      leftDown: _axisValues[ld],
      up: _axisValues[up],
      flipRD: parts[3] == '1',
      flipLD: parts[4] == '1',
      flipUp: parts[5] == '1',
    );
    if (mapping.isValid) state = mapping;
  }

  void _save(AxisMapping m) {
    final str = '${m.rightDown.index},${m.leftDown.index},${m.up.index},'
        '${m.flipRD ? 1 : 0},${m.flipLD ? 1 : 0},${m.flipUp ? 1 : 0}';
    SharedPreferences.getInstance().then((p) => p.setString(_kAxisMappingKey, str));
  }

  void set(AxisMapping mapping) {
    if (mapping.isValid) {
      state = mapping;
      _save(mapping);
    }
  }

  void reset() {
    state = const AxisMapping();
    SharedPreferences.getInstance().then((p) => p.remove(_kAxisMappingKey));
  }
}

final axisMappingProvider = NotifierProvider<AxisMappingNotifier, AxisMapping>(
  AxisMappingNotifier.new,
);

const _kGuideColorKey = 'guide_color';
const _kGuideOpacityKey = 'guide_opacity';

/// Guide line color with persistence
class GuideColorNotifier extends Notifier<Color> {
  @override
  Color build() {
    _load();
    return const Color(0xFFE74C3C); // red default
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt(_kGuideColorKey);
    if (saved != null) state = Color(saved);
  }

  void set(Color c) {
    state = c;
    SharedPreferences.getInstance().then((p) => p.setInt(_kGuideColorKey, c.toARGB32()));
  }
}

final guideColorProvider = NotifierProvider<GuideColorNotifier, Color>(
  GuideColorNotifier.new,
);

/// Guide line opacity (0.0 ~ 1.0) with persistence
class GuideOpacityNotifier extends Notifier<double> {
  @override
  double build() {
    _load();
    return 0.5; // 50% default
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getDouble(_kGuideOpacityKey);
    if (saved != null) state = saved.clamp(0.0, 1.0);
  }

  void set(double v) {
    state = v.clamp(0.0, 1.0);
    SharedPreferences.getInstance().then((p) => p.setDouble(_kGuideOpacityKey, v));
  }
}

final guideOpacityProvider = NotifierProvider<GuideOpacityNotifier, double>(
  GuideOpacityNotifier.new,
);

/// Reference image bytes
class ReferenceImageNotifier extends Notifier<Uint8List?> {
  @override
  Uint8List? build() => null;

  void set(Uint8List? bytes) => state = bytes;
  void clear() => state = null;
}

final referenceImageProvider =
    NotifierProvider<ReferenceImageNotifier, Uint8List?>(
  ReferenceImageNotifier.new,
);

final guideColorOptions = <Color>[
  const Color(0xFFE74C3C), // red
  const Color(0xFFE91E63), // pink
  const Color(0xFFFF9800), // orange
  const Color(0xFFFFEB3B), // yellow
  const Color(0xFF4CAF50), // green
  const Color(0xFF00BCD4), // cyan
  const Color(0xFF2196F3), // blue
  const Color(0xFF9C27B0), // purple
  const Color(0xFFFFFFFF), // white
  const Color(0xFF212121), // black
];
