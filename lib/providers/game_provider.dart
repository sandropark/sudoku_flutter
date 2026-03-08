import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/sudoku_logic.dart';

class _BoardMove {
  final int row;
  final int col;
  final int previousValue;
  final Set<int> previousMemos;
  final List<(int, int)> removedMemoCells; // 자동 제거된 메모 셀 좌표
  final int removedMemoNumber; // 자동 제거된 메모 숫자
  _BoardMove(this.row, this.col, this.previousValue, this.previousMemos,
      {this.removedMemoCells = const [], this.removedMemoNumber = 0});

  Map<String, dynamic> toJson() => {
        'row': row,
        'col': col,
        'previousValue': previousValue,
        'previousMemos': previousMemos.toList(),
        'removedMemoCells':
            removedMemoCells.map((e) => [e.$1, e.$2]).toList(),
        'removedMemoNumber': removedMemoNumber,
      };

  static _BoardMove fromJson(Map<String, dynamic> json) => _BoardMove(
        json['row'] as int,
        json['col'] as int,
        json['previousValue'] as int,
        Set<int>.from(json['previousMemos'] as List),
        removedMemoCells: (json['removedMemoCells'] as List)
            .map((e) => (e[0] as int, e[1] as int))
            .toList(),
        removedMemoNumber: json['removedMemoNumber'] as int,
      );
}

// Provider를 사용하기 위해 ChangeNotifier를 상속받습니다.
// 이 클래스 안에서 데이터가 바뀌고 notifyListeners()를 부르면 화면이 알아서 다시 그려집니다.
class GameProvider extends ChangeNotifier {
  late SudokuLogic _logic;

  // ===== Undo 히스토리 =====
  final List<_BoardMove> _history = [];
  bool get canUndo => _history.isNotEmpty;

  // 사용자가 화면에서 터치한 '현재 선택된 칸'의 위치 (row, col)
  int? selectedRow;
  int? selectedCol;

  // ===== 타이머 관련 변수 =====
  Timer? _timer; // Dart에서 제공하는 반복 실행 도구입니다.
  int elapsedSeconds = 0; // 게임 시작 후 흐른 초(秒)
  bool isGameClear = false; // 게임을 클리어했는지 여부

  // ===== Life 관련 변수 =====
  int _remainingLives = 3;
  bool _isGameOver = false;

  int get remainingLives => _remainingLives;
  bool get isGameOver => _isGameOver;

  // ===== 저장된 게임 유무 =====
  bool _hasSavedGame = false;
  bool get hasSavedGame => _hasSavedGame;

  // ===== 오답 추적 =====
  final Set<(int, int)> _wrongCells = {};
  bool isWrong(int row, int col) => _wrongCells.contains((row, col));

  // ===== 메모 기능 =====
  late List<List<Set<int>>> _memos;
  bool isMemoMode = false;
  Set<int> getMemos(int row, int col) => Set.unmodifiable(_memos[row][col]);

  void toggleMemoMode() {
    isMemoMode = !isMemoMode;
    notifyListeners();
  }

  static List<List<Set<int>>> _createEmptyMemos() =>
      List.generate(9, (_) => List.generate(9, (_) => <int>{}));

  // ===== 난이도 관련 변수 =====
  // '쉬움', '보통', '어려움' 중 하나를 저장합니다.
  String difficulty = '보통';

  GameProvider() {
    _logic = SudokuLogic();
    _memos = _createEmptyMemos();
  }

  // 밖에서 보드판 데이터(`_logic.board`)를 읽어갈 수 있게 해주는 '보여주기용' 변수입니다.
  List<List<int>> get board => _logic.board;

  // 정답 보드 (정답 확인용)
  List<List<int>> get solutionBoard => _logic.solutionBoard;

  // 특정 칸이 원래 문제로 고정된 숫자인지 알려주는 함수
  bool isFixed(int row, int col) => _logic.isFixedBoard[row][col];

  // 타이머에 표시할 시간을 "분:초" 형식으로 만들어주는 변환기
  String get timerText {
    int minutes = elapsedSeconds ~/ 60;
    int seconds = elapsedSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // 새 스도쿠 게임을 시작하는 함수
  void startNewGame() {
    // 난이도에 따라 빈칸 수를 다르게 설정
    int emptySpaces;
    switch (difficulty) {
      case '쉬움':
        emptySpaces = 30;
        break;
      case '어려움':
        emptySpaces = 50;
        break;
      default: // 보통
        emptySpaces = 40;
    }
    _logic.generateNewGame(emptySpaces: emptySpaces);

    selectedRow = null;
    selectedCol = null;
    isGameClear = false;
    _history.clear();
    _remainingLives = 3;
    _isGameOver = false;
    _wrongCells.clear();
    _memos = _createEmptyMemos();
    isMemoMode = false;

    // 타이머 초기화 및 재시작
    _stopTimer();
    elapsedSeconds = 0;
    _startTimer();

    unawaited(_saveGame());
    notifyListeners();
  }

  // 난이도를 변경하고 새 게임을 시작하는 함수
  void changeDifficulty(String newDifficulty) {
    difficulty = newDifficulty;
    startNewGame();
  }

  // 타이머 시작: 1초마다 elapsedSeconds를 1씩 올리고 화면을 새로고침합니다.
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!isGameClear) {
        elapsedSeconds++;
        if (elapsedSeconds % 5 == 0) unawaited(_saveGame());
        notifyListeners(); // 매 초마다 화면에 시간이 업데이트됩니다.
      }
    });
  }

  // 타이머 정지
  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  // 타이머 재개 (홈 화면에서 게임 화면으로 이동 시 사용)
  void resumeTimer() {
    _stopTimer();
    _startTimer();
  }

  // 스도쿠 보드판에서 특정 칸(row, col)을 터치했을 때 실행되는 함수
  void selectCell(int row, int col) {
    selectedRow = row;
    selectedCol = col;
    notifyListeners();
  }

  // 사용자가 하단 키패드에서 숫자 버튼(1~9)을 눌렀을 때 실행되는 함수
  void setInput(int number) {
    if (selectedRow == null || selectedCol == null) return;
    if (isFixed(selectedRow!, selectedCol!)) return;
    if (isGameClear) return; // 이미 클리어했으면 더 이상 입력 불가
    if (_isGameOver) return; // 게임 오버면 입력 불가

    final row = selectedRow!;
    final col = selectedCol!;

    // 메모 모드: 숫자가 있으면 지우고 메모로 전환
    if (isMemoMode) {
      final previousValue = _logic.board[row][col];
      final prevMemos = Set<int>.from(_memos[row][col]);
      _history.add(_BoardMove(row, col, previousValue, prevMemos));
      if (previousValue != 0) {
        _logic.board[row][col] = 0;
        _wrongCells.remove((row, col));
      }
      if (_memos[row][col].contains(number)) {
        _memos[row][col].remove(number);
      } else {
        _memos[row][col].add(number);
      }
      notifyListeners();
      unawaited(_saveGame());
      return;
    }

    // 일반 모드
    final previousValue = _logic.board[row][col];
    final prevMemos = Set<int>.from(_memos[row][col]);

    // 토글: 같은 숫자를 다시 누르면 지우기
    if (previousValue == number) {
      _history.add(_BoardMove(row, col, previousValue, prevMemos));
      _logic.board[row][col] = 0;
      _wrongCells.remove((row, col));
      notifyListeners();
      unawaited(_saveGame());
      return;
    }

    _logic.board[row][col] = number;
    _memos[row][col].clear(); // 숫자 입력 시 메모 클리어

    // 같은 줄, 같은 열, 같은 3x3 블록의 메모에서 해당 숫자 제거
    final removedCells = _removeNumberFromRelatedMemos(row, col, number);
    _history.add(_BoardMove(row, col, previousValue, prevMemos,
        removedMemoCells: removedCells, removedMemoNumber: number));

    // 정답 확인: 틀리면 life 차감 + 오답 표시
    if (!_logic.isCorrect(row, col, number)) {
      _wrongCells.add((row, col));
      _remainingLives--;
      if (_remainingLives <= 0) {
        _isGameOver = true;
        _stopTimer();
      }
    } else {
      _wrongCells.remove((row, col));
    }

    // 만약 방금 넣은 숫자로 인해 스도쿠가 끝났다면?
    if (_logic.isSolved()) {
      isGameClear = true;
      _stopTimer(); // 타이머도 멈춥니다!
    }

    notifyListeners();
    unawaited(_saveGame());
  }

  // 사용자가 하단 키패드에서 '지우기' 버튼을 눌렀을 때 실행되는 함수
  void clearCell() {
    if (selectedRow == null || selectedCol == null) return;
    if (isFixed(selectedRow!, selectedCol!)) return;
    if (isGameClear) return;
    if (_isGameOver) return;

    final row = selectedRow!;
    final col = selectedCol!;
    final currentValue = _logic.board[row][col];
    final currentMemos = _memos[row][col];

    // 숫자도 없고 메모도 없으면 아무것도 하지 않음
    if (currentValue == 0 && currentMemos.isEmpty) return;

    final prevMemos = Set<int>.from(currentMemos);
    _history.add(_BoardMove(row, col, currentValue, prevMemos));
    _logic.board[row][col] = 0;
    _memos[row][col].clear();
    _wrongCells.remove((row, col));
    notifyListeners();
    unawaited(_saveGame());
  }

  // Undo: 마지막 입력/지우기 동작을 되돌린다
  void undo() {
    if (_history.isEmpty) return;
    if (isGameClear) return;
    if (_isGameOver) return;

    final move = _history.removeLast();
    _logic.board[move.row][move.col] = move.previousValue;
    _memos[move.row][move.col] = Set<int>.from(move.previousMemos);
    // 자동 제거된 메모 복원
    for (final (r, c) in move.removedMemoCells) {
      _memos[r][c].add(move.removedMemoNumber);
    }
    // undo 후 오답 상태 재계산
    if (move.previousValue != 0 &&
        !_logic.isCorrect(move.row, move.col, move.previousValue)) {
      _wrongCells.add((move.row, move.col));
    } else {
      _wrongCells.remove((move.row, move.col));
    }
    selectedRow = move.row;
    selectedCol = move.col;
    notifyListeners();
    unawaited(_saveGame());
  }

  // 같은 줄, 같은 열, 같은 3x3 블록의 메모에서 해당 숫자를 제거하고, 제거된 셀 목록 반환
  List<(int, int)> _removeNumberFromRelatedMemos(int row, int col, int number) {
    final removed = <(int, int)>[];
    final boxStartRow = (row ~/ 3) * 3;
    final boxStartCol = (col ~/ 3) * 3;
    for (int i = 0; i < 9; i++) {
      if (_memos[row][i].remove(number)) removed.add((row, i));
      if (_memos[i][col].remove(number)) removed.add((i, col));
    }
    for (int r = boxStartRow; r < boxStartRow + 3; r++) {
      for (int c = boxStartCol; c < boxStartCol + 3; c++) {
        if (_memos[r][c].remove(number)) removed.add((r, c));
      }
    }
    return removed;
  }

  // 진행률: 빈칸 중 채워진 비율 (0.0 ~ 1.0)
  double get progress {
    int filled = 0;
    int total = 0;
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (!_logic.isFixedBoard[r][c]) {
          total++;
          if (_logic.board[r][c] != 0) filled++;
        }
      }
    }
    return total == 0 ? 1.0 : filled / total;
  }

  // 보드판 전체에서 특정 숫자(1~9)가 몇 개나 들어가 있는지 세는 함수
  // 9개가 다 채워졌다면 그 숫자 버튼은 비활성화해야 합니다!
  int numberCount(int number) {
    int count = 0;
    for (int i = 0; i < 9; i++) {
      for (int j = 0; j < 9; j++) {
        if (_logic.board[i][j] == number) count++;
      }
    }
    return count;
  }

  // 힌트 기능: 현재 선택된 빈칸에 정답 숫자를 알려줍니다.
  void useHint() {
    if (selectedRow == null || selectedCol == null) return;
    if (isFixed(selectedRow!, selectedCol!)) return;
    if (isGameClear) return;
    if (_logic.board[selectedRow!][selectedCol!] != 0) return; // 이미 숫자가 있으면 무시

    // 정답 보드에서 해당 칸의 정답을 가져와서 넣어줍니다.
    int answer = _logic.solutionBoard[selectedRow!][selectedCol!];
    _logic.board[selectedRow!][selectedCol!] = answer;
    _memos[selectedRow!][selectedCol!].clear();
    _removeNumberFromRelatedMemos(selectedRow!, selectedCol!, answer);

    // 힌트로 넣은 숫자도 고정 처리해서 지울 수 없게 만듭니다.
    _logic.isFixedBoard[selectedRow!][selectedCol!] = true;

    if (_logic.isSolved()) {
      isGameClear = true;
      _stopTimer();
    }

    notifyListeners();
    unawaited(_saveGame());
  }

  // ===== 이어하기 (저장/복원) =====

  static const _saveKey = 'savedGame';

  Map<String, dynamic> _toJson() => {
        'difficulty': difficulty,
        'board': _logic.board,
        'solutionBoard': _logic.solutionBoard,
        'isFixedBoard': _logic.isFixedBoard,
        'memos': _memos
            .map((row) => row.map((cell) => cell.toList()).toList())
            .toList(),
        'wrongCells': _wrongCells.map((e) => [e.$1, e.$2]).toList(),
        'history': _history.map((m) => m.toJson()).toList(),
        'selectedRow': selectedRow,
        'selectedCol': selectedCol,
        'elapsedSeconds': elapsedSeconds,
        'remainingLives': _remainingLives,
      };

  void _fromJson(Map<String, dynamic> json) {
    difficulty = json['difficulty'] as String;

    _logic.board = (json['board'] as List)
        .map((row) => (row as List).map((e) => e as int).toList())
        .toList();
    _logic.solutionBoard = (json['solutionBoard'] as List)
        .map((row) => (row as List).map((e) => e as int).toList())
        .toList();
    _logic.isFixedBoard = (json['isFixedBoard'] as List)
        .map((row) => (row as List).map((e) => e as bool).toList())
        .toList();

    _memos = (json['memos'] as List)
        .map((row) => (row as List)
            .map((cell) => Set<int>.from(cell as List))
            .toList())
        .toList();

    _wrongCells.clear();
    for (final cell in json['wrongCells'] as List) {
      _wrongCells.add((cell[0] as int, cell[1] as int));
    }

    _history.clear();
    for (final move in json['history'] as List) {
      _history.add(_BoardMove.fromJson(move as Map<String, dynamic>));
    }

    selectedRow = json['selectedRow'] as int?;
    selectedCol = json['selectedCol'] as int?;
    elapsedSeconds = json['elapsedSeconds'] as int;
    _remainingLives = json['remainingLives'] as int;

    _isGameOver = _remainingLives <= 0;
    isGameClear = _logic.isSolved();
    isMemoMode = false;
  }

  Future<void> _saveGame() async {
    if (isGameClear || _isGameOver) {
      await _clearSavedGame();
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_saveKey, jsonEncode(_toJson()));
      _hasSavedGame = true;
    } catch (_) {
      // 저장 실패는 치명적이지 않으므로 무시
    }
  }

  Future<void> _clearSavedGame() async {
    _hasSavedGame = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_saveKey);
  }

  Future<bool> loadSavedGame() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_saveKey);
    if (jsonString == null) return false;

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      _fromJson(json);
      _hasSavedGame = true;
      notifyListeners();
      return true;
    } catch (_) {
      await _clearSavedGame();
      return false;
    }
  }

  // Provider가 더 이상 필요 없어질 때(앱 종료 등) 타이머를 정리합니다.
  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}
