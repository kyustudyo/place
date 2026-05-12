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

### 참조 이미지 웹 버그 수정
- `MissingPluginException`: `flutter clean` 후 재빌드로 해결 (웹 플러그인 등록자 갱신)
- 브라우저 파일 피커 차단: 바텀시트 안에서 직접 `pickImage()` 호출로 해결
- 커맨더에 웹 이미지 첨부 규칙 전달 (`from_place_image_picker_web.md`)
- `MISTAKES.md`에 실수 2건 기록

## 2026-04-27

### v1.1.0 iOS + Android 배포
- 버전: 1.1.0+7
- iOS: `xcrun altool` → App Store Connect 업로드 성공
- Android: `fastlane supply` → Google Play 내부 테스트 업로드 성공
- Git 태그: `v1.1.0`
- 주요 변경사항:
  - 참조 이미지 기능 (설정에서 추가, 상단 탭 전환, 핀치 줌)
  - 사물 크기 수정 비율 유지 체크박스
  - JSON 다이얼로그 붙여넣기 버튼
  - 테마 설정 SharedPreferences 영속화
  - JSON 가져오기 시 room 키 선택사항
  - 참조 화면에서 + 버튼/목록 숨김, 상태바 텍스트 숨김

## 2026-04-29

### 다중 방 저장/불러오기 기능 추가
- inbox `from_unity_multi_room_save.md` 확인 → 조치 → 삭제
- unity팀 요청: 여러 방을 이름 붙여 저장/불러오기/삭제
- 구현:
  - `lib/utils/session_storage.dart` — `saveRoom()`, `loadRoom()`, `deleteRoom()`, `getSavedRoomNames()` 추가
  - `lib/screens/placement_screen.dart` — 저장 시 이름 입력 다이얼로그, 불러오기 시 방 목록 바텀시트(`_SavedRoomsSheet`)
  - 불러오기 버튼 항상 표시 (저장된 방 없으면 스낵바 안내)
  - SharedPreferences `place_saved_rooms` 키에 JSON 맵으로 저장
- unity팀에 회신 완료 (`from_place_multi_room_reply.md`)
- `flutter analyze` 통과 (0 issues, 1 info)

### 설정에 초기화 버튼 추가
- 초기화 버튼 → 확인 팝업 → 방+사물 전부 리셋 → ① 공간 크기 설정부터 재시작
- 빨간색 destructive 스타일 적용
- 수정 파일: `lib/providers/placement_provider.dart`, `lib/screens/placement_screen.dart`

### 사물 롱프레스 복제/삭제 기능
- 배치된 사물 꾹 누르면 "복제하기" + "삭제하기" 팝업 메뉴 표시
- 복제 이름: 숫자 순번 방식 (소파 → 소파2 → 소파3)
- 드래그 중에는 팝업 안 뜸
- 수정 파일: `lib/providers/placement_provider.dart`, `lib/widgets/isometric_room.dart`

### 저장 다이얼로그 UX 개선
- "방 저장" → "파일 저장"으로 변경
- `AlertDialog` → `Dialog`로 변경하여 키보드 밀림 방지
- 기존 저장된 방이면 텍스트필드에 이름 표시 + 잠금 아이콘 (비활성)
- "새 이름으로 저장" 체크 → 텍스트필드 활성화 + 전체 선택
- 같은 이름 입력 시 저장 거부 스낵바
- 수정 파일: `lib/screens/placement_screen.dart`

### v1.2.0 iOS + Android 배포
- 버전: 1.2.0+8
- iOS: `xcrun altool` → App Store Connect 업로드 성공
- Android: `fastlane supply` → Google Play 내부 테스트 업로드 성공
- Git 태그: `v1.2.0`
- 주요 변경사항:
  - 다중 방 저장/불러오기/삭제
  - 초기화 버튼 (확인 팝업)
  - 사물 롱프레스 → 복제/삭제 메뉴
  - 복제 이름 숫자 순번 방식
  - 저장 다이얼로그 덮어쓰기/새 이름 UX

## 2026-04-30

### Place 텍스트 스타일 변경
- 참조 이미지 없을 때 배경색 없는 일반 텍스트로 표시
- 참조 이미지 있을 때만 버튼 스타일
- 수정 파일: `lib/screens/placement_screen.dart`

### 설정 화면 정리 + 맵 크기 변경 추가
- 가이드 색상/투명도 + 테마 선택 → "꾸미기" 하위 바텀시트로 분리
- 설정에 "맵 크기 변경" 버튼 추가 (기존 공간 크기 다이얼로그 재사용)
- 설정 화면이 간결해짐
- 수정 파일: `lib/screens/placement_screen.dart`
- 배포 완료: https://place-cbp.pages.dev/

### 그리드/축/중앙정렬 개선
- 비정사각형 맵(30×10 등)에서 Z축 그리드 초과 버그 수정
- 맵이 화면 중앙에 오도록 origin 계산 개선
- 축 라벨: `− X +`, `− Z +`, Y축 위아래 +/− 표시
- 수정 파일: `lib/widgets/grid_painter.dart`, `lib/widgets/isometric_room.dart`

### 크기 입력 UX 개선
- 실시간 검증 (입력 즉시 빨간 에러 표시)
- 0 이하 값 검증 추가
- 키보드 밀림 방지 (AlertDialog → Dialog)
- 에러 메시지와 버튼 간격 개선
- 공간 크기 설정에 닫기(X) 버튼 (설정에서 열 때만)
- 맵 크기 변경 시 '기존 사물 유지' 체크박스
- 가구 크기 제한: 맵 기준 → 절대 최대값(50m/20m)
- 꾸미기 바텀시트 안 열리는 버그 수정 + 뒤로가기 버튼
- 수정 파일: `lib/widgets/dimension_dialog.dart`, `lib/screens/placement_screen.dart`

### 축 방향 설정 UI 교체
- 기존: X-Z 축 스왑 토글 (Switch, bool)
- 변경: 3축 자유 매핑 시트 (직육면체 프리뷰 + X/Y/Z 방향 선택 버튼)
- `AxisSwapNotifier(bool)` → `AxisMappingNotifier(AxisMapping)` — 6가지 축 조합 지원
- `IsometricMath`: `swapAxes` bool → `axisMapping` 객체로 3축 자유 매핑
- 수정 파일: `lib/providers/theme_provider.dart`, `lib/screens/placement_screen.dart`, `lib/utils/isometric_math.dart`, `lib/widgets/grid_painter.dart`, `lib/widgets/isometric_room.dart`

## 2026-05-01

### 축 방향 설정: +/- 반전 기능 + 겹침 수정
- 각 축(오른쪽아래/왼쪽아래/위)별 +/- 방향 반전 토글 추가
- `AxisMapping`에 `flipRD`/`flipLD`/`flipUp` 필드 추가
- `IsometricMath`: worldToScreen/screenToWorld에서 flip 시 값 반전
- 프리뷰 cuboid 스케일 축소 + origin 하단 이동으로 제목 겹침 해결
- 수정 파일: `lib/providers/theme_provider.dart`, `lib/screens/placement_screen.dart`, `lib/utils/isometric_math.dart`

### 설정값 앱 내 저장 + 축 설정 초기화 버튼
- 축 방향 설정 시트 오른쪽 상단에 "초기화" 버튼 추가 (디폴트 복원)
- 축 방향 설정(AxisMapping): SharedPreferences로 저장/복원
- 가이드 색상/투명도: SharedPreferences로 저장/복원
- 테마 인덱스는 기존에 이미 저장됨
- 수정 파일: `lib/providers/theme_provider.dart`, `lib/screens/placement_screen.dart`

### 축 매핑 라벨 전용으로 변경
- 축 변경 시 벽/가구가 회전하는 문제 해결
- `worldToScreen`/`screenToWorld`에서 축 매핑 제거 — 맵 렌더링 항상 고정
- 축 설정은 GridPainter 라벨과 프리뷰에서만 사용
- 수정 파일: `lib/utils/isometric_math.dart`, `lib/widgets/isometric_room.dart`

### 축 라벨 flip 반영
- 축 설정에서 +/- 변경 시 그리드 라벨의 +/− 순서가 실제로 뒤바뀌도록 수정
- X/Z 바닥 라벨 + Y 세로 라벨 모두 적용
- 수정 파일: `lib/widgets/grid_painter.dart`

### 저장 파일에 축 설정 포함 + JSON 내보내기 축 매핑 반영
- 저장 시 축 설정(axisMapping) 포함, 불러올 때 자동 복원
- JSON 내보내기에서 축 매핑에 따라 position/size 좌표 재배치
- position은 flip 반영, size는 축 매핑만 적용
- unity팀 요청 처리 (축 설정 → JSON 반영) + 회신 전달
- 수정 파일: `lib/utils/json_parser.dart`, `lib/utils/session_storage.dart`, `lib/providers/placement_provider.dart`, `lib/screens/placement_screen.dart`

### 스토어 에셋 정비 (Commander 요청)
- `store-assets/listings/ios/` — description, subtitle, keywords, whats-new, promo-text
- `store-assets/listings/android/` — short-description, full-description, whats-new
- builds, icon은 기존에 이미 존재
- 웹 배포 완료: https://place-cbp.pages.dev/

## 2026-05-04

### Android APK 빌드 추가
- `store-assets/builds/android/place-release.apk` 생성 (50.3MB)
- 파일 브라우저에서 다운로드 가능

### JSON 내보내기에 size 추가 (unity팀 요청)
- 내보내기 JSON에 `size` 필드 추가 (`position`, `rotation`과 함께)
- unity팀에 position 기준점(min corner) 회신
- 수정 파일: `lib/models/placement.dart`, `lib/utils/json_parser.dart`
- 웹 배포 완료: https://place-cbp.pages.dev/

### v1.3.0 iOS + Android 배포
- 버전: 1.3.0+10
- iOS: App Store Connect 업로드 성공
- Android: Google Play 비공개 테스트(alpha) 업로드 성공
- Git 태그: `v1.3.0`

## 2026-05-08

### 상세 조정 undo 지원 + 내보내기 position 바닥 중앙으로 변경
- fine-tune +/- 버튼에 undo 지원 추가 (`nudgePosition`, `nudgeHeight`에 `_saveUndo()`)
- 내보내기 JSON position을 min corner → bottom center로 변경 (Unity팀 요청)
- 수정 파일: `lib/providers/placement_provider.dart`, `lib/utils/json_parser.dart`, `lib/widgets/isometric_room.dart`
- 웹 배포 완료: https://place-cbp.pages.dev/

### v1.4.0 태그 생성
- Git 태그: `v1.4.0`

## 2026-05-09

### 벽면 배치 모드 추가 (Unity팀 요청)
- inbox `from_unity_wall_placement_mode.md` 확인 → 조치 → 삭제
- 뒷벽(BackWall), 오른벽(RightWall)을 2D 정면 뷰로 보며 문/창문 배치
- 벽 크기 = 방 크기에서 자동 파생 (뒷벽 가로=room.width, 오른벽 가로=room.depth)
- `flutter analyze` 통과 (0 errors/warnings)
- 웹 배포 완료: https://place-cbp.pages.dev/

## 2026-05-11

### 벽면 배치를 기존 아이소메트릭 뷰에 통합
- 별도 2D 벽 뷰 제거 → 기존 3D 아이소메트릭 뷰에서 벽 가구도 배치
- 상단바 모드 탭 [바닥][뒷벽][오른벽] 유지
- 벽 모드에서 + 누르면 해당 벽에 붙는 얇은 가구 생성 (두께 0.1m)
  - 뒷벽(z=0): size(가로, 높이, 0.1), position.z=0
  - 오른벽(x=0): size(0.1, 높이, 가로), position.x=0
- 기존 드래그, fine-tune(Y로 높이 조절), undo/redo 모두 그대로 사용
- `addWallFurniture()` 메서드 추가 (`lib/providers/placement_provider.dart`)
- `DimensionDialog`에 hideZ 옵션 (벽 아이템은 가로/높이만 입력)
- 수정 파일: `lib/screens/placement_screen.dart`, `lib/providers/placement_provider.dart`
- `flutter analyze` 통과 (0 errors/warnings)

### 벽 모드 UX 개선
- 상단바: [바닥] [벽] 두 탭으로 단순화
- [벽] 누르면 뒷벽/왼벽 빨간색 서브탭 나타남 + 아이소메트릭 뷰에서 벽 빨간 하이라이트
- 서브탭 선택 시 해당 벽만 하이라이트
- "사물 추가 (벽)" 다이얼로그: 이름 placeholder "문, 창문", x/y/z 크기 모두 입력
- addWallFurniture()가 x/y/z 직접 받도록 변경
- 수정 파일: `lib/screens/placement_screen.dart`, `lib/providers/placement_provider.dart`, `lib/providers/theme_provider.dart`, `lib/widgets/grid_painter.dart`, `lib/widgets/isometric_room.dart`, `lib/widgets/dimension_dialog.dart`
- `flutter analyze` 통과 (0 errors/warnings)

### 벽 선택을 맵에서 직접 탭으로 변경
- 서브탭(뒷벽/왼벽) 버튼 제거 → 아이소메트릭 뷰에서 벽을 직접 탭하여 선택
- [벽] 탭 누르면 두 벽 빨간 하이라이트 + 설정/+/목록 버튼 숨김
- 벽 탭하면 해당 벽만 하이라이트 + 버튼 표시 + 탭 옆에 "뒷벽"/"왼벽" 텍스트
- IsometricRoom에 벽 폴리곤 히트테스트 추가 (`_wallHitTest`)
- 수정 파일: `lib/screens/placement_screen.dart`, `lib/widgets/isometric_room.dart`
- `flutter analyze` 통과 (0 errors/warnings)

### 벽 선택 버튼 탭 시 다른 벽 전환 + 벽별 기본 크기값
- 뒷벽/왼벽 버튼 탭 → 벽 선택 해제, 다시 두 벽 하이라이트 (다른 벽 선택 가능)
- 뒷벽 + 기본값: X=1.5(넓은), Y=2.0, Z=0.1(얇은)
- 왼벽 + 기본값: X=0.1(얇은), Y=2.0, Z=1.5(넓은)
- 수정 파일: `lib/screens/placement_screen.dart`
- `flutter analyze` 통과 (0 errors/warnings)
- 웹 배포 완료: https://place-cbp.pages.dev/

### 벽 아이템 바닥 그림자 제거 + 드래그 벽 고정 + 범위 제한 + Y 드래그
- 벽 아이템 Y 올려도 바닥 그림자 안 나옴
- 드래그 시 벽면 고정 (벽에서 떼려면 상세조정만 가능)
- 드래그 범위 벽 안으로 제한 (가로 0~벽너비, 높이 0~벽높이)
- 벽 아이템 드래그로 상하+좌우 이동 (screenDeltaToBackWall/LeftWall 변환)
- 수정 파일: `lib/widgets/grid_painter.dart`, `lib/providers/placement_provider.dart`, `lib/utils/isometric_math.dart`, `lib/widgets/isometric_room.dart`

### v1.5.0 iOS + Android 배포
- 버전: 1.5.0+11
- iOS: App Store Connect 업로드 성공
- Android: Google Play 비공개 테스트(alpha) 업로드 성공
- APK: `store-assets/builds/android/place-release.apk` 갱신
- Git 태그: `v1.5.0`

## 2026-05-12

### 벽 모드 UX 개선 (8 커밋)
- 벽 선택 후 다른 벽 탭하면 전환 (`d427629`)
- 벽 모드에서 상세조정/오버레이 UI 숨김 → 이후 점진적 복원 (`33b98c4`, `989ec50`)
- 벽 아이템에도 상세조정 + 양쪽 벽 가이드 점선 표시 (`ccbd959`)
- 벽 아이템 회전 시 다른 벽으로 자동 전환 (`8e4b919`)
- 벽 아이템 두께 감지 기준 0.2m → 1.0m 확대 (`d021ad5`)
- 벽 모드 전환 시 선택된 가구 해제 (`8bf8af8`)
- 벽 가구 회전 시 벽 하이라이트도 해당 벽으로 전환 (`cd9890d`)
- 벽 모드에서도 이름/사이즈 편집 + 삭제/undo/redo 버튼 표시 (`bde9875`, `0e94690`)
- 수정 파일: `lib/widgets/isometric_room.dart`, `lib/providers/placement_provider.dart`, `lib/screens/placement_screen.dart`

### 바닥 모드에서 벽 가구 방 안쪽 드래그 가능
- 기존: 벽 가구가 벽에 고정되어 드래그로 방 안으로 이동 불가
- 변경: 바닥 모드(벽 하이라이트 없음)에서는 벽 가구도 바닥 드래그(X+Z)로 이동 가능
- 벽 모드에서는 기존대로 벽면 드래그(X+Y / Z+Y) 유지
- 수정 파일: `lib/widgets/isometric_room.dart`, `lib/providers/placement_provider.dart`

### 벽 가구 드래그 동작 최종 정리
- 벽 모드: 벽 가구는 벽-플레인 드래그(X+Y 또는 Z+Y) — Y 이동 가능, 벽 강제 스냅 없음
- 바닥 모드: 모든 가구 바닥 드래그(X+Z) — 벽 가구도 방 안쪽 이동 가능
- 방 안쪽 이동: 바닥 모드 드래그 또는 상세조정(fine-tune)
- 최종: 벽 모드에서는 벽-플레인(X+Y) 드래그만, 방 안쪽 이동은 바닥 모드 또는 상세조정
- 벽 가구 선택 시 반대벽까지 바닥 점선 가이드 추가 (`lib/widgets/grid_painter.dart`)
- 가구 크기 수정 비율 유지 기본값 off (`lib/widgets/dimension_dialog.dart`)
- 벽 가구 복제 시 같은 벽에 붙어서 생성 + 코너 판별 수정 (`lib/providers/placement_provider.dart`)
- 벽 모드 드래그: wallHighlight 대신 아이템 얇은 차원으로 벽 판별 (`lib/widgets/isometric_room.dart`)
- 벽 모드 진입 시 '벽을 선택하세요' 안내 팝업 (`lib/widgets/isometric_room.dart`)
- JSON 가져오기: 예시에 벽 가구(문/창문) 추가 + 도움말 버튼 (`lib/screens/placement_screen.dart`)
- 수정 파일: `lib/widgets/isometric_room.dart`

### 벽 모드 벽 가구 판별 기준 변경 (위치→얇은 차원)
- 기존: `position.z < 0.01 && effectiveDepth < 1.0`으로 판별 → 방 안으로 옮겼다 다시 벽에 놓으면 z가 0이 아니라 벽 아이템 인식 실패
- 변경: 벽 모드에서는 `wallHighlight`(선택된 벽) + `effectiveDepth/Width < 1.0`(얇은 차원)으로 판별
- 벽 모드 드래그 시 자동 벽 스냅(`z=0` 또는 `x=0`)
- 수정 파일: `lib/widgets/isometric_room.dart`

### inbox 처리: unity팀 벽면 JSON 형식 문의
- 질문: 벽 아이템 JSON 가져오기/내보내기 형식
- 답변: 기존 furniture 배열과 동일한 형식 (벽 아이템 = 얇은 가구)
  - 뒷벽: position.z=0, size.z < 1.0
  - 왼벽: position.x=0, size.x < 1.0
- unity팀에 회신 완료 (`from_place_wall_json_format_reply.md`)
