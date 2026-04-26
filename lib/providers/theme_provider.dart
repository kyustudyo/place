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

/// X-Z axis swap
class AxisSwapNotifier extends Notifier<bool> {
  @override
  bool build() => false; // false = default (X→오른쪽아래, Z→왼쪽아래)

  void toggle() => state = !state;
}

final axisSwapProvider = NotifierProvider<AxisSwapNotifier, bool>(
  AxisSwapNotifier.new,
);

/// Guide line color
class GuideColorNotifier extends Notifier<Color> {
  @override
  Color build() => const Color(0xFFE74C3C); // red default — visible on most walls

  void set(Color c) => state = c;
}

final guideColorProvider = NotifierProvider<GuideColorNotifier, Color>(
  GuideColorNotifier.new,
);

/// Guide line opacity (0.0 ~ 1.0)
class GuideOpacityNotifier extends Notifier<double> {
  @override
  double build() => 0.5; // 50% default

  void set(double v) => state = v.clamp(0.0, 1.0);
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
