# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run Commands

```bash
flutter run                    # 앱 실행 (디바이스/에뮬레이터 필요)
flutter build apk              # Android APK 빌드
flutter build ios               # iOS 빌드
flutter analyze                 # 정적 분석 (lint)
flutter test                    # 전체 테스트 실행
flutter test test/widget_test.dart  # 단일 테스트 파일 실행
flutter pub get                 # 의존성 설치
```

## Architecture

Provider 패턴 기반의 단일 화면 Flutter 스도쿠 앱.

### 레이어 구조

```
lib/
├── main.dart                    # 앱 진입점, ChangeNotifierProvider로 GameProvider 주입
├── providers/game_provider.dart # 게임 상태 관리 (ChangeNotifier)
├── utils/sudoku_logic.dart      # 순수 로직 (UI 무관, 보드 생성/검증)
├── screens/board_screen.dart    # 메인 화면 (난이도 선택, 타이머, 그리드, 키패드 조합)
└── widgets/
    ├── sudoku_grid.dart         # 9x9 보드 렌더링 + 셀 선택/하이라이트
    └── number_pad.dart          # 1-9 입력 버튼 + 액션 버튼(되돌리기/지우기/메모/힌트)
```

### 데이터 흐름

- `SudokuLogic`: 백트래킹으로 완성 보드 생성 → 빈칸 제거로 퍼즐 출제. `board`(현재), `solutionBoard`(정답), `isFixedBoard`(고정 여부) 3개 2D 리스트 관리
- `GameProvider`: SudokuLogic을 감싸며 셀 선택, 입력, 힌트, 타이머, 난이도, 클리어 판정 등 게임 상태 관리. `notifyListeners()`로 UI 갱신
- 위젯들은 `Consumer<GameProvider>`로 상태 구독

### 주요 규칙

- 보드 값 `0` = 빈칸, `1-9` = 숫자
- 난이도별 빈칸 수: 쉬움(30), 보통(40), 어려움(50)
- 힌트 사용 시 해당 칸은 `isFixed = true`로 고정 처리
- 숫자가 보드에 9개 채워지면 해당 번호 버튼 비활성화

## Dependencies

- `provider` (^6.1.5): 상태 관리
- `flutter_lints` (^6.0.0): 린트 규칙 (analysis_options.yaml에서 설정)
- Dart SDK: ^3.11.1

## 워크플로우

- 작업 완료 후 CLAUDE.md 내용이 현재 코드와 맞지 않거나 추가할 내용이 있으면 업데이트를 제안할 것


## 참고

- `backlog.md`에 기능 백로그 관리 중
- 한글 UI (난이도: 쉬움/보통/어려움)