# place — Tech Spec

## 아키텍처
- 플랫폼: Flutter (iOS + Android + Web)
- 상태 관리: Riverpod
- 데이터 저장: 없음 (클립보드 JSON 입출력만)
- 서버: 없음 (클라이언트 전용)
- 3D 렌더링: CustomPainter 아이소메트릭 2.5D

## 핵심 구조

```
lib/
├── main.dart
├── models/
│   ├── room.dart              # Room 데이터 모델
│   ├── furniture.dart         # Furniture 데이터 모델
│   └── placement.dart         # Placement 결과 모델
├── providers/
│   ├── room_provider.dart     # 방 상태 관리
│   └── furniture_provider.dart # 가구 목록/배치 상태
├── screens/
│   └── placement_screen.dart  # 메인 배치 화면
├── widgets/
│   ├── isometric_room.dart    # 아이소메트릭 방 렌더링
│   ├── furniture_item.dart    # 가구 직육면체 렌더링
│   ├── furniture_panel.dart   # 사이드 가구 목록 패널
│   └── grid_painter.dart      # 바닥 그리드 페인터
└── utils/
    ├── json_parser.dart       # JSON 파싱/생성
    ├── isometric_math.dart    # 아이소메트릭 좌표 변환
    └── collision.dart         # 충돌 감지 로직
```

## 아이소메트릭 좌표계
- 월드 좌표 (x, z) → 화면 좌표 (screenX, screenY) 변환
- x축: 오른쪽 아래 방향
- z축: 왼쪽 아래 방향
- y축: 위쪽 (높이)
- 타일 크기: 0.5m → 화면 픽셀 비율 계산

## 충돌 감지
- AABB(Axis-Aligned Bounding Box) 기반
- 회전 시 바운딩 박스 재계산 (x, z 스왑)
- 방 경계 체크: 0 <= position <= room.width/depth - furniture.size

## 의존성
- `flutter` SDK
- `flutter_riverpod` — 상태 관리
- 추가 패키지 최소화 (CustomPainter로 직접 렌더링)

## 빌드 & 배포
- iOS: flutter build ios → App Store
- Android: flutter build apk → Google Play
- Web: flutter build web → Cloudflare Pages
- CI/CD: GitHub Actions → 테스트 → 배포 → 텔레그램 보고
