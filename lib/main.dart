import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'providers/game_provider.dart';
import 'theme/pixel_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 번들된 DotGothic16 폰트의 OFL 라이선스를 앱 라이선스 페이지에 등록(재배포 요건).
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(['DotGothic16'], license);
  });

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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: PixelColors.gridBorderDark),
        useMaterial3: true,
        scaffoldBackgroundColor: PixelColors.scaffoldBg,
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
