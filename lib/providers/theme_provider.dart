import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_theme.dart';

class ThemeNotifier extends Notifier<int> {
  @override
  int build() => defaultThemeIndex;

  void setTheme(int index) {
    if (index >= 0 && index < appThemes.length) {
      state = index;
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
