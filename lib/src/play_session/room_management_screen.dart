import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:logging/logging.dart';

import 'package:karma_palace/src/games_services/firebase_game_service.dart';
import 'package:karma_palace/src/style/palette.dart';

import '../style/my_button.dart';

class RoomManagementScreen extends StatefulWidget {
  const RoomManagementScreen({super.key});

  @override
  State<RoomManagementScreen> createState() => _RoomManagementScreenState();
}

class _RoomManagementScreenState extends State<RoomManagementScreen> {
  static final Logger _log = Logger('RoomManagementScreen');
  
  final TextEditingController _playerNameController = TextEditingController();
  final TextEditingController _roomIdController = TextEditingController();
  final TextEditingController _joinRoomIdController = TextEditingController();
  
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    // Set default player name
    _playerNameController.text = 'Player${DateTime.now().millisecondsSinceEpoch % 1000}';
  }

  @override
  void dispose() {
    _playerNameController.dispose();
    _roomIdController.dispose();
    _joinRoomIdController.dispose();
    super.dispose();
  }

  Future<void> _createRoom() async {
    if (_playerNameController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a player name';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final gameService = context.read<FirebaseGameService>();
      final roomId = await gameService.createRoom(_playerNameController.text.trim());
      
      setState(() {
        _roomIdController.text = roomId;
        _successMessage = 'Room created successfully! Share this room ID with friends: $roomId';
      });
      
      _log.info('Created room: $roomId');
      
      // Navigate to the live game screen
      if (mounted) {
        context.go('/karma-palace-live');
      }
      
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to create room: $e';
      });
      _log.severe('Failed to create room: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _joinRoom() async {
    if (_playerNameController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a player name';
      });
      return;
    }

    if (_joinRoomIdController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a room ID';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final gameService = context.read<FirebaseGameService>();
      await gameService.joinRoom(
        _joinRoomIdController.text.trim(),
        _playerNameController.text.trim(),
      );
      
      setState(() {
        _successMessage = 'Successfully joined room!';
      });
      
      _log.info('Joined room: ${_joinRoomIdController.text.trim()}');
      
      // Navigate to the live game screen
      if (mounted) {
        context.go('/karma-palace-live');
      }
      
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to join room: $e';
      });
      _log.severe('Failed to join room: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();

    return Scaffold(
      backgroundColor: palette.backgroundPlaySession,
      appBar: AppBar(
        title: const Text('Karma Palace - Room Management'),
        backgroundColor: palette.backgroundPlaySession,
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

            // Create Room Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create New Room',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: palette.cardInk,
                      ),
                    ),
                    const SizedBox(height: 16),
                    MyButton(
                      onPressed: _isLoading ? null : _createRoom,
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Create Room'),
                    ),
                    if (_roomIdController.text.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: palette.ink.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Room ID:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: palette.ink,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _roomIdController.text,
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 16,
                                      color: palette.ink,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () async {
                                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                                    await Clipboard.setData(ClipboardData(text: _roomIdController.text));
                                    if (mounted) {
                                      scaffoldMessenger.showSnackBar(
                                        const SnackBar(
                                          content: Text('Room ID copied to clipboard!'),
                                          backgroundColor: Colors.green,
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  },
                                  icon: Icon(Icons.copy, color: palette.ink),
                                  tooltip: 'Copy Room ID',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Join Room Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Join Existing Room',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: palette.cardInk,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _joinRoomIdController,
                      style: TextStyle(
                        color: palette.inputText,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter room ID',
                        hintStyle: TextStyle(
                          color: palette.inputText.withValues(alpha: 0.6),
                        ),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    MyButton(
                      onPressed: _isLoading ? null : _joinRoom,
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Join Room'),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Status Messages
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
            
            if (_successMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _successMessage!,
                  style: const TextStyle(color: Colors.green),
                ),
              ),
            
            const Spacer(),
            
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