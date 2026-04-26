# place 작업 로그

## 2026-04-11
### 시작
- 프로젝트 생성 (commander)
- 플랫폼: flutter
- 설명: 가구 배치 도구 — 3D 방에서 드래그&드롭으로 가구 위치 결정, JSON 입출력

### 문서 작성 완료
- inbox `from_commander_unity_proposal.md` 확인 → 조치 → 삭제
- unity팀 제안서 기반으로 5개 문서 작성:
  - `PROJECT_BRIEF.md` — 프로젝트 개요, 목표, 성공 기준
  - `PRODUCT_SPEC.md` — 6개 핵심 기능, 데이터 모델(입출력 JSON), 사용자 시나리오
  - `TECH_SPEC.md` — Flutter 아키텍처, 디렉토리 구조, 좌표계, 충돌 감지
  - `UX_FLOW.md` — 사용자 여정 6단계, 데스크탑/모바일 레이아웃
  - `TASKS.md` — Phase 1 MVP (7단계) + Phase 2 개선
- 플랫폼: iOS + Android + Web 전부 지원

### MVP 구현 + 배포 완료
- Flutter 앱 구현:
  - `lib/main.dart` — 앱 엔트리
  - `lib/models/room.dart`, `furniture.dart`, `placement.dart` — 데이터 모델
  - `lib/providers/placement_provider.dart` — Riverpod 상태 관리
  - `lib/screens/placement_screen.dart` — 메인 화면 (상단바, 방, 패널, 상태바)
  - `lib/widgets/isometric_room.dart` — 아이소메트릭 방 + 드래그&드롭
  - `lib/widgets/grid_painter.dart` — 바닥 그리드 + 벽
  - `lib/widgets/furniture_renderer.dart` — 가구 직육면체 렌더링
  - `lib/widgets/furniture_panel.dart` — 가구 목록 사이드 패널
  - `lib/utils/isometric_math.dart` — 좌표 변환
  - `lib/utils/collision.dart` — AABB 충돌 감지
  - `lib/utils/json_parser.dart` — JSON 파싱/생성
- 10개 HTML 디자인 시안: `design/placement/placement_v1~v10.html`
- Cloudflare Pages 배포: https://place-cbp.pages.dev/
- `CLAUDE.md` 업데이트 (프로젝트 정보 반영)
- `flutter analyze` 통과 (0 issues)

### 테마 시스템 + 벽 수정
- 벽 렌더링 버그 수정: 오른벽이 x=room.width(하단)에 잘못 그려짐 → x=0(상단좌)으로 이동
  - 두 벽이 꼭대기(0,0,0)에서 V자로 만나는 정상 아이소메트릭 구조로 수정
- 10개 테마 시스템 추가:
  - `lib/models/app_theme.dart` — 10개 테마 정의 (색상, 밝기, 선 두께)
  - `lib/providers/theme_provider.dart` — 테마 상태 관리
  - v4 Warm Wood가 기본 테마
  - 상단바에 팔레트 아이콘 설정 버튼 → 바텀시트로 테마 전환
- 모든 위젯에 테마 색상 적용 (grid_painter, furniture_renderer, furniture_panel, placement_screen)
- 배포 완료: https://place-cbp.pages.dev/
- `flutter analyze` 통과 (0 issues)

### UX 전면 개편
- 기존: JSON 붙여넣기 해야 시작 → 빈 화면이 보임
- 변경: 진입 즉시 방(7.5m) + 기본 직육면체 1개 표시
- 크기 입력 팝업 자동 표시: 이름, X(가로), Y(높이), Z(세로)
- 새 파일:
  - `lib/widgets/dimension_dialog.dart` — 크기 입력 다이얼로그
- 수정 파일:
  - `lib/providers/placement_provider.dart` — 기본 방/가구 포함, addFurniture/updateFurnitureSize/removeFurniture 추가
  - `lib/screens/placement_screen.dart` — 진입 시 팝업, 상단바 아이콘 정리
  - `lib/widgets/furniture_panel.dart` — 크기 편집 버튼(자 아이콘), 삭제 기능
  - `lib/widgets/isometric_room.dart` — room non-null 대응
- 배포 완료: https://place-cbp.pages.dev/
- `flutter analyze` 통과 (0 issues)

### 진입 플로우 개선 (measure 참고)
- measure 프로젝트 UX 분석: 단계별 가이드(①②③), 한 번에 하나만 물어봄, 명확한 안내 문구
- 변경:
  - 진입 시 ① 공간 크기 설정 팝업 (가로/세로/높이/타일크기, "다음" 버튼)
  - 이어서 ② 가구 추가 팝업 (이름/X/Y/Z, "배치하기" 버튼)
  - 단계 번호 표시, 안내 부연설명 추가
- 수정 파일:
  - `lib/widgets/dimension_dialog.dart` — RoomSizeDialog 추가, DimensionDialog에 showStepNumber 옵션
  - `lib/providers/placement_provider.dart` — setRoom() 추가, 초기 가구 없이 빈 방 시작
  - `lib/screens/placement_screen.dart` — _runInitialFlow() (공간→가구 순차 팝업)
- 배포 완료: https://place-cbp.pages.dev/
- `flutter analyze` 통과 (0 issues)

## 2026-04-12

### ② 가구 추가 팝업 회색 화면 버그 수정
- 원인: `AlertDialog.actions`에서 `Expanded` 사용 → `OverflowBar` 내 레이아웃 크래시
- 수정: `SizedBox(width: double.infinity)`로 대체
- 파일: `lib/widgets/dimension_dialog.dart`
- 배포 완료: https://place-cbp.pages.dev/

### "가구" → "사물" 용어 변경
### 기본 방 크기 15×15 타일1로 변경
### 높이 점선 가이드 + 넘침 시 투명 가상벽
### ② 사물 추가 팝업에 "나중에" 버튼 추가
### + 버튼 깜박임 + "사물 추가" 툴팁 (사물 비어있을 때)

### 모바일 UX 전면 개선
- 사물목록: 하단 패널 제거 → 상단바 목록 버튼 → 바텀시트로 열기
- 맵이 모바일 전체 화면 차지
- 드래그 시 사물이 손가락 위쪽으로 오프셋 (가리지 않음)
- 드래그 중 원형 확대 루페(2.5x) 표시 — 십자선 + 사물 색상 테두리
- 수정 파일:
  - `lib/screens/placement_screen.dart` — 모바일 레이아웃, _showFurnitureSheet()
  - `lib/widgets/isometric_room.dart` — 드래그 오프셋, _LoupePainter
- 배포 완료: https://place-cbp.pages.dev/

## 2026-04-16

### 가이드 점선 투명도 조절 기능 추가
- 설정 바텀시트에 opacity 슬라이더 추가 (10%~100%, 10% 단위)
- 가이드 색상 선택 아래에 "투명도" 라벨 + Slider + % 표시
- 수정 파일:
  - `lib/providers/theme_provider.dart` — GuideOpacityNotifier, guideOpacityProvider 추가
  - `lib/widgets/grid_painter.dart` — guideOpacity 파라미터, 모든 alpha 값에 곱셈 적용
  - `lib/widgets/isometric_room.dart` — guideOpacity watch 및 GridPainter에 전달
  - `lib/screens/placement_screen.dart` — 설정에 Slider 위젯 추가
- 배포 완료: https://place-cbp.pages.dev/

### 가이드 점선 진하기 3배 강화 + 디폴트 50%
- 기본 alpha 값 약 3배 증가 (슬라이더 30% ≈ 이전 100%)
- 디폴트 50%, 슬라이더 범위 0~100% (중앙 정렬)

### iOS 배포 (App Store Connect)
- IPA 빌드 + xcrun altool CLI 업로드 성공
- 앱 이름: 어디에둘까, Bundle ID: com.kyustudyo.place
- 빌드 3 (아이콘 교체 후 재업로드)

### Android 배포 준비
- keystore 생성 (`~/upload-keystore.jks`)
- `android/key.properties` + `build.gradle.kts` 서명 설정
- AAB 빌드 성공 (42MB)
- Google Play Console 앱 미등록 → 업로드 대기

### 배포 에셋 전체 준비
- 앱 이름: place → 어디에둘까 (iOS Info.plist + Android AndroidManifest.xml)
- 커스텀 앱 아이콘: 1024x1024 원본 → iOS 전 크기 + Android mipmap 전 크기 + round
- Feature Graphic 1024x500
- 개인정보처리방침: `privacy-policy.html` → https://place-cbp.pages.dev/privacy-policy.html
- 스토어 설명 문구 (한국어) 작성

## 2026-04-19

### 스토어 스크린샷 자동 캡처
- inbox 지시 (`from_commander_screenshots.md`) 확인 → 조치 → 삭제
- `SCREENSHOT_MODE` 분기 추가 (`lib/main.dart`, `lib/screens/placement_screen.dart`)
- iPhone 14 Plus (1284x2778): 4장 (메인, 선택, 설정, 사물목록)
- iPad Pro 12.9 6th (2048x2732): 4장 (메인, 선택, 설정, 사물목록)
- Android (1080x1920): iOS 4장 리사이즈
- 결과: `store-assets/screenshots/ios/`, `ipad/`, `android/`

## 2026-04-20

### Google Play 내부 테스트 AAB 업로드
- fastlane supply로 내부 테스트 트랙에 AAB 업로드 성공 (draft)
- 빌드번호 3, 버전 1.0.0, API 24+
- 서비스 계정 권한 추가 필요했음 (주인님 직접 처리)
- 프로덕션 출시를 위해 12명 테스터 × 14일 비공개 테스트 필요

## 2026-04-22

### 테마 설정 영속화
- 선택한 화면 테마가 앱 재시작 후에도 유지되도록 SharedPreferences 저장 추가
- 수정 파일: `lib/providers/theme_provider.dart`
- `flutter analyze` 통과 (0 issues)

## 2026-04-24

### inbox 처리: unity팀 JSON room 자동 설정 요청
- 요청: JSON 가져오기 시 `room` 키도 읽어 맵 크기 자동 설정
- 기존: `room` 키 필수 — 없으면 크래시
- 수정: `room` 키 선택사항 — 있으면 맵 재구성, 없으면 기존 맵 유지
- 수정 파일: `lib/utils/json_parser.dart`, `lib/providers/placement_provider.dart`
- unity팀에 회신 완료 (`from_place_room_json_reply.md`)
- `flutter analyze` 통과 (0 issues)

### JSON 다이얼로그 붙여넣기 버튼
- JSON 가져오기 다이얼로그 오른쪽 위에 클립보드 붙여넣기 버튼 추가
- 동그란 배경 뷰(accent 15%)로 감싼 아이콘
- 수정 파일: `lib/screens/placement_screen.dart`

### 사물 크기 수정 비율 유지
- 크기 수정 다이얼로그에 "비율 유지" 체크박스 추가 (디폴트 체크)
- X/Y/Z 중 하나 변경 시 원본 비율 기준으로 나머지 자동 조정
- 수정 파일: `lib/widgets/dimension_dialog.dart`

## 2026-04-26

### 참조 이미지 기능 추가
- 설정에 "참조 이미지" 추가/변경/삭제 버튼
- 이미지 추가 시 상단바 Place 오른쪽에 "참조" 버튼 표시
- 참조 버튼 탭 → 참조 이미지 전체화면 (InteractiveViewer, 핀치 줌)
- Place 버튼 탭 → 작업화면 복귀
- 패키지 추가: `image_picker`
- 수정 파일: `lib/screens/placement_screen.dart`, `lib/providers/theme_provider.dart`
- `flutter analyze` 통과 (0 issues)
- 배포 완료: https://place-cbp.pages.dev/
