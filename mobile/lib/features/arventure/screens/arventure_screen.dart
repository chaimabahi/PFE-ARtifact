import 'package:flutter/material.dart';
import 'dart:async';
import 'package:external_app_launcher/external_app_launcher.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';

import '../../../core/providers/auth_provider.dart';
import '../../payment/screens/payment_screen.dart';

class ARventureScreen extends StatefulWidget {
  const ARventureScreen({Key? key}) : super(key: key);

  @override
  State<ARventureScreen> createState() => _ARventureScreenState();
}

class _ARventureScreenState extends State<ARventureScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _backgroundFadeAnimation;
  late Animation<double> _titleFadeAnimation;
  late Animation<double> _titleSlideAnimation;
  late Animation<double> _buttonsFadeAnimation;
  late Animation<double> _buttonsScaleAnimation;

  bool _showVirtualScreens = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _backgroundFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.3, curve: Curves.easeIn)),
    );

    _titleFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.2, 0.5, curve: Curves.easeIn)),
    );

    _titleSlideAnimation = Tween<double>(begin: -50.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.2, 0.5, curve: Curves.easeOut)),
    );

    _buttonsFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.7, 1.0, curve: Curves.easeIn)),
    );

    _buttonsScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.7, 1.0, curve: Curves.elasticOut)),
    );

    _controller.forward();

    Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _showVirtualScreens = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _launchPuzzleGame() async {
    try {
      await LaunchApp.openApp(
        androidPackageName: 'artifact.puzzle.com',
        openStore: true,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to launch app: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleTreasureHunt() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.isPremium) {
        await _launchTreasureHuntApp();
      } else {
        await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaymentScreen()));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  Future<void> _launchTreasureHuntApp() async {
    try {
      await LaunchApp.openApp(
        androidPackageName: 'com.GoldenMedina.Artifact',
        openStore: true,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to launch app: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2A2D3E), Color(0xFF1F1F2C)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              AnimatedBuilder(
                animation: _backgroundFadeAnimation,
                builder: (context, child) {
                  return Opacity(opacity: _backgroundFadeAnimation.value, child: child);
                },
                child: const SizedBox.expand(),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),
                    AnimatedBuilder(
                      animation: _titleFadeAnimation,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _titleFadeAnimation.value,
                          child: Transform.translate(
                            offset: Offset(0, _titleSlideAnimation.value),
                            child: child,
                          ),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'WELCOME TO',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [Colors.blue.shade400, Colors.purple.shade300],
                            ).createShader(bounds),
                            child: const Text(
                              'ARventure',
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            width: 80,
                            height: 4,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.blue.shade400, Colors.purple.shade300],
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 30),

                          // ✅ LOTTIE animation added here
                          SizedBox(
                            height: 335,
                            child: Lottie.asset('assets/animations/guy.json'),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    AnimatedBuilder(
                      animation: _buttonsFadeAnimation,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _buttonsFadeAnimation.value,
                          child: Transform.scale(scale: _buttonsScaleAnimation.value, child: child),
                        );
                      },
                      child: Column(
                        children: [
                          _buildButton(
                            title: 'PUZZLE GAME',
                            gradient: LinearGradient(
                                colors: [Color(0xFF1F1F2C),Color(0xff003add),Color(0xFF1F1F2C) ]
                            ),
                            onTap: _launchPuzzleGame,
                          ),
                          const SizedBox(height: 16),
                          _buildPremiumButton(authProvider),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton({
    required String title,
    required Gradient gradient,
    required VoidCallback onTap,
    bool isPremium = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            isPremium ? '$title (Premium)' : title,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumButton(AuthProvider authProvider) {
    final isPremium = authProvider.isPremium;

    return InkWell(
      onTap: _handleTreasureHunt,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: isPremium
              ? LinearGradient(colors: [Color(0xFF1F1F2C), Colors.purple.shade300, Color(0xFF1F1F2C)])
              : LinearGradient(colors: [Color(0xFF1F1F2C), Colors.purple.shade300, Color(0xFF1F1F2C)]),
          borderRadius: BorderRadius.circular(12),
          boxShadow: isPremium
              ? null
              : const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'TREASURE HUNT',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
              ),
              if (!isPremium) ...[
                const SizedBox(width: 8),
                Icon(Icons.lock, color: Colors.white.withOpacity(0.8), size: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }
}