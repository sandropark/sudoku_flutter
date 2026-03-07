import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';

class NumberPad extends StatelessWidget {
  const NumberPad({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
          child: Column(
            children: [
              // 상단: 지우기 + 힌트 버튼 (숫자 버튼과 분리!)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildActionButton(
                      context,
                      icon: Icons.undo,
                      onTap: provider.canUndo ? () => provider.undo() : null,
                      color: Colors.blueGrey,
                    ),
                    const SizedBox(width: 16),
                    _buildActionButton(
                      context,
                      icon: Icons.backspace_outlined,
                      onTap: () => provider.clearCell(),
                    ),
                    const SizedBox(width: 16),
                    _buildActionButton(
                      context,
                      icon: Icons.edit_note,
                      onTap: () => provider.toggleMemoMode(),
                      color: provider.isMemoMode ? Colors.green : Colors.grey,
                      filled: provider.isMemoMode,
                    ),
                    const SizedBox(width: 16),
                    _buildActionButton(
                      context,
                      icon: Icons.lightbulb_outline,
                      onTap: () => provider.useHint(),
                      color: Colors.amber,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // 하단: 1~9 숫자 버튼 한 줄
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(9, (index) {
                  final number = index + 1;
                  final count = provider.numberCount(number);
                  final isDisabled = count >= 9; // 9개 다 채워졌으면 비활성화!
                  return Expanded(child: _buildNumberButton(context, number, isDisabled));
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNumberButton(BuildContext context, int number, bool isDisabled) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.0),
      child: InkWell(
        onTap: isDisabled
            ? null // 비활성화된 버튼은 터치해도 아무 반응 없음!
            : () => context.read<GameProvider>().setInput(number),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            // 비활성화되면 회색으로 변합니다.
            color: isDisabled ? Colors.grey.shade200 : Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDisabled ? Colors.grey.shade300 : Colors.blue.shade200,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            number.toString(),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              // 비활성화되면 글자도 흐릿하게 표시합니다.
              color: isDisabled ? Colors.grey.shade400 : Colors.blue,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback? onTap,
    MaterialColor? color,
    bool filled = false,
  }) {
    final btnColor = color ?? Colors.grey;
    final isDisabled = onTap == null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Opacity(
        opacity: isDisabled ? 0.4 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: filled ? btnColor.shade200 : btnColor.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: btnColor.shade200),
          ),
          child: Icon(icon, color: btnColor.shade700, size: 24),
        ),
      ),
    );
  }
}
