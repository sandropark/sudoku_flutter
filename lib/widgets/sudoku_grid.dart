import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';

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
                      color: isHighlighted
                          ? const Color(0xFFE8F5E9)
                          : null,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Center(
                      child: Text(
                        memos.contains(num) ? num.toString() : '',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isHighlighted
                              ? const Color(0xFF2E7D32)
                              : Colors.grey.shade700,
                          fontWeight: isHighlighted
                              ? FontWeight.bold
                              : FontWeight.normal,
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
    return Consumer<GameProvider>(
      builder: (context, provider, child) {
        return AspectRatio(
          aspectRatio: 1.0,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFD0D5DD),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 9,
              ),
              itemCount: 81,
              itemBuilder: (context, index) {
                final row = index ~/ 9;
                final col = index % 9;

                final number = provider.board[row][col];
                final isSelected = provider.selectedRow == row &&
                    provider.selectedCol == col;
                final isFixed = provider.isFixed(row, col);
                final isWrong = provider.isWrong(row, col);

                final selectedNumber =
                    (provider.selectedRow != null &&
                            provider.selectedCol != null)
                        ? provider
                            .board[provider.selectedRow!][provider.selectedCol!]
                        : 0;
                final isSameNumber =
                    number != 0 && selectedNumber == number && !isSelected;

                bool isRelated = false;
                if (provider.selectedRow != null &&
                    provider.selectedCol != null) {
                  final sRow = provider.selectedRow!;
                  final sCol = provider.selectedCol!;
                  if (sRow == row || sCol == col) {
                    isRelated = true;
                  } else {
                    final boxStartRow = (sRow ~/ 3) * 3;
                    final boxStartCol = (sCol ~/ 3) * 3;
                    if (row >= boxStartRow &&
                        row < boxStartRow + 3 &&
                        col >= boxStartCol &&
                        col < boxStartCol + 3) {
                      isRelated = true;
                    }
                  }
                }

                // 3x3 블록 배경색 교차
                final boxRow = row ~/ 3;
                final boxCol = col ~/ 3;
                final isAltBox = (boxRow + boxCol) % 2 == 0;

                // 배경색 우선순위
                Color bgColor =
                    isAltBox ? const Color(0xFFF6F8FC) : Colors.white;
                if (isSelected) {
                  bgColor = const Color(0xFFD4E4FF);
                } else if (isWrong) {
                  bgColor = const Color(0xFFFFF0F0);
                } else if (isSameNumber) {
                  bgColor = const Color(0xFFE8F5E9);
                } else if (isRelated) {
                  bgColor = isAltBox
                      ? const Color(0xFFE8EDF7)
                      : const Color(0xFFEEF2FB);
                }

                // 테두리 정의
                const defaultBorder =
                    BorderSide(color: Color(0xFFD0D5DD), width: 0.5);
                const blockBorder =
                    BorderSide(color: Color(0xFFA0AEC0), width: 2);
                const selectedBorder =
                    BorderSide(color: Color(0xFF4A6FA5), width: 2);
                const wrongBorder =
                    BorderSide(color: Color(0xFFEF9A9A), width: 2);

                final isBlockRight = col % 3 == 2 && col < 8;
                final isBlockBottom = row % 3 == 2 && row < 8;

                BorderSide topSide = defaultBorder;
                BorderSide leftSide = defaultBorder;
                BorderSide rightSide =
                    isBlockRight ? blockBorder : defaultBorder;
                BorderSide bottomSide =
                    isBlockBottom ? blockBorder : defaultBorder;

                // 선택/오답 셀은 borderRadius와 호환되도록 4면 모두 동일 테두리 적용
                // (혼합 테두리 + borderRadius → Flutter 렌더링 실패)
                if (isSelected) {
                  topSide = selectedBorder;
                  leftSide = selectedBorder;
                  rightSide = selectedBorder;
                  bottomSide = selectedBorder;
                } else if (isWrong) {
                  topSide = wrongBorder;
                  leftSide = wrongBorder;
                  rightSide = wrongBorder;
                  bottomSide = wrongBorder;
                }

                final cellBorder = Border(
                  top: topSide,
                  left: leftSide,
                  right: rightSide,
                  bottom: bottomSide,
                );

                // 텍스트 색상
                Color textColor;
                if (isFixed) {
                  textColor = const Color(0xFF1A1A2E);
                } else if (isWrong) {
                  textColor = const Color(0xFFD32F2F);
                } else if (isSameNumber) {
                  textColor = const Color(0xFF2E7D32);
                } else if (isSelected) {
                  textColor = const Color(0xFF1A3A6A);
                } else {
                  textColor = const Color(0xFF4A6FA5);
                }

                return InkWell(
                  onTap: () => provider.selectCell(row, col),
                  child: Container(
                    decoration: BoxDecoration(
                      color: bgColor,
                      border: cellBorder,
                      borderRadius:
                          (isSelected || isWrong)
                              ? BorderRadius.circular(4)
                              : null,
                    ),
                    alignment: Alignment.center,
                    child: number != 0
                        ? Text(
                            number.toString(),
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight:
                                  isFixed ? FontWeight.w700 : FontWeight.w500,
                              color: textColor,
                            ),
                          )
                        : _buildMemoGrid(provider.getMemos(row, col),
                            highlightNumber: selectedNumber),
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
