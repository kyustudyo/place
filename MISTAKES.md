# 실수 기록

## 형식
```
### 실수 제목 (날짜)
- **상황**: 무슨 일이 있었는지
- **원인**: 왜 발생했는지
- **방지책**: 앞으로 어떻게 방지할 건지
```

---

### AlertDialog.actions에서 Expanded 사용 (2026-04-12)
- **상황**: ② 가구 추가 팝업이 회색 화면만 나옴 (다이얼로그 렌더링 크래시)
- **원인**: `AlertDialog.actions`는 `OverflowBar`로 레이아웃되는데, 그 안에 `Expanded`를 넣으면 unbounded width 에러
- **방지책**: AlertDialog actions에 `Expanded` 쓰지 마라. 전체 너비 버튼이 필요하면 `SizedBox(width: double.infinity)`를 사용

### 웹에서 image_picker MissingPluginException (2026-04-26)
- **상황**: `image_picker` 추가 후 웹에서 `pickImage()` 호출 시 `MissingPluginException` 발생. 파일 선택 창이 아예 안 뜸
- **원인**: 새 플러그인 추가 후 `flutter clean` 없이 빌드하면 웹 플러그인 등록자(`web_plugin_registrant.dart`)가 갱신되지 않음
- **방지책**: 플러그인 추가/변경 후 반드시 `flutter clean && flutter pub get` 한 뒤 빌드

### 웹에서 pickImage() 브라우저 차단 (2026-04-26)
- **상황**: 바텀시트에서 `Navigator.pop` 후 `Future.delayed`/`addPostFrameCallback`으로 `pickImage()` 호출 → 파일 선택 창 안 뜸
- **원인**: 웹 브라우저 보안 정책상 `<input type="file">`은 유저 제스처의 동기 호출 스택 안에서만 트리거 가능. pop/delay가 끼면 제스처 컨텍스트가 끊겨 차단됨
- **방지책**: `pickImage()`는 반드시 유저 탭의 동기 호출 스택에서 직접 호출. 바텀시트 안에서 먼저 호출 → 완료 후 시트 닫기
