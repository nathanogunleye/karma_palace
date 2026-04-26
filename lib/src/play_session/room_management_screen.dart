import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:logging/logging.dart';

import 'package:karma_palace/src/games_services/firebase_game_service.dart';
import 'package:karma_palace/src/style/palette.dart';

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
      setState(() => _errorMessage = 'Please enter a player name');
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
        _successMessage = 'Room created! Share ID: $roomId';
      });
      _log.info('Created room: $roomId');
      if (mounted) context.go('/karma-palace-live');
    } catch (e) {
      setState(() => _errorMessage = 'Failed to create room: $e');
      _log.severe('Failed to create room: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _joinRoom() async {
    if (_playerNameController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please enter a player name');
      return;
    }
    if (_joinRoomIdController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please enter a room ID');
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
      setState(() => _successMessage = 'Successfully joined room!');
      _log.info('Joined room: ${_joinRoomIdController.text.trim()}');
      if (mounted) context.go('/karma-palace-live');
    } catch (e) {
      setState(() => _errorMessage = 'Failed to join room: $e');
      _log.severe('Failed to join room: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

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
                        'Multiplayer',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 68),
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
                            const Text('Your Name',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                            const SizedBox(height: 10),
                            _StyledTextField(
                              controller: _playerNameController,
                              hint: 'Enter your player name',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Create Room
                      _GlassPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Create New Room',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                            const SizedBox(height: 16),
                            _ActionButton(
                              label: 'Create Room',
                              isLoading: _isLoading,
                              onTap: _isLoading ? null : _createRoom,
                              color: const Color(0xFF22C55E),
                            ),
                            if (_roomIdController.text.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white10,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0x33FFFFFF)),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Room ID',
                                              style: TextStyle(color: Colors.white60, fontSize: 12)),
                                          const SizedBox(height: 2),
                                          Text(_roomIdController.text,
                                              style: const TextStyle(
                                                  fontFamily: 'monospace', fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () async {
                                        final sm = ScaffoldMessenger.of(context);
                                        await Clipboard.setData(ClipboardData(text: _roomIdController.text));
                                        if (mounted) {
                                          sm.showSnackBar(const SnackBar(
                                            content: Text('Room ID copied!'),
                                            backgroundColor: Colors.green,
                                            duration: Duration(seconds: 2),
                                          ));
                                        }
                                      },
                                      icon: const Icon(Icons.copy, color: Colors.white70),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Join Room
                      _GlassPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Join Existing Room',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                            const SizedBox(height: 10),
                            _StyledTextField(
                              controller: _joinRoomIdController,
                              hint: 'Enter room ID',
                            ),
                            const SizedBox(height: 12),
                            _ActionButton(
                              label: 'Join Room',
                              isLoading: _isLoading,
                              onTap: _isLoading ? null : _joinRoom,
                              color: const Color(0xFF8B5CF6),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Messages
                      if (_errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
                          ),
                          child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                        ),

                      if (_successMessage != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
                          ),
                          child: Text(_successMessage!, style: const TextStyle(color: Colors.green)),
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

// ── Helper widgets ──────────────────────────────────────────────────────────

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

class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;

  const _StyledTextField({required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      cursorColor: Colors.white,
      decoration: InputDecoration(
        hintText: hint,
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
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onTap;
  final Color color;

  const _ActionButton({required this.label, required this.isLoading, this.onTap, required this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: onTap != null ? color : Colors.grey.shade700,
          borderRadius: BorderRadius.circular(10),
        ),
        child: isLoading
            ? const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
              )
            : Text(label,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                textAlign: TextAlign.center),
      ),
    );
  }
}
