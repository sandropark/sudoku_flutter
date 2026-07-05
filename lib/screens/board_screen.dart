import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../theme/pixel_theme.dart';
import '../widgets/sudoku_grid.dart';
import '../widgets/number_pad.dart';

class BoardScreen extends StatefulWidget {
  const BoardScreen({super.key});

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;
  RewardedAd? _rewardedAd;
  bool _isRewardedAdLoading = false;
  bool _dialogShown = false; // 결과 다이얼로그 중복 표시 방지

  String get _bannerAdUnitId {
    // release 빌드에서만 운영 광고 사용. debug/profile은 테스트 광고로
    // AdMob 무효 트래픽(계정 정지) 방지.
    if (!kReleaseMode) {
      return defaultTargetPlatform == TargetPlatform.android
          ? 'ca-app-pub-3940256099942544/6300978111'
          : 'ca-app-pub-3940256099942544/2934735716';
    }
    return defaultTargetPlatform == TargetPlatform.android
        ? 'ca-app-pub-8495159868358935/7552298013'
        : 'ca-app-pub-3940256099942544/2934735716';
  }

  String get _rewardedAdUnitId {
    if (!kReleaseMode) {
      return defaultTargetPlatform == TargetPlatform.android
          ? 'ca-app-pub-3940256099942544/5224354917'
          : 'ca-app-pub-3940256099942544/1712485313';
    }
    return defaultTargetPlatform == TargetPlatform.android
        ? 'ca-app-pub-8495159868358935/9945194501'
        : 'ca-app-pub-3940256099942544/1712485313';
  }

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _loadBannerAd();
      _loadRewardedAd();
    }
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) return;
          setState(() {
            _isBannerAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner ad failed to load: ${error.message}');
          ad.dispose();
          _bannerAd = null;
        },
      ),
    )..load();
  }

  void _loadRewardedAd() {
    if (_isRewardedAdLoading) return;
    _isRewardedAdLoading = true;
    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedAdLoading = false;
        },
        onAdFailedToLoad: (error) {
          debugPrint('Rewarded ad failed to load: ${error.message}');
          _rewardedAd = null;
          _isRewardedAdLoading = false;
        },
      ),
    );
  }

  void _showRewardedAdForHint(GameProvider provider) {
    if (!provider.canUseHint()) return;

    if (_rewardedAd == null) {
      provider.useHint();
      _loadRewardedAd();
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        _loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Rewarded ad failed to show: ${error.message}');
        ad.dispose();
        _rewardedAd = null;
        _loadRewardedAd();
        provider.useHint();
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        provider.useHint();
      },
    );
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _rewardedAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, provider, child) {
        // 결과 다이얼로그는 최초 1회만 예약(매 rebuild마다 중복 push 방지).
        // 새 게임 등으로 상태가 풀리면 플래그를 리셋한다.
        if (provider.isGameOver && !_dialogShown) {
          _dialogShown = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showGameOverDialog(context, provider);
          });
        } else if (provider.isGameClear && !_dialogShown) {
          _dialogShown = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showClearDialog(context, provider);
          });
        } else if (!provider.isGameOver && !provider.isGameClear) {
          _dialogShown = false;
        }

        return Scaffold(
          backgroundColor: PixelColors.scaffoldBg,
          body: SafeArea(
            child: Column(
              children: [
                // 상태바: 난이도, 하트, 타이머, 새게임
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 난이도 칩
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: pixelBoxDecoration(
                          color: PixelColors.gridBorderDark,
                          borderColor: PixelColors.pixelBlack,
                          borderWidth: 2,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: provider.difficulty,
                            isDense: true,
                            icon: const SizedBox.shrink(),
                            dropdownColor: PixelColors.gridBorderDark,
                            items:
                                ['쉬움', '보통', '어려움'].map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(
                                  value,
                                  style: PixelTextStyles.chip,
                                ),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                provider.changeDifficulty(newValue);
                              }
                            },
                          ),
                        ),
                      ),
                      // 하트 (픽셀 스타일)
                      Row(
                        children: List.generate(3, (index) {
                          final isFilled = index < provider.remainingLives;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Text(
                              isFilled ? '♥' : '♡',
                              style: PixelTextStyles.base(
                                fontSize: 20,
                                color: isFilled
                                    ? PixelColors.cellWrong
                                    : PixelColors.cellWrongBg,
                              ).copyWith(
                                shadows: [
                                  Shadow(
                                    color: PixelColors.pixelBlack
                                        .withValues(alpha: isFilled ? 0.6 : 0.2),
                                    offset: const Offset(1, 1),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                      // 타이머
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: pixelBoxDecoration(
                          color: PixelColors.gridBorderDark,
                          borderColor: PixelColors.pixelBlack,
                          borderWidth: 2,
                        ),
                        // 타이머만 매초 리빌드(보드/키패드는 리빌드되지 않음)
                        child: ValueListenableBuilder<int>(
                          valueListenable: provider.elapsed,
                          builder: (_, _, _) => Text(
                            provider.timerText,
                            style: PixelTextStyles.timer,
                          ),
                        ),
                      ),
                      // 새 게임 버튼
                      GestureDetector(
                        onTap: () => provider.startNewGame(),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: pixelBoxDecoration(
                            color: PixelColors.gridBorderDark,
                            borderColor: PixelColors.pixelBlack,
                            borderWidth: 2,
                          ),
                          child: const Icon(Icons.refresh,
                              size: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),

                // 그리드 + 컨트롤
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: SudokuGrid(),
                      ),
                      const SizedBox(height: 16),
                      NumberPad(
                        onHintTap: kIsWeb
                            ? null
                            : () => _showRewardedAdForHint(provider),
                      ),
                    ],
                  ),
                ),

                // 광고 배너 영역
                if (_isBannerAdLoaded && _bannerAd != null)
                  Container(
                    height: _bannerAd!.size.height.toDouble(),
                    width: _bannerAd!.size.width.toDouble(),
                    margin: const EdgeInsets.fromLTRB(0, 8, 0, 8),
                    child: AdWidget(ad: _bannerAd!),
                  )
                else
                  const SizedBox(height: 50),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showGameOverDialog(BuildContext context, GameProvider provider) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: const RoundedRectangleBorder(),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: pixelBoxDecoration(
              color: PixelColors.cellBackgroundAlt,
              borderColor: PixelColors.gridBorderDark,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '게임 오버',
                  style: PixelTextStyles.base(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: PixelColors.cellWrong,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '라이프를 모두 소진했습니다.',
                  style: PixelTextStyles.base(fontSize: 16),
                ),
                const SizedBox(height: 24),
                PixelButton(
                  color: PixelColors.gridBorderDark,
                  onTap: () {
                    Navigator.of(dialogContext).pop();
                    provider.startNewGame();
                  },
                  child: Text(
                    '새 게임 시작',
                    style: PixelTextStyles.base(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showClearDialog(BuildContext context, GameProvider provider) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: const RoundedRectangleBorder(),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: pixelBoxDecoration(
              color: PixelColors.cellBackgroundAlt,
              borderColor: PixelColors.gridBorderDark,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '축하합니다!',
                  style: PixelTextStyles.base(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: PixelColors.numberFixed,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '스도쿠를 완성했습니다!',
                  style: PixelTextStyles.base(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  '소요 시간: ${provider.timerText}',
                  style: PixelTextStyles.base(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: PixelColors.gridBorderDark,
                  ),
                ),
                Text(
                  '난이도: ${provider.difficulty}',
                  style: PixelTextStyles.base(
                    fontSize: 16,
                    color: PixelColors.gridBorderLight,
                  ),
                ),
                const SizedBox(height: 24),
                PixelButton(
                  color: PixelColors.gridBorderDark,
                  onTap: () {
                    Navigator.of(dialogContext).pop();
                    provider.startNewGame();
                  },
                  child: Text(
                    '새 게임 시작',
                    style: PixelTextStyles.base(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
