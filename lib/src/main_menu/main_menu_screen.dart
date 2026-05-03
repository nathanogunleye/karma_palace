import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../audio/audio_controller.dart';
import '../audio/sounds.dart';
import '../settings/settings.dart';
import '../style/palette.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  String? _selectedMode; // 'single' or 'online'
  int _playerCount = 2;

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();
    final settingsController = context.watch<SettingsController>();
    final audioController = context.watch<AudioController>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              palette.bgGradientStart,
              palette.bgGradientMid,
              palette.bgGradientEnd,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Crown icon
                      const Icon(
                        Icons.workspace_premium,
                        color: Color(0xFFFACC15),
                        size: 80,
                      ),
                      const SizedBox(height: 16),

                      // Title
                      const Text(
                        'Karma Palace',
                        style: TextStyle(
                          fontFamily: 'Permanent Marker',
                          fontSize: 52,
                          color: Colors.white,
                          height: 1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),

                      // Subtitle
                      const Text(
                        "Don't be the last one standing!",
                        style: TextStyle(
                          color: Color(0xFFE9D5FF),
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 48),

                      // Single Player mode button
                      _ModeButton(
                        icon: Icons.person,
                        title: 'Single Player',
                        subtitle: 'Play against AI',
                        isSelected: _selectedMode == 'single',
                        onTap: () {
                          audioController.playSfx(SfxType.buttonTap);
                          setState(() => _selectedMode = 'single');
                        },
                      ),

                      const SizedBox(height: 16),

                      // Multiplayer mode button
                      _ModeButton(
                        icon: Icons.wifi,
                        title: 'Multiplayer',
                        subtitle: 'Play with friends online',
                        isSelected: _selectedMode == 'online',
                        onTap: () {
                          audioController.playSfx(SfxType.buttonTap);
                          setState(() => _selectedMode = 'online');
                        },
                      ),

                      const SizedBox(height: 16),

                      // Single player: player count picker + Start Game
                      if (_selectedMode == 'single') ...[
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0x1AFFFFFF),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0x33FFFFFF)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Number of Players',
                                style: TextStyle(color: Colors.white70, fontSize: 14),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [2, 3, 4, 5].map((n) {
                                  final selected = _playerCount == n;
                                  return GestureDetector(
                                    onTap: () => setState(() => _playerCount = n),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 150),
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: selected ? Colors.white : const Color(0x1AFFFFFF),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: selected ? Colors.white : const Color(0x66FFFFFF),
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '$n',
                                          style: TextStyle(
                                            color: selected ? const Color(0xFF581C87) : Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _GradientButton(
                          label: 'Start Game',
                          onTap: () {
                            audioController.playSfx(SfxType.buttonTap);
                            GoRouter.of(context).go('/single-player-setup', extra: _playerCount);
                          },
                        ),
                      ] else if (_selectedMode == 'online')
                        _GradientButton(
                          label: 'Continue',
                          onTap: () {
                            audioController.playSfx(SfxType.buttonTap);
                            GoRouter.of(context).go('/room-management');
                          },
                        ),

                      const SizedBox(height: 32),

                      // Bottom utility row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ValueListenableBuilder<bool>(
                            valueListenable: settingsController.audioOn,
                            builder: (context, audioOn, _) {
                              return IconButton(
                                onPressed: () => settingsController.toggleAudioOn(),
                                icon: Icon(
                                  audioOn ? Icons.volume_up : Icons.volume_off,
                                  color: Colors.white70,
                                ),
                              );
                            },
                          ),
                          IconButton(
                            onPressed: () => GoRouter.of(context).push('/settings'),
                            icon: const Icon(Icons.settings, color: Colors.white70),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : const Color(0x1AFFFFFF),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? const Color(0xFF581C87) : Colors.white,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isSelected ? const Color(0xFF581C87) : Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: isSelected
                    ? const Color(0xFF581C87).withValues(alpha: 0.75)
                    : Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _GradientButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFACC15), Color(0xFFF97316)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFACC15).withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
