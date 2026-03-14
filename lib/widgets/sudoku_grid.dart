import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../theme/pixel_theme.dart';

class SudokuGrid extends StatelessWidget {
  const SudokuGrid({super.key});

  Widget _buildNumberText(
      int number, bool isFixed, bool isWrong, Color textColor) {
    final text = number.toString();
    final style = PixelTextStyles.base(
      fontSize: 22,
      fontWeight: isFixed ? FontWeight.w800 : FontWeight.w700,
      color: textColor,
    );

    // 고정 숫자는 테두리 없이 그대로
    if (isFixed || isWrong) {
      return Text(text, style: style);
    }

    // 사용자 입력: 얇은 테두리 추가
    return Stack(
      alignment: Alignment.center,
      children: [
        Text(
          text,
          style: style.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 0.8
              ..color = PixelColors.numberFixed.withValues(alpha: 0.4),
          ),
        ),
        Text(text, style: style),
      ],
    );
  }

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
                    color: isHighlighted
                        ? PixelColors.cellSameNumber
                        : null,
                    child: Center(
                      child: Text(
                        memos.contains(num) ? num.toString() : '',
                        style: PixelTextStyles.base(
                          fontSize: 11.5,
                          color: isHighlighted
                              ? PixelColors.numberFixed
                              : PixelColors.gridBorderLight,
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
              color: PixelColors.gridBorderDark,
              boxShadow: pixelShadow(
                color: PixelColors.pixelBlack.withValues(alpha: 0.3),
                offset: const Offset(5, 5),
              ),
              border: Border.all(color: PixelColors.pixelBlack, width: 4),
            ),
            clipBehavior: Clip.hardEdge,
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
                Color bgColor = isAltBox
                    ? PixelColors.cellBackground
                    : PixelColors.cellBackgroundAlt;
                if (isSelected) {
                  bgColor = PixelColors.cellSelected;
                } else if (isWrong) {
                  bgColor = PixelColors.cellWrongBg;
                } else if (isSameNumber) {
                  bgColor = PixelColors.cellSameNumber;
                } else if (isRelated) {
                  bgColor = PixelColors.cellRelated;
                }

                // 테두리 정의
                const defaultBorder =
                    BorderSide(color: PixelColors.gridBorderLight, width: 0.5);
                const blockBorder =
                    BorderSide(color: PixelColors.gridBorderDark, width: 3);

                final isBlockRight = col % 3 == 2 && col < 8;
                final isBlockBottom = row % 3 == 2 && row < 8;

                final cellBorder = Border(
                  top: defaultBorder,
                  left: defaultBorder,
                  right: isBlockRight ? blockBorder : defaultBorder,
                  bottom: isBlockBottom ? blockBorder : defaultBorder,
                );

                // 텍스트 색상
                Color textColor;
                if (isFixed) {
                  textColor = PixelColors.numberFixed;
                } else if (isWrong) {
                  textColor = PixelColors.cellWrong;
                } else if (isSameNumber) {
                  textColor = PixelColors.numberFixed;
                } else if (isSelected) {
                  textColor = PixelColors.numberFixed;
                } else {
                  textColor = PixelColors.numberUser;
                }

                return GestureDetector(
                  onTap: () => provider.selectCell(row, col),
                  child: Container(
                    decoration: BoxDecoration(
                      color: bgColor,
                      border: cellBorder,
                    ),
                    alignment: Alignment.center,
                    child: number != 0
                        ? _buildNumberText(
                            number, isFixed, isWrong, textColor)

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
