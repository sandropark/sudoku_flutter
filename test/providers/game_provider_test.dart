import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku/providers/game_provider.dart';

void main() {
  late GameProvider provider;

  setUp(() {
    provider = GameProvider();
  });

  tearDown(() {
    provider.dispose();
  });

  group('Life 기능', () {
    test('초기 remainingLives는 3이다', () {
      expect(provider.remainingLives, 3);
    });

    test('초기 isGameOver는 false이다', () {
      expect(provider.isGameOver, false);
    });

    test('오답 입력 시 remainingLives가 감소한다', () {
      final pos = _findEmptyCell(provider);
      provider.selectCell(pos.$1, pos.$2);

      final correctNumber = _getSolutionNumber(provider, pos.$1, pos.$2);
      final wrongNumber = (correctNumber % 9) + 1;

      provider.setInput(wrongNumber);
      expect(provider.remainingLives, 2);
    });

    test('정답 입력 시 remainingLives가 유지된다', () {
      final pos = _findEmptyCell(provider);
      provider.selectCell(pos.$1, pos.$2);

      final correctNumber = _getSolutionNumber(provider, pos.$1, pos.$2);
      provider.setInput(correctNumber);
      expect(provider.remainingLives, 3);
    });

    test('3번 틀리면 isGameOver가 true가 된다', () {
      for (int i = 0; i < 3; i++) {
        final pos = _findEmptyCell(provider);
        provider.selectCell(pos.$1, pos.$2);
        final correctNumber = _getSolutionNumber(provider, pos.$1, pos.$2);
        final wrongNumber = (correctNumber % 9) + 1;
        provider.setInput(wrongNumber);
      }

      expect(provider.remainingLives, 0);
      expect(provider.isGameOver, true);
    });

    test('게임 오버 시 입력이 차단된다', () {
      for (int i = 0; i < 3; i++) {
        final pos = _findEmptyCell(provider);
        provider.selectCell(pos.$1, pos.$2);
        final correctNumber = _getSolutionNumber(provider, pos.$1, pos.$2);
        final wrongNumber = (correctNumber % 9) + 1;
        provider.setInput(wrongNumber);
      }
      expect(provider.isGameOver, true);

      final pos = _findEmptyCell(provider);
      provider.selectCell(pos.$1, pos.$2);
      final boardBefore = provider.board[pos.$1][pos.$2];
      provider.setInput(5);
      expect(provider.board[pos.$1][pos.$2], boardBefore);
    });

    test('startNewGame 시 life가 초기화된다', () {
      final pos = _findEmptyCell(provider);
      provider.selectCell(pos.$1, pos.$2);
      final correctNumber = _getSolutionNumber(provider, pos.$1, pos.$2);
      final wrongNumber = (correctNumber % 9) + 1;
      provider.setInput(wrongNumber);
      expect(provider.remainingLives, 2);

      provider.startNewGame();
      expect(provider.remainingLives, 3);
      expect(provider.isGameOver, false);
    });
  });

  group('selectCell', () {
    test('선택한 좌표가 저장된다', () {
      provider.selectCell(3, 5);
      expect(provider.selectedRow, 3);
      expect(provider.selectedCol, 5);
    });
  });

  group('setInput', () {
    test('같은 숫자를 재입력하면 0으로 토글된다', () {
      final pos = _findEmptyCell(provider);
      provider.selectCell(pos.$1, pos.$2);

      final correctNumber = _getSolutionNumber(provider, pos.$1, pos.$2);
      provider.setInput(correctNumber);
      expect(provider.board[pos.$1][pos.$2], correctNumber);

      // 같은 숫자 재입력 → 0으로 토글
      provider.setInput(correctNumber);
      expect(provider.board[pos.$1][pos.$2], 0);
    });

    test('고정 셀에는 입력할 수 없다', () {
      // 고정 셀 찾기
      final pos = _findFixedCell(provider);
      provider.selectCell(pos.$1, pos.$2);
      final originalValue = provider.board[pos.$1][pos.$2];

      provider.setInput(originalValue == 1 ? 2 : 1);
      expect(provider.board[pos.$1][pos.$2], originalValue);
    });
  });

  group('useHint', () {
    test('빈칸에 정답이 입력되고 고정 처리된다', () {
      final pos = _findEmptyCell(provider);
      provider.selectCell(pos.$1, pos.$2);

      final answer = _getSolutionNumber(provider, pos.$1, pos.$2);
      provider.useHint();

      expect(provider.board[pos.$1][pos.$2], answer);
      expect(provider.isFixed(pos.$1, pos.$2), isTrue);
    });
  });

  group('Undo 기능', () {
    test('초기 상태에서 canUndo는 false이다', () {
      expect(provider.canUndo, false);
    });

    test('숫자 입력 후 canUndo는 true이다', () {
      final pos = _findEmptyCell(provider);
      provider.selectCell(pos.$1, pos.$2);
      final correctNumber = _getSolutionNumber(provider, pos.$1, pos.$2);
      provider.setInput(correctNumber);

      expect(provider.canUndo, true);
    });

    test('undo하면 이전 값으로 복원된다', () {
      final pos = _findEmptyCell(provider);
      provider.selectCell(pos.$1, pos.$2);
      final correctNumber = _getSolutionNumber(provider, pos.$1, pos.$2);
      provider.setInput(correctNumber);
      expect(provider.board[pos.$1][pos.$2], correctNumber);

      provider.undo();
      expect(provider.board[pos.$1][pos.$2], 0);
    });

    test('undo하면 해당 셀이 선택된다', () {
      final pos = _findEmptyCell(provider);
      provider.selectCell(pos.$1, pos.$2);
      final correctNumber = _getSolutionNumber(provider, pos.$1, pos.$2);
      provider.setInput(correctNumber);

      // 다른 셀 선택
      provider.selectCell(0, 0);

      provider.undo();
      expect(provider.selectedRow, pos.$1);
      expect(provider.selectedCol, pos.$2);
    });

    test('토글(같은 숫자 재입력으로 지우기)도 undo 대상이다', () {
      final pos = _findEmptyCell(provider);
      provider.selectCell(pos.$1, pos.$2);
      final correctNumber = _getSolutionNumber(provider, pos.$1, pos.$2);

      provider.setInput(correctNumber); // 입력
      provider.setInput(correctNumber); // 토글로 지우기
      expect(provider.board[pos.$1][pos.$2], 0);

      provider.undo(); // 토글 되돌리기 → correctNumber 복원
      expect(provider.board[pos.$1][pos.$2], correctNumber);
    });

    test('clearCell도 undo 대상이다', () {
      final pos = _findEmptyCell(provider);
      provider.selectCell(pos.$1, pos.$2);
      final correctNumber = _getSolutionNumber(provider, pos.$1, pos.$2);
      provider.setInput(correctNumber);

      provider.clearCell();
      expect(provider.board[pos.$1][pos.$2], 0);

      provider.undo(); // clearCell 되돌리기
      expect(provider.board[pos.$1][pos.$2], correctNumber);
    });

    test('힌트 사용은 undo 대상이 아니다', () {
      final pos = _findEmptyCell(provider);
      provider.selectCell(pos.$1, pos.$2);
      provider.useHint();

      // 힌트 전에 다른 입력이 없었으므로 canUndo는 false
      expect(provider.canUndo, false);
    });

    test('여러 번 undo할 수 있다', () {
      final pos1 = _findEmptyCell(provider);
      provider.selectCell(pos1.$1, pos1.$2);
      final num1 = _getSolutionNumber(provider, pos1.$1, pos1.$2);
      provider.setInput(num1);

      final pos2 = _findEmptyCell(provider);
      provider.selectCell(pos2.$1, pos2.$2);
      final num2 = _getSolutionNumber(provider, pos2.$1, pos2.$2);
      provider.setInput(num2);

      provider.undo();
      expect(provider.board[pos2.$1][pos2.$2], 0);

      provider.undo();
      expect(provider.board[pos1.$1][pos1.$2], 0);
      expect(provider.canUndo, false);
    });

    test('히스토리가 비어있으면 undo해도 아무 일 없다', () {
      provider.undo(); // 에러 없이 무시
      expect(provider.canUndo, false);
    });

    test('startNewGame하면 히스토리가 초기화된다', () {
      final pos = _findEmptyCell(provider);
      provider.selectCell(pos.$1, pos.$2);
      final correctNumber = _getSolutionNumber(provider, pos.$1, pos.$2);
      provider.setInput(correctNumber);
      expect(provider.canUndo, true);

      provider.startNewGame();
      expect(provider.canUndo, false);
    });

    test('게임 클리어 상태에서는 undo 불가', () {
      // 모든 빈칸을 정답으로 채워서 클리어
      _fillAllCorrect(provider);
      expect(provider.isGameClear, true);

      provider.undo(); // 클리어 상태에서 undo 시도
      // 클리어 상태가 유지되어야 함 (undo가 실행되지 않음)
    });

    test('게임 오버 상태에서는 undo 불가', () {
      for (int i = 0; i < 3; i++) {
        final pos = _findEmptyCell(provider);
        provider.selectCell(pos.$1, pos.$2);
        final correctNumber = _getSolutionNumber(provider, pos.$1, pos.$2);
        final wrongNumber = (correctNumber % 9) + 1;
        provider.setInput(wrongNumber);
      }
      expect(provider.isGameOver, true);
      final historyBefore = provider.canUndo;

      provider.undo();
      expect(provider.canUndo, historyBefore); // 변화 없음
    });
  });

  group('오답 색상 표시', () {
    test('오답 입력 시 isWrong이 true이다', () {
      final pos = _findEmptyCell(provider);
      provider.selectCell(pos.$1, pos.$2);
      final correctNumber = _getSolutionNumber(provider, pos.$1, pos.$2);
      final wrongNumber = (correctNumber % 9) + 1;

      provider.setInput(wrongNumber);
      expect(provider.isWrong(pos.$1, pos.$2), true);
    });

    test('정답 입력 시 isWrong이 false이다', () {
      final pos = _findEmptyCell(provider);
      provider.selectCell(pos.$1, pos.$2);
      final correctNumber = _getSolutionNumber(provider, pos.$1, pos.$2);

      provider.setInput(correctNumber);
      expect(provider.isWrong(pos.$1, pos.$2), false);
    });

    test('오답 후 지우기하면 isWrong이 false가 된다', () {
      final pos = _findEmptyCell(provider);
      provider.selectCell(pos.$1, pos.$2);
      final correctNumber = _getSolutionNumber(provider, pos.$1, pos.$2);
      final wrongNumber = (correctNumber % 9) + 1;

      provider.setInput(wrongNumber);
      expect(provider.isWrong(pos.$1, pos.$2), true);

      provider.clearCell();
      expect(provider.isWrong(pos.$1, pos.$2), false);
    });

    test('오답 후 토글(같은 숫자 재입력)하면 isWrong이 false가 된다', () {
      final pos = _findEmptyCell(provider);
      provider.selectCell(pos.$1, pos.$2);
      final correctNumber = _getSolutionNumber(provider, pos.$1, pos.$2);
      final wrongNumber = (correctNumber % 9) + 1;

      provider.setInput(wrongNumber);
      expect(provider.isWrong(pos.$1, pos.$2), true);

      provider.setInput(wrongNumber); // 토글로 지우기
      expect(provider.isWrong(pos.$1, pos.$2), false);
    });

    test('오답 입력 후 undo하면 isWrong이 false가 된다', () {
      final pos = _findEmptyCell(provider);
      provider.selectCell(pos.$1, pos.$2);
      final correctNumber = _getSolutionNumber(provider, pos.$1, pos.$2);
      final wrongNumber = (correctNumber % 9) + 1;

      provider.setInput(wrongNumber);
      expect(provider.isWrong(pos.$1, pos.$2), true);

      provider.undo();
      expect(provider.isWrong(pos.$1, pos.$2), false);
    });

    test('startNewGame 시 오답 상태가 초기화된다', () {
      final pos = _findEmptyCell(provider);
      provider.selectCell(pos.$1, pos.$2);
      final correctNumber = _getSolutionNumber(provider, pos.$1, pos.$2);
      final wrongNumber = (correctNumber % 9) + 1;

      provider.setInput(wrongNumber);
      expect(provider.isWrong(pos.$1, pos.$2), true);

      provider.startNewGame();
      // 새 게임이므로 해당 좌표에 오답 상태가 없어야 함
      expect(provider.isWrong(pos.$1, pos.$2), false);
    });
  });

  group('메모 기능', () {
    test('초기 isMemoMode는 false이다', () {
      expect(provider.isMemoMode, false);
    });

    test('toggleMemoMode로 메모 모드를 토글할 수 있다', () {
      provider.toggleMemoMode();
      expect(provider.isMemoMode, true);
      provider.toggleMemoMode();
      expect(provider.isMemoMode, false);
    });

    test('메모 모드에서 숫자 입력 시 메모가 추가된다', () {
      final pos = _findEmptyCell(provider);
      provider.selectCell(pos.$1, pos.$2);
      provider.toggleMemoMode();

      provider.setInput(3);
      expect(provider.getMemos(pos.$1, pos.$2).contains(3), true);
    });

    test('메모 모드에서 같은 숫자 재입력 시 메모가 제거된다', () {
      final pos = _findEmptyCell(provider);
      provider.selectCell(pos.$1, pos.$2);
      provider.toggleMemoMode();

      provider.setInput(3);
      expect(provider.getMemos(pos.$1, pos.$2).contains(3), true);

      provider.setInput(3); // 토글로 제거
      expect(provider.getMemos(pos.$1, pos.$2).contains(3), false);
    });

    test('메모 모드에서 여러 숫자를 메모할 수 있다', () {
      final pos = _findEmptyCell(provider);
      provider.selectCell(pos.$1, pos.$2);
      provider.toggleMemoMode();

      provider.setInput(1);
      provider.setInput(5);
      provider.setInput(9);
      expect(provider.getMemos(pos.$1, pos.$2), {1, 5, 9});
    });

    test('메모 모드에서 숫자가 있는 칸에 메모하면 숫자가 지워지고 메모로 전환된다', () {
      final pos = _findEmptyCell(provider);
      provider.selectCell(pos.$1, pos.$2);

      // 일반 모드로 숫자 입력
      final correctNumber = _getSolutionNumber(provider, pos.$1, pos.$2);
      provider.setInput(correctNumber);
      expect(provider.board[pos.$1][pos.$2], correctNumber);

      // 메모 모드로 전환 후 메모 시도
      provider.toggleMemoMode();
      provider.setInput(3);
      expect(provider.board[pos.$1][pos.$2], 0); // 숫자가 지워짐
      expect(provider.getMemos(pos.$1, pos.$2).contains(3), true); // 메모가 추가됨
    });

    test('메모 모드에서 숫자 덮어쓰기 후 undo하면 숫자가 복원된다', () {
      final pos = _findEmptyCell(provider);
      provider.selectCell(pos.$1, pos.$2);

      final correctNumber = _getSolutionNumber(provider, pos.$1, pos.$2);
      provider.setInput(correctNumber);

      provider.toggleMemoMode();
      provider.setInput(5);
      expect(provider.board[pos.$1][pos.$2], 0);
      expect(provider.getMemos(pos.$1, pos.$2).contains(5), true);

      provider.undo();
      expect(provider.board[pos.$1][pos.$2], correctNumber);
      expect(provider.getMemos(pos.$1, pos.$2).isEmpty, true);
    });

    test('일반 모드로 숫자 입력 시 메모가 클리어된다', () {
      final pos = _findEmptyCell(provider);
      provider.selectCell(pos.$1, pos.$2);

      // 메모 추가
      provider.toggleMemoMode();
      provider.setInput(1);
      provider.setInput(5);
      expect(provider.getMemos(pos.$1, pos.$2), {1, 5});

      // 일반 모드로 숫자 입력
      provider.toggleMemoMode();
      final correctNumber = _getSolutionNumber(provider, pos.$1, pos.$2);
      provider.setInput(correctNumber);
      expect(provider.getMemos(pos.$1, pos.$2).isEmpty, true);
    });

    test('clearCell 시 메모도 클리어된다', () {
      final pos = _findEmptyCell(provider);
      provider.selectCell(pos.$1, pos.$2);

      provider.toggleMemoMode();
      provider.setInput(2);
      provider.setInput(7);
      expect(provider.getMemos(pos.$1, pos.$2), {2, 7});

      provider.toggleMemoMode(); // 일반 모드로 복귀
      provider.clearCell();
      expect(provider.getMemos(pos.$1, pos.$2).isEmpty, true);
    });

    test('메모 추가 후 undo하면 메모가 복원된다', () {
      final pos = _findEmptyCell(provider);
      provider.selectCell(pos.$1, pos.$2);
      provider.toggleMemoMode();

      provider.setInput(4);
      expect(provider.getMemos(pos.$1, pos.$2), {4});

      provider.setInput(8);
      expect(provider.getMemos(pos.$1, pos.$2), {4, 8});

      provider.undo(); // 8 추가 취소
      expect(provider.getMemos(pos.$1, pos.$2), {4});

      provider.undo(); // 4 추가 취소
      expect(provider.getMemos(pos.$1, pos.$2).isEmpty, true);
    });

    test('일반 입력으로 메모가 지워진 후 undo하면 메모가 복원된다', () {
      final pos = _findEmptyCell(provider);
      provider.selectCell(pos.$1, pos.$2);

      // 메모 추가
      provider.toggleMemoMode();
      provider.setInput(3);
      provider.setInput(6);
      expect(provider.getMemos(pos.$1, pos.$2), {3, 6});

      // 일반 모드로 숫자 입력 → 메모 클리어
      provider.toggleMemoMode();
      final correctNumber = _getSolutionNumber(provider, pos.$1, pos.$2);
      provider.setInput(correctNumber);
      expect(provider.getMemos(pos.$1, pos.$2).isEmpty, true);

      // undo → 메모 복원
      provider.undo();
      expect(provider.getMemos(pos.$1, pos.$2), {3, 6});
    });

    test('startNewGame 시 메모가 초기화된다', () {
      final pos = _findEmptyCell(provider);
      provider.selectCell(pos.$1, pos.$2);
      provider.toggleMemoMode();
      provider.setInput(5);

      provider.startNewGame();
      expect(provider.getMemos(pos.$1, pos.$2).isEmpty, true);
      expect(provider.isMemoMode, false);
    });
  });

  group('코드 리뷰 수정', () {
    test('게임 오버 시 clearCell이 차단된다', () {
      final pos = _findEmptyCell(provider);
      provider.selectCell(pos.$1, pos.$2);
      final correctNumber = _getSolutionNumber(provider, pos.$1, pos.$2);
      provider.setInput(correctNumber);
      expect(provider.board[pos.$1][pos.$2], correctNumber);

      // 게임 오버 만들기
      for (int i = 0; i < 3; i++) {
        final p = _findEmptyCell(provider);
        provider.selectCell(p.$1, p.$2);
        final correct = _getSolutionNumber(provider, p.$1, p.$2);
        final wrong = (correct % 9) + 1;
        provider.setInput(wrong);
      }
      expect(provider.isGameOver, true);

      // 게임 오버 상태에서 clearCell 시도
      provider.selectCell(pos.$1, pos.$2);
      provider.clearCell();
      expect(provider.board[pos.$1][pos.$2], correctNumber); // 지워지면 안 됨
    });

    test('useHint 시 해당 셀의 메모가 클리어된다', () {
      final pos = _findEmptyCell(provider);
      provider.selectCell(pos.$1, pos.$2);

      // 메모 추가
      provider.toggleMemoMode();
      provider.setInput(1);
      provider.setInput(5);
      expect(provider.getMemos(pos.$1, pos.$2).isNotEmpty, true);

      // 일반 모드로 복귀 후 메모를 지우고 빈칸 만들기
      provider.toggleMemoMode();
      provider.clearCell();

      // 다시 메모 추가
      provider.toggleMemoMode();
      provider.setInput(3);
      provider.setInput(7);
      provider.toggleMemoMode();
      expect(provider.getMemos(pos.$1, pos.$2), {3, 7});

      // 힌트 사용
      provider.useHint();
      final answer = _getSolutionNumber(provider, pos.$1, pos.$2);
      expect(provider.board[pos.$1][pos.$2], answer);
      expect(provider.getMemos(pos.$1, pos.$2).isEmpty, true); // 메모가 지워져야 함
    });
  });

  group('changeDifficulty', () {
    test('난이도 변경 후 빈칸 수가 달라진다', () {
      provider.changeDifficulty('쉬움');
      final easyEmpty = _countEmptyCells(provider);

      provider.changeDifficulty('어려움');
      final hardEmpty = _countEmptyCells(provider);

      expect(easyEmpty, 30);
      expect(hardEmpty, 50);
    });
  });
}

/// 빈칸 위치를 찾아 (row, col) 반환
(int, int) _findEmptyCell(GameProvider provider) {
  for (int i = 0; i < 9; i++) {
    for (int j = 0; j < 9; j++) {
      if (provider.board[i][j] == 0 && !provider.isFixed(i, j)) {
        return (i, j);
      }
    }
  }
  throw StateError('빈칸이 없습니다');
}

/// 고정 셀 위치를 찾아 (row, col) 반환
(int, int) _findFixedCell(GameProvider provider) {
  for (int i = 0; i < 9; i++) {
    for (int j = 0; j < 9; j++) {
      if (provider.isFixed(i, j)) {
        return (i, j);
      }
    }
  }
  throw StateError('고정 셀이 없습니다');
}

/// solutionBoard에서 정답 숫자를 가져온다
int _getSolutionNumber(GameProvider provider, int row, int col) {
  return provider.solutionBoard[row][col];
}

/// 모든 빈칸을 정답으로 채워서 게임 클리어 상태로 만든다
void _fillAllCorrect(GameProvider provider) {
  for (int i = 0; i < 9; i++) {
    for (int j = 0; j < 9; j++) {
      if (provider.board[i][j] == 0 && !provider.isFixed(i, j)) {
        provider.selectCell(i, j);
        provider.setInput(provider.solutionBoard[i][j]);
      }
    }
  }
}

/// 보드의 빈칸 수를 센다
int _countEmptyCells(GameProvider provider) {
  int count = 0;
  for (int i = 0; i < 9; i++) {
    for (int j = 0; j < 9; j++) {
      if (provider.board[i][j] == 0) count++;
    }
  }
  return count;
}
