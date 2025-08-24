import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:logging/logging.dart';

import 'package:karma_palace/src/games_services/local_game_service.dart';
import 'package:karma_palace/src/games_services/ai_player_service.dart' show AIDifficulty;
import 'package:karma_palace/src/style/palette.dart';
import 'package:karma_palace/src/style/my_button.dart';

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
    // Set default player name
    _playerNameController.text = 'Player${DateTime.now().millisecondsSinceEpoch % 1000}';
  }

  @override
  void dispose() {
    _playerNameController.dispose();
    super.dispose();
  }

  Future<void> _startSinglePlayerGame() async {
    if (_playerNameController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a player name';
      });
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
      
      // Navigate to the live game screen
      if (mounted) {
        context.go('/single-player-game');
      }
      
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to create game: $e';
      });
      _log.severe('Failed to create single player game: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getDifficultyDescription(AIDifficulty difficulty) {
    switch (difficulty) {
      case AIDifficulty.easy:
        return 'Easy - Random card selection';
      case AIDifficulty.medium:
        return 'Medium - Strategic card saving';
      case AIDifficulty.hard:
        return 'Hard - Advanced strategy with special cards';
    }
  }

  Color _getDifficultyColor(AIDifficulty difficulty) {
    switch (difficulty) {
      case AIDifficulty.easy:
        return Colors.green;
      case AIDifficulty.medium:
        return Colors.orange;
      case AIDifficulty.hard:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();

    return Scaffold(
      backgroundColor: palette.backgroundMain,
      appBar: AppBar(
        title: const Text('Single Player Setup'),
        backgroundColor: palette.backgroundMain,
        foregroundColor: palette.ink,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Player Name Input
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Name',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: palette.cardInk,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _playerNameController,
                      style: TextStyle(
                        color: palette.inputText,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter your player name',
                        hintStyle: TextStyle(
                          color: palette.inputText.withValues(alpha: 0.6),
                        ),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Difficulty Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Difficulty',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: palette.cardInk,
                      ),
                    ),
                    const SizedBox(height: 16),
                                        ...AIDifficulty.values.map((difficulty) {
                      return RadioListTile<AIDifficulty>(
                        title: Text(
                          difficulty.name.toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _getDifficultyColor(difficulty),
                          ),
                        ),
                        subtitle: Text(
                          _getDifficultyDescription(difficulty),
                          style: TextStyle(
                            color: palette.cardInk.withValues(alpha: 0.7),
                          ),
                        ),
                        value: difficulty,
                        groupValue: _selectedDifficulty,
                        onChanged: (value) {
                          setState(() {
                            _selectedDifficulty = value!;
                          });
                        },
                        activeColor: _getDifficultyColor(difficulty),
                      );
                    }),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Error Message
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            
            const Spacer(),
            
            // Start Game Button
            MyButton(
              onPressed: _isLoading ? null : _startSinglePlayerGame,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Start Single Player Game'),
            ),
            
            const SizedBox(height: 16),
            
            // Back Button
            MyButton(
              onPressed: () => context.go('/'),
              child: const Text('Back to Main Menu'),
            ),
          ],
        ),
      ),
    );
  }
}
