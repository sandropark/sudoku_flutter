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
