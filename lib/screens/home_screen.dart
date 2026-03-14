import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../theme/pixel_theme.dart';
import 'board_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedDifficulty = '보통';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();

    return Scaffold(
      backgroundColor: PixelColors.scaffoldBg,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 앱 타이틀
                Text('스 도 쿠', style: PixelTextStyles.title),
                Container(
                  width: 180,
                  height: 3,
                  color: PixelColors.gridBorderDark,
                  margin: const EdgeInsets.only(top: 4),
                ),
                const SizedBox(height: 60),

                // 이어하기 버튼
                if (provider.hasSavedGame) ...[
                  PixelButton(
                    color: PixelColors.cellBackgroundAlt,
                    onTap: () {
                      provider.resumeTimer();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const BoardScreen()),
                      );
                    },
                    child: Column(
                      children: [
                        Text(
                          '▶ 이어하기',
                          style: PixelTextStyles.base(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: PixelColors.numberFixed,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${provider.difficulty}  ${provider.timerText}',
                          style: PixelTextStyles.base(
                            fontSize: 14,
                            color: PixelColors.gridBorderDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 난이도 선택
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: pixelBoxDecoration(
                    color: PixelColors.cellBackground,
                    borderColor: PixelColors.gridBorderLight,
                    borderWidth: 2,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedDifficulty,
                      isExpanded: true,
                      dropdownColor: PixelColors.cellBackgroundAlt,
                      items: ['쉬움', '보통', '어려움'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value,
                            style: PixelTextStyles.base(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: PixelColors.gridBorderDark,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedDifficulty = newValue;
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 새 게임 버튼
                PixelButton(
                  color: PixelColors.gridBorderDark,
                  onTap: () {
                    provider.difficulty = _selectedDifficulty;
                    provider.startNewGame();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const BoardScreen()),
                    );
                  },
                  child: Text(
                    '새 게임 시작',
                    style: PixelTextStyles.base(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
