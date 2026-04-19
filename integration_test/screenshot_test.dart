import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:place/main.dart' as app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('스토어 스크린샷 자동 캡처', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    // ── 1. 공간 크기 설정 다이얼로그 ──
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();
    await binding.takeScreenshot('01_room_setup');

    // 기본값으로 "다음" 탭
    final nextBtn = find.text('다음');
    if (nextBtn.evaluate().isNotEmpty) {
      await tester.tap(nextBtn);
      await tester.pumpAndSettle();
    }

    // ── 2. 사물 추가 다이얼로그 ──
    await tester.pumpAndSettle();
    await binding.takeScreenshot('02_add_item');

    // "나중에" 탭하여 다이얼로그 닫기
    final laterBtn = find.text('나중에');
    if (laterBtn.evaluate().isNotEmpty) {
      await tester.tap(laterBtn);
      await tester.pumpAndSettle();
    }

    // ── 3. 빈 맵 상태 → JSON 예시 데이터 로드 ──
    // 설정 버튼 탭
    final settingsBtn = find.byIcon(Icons.settings_outlined);
    if (settingsBtn.evaluate().isNotEmpty) {
      await tester.tap(settingsBtn);
      await tester.pumpAndSettle();
    }

    // JSON 가져오기 탭
    final importBtn = find.text('JSON 가져오기');
    if (importBtn.evaluate().isNotEmpty) {
      await tester.tap(importBtn);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
    }

    // 예시 채우기 버튼 탭
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    final exampleBtn = find.text('예시 채우기');
    if (exampleBtn.evaluate().isNotEmpty) {
      await tester.tap(exampleBtn);
      await tester.pumpAndSettle();
    }

    // 확인 버튼 탭
    final confirmBtn = find.text('확인');
    if (confirmBtn.evaluate().isNotEmpty) {
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();
    }

    // ── 4. 메인 화면 — 예시 데이터 로드된 상태 ──
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await binding.takeScreenshot('03_main_with_items');

    // ── 5. 사물 선택 — 첫 번째 사물 탭 (맵 중앙 근처) ──
    // 화면 중앙을 탭하여 사물 선택 시도
    final size = tester.view.physicalSize / tester.view.devicePixelRatio;
    await tester.tapAt(Offset(size.width * 0.45, size.height * 0.45));
    await tester.pumpAndSettle();
    await binding.takeScreenshot('04_item_selected');

    // ── 6. 설정 화면 ──
    final settingsBtn2 = find.byIcon(Icons.settings_outlined);
    if (settingsBtn2.evaluate().isNotEmpty) {
      await tester.tap(settingsBtn2);
      await tester.pumpAndSettle();
    }
    await binding.takeScreenshot('05_settings');
  });
}
