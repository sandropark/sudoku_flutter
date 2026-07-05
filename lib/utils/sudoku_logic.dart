/// 스도쿠 게임의 모든 두뇌(로직)를 담당하는 클래스입니다.
/// 화면(UI)과는 분리되어 오직 9x9의 숫자 데이터만 다룹니다.
class SudokuLogic {
  // 9x9 스도쿠 보드판 데이터를 담을 2차원 리스트입니다.
  // 0은 '빈칸'을 의미하고, 1~9는 채워진 숫자를 의미합니다.
  late List<List<int>> board;

  // 사용자가 지울 수 없는 '원래 문제(고정된 숫자)'인지 기억해두는 2차원 리스트입니다.
  // true면 고정된 숫자(기본 문제), false면 사용자가 나중에 적은 숫자입니다.
  late List<List<bool>> isFixedBoard;

  // 힌트 기능을 위해, 완성된 정답을 따로 보관해두는 보드입니다.
  late List<List<int>> solutionBoard;


  SudokuLogic() {
    // 클래스가 처음 생성될 때, 9x9 보드를 새로 만들고 0으로 가득 채웁니다.
    _initializeEmptyBoard();
  }

  /// 1. 보드판을 모두 0(빈칸)으로 초기화하는 함수
  void _initializeEmptyBoard() {
    // List.generate를 써서 길이가 9이고, 안에는 또 [0,0,0...] 이 9개 있는 구조를 만듭니다.
    board = List.generate(9, (_) => List.filled(9, 0));
    isFixedBoard = List.generate(9, (_) => List.filled(9, false)); // 처음엔 모두 false로 시작
  }

  /// 2. 새 스도쿠 게임을 시작할 때 부르는 메인 함수
  /// 완전한 답안지를 만들고 -> 적당히 구멍을 뚫어서 문제를 출제합니다.
  void generateNewGame({int emptySpaces = 40}) {
    _initializeEmptyBoard();
    
    // (1) 1행 1열부터 시작해서 스도쿠 규칙에 맞게 숫자를 꽉꽉 채워 넣습니다.
    _fillBoard(0, 0);

    // (1.5) 힌트 기능을 위해 지금 꽉 찬 정답을 따로 복사해둡니다!
    solutionBoard = List.generate(9, (i) => List.from(board[i]));
    
    // (2) 꽉 찬 답안지가 완성되면, 무작위로 구멍을 송송 뚫어서 사용자에게 낼 문제를 완성합니다!
    _removeNumbers(emptySpaces);

    // (3) 구멍 뚫기까지 끝난 현재 보드판 상태를 보고, 0(빈칸)이 아닌 숫자들은 
    // 사용자가 지울 수 없는 '고정된 문제 정답'으로 못을 박습니다. (isFixed를 true로 변경)
    for (int i = 0; i < 9; i++) {
      for (int j = 0; j < 9; j++) {
        if (board[i][j] != 0) {
          isFixedBoard[i][j] = true;
        }
      }
    }
  }

  /// 3. 특정 칸(row, col)에 들어간 숫자가 스도쿠 규칙을 어기지 않는지 '검사'하는 아주 중요한 함수!
  /// (현재 게임 보드 `board`를 기준으로 검사합니다.)
  bool isValid(int row, int col, int num) => _isValidOn(board, row, col, num);

  /// 임의의 보드 `b`에서 (row, col)에 num을 넣어도 규칙 위반이 없는지 검사합니다.
  /// (isValid와 해 개수 카운터가 공유하는 순수 검사 로직)
  static bool _isValidOn(List<List<int>> b, int row, int col, int num) {
    // [검사 1] 가로줄(row)에 똑같은 숫자가 있는가?
    for (int i = 0; i < 9; i++) {
      if (b[row][i] == num) return false; // 규칙 위반!
    }

    // [검사 2] 세로줄(col)에 똑같은 숫자가 있는가?
    for (int i = 0; i < 9; i++) {
      if (b[i][col] == num) return false; // 규칙 위반!
    }

    // [검사 3] 3x3 작은 네모 박스 안에 똑같은 숫자가 있는가?
    // 이 구역의 시작 좌표(왼쪽 위 모서리)를 계산하는 공식입니다. (예: 4 // 3 * 3 = 3)
    final startRow = (row ~/ 3) * 3;
    final startCol = (col ~/ 3) * 3;
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        if (b[startRow + i][startCol + j] == num) return false; // 규칙 위반!
      }
    }

    // 3가지 검사를 무사히 통과했다면? 통과!
    return true;
  }

  /// 보드 `b`의 해(solution) 개수를 세되, `limit`개에 도달하면 즉시 중단합니다.
  /// 유일해 검사에는 limit=2로 호출해서 "해가 정확히 1개인지"만 빠르게 판별합니다.
  static int _countSolutions(List<List<int>> b, int limit) {
    // 첫 번째 빈칸을 찾습니다.
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (b[r][c] == 0) {
          int total = 0;
          for (int num = 1; num <= 9; num++) {
            if (_isValidOn(b, r, c, num)) {
              b[r][c] = num;
              total += _countSolutions(b, limit);
              b[r][c] = 0; // 원복(백트래킹)
              if (total >= limit) return total; // 조기 종료
            }
          }
          return total; // 이 칸에 넣을 수 있는 숫자를 다 시도함
        }
      }
    }
    // 빈칸이 하나도 없다 = 보드가 완성됨 = 해 1개 발견
    return 1;
  }

  /// 4. 보드를 규칙에 맞게 꽉 채워주는 재귀 함수 (백트래킹 알고리즘)
  /// 빈칸을 만나면 1부터 9까지 하나씩 넣어보고, 다음 칸으로 넘어갑니다.
  /// 만약 막히면 뒤로 돌아가서(Backtrack) 다른 숫자를 넣어봅니다.
  bool _fillBoard(int row, int col) {
    // 만약 9번째 줄(인덱스 9)까지 다 채웠다면? 끝까지 도달했으므로 성공(true)입니다.
    if (row == 9) return true;

    // 현재 줄의 마지막 칸(인덱스 8)까지 채웠다면? 
    // 다음 줄(row + 1)의 첫 번째 칸(col = 0)으로 넘어갑니다.
    if (col == 9) return _fillBoard(row + 1, 0);

    // 이미 숫자가 채워진 칸이라면 스킵하고 다음 칸으로 넘어갑니다.
    if (board[row][col] != 0) return _fillBoard(row, col + 1);

    // 랜덤하게 숫자를 섞어서 넣어봅니다. 안 섞으면 맨날 같은 스도쿠만 나와요!
    List<int> numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9];
    numbers.shuffle(); // 숫자를 쉐킷쉐킷 섞습니다.

    // 섞어둔 1~9 사이의 숫자를 하나씩 꺼내서 넣어봅니다.
    for (int num in numbers) {
      // 그 숫자를 넣어도 규칙에 어긋나지 않는지(isValid) 물어봅니다.
      if (isValid(row, col, num)) {
        board[row][col] = num; // 통과면 숫자를 써넣습니다.

        // 그리고 다음 칸(_fillBoard)으로 떠넘깁니다.
        // 다음 칸들도 무사히 다 채웠다면 최종적으로 true를 반환하며 끝납니다!
        if (_fillBoard(row, col + 1)) return true;

        // 만약 다음 칸에서 "저 더 이상 넣을 숫자가 없어요!" 하고 막혔다면(false가 돌아오면)?
        // 내가 넣었던 숫자가 틀렸다는 뜻이므로 지우개로 지워버립니다 (0으로 만듦).
        board[row][col] = 0;
      }
    }

    // 1부터 9까지 다 넣어봤는데도 안 된다면? 나도 실패!(false 반환) 이전 칸으로 되돌아갑니다.
    return false;
  }

  /// 5. 랜덤하게 칸을 0(빈칸)으로 만들어서 문제를 출제하는 함수
  /// 전체 좌표를 셔플한 뒤, 칸을 하나씩 지울 때마다 "해가 여전히 유일한지"를 검사합니다.
  /// 유일해가 유지될 때만 제거를 확정하므로, 규칙상 유효한 다른 답이 오답 처리되는 문제를 방지합니다.
  /// (유일해를 지키면서 목표 빈칸 수에 도달하지 못하면, 도달 가능한 만큼만 제거합니다.)
  void _removeNumbers(int emptySpaces) {
    final positions = [
      for (int i = 0; i < 9; i++)
        for (int j = 0; j < 9; j++) (i, j),
    ]..shuffle();

    int removed = 0;
    for (final (row, col) in positions) {
      if (removed >= emptySpaces) break;

      final backup = board[row][col];
      board[row][col] = 0;

      // 지운 상태의 보드를 복사해 해가 유일한지(정확히 1개) 검사합니다.
      final copy = [for (final r in board) List<int>.from(r)];
      if (_countSolutions(copy, 2) == 1) {
        removed++; // 유일해 유지 → 제거 확정
      } else {
        board[row][col] = backup; // 유일해가 깨지면 원복
      }
    }
  }

  /// 6. 특정 칸에 입력한 숫자가 정답인지 확인하는 함수
  bool isCorrect(int row, int col, int number) {
    return solutionBoard[row][col] == number;
  }

  /// 7. (보너스) 게임을 클리어했는지 확인하는 함수!
  /// solutionBoard와 직접 비교하여 모든 칸이 일치하면 클리어!
  bool isSolved() {
    for (int i = 0; i < 9; i++) {
      for (int j = 0; j < 9; j++) {
        if (board[i][j] != solutionBoard[i][j]) return false;
      }
    }
    return true;
  }

  /// 8. 현재 문제 보드(board)의 해가 유일한지 여부. (생성기 유일해 보장 검증용)
  bool get hasUniqueSolution {
    final copy = [for (final r in board) List<int>.from(r)];
    // 이미 채워진 칸이 규칙을 위반하면 유효한 해가 없으므로 유일하지 않다.
    // (_countSolutions는 성능을 위해 초기 단서의 유효성을 검사하지 않으므로 여기서 방어)
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        final v = copy[r][c];
        if (v != 0) {
          copy[r][c] = 0; // 자기 자신을 제외하고 검사
          final ok = _isValidOn(copy, r, c, v);
          copy[r][c] = v;
          if (!ok) return false;
        }
      }
    }
    return _countSolutions(copy, 2) == 1;
  }
}
