import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/placement_screen.dart';

const isScreenshotMode = bool.fromEnvironment('SCREENSHOT_MODE');

void main() {
  runApp(const ProviderScope(child: PlaceApp()));
}

class PlaceApp extends StatelessWidget {
  const PlaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Place — 사물 배치 도구',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFFE8A838),
      ),
      home: const PlacementScreen(),
    );
  }
}
