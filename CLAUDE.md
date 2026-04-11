# Place — Claude Code 가이드

## 프로젝트 요약
- **설명**: 가구 배치 도구 — 3D 아이소메트릭 방에서 드래그&드롭으로 가구 위치 결정, JSON 입출력
- **스택**: Flutter (iOS + Android + Web), Riverpod, CustomPainter
- **용도**: Unity 파이프라인의 중간 도구. measure 앱에서 측정한 가구를 방에 배치하고 결과 JSON을 Unity에 전달

## 호칭
- 유저를 **"주인님"**으로 호칭할 것

## 절대 규칙
1. **계획 먼저**: 작업 전 계획이 모호하면 반드시 주인님에게 확인받아라
2. **자기 점검 필수**: 작업 완료 후 반드시 `flutter analyze` 통과 확인. 검증 없이 "끝났습니다" 하지 마라
3. **실수 기록 필수**: 작업 중 실수가 발생하면 `MISTAKES.md`에 즉시 기록
4. **즉시 커밋**: 작업했으면 바로 커밋해라
5. **수정 범위 제한**: 요청받은 것만 수정하라
6. **작업일지 필수**: 작업 시작/완료 시 `work-logs/work-log.md`에 반드시 기록. 빠뜨리지 마라

## 작업 시작 전 (매 응답 시)
- `inbox/` 확인 — 파일 있으면 읽고 조치 후 삭제
- `work-logs/work-log.md`를 읽고 이전 상태를 파악하라
- 작업 시작/완료 시 기록하라. 변경한 파일 경로를 명시하라

## 필요 시 참조 (매번 읽지 마라)
- `MISTAKES.md` — 같은 영역 작업 시 실수 반복 방지
- `TODO.md` — 새 작업 시작 시 🔴 항목 확인
- `claude-rules/INCIDENT_REPORTS.md` — 새 기능/아키텍처 변경 시만
- `claude-rules/guides/` — 빌드, 배포, 테스트, 디자인 가이드
- `claude-rules/guides/design-workflow.md` — 디자인 작업 시 반드시 읽어라 (폴더 구조 + legacy 규칙)
- `~/tools/figma-web-capture-pro/GUEST_GUIDE.md` — 디자인 작업 시 반드시 먼저 읽어라. 이 안에 DESIGN_MIX.md 등 전체 프로세스가 있다
- 디자인 폴더: `design/` (프로젝트 루트) — 화면별 폴더에 HTML 버전 관리

## 획기적 발견
- 작업 중 뛰어난 기술/발견/패턴을 알아내면 `discoveries/`에 기록하라
- 지금 안 써도 나중에 쓸 수 있는 범용 기술을 모아둔다
- 파일명: `{날짜}_{주제}.md`

## 보고 형식
- 요약 먼저, 상세는 그 다음
- 혼자 해결 가능한 것과 주인님 확인이 필요한 것을 구분하라

## 실행 & 점검
```bash
flutter analyze
flutter test
```

## 수정 가능 범위
- **수정 가능**: `lib/`, `design/`, `test/`, `web/`
- **주의**: `pubspec.yaml` (의존성 변경 시 주의)
- **건드리지 마**: `.env`, credentials, `claude-rules/`

## 웹 테스트
- 로컬 `flutter run -d chrome` 사용하지 마라 — 불안정
- **push → CI 자동 배포 → 배포 URL에서 확인**
- 배포 URL: https://place-cbp.pages.dev/

## 기존 문서 참조
| 문서 | 내용 |
|------|------|
| `PROJECT_BRIEF.md` | 프로젝트 개요, 목표, 성공 기준 |
| `PRODUCT_SPEC.md` | 핵심 기능 6개, JSON 스키마, 사용자 시나리오 |
| `TECH_SPEC.md` | 아키텍처, 디렉토리 구조, 좌표계, 충돌 감지 |
| `UX_FLOW.md` | 사용자 여정, 데스크탑/모바일 레이아웃 |
| `TASKS.md` | Phase 1 MVP + Phase 2 개선 |
