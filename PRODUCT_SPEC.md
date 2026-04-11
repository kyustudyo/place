# place — Product Spec

## 핵심 기능

### 1. JSON 입력 (클립보드 붙여넣기)
- 화면에 "붙여넣기" 버튼 또는 Ctrl+V로 furniture_sizes.json 입력
- 파싱 후 가구 목록을 사이드 패널에 표시
- 잘못된 JSON 형식 시 에러 메시지

### 2. 3D 아이소메트릭 방 시각화
- 7.5m x 7.5m 방 (뒤벽 + 오른벽)
- 0.5m 단위 그리드 (15x15 타일)
- 높이 4.0m
- CustomPainter 기반 2.5D 아이소메트릭 렌더링

### 3. 가구 표현
- 각 가구를 size(x, y, z) 기반 직육면체로 표현
- 가구별 색상 구분
- 이름 라벨 표시

### 4. 드래그&드롭 배치
- 가구를 방 바닥으로 드래그&드롭
- 0.5m 타일 스냅 (tileSize: 0.5)
- 탭으로 회전 (0 / 90 / 180 / 270도)

### 5. 충돌 감지
- 가구 간 겹침 시 시각적 경고 (빨간 테두리 등)
- 방 범위 밖 배치 불가

### 6. JSON 출력 (클립보드 복사)
- "복사" 버튼으로 placement_result.json을 클립보드에 복사
- 배치된 가구의 position, rotation만 출력

## 데이터 모델

### 입력: furniture_sizes.json
```json
{
  "room": {
    "width": 7.5,
    "height": 4.0,
    "depth": 7.5,
    "tileSize": 0.5,
    "gridSize": 15
  },
  "furniture": [
    {
      "id": "sofa",
      "name": "Sofa",
      "size": { "x": 1.50, "y": 0.60, "z": 1.00 },
      "position": { "x": 1.00, "y": 0.09, "z": 0.50 },
      "rotation": 225
    }
  ]
}
```

### 출력: placement_result.json
```json
{
  "placements": [
    {
      "id": "sofa",
      "position": { "x": 1.25, "y": 0.09, "z": 3.50 },
      "rotation": 0
    }
  ]
}
```

## 사용자 시나리오

### 시나리오 1: 기본 배치
1. measure 앱에서 가구 크기 측정 완료
2. Unity에서 furniture_sizes.json 생성
3. Place 앱 열기 → JSON 붙여넣기
4. 가구들이 사이드 패널에 나타남
5. 하나씩 드래그해서 방 안에 배치
6. 탭으로 회전 조정
7. "복사" 버튼 → placement_result.json 클립보드 복사
8. Unity에 붙여넣기 → 자동 배치 완료

### 시나리오 2: 재배치
1. 이전 배치 결과가 포함된 furniture_sizes.json 입력 (position 값 있음)
2. 기존 position에 가구가 자동 배치됨
3. 원하는 가구만 드래그해서 위치 수정
4. 결과 JSON 복사
