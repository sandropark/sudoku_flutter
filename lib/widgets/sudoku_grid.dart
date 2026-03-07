import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // 상태 관리 패키지 추가
import '../providers/game_provider.dart'; // 우리가 만든 두뇌 연결

class SudokuGrid extends StatelessWidget {
  const SudokuGrid({super.key});

  Widget _buildMemoGrid(Set<int> memos, {int? highlightNumber}) {
    if (memos.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.all(1.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (rowIdx) {
          return Expanded(
            child: Row(
              children: List.generate(3, (colIdx) {
                final num = rowIdx * 3 + colIdx + 1;
                final isHighlighted = highlightNumber != null &&
                    highlightNumber != 0 &&
                    num == highlightNumber &&
                    memos.contains(num);
                return Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isHighlighted ? Colors.yellow.shade100 : null,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Center(
                      child: Text(
                        memos.contains(num) ? num.toString() : '',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isHighlighted ? Colors.blue.shade700 : Colors.grey.shade700,
                          fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Consumer 위젯으로 감싸면, GameProvider(두뇌)에서 "화면 새로고침해줘!"라고 할 때마다 
    // 여기 있는 UI들만 싹 다 최신 데이터로 다시 예쁘게 그려줍니다.
    return Consumer<GameProvider>(
      builder: (context, provider, child) {
        return AspectRatio(
          aspectRatio: 1.0,
          child: Container(
            margin: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blue.shade900, width: 2.0),
            ),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(), // 스크롤 방지
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 9, // 가로로 9칸
              ),
              itemCount: 81, // 총 9x9 = 81칸
              itemBuilder: (context, index) {
                final row = index ~/ 9;
                final col = index % 9;
                
                // 3x3 박스 구분을 위해 테두리 두께 조절 (주니어 필수 꿀팁!)
                final topBorder = row % 3 == 0 ? 2.0 : 0.5;
                final leftBorder = col % 3 == 0 ? 2.0 : 0.5;

                // 두뇌(Provider)에서 현재 칸에 들어갈 숫자를 물어옵니다.
                final number = provider.board[row][col];
                
                // 지금 그리고 있는 칸이, 사용자가 선택한 칸인지 확인합니다.
                final isSelected = provider.selectedRow == row && provider.selectedCol == col;

                // 추가된 기능: 초기 고정된 숫자인지 확인
                final isFixed = provider.isFixed(row, col);
                final isWrong = provider.isWrong(row, col);

                // 추가된 기능: 현재 선택된 칸의 숫자와 같은 숫자인지 (0 제외)
                final selectedNumber = (provider.selectedRow != null && provider.selectedCol != null)
                    ? provider.board[provider.selectedRow!][provider.selectedCol!]
                    : 0;
                final isSameNumber = number != 0 && selectedNumber == number;


                // 추가된 기능: 선택된 칸과 같은 줄(가로/세로/3x3)에 있는지 확인
                bool isRelated = false;
                if (provider.selectedRow != null && provider.selectedCol != null) {
                  final sRow = provider.selectedRow!;
                  final sCol = provider.selectedCol!;
                  
                  if (sRow == row || sCol == col) {
                    isRelated = true; // 같은 가로/세로줄
                  } else {
                    int boxStartRow = (sRow ~/ 3) * 3;
                    int boxStartCol = (sCol ~/ 3) * 3;
                    if (row >= boxStartRow && row < boxStartRow + 3 &&
                        col >= boxStartCol && col < boxStartCol + 3) {
                      isRelated = true; // 같은 3x3 박스
                    }
                  }
                }

                // 하이라이트 배경색 우선순위 적용
                Color bgColor = Colors.white;
                if (isSelected) {
                  bgColor = Colors.blue.shade200; // 가장 진한 파란색
                } else if (isWrong) {
                  bgColor = Colors.red.shade50; // 오답 배경
                } else if (isSameNumber) {
                  bgColor = Colors.yellow.shade100; // 파스텔 노란색
                } else if (isRelated) {
                  bgColor = Colors.blue.shade50; // 연한 파란색
                }

                // InkWell 위젯을 쓰면 터치했을 때 물결 효과가 나고 이벤트를 받을 수 있습니다.
                return InkWell(
                  onTap: () {
                    // 터치하면 두뇌(Provider)에게 "나 이 칸 선택했어!" 라고 알려줍니다.
                    provider.selectCell(row, col);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: bgColor,
                      border: Border(
                        top: BorderSide(color: Colors.blue.shade900, width: topBorder),
                        left: BorderSide(color: Colors.blue.shade900, width: leftBorder),
                        right: BorderSide(color: Colors.blue.shade900, width: 0.5),
                        bottom: BorderSide(color: Colors.blue.shade900, width: 0.5),
                      ),
                    ),
                    alignment: Alignment.center,
                    // 숫자가 있으면 큰 숫자, 없고 메모가 있으면 3x3 미니 격자, 둘 다 없으면 빈칸
                    child: number != 0
                        ? Text(
                            number.toString(),
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: isFixed ? FontWeight.w900 : FontWeight.w500,
                              color: isFixed
                                  ? Colors.black87
                                  : isWrong
                                      ? Colors.red.shade700
                                      : Colors.blue.shade700,
                            ),
                          )
                        : _buildMemoGrid(provider.getMemos(row, col), highlightNumber: selectedNumber),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
