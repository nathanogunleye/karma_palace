import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../player_progress/player_progress.dart';
import '../style/palette.dart';
import 'custom_name_dialog.dart';
import 'settings.dart';

class SettingsScreen extends StatelessWidget {
  static final Future<PackageInfo> _packageInfoFuture =
      PackageInfo.fromPlatform();

  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();
    final settings = context.watch<SettingsController>();

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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => GoRouter.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0x1AFFFFFF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.arrow_back,
                                color: Colors.white, size: 16),
                            SizedBox(width: 4),
                            Text(
                              'Back',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'Settings',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 68), // balance back button
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

                      // Name
                      _SettingsRow(
                        onTap: () => showCustomNameDialog(context),
                        child: Row(
                          children: [
                            const Icon(Icons.person_outline,
                                color: Colors.white70, size: 20),
                            const SizedBox(width: 12),
                            const Text(
                              'Name',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            ValueListenableBuilder(
                              valueListenable: settings.playerName,
                              builder: (context, name, _) => Text(
                                name,
                                style: const TextStyle(
                                    color: Colors.white54, fontSize: 15),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.chevron_right,
                                color: Colors.white38, size: 20),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Sound FX
                      ValueListenableBuilder<bool>(
                        valueListenable: settings.soundsOn,
                        builder: (context, soundsOn, _) => _SettingsRow(
                          onTap: () => settings.toggleSoundsOn(),
                          child: Row(
                            children: [
                              Icon(
                                soundsOn ? Icons.graphic_eq : Icons.volume_off,
                                color: Colors.white70,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Sound FX',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              _Toggle(value: soundsOn),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Music
                      ValueListenableBuilder<bool>(
                        valueListenable: settings.musicOn,
                        builder: (context, musicOn, _) => _SettingsRow(
                          onTap: () => settings.toggleMusicOn(),
                          child: Row(
                            children: [
                              Icon(
                                musicOn ? Icons.music_note : Icons.music_off,
                                color: Colors.white70,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Music',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              _Toggle(value: musicOn),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Haptics
                      ValueListenableBuilder<bool>(
                        valueListenable: settings.hapticsOn,
                        builder: (context, hapticsOn, _) => _SettingsRow(
                          onTap: () => settings.toggleHapticsOn(),
                          child: Row(
                            children: [
                              Icon(
                                hapticsOn
                                    ? Icons.vibration
                                    : Icons.phone_android,
                                color: Colors.white70,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Haptics',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              _Toggle(value: hapticsOn),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Reset progress
                      _SettingsRow(
                        onTap: () {
                          context.read<PlayerProgress>().reset();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Player progress has been reset.'),
                            ),
                          );
                        },
                        child: const Row(
                          children: [
                            Icon(Icons.delete_outline,
                                color: Color(0xFFFC8181), size: 20),
                            SizedBox(width: 12),
                            Text(
                              'Reset Progress',
                              style: TextStyle(
                                color: Color(0xFFFC8181),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // App version
                      FutureBuilder<PackageInfo>(
                        future: _packageInfoFuture,
                        builder: (context, snapshot) {
                          final packageInfo = snapshot.data;
                          final versionLabel = packageInfo == null
                              ? 'Loading...'
                              : '${packageInfo.version} (Build ${packageInfo.buildNumber})';

                          return _SettingsRow(
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline,
                                    color: Colors.white70, size: 20),
                                const SizedBox(width: 12),
                                const Text(
                                  'Version',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Flexible(
                                  child: Text(
                                    versionLabel,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.end,
                                    style: const TextStyle(
                                        color: Colors.white54, fontSize: 15),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
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

class _SettingsRow extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _SettingsRow({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0x1AFFFFFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x33FFFFFF)),
        ),
        child: child,
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  final bool value;

  const _Toggle({required this.value});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 44,
      height: 26,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13),
        color: value ? const Color(0xFFFACC15) : const Color(0x33FFFFFF),
        border: Border.all(
          color: value ? const Color(0xFFFACC15) : const Color(0x66FFFFFF),
        ),
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 150),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 20,
          height: 20,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
