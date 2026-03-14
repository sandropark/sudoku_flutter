import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../theme/pixel_theme.dart';

class NumberPad extends StatelessWidget {
  final VoidCallback? onHintTap;
  const NumberPad({super.key, this.onHintTap});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, provider, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              // 액션 버튼
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildActionButton(
                    icon: Icons.undo,
                    label: '되돌리기',
                    onTap: provider.canUndo ? () => provider.undo() : null,
                  ),
                  const SizedBox(width: 12),
                  _buildActionButton(
                    icon: Icons.backspace_outlined,
                    label: '지우기',
                    onTap: () => provider.clearCell(),
                  ),
                  const SizedBox(width: 12),
                  _buildActionButton(
                    icon: Icons.edit_note,
                    label: '메모',
                    onTap: () => provider.toggleMemoMode(),
                    isActive: provider.isMemoMode,
                  ),
                  const SizedBox(width: 12),
                  _buildActionButton(
                    icon: Icons.lightbulb_outline,
                    label: '힌트(AD)',
                    onTap: onHintTap ?? () => provider.useHint(),
                    isHint: true,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // 숫자 버튼 1~9
              Row(
                children: List.generate(9, (index) {
                  final number = index + 1;
                  final count = provider.numberCount(number);
                  final remaining = 9 - count;
                  final isDisabled = count >= 9;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: _PixelNumberButton(
                        number: number,
                        remaining: remaining,
                        isDisabled: isDisabled,
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    bool isActive = false,
    bool isHint = false,
  }) {
    final isDisabled = onTap == null;

    Color bgColor;
    Color iconColor;
    BoxBorder? border;

    if (isActive) {
      bgColor = PixelColors.memoActiveBg;
      iconColor = PixelColors.memoActive;
      border = Border.all(color: PixelColors.memoActive, width: 3);
    } else if (isHint) {
      bgColor = PixelColors.hintBg;
      iconColor = PixelColors.accentOrange;
      border = Border.all(color: PixelColors.accentOrange, width: 2);
    } else {
      bgColor = PixelColors.gridBorderDark.withValues(alpha: 0.3);
      iconColor = Colors.white;
      border = Border.all(color: PixelColors.gridBorderDark, width: 2);
    }

    return Opacity(
      opacity: isDisabled ? 0.4 : 1.0,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: bgColor,
                border: border,
                boxShadow: pixelShadow(offset: const Offset(3, 3)),
              ),
              child: isHint
                  ? Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        Icon(icon, color: iconColor, size: 26),
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 3, vertical: 1),
                            color: PixelColors.accentOrange,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.ad_units,
                                    color: Colors.white, size: 8),
                                const SizedBox(width: 1),
                                Text('AD',
                                    style: PixelTextStyles.base(
                                      fontSize: 7,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    )),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Icon(icon, color: iconColor, size: 26),
            ),
            const SizedBox(height: 4),
            Text(label, style: PixelTextStyles.label),
          ],
        ),
      ),
    );
  }
}

/// 픽셀 스타일 숫자 버튼 (눌림 효과)
class _PixelNumberButton extends StatefulWidget {
  final int number;
  final int remaining;
  final bool isDisabled;

  const _PixelNumberButton({
    required this.number,
    required this.remaining,
    required this.isDisabled,
  });

  @override
  State<_PixelNumberButton> createState() => _PixelNumberButtonState();
}

class _PixelNumberButtonState extends State<_PixelNumberButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.isDisabled ? null : (_) => setState(() => _isPressed = true),
      onTapUp: widget.isDisabled
          ? null
          : (_) {
              setState(() => _isPressed = false);
              context.read<GameProvider>().setInput(widget.number);
            },
      onTapCancel: widget.isDisabled ? null : () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 50),
        height: 52,
        transform: _isPressed
            ? Matrix4.translationValues(2.0, 2.0, 0)
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: widget.isDisabled
              ? PixelColors.buttonDisabled
              : PixelColors.cellBackground,
          border: Border.all(
            color: widget.isDisabled
                ? PixelColors.buttonDisabled
                : PixelColors.gridBorderDark,
            width: 2,
          ),
          boxShadow: _isPressed || widget.isDisabled
              ? null
              : pixelShadow(offset: const Offset(2, 2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.number.toString(),
              style: PixelTextStyles.base(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: widget.isDisabled
                    ? PixelColors.gridBorderLight
                    : PixelColors.numberFixed,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              widget.remaining.toString(),
              style: PixelTextStyles.base(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: widget.isDisabled
                    ? PixelColors.gridBorderLight
                    : PixelColors.gridBorderDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
