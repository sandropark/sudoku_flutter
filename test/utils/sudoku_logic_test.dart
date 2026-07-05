import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku/utils/sudoku_logic.dart';

void main() {
  late SudokuLogic logic;

  setUp(() {
    logic = SudokuLogic();
    logic.generateNewGame(emptySpaces: 40);
  });

  group('generateNewGame', () {
    test('지정한 수만큼 빈칸이 생성된다', () {
      logic.generateNewGame(emptySpaces: 30);
      int emptyCount = 0;
      for (int i = 0; i < 9; i++) {
        for (int j = 0; j < 9; j++) {
          if (logic.board[i][j] == 0) emptyCount++;
        }
      }
      expect(emptyCount, 30);
    });

    test('빈칸이 아닌 셀은 isFixed가 true이다', () {
      for (int i = 0; i < 9; i++) {
        for (int j = 0; j < 9; j++) {
          if (logic.board[i][j] != 0) {
            expect(logic.isFixedBoard[i][j], isTrue);
          } else {
            expect(logic.isFixedBoard[i][j], isFalse);
          }
        }
      }
    });
  });

  group('유일해 보장', () {
    // 생성기와 무관한 고정 정답 보드 (해-카운터 독립 검증용 오라클)
    const solvedBoard = [
      [5, 3, 4, 6, 7, 8, 9, 1, 2],
      [6, 7, 2, 1, 9, 5, 3, 4, 8],
      [1, 9, 8, 3, 4, 2, 5, 6, 7],
      [8, 5, 9, 7, 6, 1, 4, 2, 3],
      [4, 2, 6, 8, 5, 3, 7, 9, 1],
      [7, 1, 3, 9, 2, 4, 8, 5, 6],
      [9, 6, 1, 5, 3, 7, 2, 8, 4],
      [2, 8, 7, 4, 1, 9, 6, 3, 5],
      [3, 4, 5, 2, 8, 6, 1, 7, 9],
    ];

    test('한 칸만 비운 유효한 보드는 유일해(true)로 판정된다', () {
      // 빈칸이 있어 실제 백트래킹 솔버 경로를 타는 독립 검증
      // (항상 2 이상을 반환하는 카운터 버그를 잡는다)
      final b = [for (final r in solvedBoard) List<int>.from(r)];
      b[4][4] = 0;
      logic.board = b;
      expect(logic.hasUniqueSolution, isTrue);
    });

    test('빈 보드(모두 0)는 복수해(false)로 판정된다', () {
      // 해-카운터가 항상 1을 반환하는 버그를 잡는 독립 검증
      logic.board = List.generate(9, (_) => List.filled(9, 0));
      expect(logic.hasUniqueSolution, isFalse);
    });

    test('규칙을 위반한 완성 보드는 유일해가 아니다(false)', () {
      // 채워진 단서 자체가 모순이면 유효한 해가 없으므로 false여야 한다
      final b = [for (final r in solvedBoard) List<int>.from(r)];
      b[0][0] = b[0][1]; // 같은 행에 중복 생성 → 규칙 위반
      logic.board = b;
      expect(logic.hasUniqueSolution, isFalse);
    });

    test('생성된 퍼즐은 난이도와 무관하게 유일해를 가진다', () {
      for (final empty in [30, 40, 50]) {
        for (int trial = 0; trial < 5; trial++) {
          logic.generateNewGame(emptySpaces: empty);
          expect(logic.hasUniqueSolution, isTrue,
              reason: 'emptySpaces=$empty 에서 복수해 퍼즐이 생성됨');
        }
      }
    });

    test('solutionBoard는 스도쿠 규칙을 만족하는 완전한 해다', () {
      logic.generateNewGame(emptySpaces: 45);
      final s = logic.solutionBoard;

      // (1) 문제(고정 셀)가 solutionBoard와 모순되지 않는지
      for (int i = 0; i < 9; i++) {
        for (int j = 0; j < 9; j++) {
          if (logic.board[i][j] != 0) {
            expect(logic.board[i][j], s[i][j]);
          }
        }
      }

      // (2) 모든 행/열/3x3 박스가 1~9를 정확히 한 번씩 포함하는지
      for (int i = 0; i < 9; i++) {
        final row = <int>{}, col = <int>{}, box = <int>{};
        for (int j = 0; j < 9; j++) {
          row.add(s[i][j]);
          col.add(s[j][i]);
          box.add(s[(i ~/ 3) * 3 + j ~/ 3][(i % 3) * 3 + j % 3]);
        }
        expect(row, {1, 2, 3, 4, 5, 6, 7, 8, 9}, reason: '$i행 위반');
        expect(col, {1, 2, 3, 4, 5, 6, 7, 8, 9}, reason: '$i열 위반');
        expect(box, {1, 2, 3, 4, 5, 6, 7, 8, 9}, reason: '$i박스 위반');
      }
    });
  });

  group('isSolved', () {
    test('완성된 보드에서 true를 반환한다', () {
      // 모든 빈칸을 정답으로 채우기
      for (int i = 0; i < 9; i++) {
        for (int j = 0; j < 9; j++) {
          logic.board[i][j] = logic.solutionBoard[i][j];
        }
      }
      expect(logic.isSolved(), isTrue);
    });

    test('빈칸이 있으면 false를 반환한다', () {
      expect(logic.isSolved(), isFalse);
    });
  });

  group('isValid', () {
    test('같은 행에 중복 숫자가 있으면 false를 반환한다', () {
      // 빈 보드에서 테스트
      logic.board = List.generate(9, (_) => List.filled(9, 0));
      logic.board[0][0] = 5;
      expect(logic.isValid(0, 3, 5), isFalse);
    });

    test('같은 열에 중복 숫자가 있으면 false를 반환한다', () {
      logic.board = List.generate(9, (_) => List.filled(9, 0));
      logic.board[0][0] = 5;
      expect(logic.isValid(3, 0, 5), isFalse);
    });

    test('같은 3x3 박스에 중복 숫자가 있으면 false를 반환한다', () {
      logic.board = List.generate(9, (_) => List.filled(9, 0));
      logic.board[0][0] = 5;
      expect(logic.isValid(1, 1, 5), isFalse);
    });

    test('규칙 위반이 없으면 true를 반환한다', () {
      logic.board = List.generate(9, (_) => List.filled(9, 0));
      logic.board[0][0] = 5;
      // 다른 행, 다른 열, 다른 박스
      expect(logic.isValid(3, 3, 5), isTrue);
    });
  });

  group('isCorrect', () {
    test('정답과 일치하는 숫자를 입력하면 true를 반환한다', () {
      int? emptyRow, emptyCol;
      for (int i = 0; i < 9 && emptyRow == null; i++) {
        for (int j = 0; j < 9; j++) {
          if (logic.board[i][j] == 0) {
            emptyRow = i;
            emptyCol = j;
            break;
          }
        }
      }

      expect(emptyRow, isNotNull);
      final correctNumber = logic.solutionBoard[emptyRow!][emptyCol!];
      expect(logic.isCorrect(emptyRow, emptyCol, correctNumber), isTrue);
    });

    test('정답과 다른 숫자를 입력하면 false를 반환한다', () {
      int? emptyRow, emptyCol;
      for (int i = 0; i < 9 && emptyRow == null; i++) {
        for (int j = 0; j < 9; j++) {
          if (logic.board[i][j] == 0) {
            emptyRow = i;
            emptyCol = j;
            break;
          }
        }
      }

      expect(emptyRow, isNotNull);
      final correctNumber = logic.solutionBoard[emptyRow!][emptyCol!];
      final wrongNumber = (correctNumber % 9) + 1;
      expect(logic.isCorrect(emptyRow, emptyCol, wrongNumber), isFalse);
    });
  });
}
