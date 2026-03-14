import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';

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
              // 액션 버튼 (되돌리기, 지우기, 메모, 힌트)
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
                      child: _buildNumberButton(
                          context, number, remaining, isDisabled),
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

  Widget _buildNumberButton(
      BuildContext context, int number, int remaining, bool isDisabled) {
    return InkWell(
      onTap: isDisabled
          ? null
          : () => context.read<GameProvider>().setInput(number),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: isDisabled ? const Color(0xFFF5F5F5) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDisabled
                ? const Color(0xFFEEEEEE)
                : const Color(0xFFE0E3EA),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              number.toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDisabled
                    ? const Color(0xFFCCCCCC)
                    : const Color(0xFF1A1A2E),
                height: 1.0,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              remaining.toString(),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: isDisabled
                    ? const Color(0xFFDDDDDD)
                    : const Color(0xFFAAAAAA),
              ),
            ),
          ],
        ),
      ),
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
      bgColor = const Color(0xFFE0F2F1);
      iconColor = const Color(0xFF00897B);
      border = Border.all(color: const Color(0xFF4ECDC4), width: 2);
    } else if (isHint) {
      bgColor = const Color(0xFFFFF3E0);
      iconColor = const Color(0xFFF57C00);
      border = null;
    } else {
      bgColor = const Color(0xFFF0F1F5);
      iconColor = const Color(0xFF555555);
      border = null;
    }

    return Opacity(
      opacity: isDisabled ? 0.4 : 1.0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(14),
                border: border,
              ),
              child: isHint
                  ? Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        Icon(icon, color: iconColor, size: 20),
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 3, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF57C00),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.ad_units,
                                    color: Colors.white, size: 8),
                                SizedBox(width: 1),
                                Text('AD',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 7,
                                      fontWeight: FontWeight.w700,
                                    )),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFF888888),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
