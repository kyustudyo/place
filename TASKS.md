# place — Tasks

## Phase 1: MVP — 기본 배치 도구

### 1-1. 프로젝트 셋업
- [ ] Flutter 프로젝트 생성 (iOS + Android + Web)
- [ ] 디렉토리 구조 설정 (models, providers, screens, widgets, utils)
- [ ] 의존성 추가 (flutter_riverpod)
- [ ] GitHub repo 설정 + CI/CD 템플릿 적용

### 1-2. 데이터 모델 & JSON 파싱
- [ ] Room 모델 (width, height, depth, tileSize, gridSize)
- [ ] Furniture 모델 (id, name, size, position, rotation)
- [ ] Placement 출력 모델 (id, position, rotation)
- [ ] JSON 파서 (입력 파싱 + 출력 생성)
- [ ] 클립보드 읽기/쓰기 유틸

### 1-3. 아이소메트릭 렌더링
- [ ] 아이소메트릭 좌표 변환 유틸 (월드 → 화면)
- [ ] 바닥 그리드 그리기 (15x15, 0.5m 타일)
- [ ] 뒤벽 + 오른벽 그리기
- [ ] 가구 직육면체 렌더링 (size 기반, 색상 구분)
- [ ] 가구 이름 라벨 표시

### 1-4. 드래그&드롭 + 회전
- [ ] 사이드 패널에서 방으로 드래그&드롭
- [ ] 방 안에서 가구 드래그 이동
- [ ] 0.5m 타일 스냅
- [ ] 탭 회전 (0/90/180/270)
- [ ] 화면 좌표 → 월드 좌표 역변환 (히트 테스트)

### 1-5. 충돌 감지
- [ ] AABB 충돌 감지 (가구 간 겹침)
- [ ] 방 경계 체크
- [ ] 충돌 시 시각적 경고 (빨간 테두리)

### 1-6. UI 통합
- [ ] 메인 화면 레이아웃 (방 + 사이드 패널 + 상단 바)
- [ ] 모바일 레이아웃 (방 + 하단 시트)
- [ ] JSON 붙여넣기 버튼/다이얼로그
- [ ] JSON 복사 버튼 + 성공 토스트
- [ ] 상태바 (배치 수, 충돌 여부)

### 1-7. 빌드 & 배포
- [ ] flutter build web 확인
- [ ] flutter build ios 확인
- [ ] flutter build apk 확인
- [ ] Cloudflare Pages 배포 설정
- [ ] GitHub Actions CI/CD 구성

## Phase 2: 개선
- [ ] 가구 선택 하이라이트
- [ ] Undo/Redo
- [ ] 줌 인/아웃
- [ ] 가구 삭제 (배치 해제 → 패널로 복귀)
- [ ] 모바일 터치 최적화
