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
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'Pretendard',
      ),
      home: const MainScreen(),
      routes: {
        '/home': (context) => const HomePage(),
        '/user-input': (context) => const UserInputPage(),
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // 각 탭의 화면들
  static const List<Widget> _screens = [
    HomePage(),  // 0: 스토리보드
    HomePage(),  // 1: 큐카드 (임시로 HomePage)
    HomePage(),  // 2: 사용자 정보 (임시로 HomePage)
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: AppColors.cardBackground,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.view_timeline),
            label: '스토리보드',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.style),
            label: '큐카드',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '사용자 정보',
          ),
        ],
      ),
    );
  }
}

