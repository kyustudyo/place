# place — Project Brief

## 한줄 요약
가구 배치 도구 — 3D 아이소메트릭 방에서 드래그&드롭으로 가구 위치 결정, JSON 입출력

## 배경
- **measure 앱** = 가구 크기 측정 (Z비율%)
- **Place 앱** = 가구 위치 배치 (15x15 그리드 방에서 드래그&드롭)
- 서버 없는 클라이언트 전용 도구, JSON 클립보드 입출력
- Unity 파이프라인의 중간 도구: measure → Place → Unity 자동 배치

## 워크플로우
```
measure 앱 → Z비율 JSON → Unity 스케일 적용 → furniture_sizes.json 내보내기
→ Place 앱에서 배치 → placement_result.json → Unity 자동 배치
```

## 목표
- 클립보드 JSON 입력으로 가구 크기 데이터를 받아
- 3D 아이소메트릭 방(7.5m x 7.5m)에서 드래그&드롭으로 가구 배치
- 배치 결과를 JSON으로 클립보드 복사하여 Unity에 전달

## 성공 기준
1. furniture_sizes.json 붙여넣기 → 가구 목록 표시
2. 가구를 방 안에서 드래그&드롭으로 배치 가능
3. 0.5m 타일 스냅 + 탭 회전(0/90/180/270) 동작
4. 충돌 감지로 겹침 경고
5. placement_result.json 클립보드 복사 → Unity에서 정상 로드

## 범위 밖 (Out of Scope)
- 서버/DB 연동
- 사용자 인증
- 가구 크기 편집 (measure 앱 담당)
- 실제 3D 렌더링 (2.5D 아이소메트릭으로 대체)
- 방 크기/형태 커스터마이징 (7.5m x 7.5m 고정)

## 플랫폼
- iOS
- Android
- Web (Cloudflare Pages 배포)
