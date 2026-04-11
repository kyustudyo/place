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
