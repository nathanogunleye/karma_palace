import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:logging/logging.dart';

import 'package:karma_palace/src/games_services/firebase_game_service.dart';
import 'package:karma_palace/src/settings/settings.dart';
import 'package:karma_palace/src/style/palette.dart';

enum _Step { name, mode, create, join }

class RoomManagementScreen extends StatefulWidget {
  const RoomManagementScreen({super.key});

  @override
  State<RoomManagementScreen> createState() => _RoomManagementScreenState();
}

class _RoomManagementScreenState extends State<RoomManagementScreen> {
  static final _log = Logger('RoomManagementScreen');

  _Step _step = _Step.name;
  final _nameController = TextEditingController();
  final _joinIdController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  String _createdRoomId = '';
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _joinIdController.addListener(() => setState(() {}));
    _nameController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadNameFromSettings());
  }

  void _loadNameFromSettings() {
    if (!mounted) return;
    final settings = context.read<SettingsController>();
    final savedName = settings.playerName.value;
    _nameController.text = savedName;
    // Skip name step if the player already has a custom name
    if (savedName != 'Player') {
      setState(() => _step = _Step.mode);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _joinIdController.dispose();
    super.dispose();
  }

  void _back() {
    setState(() => _errorMessage = null);
    switch (_step) {
      case _Step.name:
        context.go('/');
      case _Step.mode:
        setState(() => _step = _Step.name);
      case _Step.create:
        // Leave the Firebase room we created and go back to mode
        final gameService = context.read<FirebaseGameService>();
        gameService.leaveRoom().catchError((_) {});
        setState(() => _step = _Step.mode);
      case _Step.join:
        setState(() => _step = _Step.mode);
    }
  }

  Future<void> _createRoom() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final name = _nameController.text.trim();
      context.read<SettingsController>().setPlayerName(name);
      final roomId = await context.read<FirebaseGameService>().createRoom(name);
      setState(() { _createdRoomId = roomId; _step = _Step.create; });
    } catch (e) {
      setState(() => _errorMessage = 'Failed to create room: $e');
      _log.severe('Failed to create room: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _joinRoom() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final name = _nameController.text.trim();
      context.read<SettingsController>().setPlayerName(name);
      await context.read<FirebaseGameService>().joinRoom(
        _joinIdController.text.trim(),
        name,
      );
      if (mounted) context.go('/karma-palace-live');
    } catch (e) {
      setState(() => _errorMessage = 'Failed to join room: $e');
      _log.severe('Failed to join room: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _copyRoomId() async {
    await Clipboard.setData(ClipboardData(text: _createdRoomId));
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
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
            colors: [palette.bgGradientStart, palette.bgGradientMid, palette.bgGradientEnd],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Back button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: _back,
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
                ),
              ),

              // Step content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                  child: _buildCurrentStep(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep(BuildContext context) {
    return switch (_step) {
      _Step.name => _buildNameStep(),
      _Step.mode => _buildModeStep(),
      _Step.create => _buildCreateStep(),
      _Step.join => _buildJoinStep(),
    };
  }

  // ── Step 1: Name ──────────────────────────────────────────────────────────

  Widget _buildNameStep() {
    final canContinue = _nameController.text.trim().isNotEmpty;
    return Column(
      children: [
        const SizedBox(height: 16),
        const Icon(Icons.people_alt_outlined, color: Color(0xFFD8B4FE), size: 72),
        const SizedBox(height: 20),
        const Text(
          'Online Multiplayer',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 8),
        const Text(
          'Enter your name to continue',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: Color(0xFFE9D5FF)),
        ),
        const SizedBox(height: 32),
        _GlassPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Your Name',
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 10),
              _Field(
                controller: _nameController,
                hint: 'Enter your name...',
                maxLength: 20,
                onSubmitted: canContinue
                    ? (_) => setState(() { _step = _Step.mode; _errorMessage = null; })
                    : null,
              ),
              const SizedBox(height: 16),
              _PrimaryButton(
                label: 'Continue',
                enabled: canContinue,
                onTap: canContinue
                    ? () => setState(() { _step = _Step.mode; _errorMessage = null; })
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Step 2: Mode ──────────────────────────────────────────────────────────

  Widget _buildModeStep() {
    return Column(
      children: [
        const SizedBox(height: 16),
        Text(
          'Welcome, ${_nameController.text.trim()}!',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 8),
        const Text(
          'Create or join a game room',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: Color(0xFFE9D5FF)),
        ),
        const SizedBox(height: 32),
        if (_isLoading)
          const _LoadingPanel()
        else ...[
          _BigModeCard(
            icon: Icons.add_circle_outline,
            title: 'Create Room',
            subtitle: 'Start a new game and invite friends',
            onTap: _createRoom,
          ),
          const SizedBox(height: 12),
          _BigModeCard(
            icon: Icons.login,
            title: 'Join Room',
            subtitle: 'Enter a Room ID to join a friend',
            onTap: () => setState(() { _step = _Step.join; _errorMessage = null; }),
          ),
        ],
        if (_errorMessage != null) ...[
          const SizedBox(height: 16),
          _ErrorBanner(message: _errorMessage!),
        ],
      ],
    );
  }

  // ── Step 3: Create (lobby) ─────────────────────────────────────────────────

  Widget _buildCreateStep() {
    return Consumer<FirebaseGameService>(
      builder: (context, gameService, _) {
        final playerCount = gameService.currentRoom?.players.length ?? 1;

        return Column(
          children: [
            const SizedBox(height: 16),
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFF22C55E),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 44),
            ),
            const SizedBox(height: 20),
            const Text(
              'Room Created!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            const Text(
              'Share this Room ID with your friends',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Color(0xFFE9D5FF)),
            ),
            const SizedBox(height: 32),
            _GlassPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Room ID',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            color: const Color(0x1AFFFFFF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0x66FFFFFF)),
                          ),
                          child: Text(
                            _createdRoomId,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 3,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _copyRoomId,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0x1AFFFFFF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0x66FFFFFF)),
                          ),
                          child: Icon(
                            _copied ? Icons.check : Icons.copy,
                            color: _copied ? const Color(0xFF4ADE80) : Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0x0FFFFFFF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Waiting for players...',
                          style: TextStyle(color: Colors.white60, fontSize: 13),
                        ),
                        Text(
                          '$playerCount player${playerCount == 1 ? '' : 's'} joined',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _PrimaryButton(
                    label: 'Go to Game Lobby',
                    enabled: true,
                    onTap: () => context.go('/karma-palace-live'),
                    color: const Color(0xFF22C55E),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Step 4: Join ──────────────────────────────────────────────────────────

  Widget _buildJoinStep() {
    final canJoin = _joinIdController.text.trim().isNotEmpty;
    return Column(
      children: [
        const SizedBox(height: 16),
        const Icon(Icons.login, color: Color(0xFFD8B4FE), size: 72),
        const SizedBox(height: 20),
        const Text(
          'Join Room',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 8),
        const Text(
          'Enter the Room ID to join a game',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: Color(0xFFE9D5FF)),
        ),
        const SizedBox(height: 32),
        _GlassPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Room ID',
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 10),
              _Field(
                controller: _joinIdController,
                hint: 'Enter room ID...',
                isMonospace: true,
                textCapitalization: TextCapitalization.characters,
                onSubmitted: canJoin ? (_) => _joinRoom() : null,
              ),
              const SizedBox(height: 16),
              if (_isLoading)
                const _LoadingPanel()
              else
                _PrimaryButton(
                  label: 'Join Game',
                  enabled: canJoin,
                  onTap: canJoin ? _joinRoom : null,
                ),
            ],
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 16),
          _ErrorBanner(message: _errorMessage!),
        ],
      ],
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x33FFFFFF)),
      ),
      child: child,
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int? maxLength;
  final bool isMonospace;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onSubmitted;

  const _Field({
    required this.controller,
    required this.hint,
    this.maxLength,
    this.isMonospace = false,
    this.textCapitalization = TextCapitalization.none,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLength: maxLength,
      textCapitalization: textCapitalization,
      onSubmitted: onSubmitted,
      style: TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontFamily: isMonospace ? 'monospace' : null,
        letterSpacing: isMonospace ? 2 : null,
      ),
      cursorColor: Colors.white,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        counterText: '',
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0x66FFFFFF)),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: const Color(0x0FFFFFFF),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback? onTap;
  final Color? color;

  const _PrimaryButton({
    required this.label,
    required this.enabled,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          gradient: enabled && color == null
              ? const LinearGradient(
                  colors: [Color(0xFF9333EA), Color(0xFFEC4899)],
                )
              : null,
          color: color != null
              ? (enabled ? color : Colors.grey.shade700)
              : (enabled ? null : Colors.grey.shade700),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

class _BigModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _BigModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0x1AFFFFFF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0x33FFFFFF)),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 40),
            const SizedBox(height: 10),
            Text(title,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 4),
            Text(subtitle,
                style: const TextStyle(fontSize: 13, color: Colors.white60),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _LoadingPanel extends StatelessWidget {
  const _LoadingPanel();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 54,
      child: Center(
        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
      ),
      child: Text(message, style: const TextStyle(color: Colors.red, fontSize: 13)),
    );
  }
}
