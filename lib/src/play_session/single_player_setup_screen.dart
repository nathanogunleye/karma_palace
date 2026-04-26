import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:logging/logging.dart';

import 'package:karma_palace/src/games_services/local_game_service.dart';
import 'package:karma_palace/src/games_services/ai_player_service.dart' show AIDifficulty;
import 'package:karma_palace/src/style/palette.dart';

class SinglePlayerSetupScreen extends StatefulWidget {
  const SinglePlayerSetupScreen({super.key});

  @override
  State<SinglePlayerSetupScreen> createState() => _SinglePlayerSetupScreenState();
}

class _SinglePlayerSetupScreenState extends State<SinglePlayerSetupScreen> {
  static final Logger _log = Logger('SinglePlayerSetupScreen');

  final TextEditingController _playerNameController = TextEditingController();
  AIDifficulty _selectedDifficulty = AIDifficulty.medium;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _playerNameController.text = 'Player${DateTime.now().millisecondsSinceEpoch % 1000}';
  }

  @override
  void dispose() {
    _playerNameController.dispose();
    super.dispose();
  }

  Future<void> _startSinglePlayerGame() async {
    if (_playerNameController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please enter a player name');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final gameService = context.read<LocalGameService>();
      await gameService.createSinglePlayerGame(
        _playerNameController.text.trim(),
        _selectedDifficulty,
      );
      _log.info('Created single player game with difficulty: $_selectedDifficulty');
      if (mounted) context.go('/single-player-game');
    } catch (e) {
      setState(() => _errorMessage = 'Failed to create game: $e');
      _log.severe('Failed to create single player game: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _difficultyLabel(AIDifficulty d) => switch (d) {
        AIDifficulty.easy => 'Easy',
        AIDifficulty.medium => 'Medium',
        AIDifficulty.hard => 'Hard',
      };

  String _difficultyDesc(AIDifficulty d) => switch (d) {
        AIDifficulty.easy => 'Random card selection',
        AIDifficulty.medium => 'Strategic card saving',
        AIDifficulty.hard => 'Advanced strategy',
      };

  Color _difficultyColor(AIDifficulty d) => switch (d) {
        AIDifficulty.easy => Colors.green,
        AIDifficulty.medium => Colors.orange,
        AIDifficulty.hard => Colors.red,
      };

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();

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
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.go('/'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0x1AFFFFFF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.arrow_back, color: Colors.white, size: 16),
                            SizedBox(width: 4),
                            Text('Back', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'Single Player Setup',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 68), // balance the back button
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),

                      // Player Name
                      _GlassPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Your Name',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _playerNameController,
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                              cursorColor: Colors.white,
                              decoration: InputDecoration(
                                hintText: 'Enter your player name',
                                hintStyle: const TextStyle(color: Colors.white38),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(color: Color(0x66FFFFFF)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(color: Colors.white, width: 1.5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: const Color(0x0FFFFFFF),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Difficulty Selection
                      _GlassPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'AI Difficulty',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...AIDifficulty.values.map((d) {
                              final isSelected = _selectedDifficulty == d;
                              return GestureDetector(
                                onTap: () => setState(() => _selectedDifficulty = d),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? _difficultyColor(d).withValues(alpha: 0.25)
                                        : const Color(0x0FFFFFFF),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected
                                          ? _difficultyColor(d)
                                          : const Color(0x33FFFFFF),
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isSelected
                                              ? _difficultyColor(d)
                                              : const Color(0x33FFFFFF),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _difficultyLabel(d).toUpperCase(),
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: isSelected
                                                    ? _difficultyColor(d)
                                                    : Colors.white70,
                                                fontSize: 13,
                                              ),
                                            ),
                                            Text(
                                              _difficultyDesc(d),
                                              style: const TextStyle(
                                                color: Colors.white54,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Error
                      if (_errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),

                      const SizedBox(height: 24),

                      // Start button
                      GestureDetector(
                        onTap: _isLoading ? null : _startSinglePlayerGame,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: _isLoading
                                ? null
                                : const LinearGradient(
                                    colors: [Color(0xFFFACC15), Color(0xFFF97316)],
                                  ),
                            color: _isLoading ? Colors.grey.shade700 : null,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: _isLoading
                              ? const Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'Start Game',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  final Widget child;
  const _GlassPanel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0x1AFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x33FFFFFF)),
      ),
      child: child,
    );
  }
}
