import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/placement_screen.dart';

void main() {
  runApp(const ProviderScope(child: PlaceApp()));
}

class PlaceApp extends StatelessWidget {
  const PlaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Place — 가구 배치 도구',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F0F23),
        colorSchemeSeed: const Color(0xFF5B8DEF),
      ),
      home: const PlacementScreen(),
    );
  }
}
