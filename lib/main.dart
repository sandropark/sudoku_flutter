import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // 상태 관리 패키지 추가
import 'screens/board_screen.dart';
import 'providers/game_provider.dart'; // 우리가 만든 앱 전용 두뇌 연결

void main() {
  // 앱이 시작될 때 'GameProvider(게임 두뇌)'를 앱 전체에 덮어씌워서 실행합니다!
  // 이제 앱 안의 어떤 화면이나 버튼에서도 이 두뇌에 접근해서 질문하거나 정보를 바꿀 수 있습니다.
  runApp(
    ChangeNotifierProvider(
      create: (context) => GameProvider(),
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
      // 시작 화면을 우리가 방금 만든 BoardScreen으로 지정합니다.
      home: const BoardScreen(),
      debugShowCheckedModeBanner: false, // 우측 상단의 못생긴 'DEBUG' 띠를 없앱니다.
    );
  }
}
