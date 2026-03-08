import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart'; // 상태 관리 패키지 추가
import 'screens/home_screen.dart';
import 'providers/game_provider.dart'; // 우리가 만든 앱 전용 두뇌 연결

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    await MobileAds.instance.initialize();
  }

  final gameProvider = GameProvider();
  await gameProvider.loadSavedGame();

  runApp(
    ChangeNotifierProvider.value(
      value: gameProvider,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sudoku App',
      // 앱 전체의 테마(색상, 폰트 등)를 설정하는 곳입니다. 파란색으로 맞췄어요!
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
      ),
      // 시작 화면을 홈 화면으로 지정합니다.
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false, // 우측 상단의 못생긴 'DEBUG' 띠를 없앱니다.
    );
  }
}
