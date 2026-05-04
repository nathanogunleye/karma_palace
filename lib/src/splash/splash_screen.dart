import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../games_services/local_game_service.dart';
import '../games_services/ai_player_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entryController;
  late final AnimationController _crownController;
  late final AnimationController _dotsController;
  late final AnimationController _exitController;

  late final Animation<double> _crownScale;
  late final Animation<double> _crownFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _titleFade;
  late final Animation<double> _subtitleFade;
  late final Animation<double> _dotsFade;
  late final Animation<double> _screenFade;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _crownController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();

    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _crownScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );

    _crownFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.35, 0.75, curve: Curves.easeOutCubic),
      ),
    );

    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.35, 0.65, curve: Curves.easeIn),
      ),
    );

    _subtitleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.6, 0.9, curve: Curves.easeIn),
      ),
    );

    _dotsFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.8, 1.0, curve: Curves.easeIn),
      ),
    );

    _screenFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _exitController,
        curve: Curves.easeOut,
      ),
    );

    _entryController.forward().then((_) async {
      await Future.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return;
      await _exitController.forward();
      if (!mounted) return;

      final gameService = context.read<LocalGameService>();
      final router = GoRouter.of(context);
      final prefs = await SharedPreferences.getInstance();
      final isFirstLaunch = prefs.getBool('has_launched') != true;

      if (!mounted) return;

      if (isFirstLaunch) {
        await prefs.setBool('has_launched', true);
        await gameService.createSinglePlayerGame(
          'Player',
          AIDifficulty.easy,
          aiPlayerCount: 1,
        );
        await gameService.startGame();
        if (!mounted) return;
        router.go('/how-to-play');
      } else {
        router.go('/');
      }
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    _crownController.dispose();
    _dotsController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _screenFade,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF581C87),
                Color(0xFF6B21A8),
                Color(0xFF831843),
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated crown
                  FadeTransition(
                    opacity: _crownFade,
                    child: ScaleTransition(
                      scale: _crownScale,
                      child: AnimatedBuilder(
                        animation: _crownController,
                        builder: (context, child) {
                          final pulse = 1.0 +
                              0.08 *
                                  math.sin(
                                      _crownController.value * math.pi);
                          return Transform.scale(
                            scale: pulse,
                            child: child,
                          );
                        },
                        child: const Icon(
                          Icons.workspace_premium,
                          color: Color(0xFFFACC15),
                          size: 90,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Animated title
                  FadeTransition(
                    opacity: _titleFade,
                    child: SlideTransition(
                      position: _titleSlide,
                      child: const Text(
                        'Karma Palace',
                        style: TextStyle(
                          fontFamily: 'Permanent Marker',
                          fontSize: 52,
                          color: Colors.white,
                          height: 1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Subtitle
                  FadeTransition(
                    opacity: _subtitleFade,
                    child: const Text(
                      "Don't be the last one standing!",
                      style: TextStyle(
                        color: Color(0xFFE9D5FF),
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 60),

                  // Animated loading dots
                  FadeTransition(
                    opacity: _dotsFade,
                    child: _BouncingDots(controller: _dotsController),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BouncingDots extends AnimatedWidget {
  const _BouncingDots({required AnimationController controller})
      : super(listenable: controller);

  @override
  Widget build(BuildContext context) {
    final t = (listenable as AnimationController).value;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final phase = (t - i * 0.2).clamp(0.0, 1.0);
        final bounce = math.sin(phase * math.pi).clamp(0.0, 1.0);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Transform.translate(
            offset: Offset(0, -10 * bounce),
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.4 + 0.6 * bounce),
              ),
            ),
          ),
        );
      }),
    );
  }
}
