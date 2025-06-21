import 'package:ARtifact/features/quiz/category/categories_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../shared/l10n/app_localizations.dart';
import '../../arventure/screens/arventure_screen.dart';
import '../../profile/screens/completeProfile.dart';
import '../../auth/screens/login_screen.dart';
import '../../favorite/favorites_screen.dart';
import '../../home/screens/home_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../quiz/screens/ThemesScreen.dart';
import '../widgets/animated_bottom_bar.dart';

class MainNavigation extends StatefulWidget {
  final int initialIndex;

  const MainNavigation({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  late int _currentIndex;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final localizations = AppLocalizations.of(context);

    if (authProvider.status == AuthStatus.unauthenticated) {
      return const LoginScreen();
    }

    if (!_isProfileComplete(authProvider)) {
      return const CompleteProfileScreen();
    }

    return Scaffold(
      backgroundColor: _currentIndex == 1 ? Colors.transparent : null,
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: const NeverScrollableScrollPhysics(),
        children: _getPages(authProvider),
      ),
      bottomNavigationBar: AnimatedBottomBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        items: [
          BottomBarItem(
            icon: Icons.home_rounded,
            label: localizations.translate('home'),
            activeColor: Theme.of(context).primaryColor,
          ),
          BottomBarItem(
            icon: Icons.explore_rounded,
            label: localizations.translate('ARventure'),
            activeColor: Colors.purple,
          ),
          BottomBarItem(
            icon: Icons.quiz,
            label: localizations.translate('Quiz'),
            activeColor: Colors.orange,
          ),
          BottomBarItem(
            icon: Icons.person_rounded,
            label: localizations.translate('profile'),
            activeColor: Colors.teal,
          ),
        ],
      ),
    );
  }

  List<Widget> _getPages(AuthProvider authProvider) {
    return [
      const HomeScreen(),
      const ARventureScreen(),
      const CategoriesScreen(),
      const ProfileScreen(),
    ];
  }

  bool _isProfileComplete(AuthProvider authProvider) {
    final user = authProvider.user;
    return user != null &&
        user.username != null &&
        user.username!.isNotEmpty &&
        user.phoneNumber != null &&
        user.phoneNumber!.isNotEmpty &&
        user.age != null;
  }
}