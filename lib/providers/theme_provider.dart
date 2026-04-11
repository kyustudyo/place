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
