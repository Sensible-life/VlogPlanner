import 'package:flutter/material.dart';
import 'config/api_config.dart';
import 'constants/app_colors.dart';
import 'screens/home_page.dart';
import 'screens/user_input/user_input_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiConfig.initialize();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.white,
        fontFamily: 'Pretendard',
      ),
      home: const HomePage(),
      routes: {
        '/user-input': (context) => const UserInputPage(),
        '/main': (context) => const HomePage(),
      },
    );
  }
}

