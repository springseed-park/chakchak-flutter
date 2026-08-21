# CHAKCHAK Flutter UI 작업 규칙

- UI를 구현하거나 수정하기 전에 `/Users/juwonpark/Desktop/착착_Codex_UI_구현지침.md`를 처음부터 끝까지 확인한다.
- 색상, 타이포그래피, 간격, radius, 버튼, 입력, chip 규격은 해당 문서를 기본 디자인 기준으로 사용한다.
- 모든 버튼 label은 Paperlogy 500, 14px을 사용한다.
- 입력 label은 Paperlogy 500, 16px을 사용한다.
- 사용자의 현재 요청이 디자인 지침과 충돌하면 현재 요청을 우선하고, 확정된 변경은 디자인 지침에도 반영한다.
- 화면별 임의 스타일을 추가하지 말고 `lib/design_system.dart`의 토큰과 공용 컴포넌트를 우선 사용한다.
- 변경 후 402 × 874px 기준 레이아웃을 확인하고 관련 테스트와 Flutter Web 빌드를 검증한다.
