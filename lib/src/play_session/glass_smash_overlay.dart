import 'dart:math';

import 'package:flutter/material.dart';

class GlassSmashOverlay extends StatefulWidget {
  final bool isActive;
  const GlassSmashOverlay({super.key, required this.isActive});

  @override
  State<GlassSmashOverlay> createState() => _GlassSmashOverlayState();
}

class _GlassSmashOverlayState extends State<GlassSmashOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_ShardData> _shards;
  late final List<_ParticleData> _particles;
  late final List<_CrackData> _cracks;

  @override
  void initState() {
    super.initState();
    final rng = Random(42);

    _shards = List.generate(20, (i) {
      final ix = (rng.nextDouble() - 0.5) * 200;
      final iy = (rng.nextDouble() - 0.5) * 200;
      final rot = rng.nextDouble() * 2 * pi;
      return _ShardData(
        initialX: ix,
        initialY: iy,
        rotation: rot,
        size: 20 + rng.nextDouble() * 60,
        delay: rng.nextDouble() * 0.2,
        targetX: ix * 4 + (rng.nextDouble() - 0.5) * 100,
        targetY: iy * 4 + rng.nextDouble() * 300 + 200,
        targetRotation: rot + 2 * pi + rng.nextDouble() * 2 * pi,
      );
    });

    _particles = List.generate(30, (i) => _ParticleData(
          targetX: (rng.nextDouble() - 0.5) * 600,
          targetY: rng.nextDouble() * 400 + 100,
          delay: 0.3 + rng.nextDouble() * 0.3,
        ));

    // Primary radial cracks: 12 evenly spaced, growing from center
    _cracks = [
      ...List.generate(12, (i) => _CrackData(
            angle: i * 30 * pi / 180,
            lengthFraction: (40 + rng.nextDouble() * 20) / 100,
            startDelay: i * 0.02 / 2.0, // normalised to [0,1] over 2s
            duration: 0.15,
            isPrimary: true,
            startOffsetFraction: 0.0,
          )),
      // Secondary offset cracks: 8 lines branching off
      ...List.generate(8, (i) {
        final angle = (i * 45 + 22.5) * pi / 180;
        final branchAngle = angle + pi / 6;
        return _CrackData(
          angle: branchAngle,
          lengthFraction: (20 + rng.nextDouble() * 15) / 100,
          startDelay: (0.1 + i * 0.025) / 2.0,
          duration: 0.125,
          isPrimary: false,
          startOffsetFraction: 0.15,
        );
      }),
    ];

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
  }

  @override
  void didUpdateWidget(GlassSmashOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller.forward(from: 0);
    } else if (!widget.isActive) {
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: widget.isActive ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: IgnorePointer(
        child: SizedBox.expand(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = _controller.value;
              return LayoutBuilder(
                builder: (context, constraints) {
                  final cx = constraints.maxWidth / 2;
                  final cy = constraints.maxHeight / 2;
                  return Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
                      // Cyan glass tint that fades out by ~0.6s
                      Positioned.fill(
                        child: Opacity(
                          opacity: _glassTintOpacity(t),
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0x66CFFAFE),
                                  Color(0x4DBFDBFE),
                                  Color(0x66CFFAFE),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Crack lines painted on canvas
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _CrackPainter(_cracks, t),
                        ),
                      ),

                      // Impact glow at center
                      _buildImpactFlash(cx, cy, t),

                      // Shards flying outward
                      for (final s in _shards) _buildShard(s, cx, cy, t),

                      // Small particles
                      for (final p in _particles) _buildParticle(p, cx, cy, t),

                      // "Glass!" message card
                      _buildMessageCard(t),

                      // White flash at impact moment
                      Positioned.fill(
                        child: Opacity(
                          opacity: _whiteFlashOpacity(t),
                          child: Container(color: Colors.white),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  // Glass tint: holds at full opacity for first 0.3 normalised units, then fades.
  double _glassTintOpacity(double t) {
    if (t < 0.3) return 1.0;
    return ((1.0 - t) / 0.7).clamp(0.0, 1.0);
  }

  // Flash: quick spike to 0.6 opacity then decay, completes within 0.2 normalised.
  double _whiteFlashOpacity(double t) {
    if (t < 0.05) return (t / 0.05) * 0.6;
    if (t < 0.2) return ((0.2 - t) / 0.15) * 0.6;
    return 0.0;
  }

  Widget _buildImpactFlash(double cx, double cy, double t) {
    const dur = 0.25;
    if (t >= dur) return const SizedBox.shrink();
    final lt = t / dur;
    final scale = lt * 3.0;
    final opacity = lt < 0.5 ? lt * 2.0 : (1.0 - lt) * 2.0;
    return Positioned(
      left: cx - 64,
      top: cy - 64,
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: scale.clamp(0.0, 3.0),
          child: Container(
            width: 128,
            height: 128,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.8),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.5),
                  blurRadius: 40,
                  spreadRadius: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShard(_ShardData s, double cx, double cy, double t) {
    // Delay: (0.3 + shard.delay) seconds, normalised: /2.0
    final startT = (0.3 + s.delay) / 2.0;
    const dur = 0.75; // 1.5s / 2s
    if (t < startT) return const SizedBox.shrink();
    final lt = ((t - startT) / dur).clamp(0.0, 1.0);
    final eased = Curves.easeInOut.transform(lt);

    final x = _lerp(s.initialX, s.targetX, eased);
    final y = _lerp(s.initialY, s.targetY, eased);
    final rot = _lerp(s.rotation, s.targetRotation, eased);

    final opacity = lt < 0.25
        ? lt / 0.25
        : lt < 0.75
            ? 1.0
            : 1.0 - (lt - 0.75) / 0.25;
    final scale = lt < 0.75 ? 1.0 : 1.0 - (lt - 0.75) / 0.25 * 0.5;

    return Positioned(
      left: cx + x - s.size / 2,
      top: cy + y - s.size * 0.15,
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Transform.rotate(
          angle: rot,
          child: Transform.scale(
            scale: scale,
            child: CustomPaint(
              size: Size(s.size, s.size),
              painter: const _PentagonPainter(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildParticle(_ParticleData p, double cx, double cy, double t) {
    final startT = p.delay / 2.0;
    const dur = 0.6; // 1.2s / 2s
    if (t < startT) return const SizedBox.shrink();
    final lt = ((t - startT) / dur).clamp(0.0, 1.0);
    final eased = Curves.easeOut.transform(lt);

    final x = p.targetX * eased;
    final y = p.targetY * eased;
    final opacity = lt < 0.3 ? lt / 0.3 : 1.0 - (lt - 0.3) / 0.7;
    final scale = lt < 0.3 ? lt / 0.3 : 1.0 - (lt - 0.3) / 0.7 * 0.5;

    return Positioned(
      left: cx + x - 4,
      top: cy + y - 4,
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: scale.clamp(0.0, 1.0),
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xCC67E8F9),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageCard(double t) {
    const startT = 0.25; // 0.5s delay
    const dur = 0.35;
    if (t < startT) return const SizedBox.shrink();
    final lt = ((t - startT) / dur).clamp(0.0, 1.0);
    final scale = Curves.elasticOut.transform(lt);
    final opacity = (lt * 3).clamp(0.0, 1.0);
    final dy = _lerp(100.0, 0.0, Curves.easeOut.transform(lt));

    return Align(
      alignment: const Alignment(0, 0.35),
      child: Opacity(
        opacity: opacity,
        child: Transform.translate(
          offset: Offset(0, dy),
          child: Transform.scale(
            scale: scale,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF06B6D4), Color(0xFF2563EB)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF67E8F9), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '💎 Glass! 💎',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '5 Played — See Through',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;
}

// ── Data classes ─────────────────────────────────────────────────────────────

class _ShardData {
  final double initialX, initialY, rotation, size, delay;
  final double targetX, targetY, targetRotation;
  const _ShardData({
    required this.initialX,
    required this.initialY,
    required this.rotation,
    required this.size,
    required this.delay,
    required this.targetX,
    required this.targetY,
    required this.targetRotation,
  });
}

class _ParticleData {
  final double targetX, targetY, delay;
  const _ParticleData(
      {required this.targetX, required this.targetY, required this.delay});
}

class _CrackData {
  final double angle, lengthFraction, startDelay, duration, startOffsetFraction;
  final bool isPrimary;
  const _CrackData({
    required this.angle,
    required this.lengthFraction,
    required this.startDelay,
    required this.duration,
    required this.isPrimary,
    required this.startOffsetFraction,
  });
}

// ── Painters ─────────────────────────────────────────────────────────────────

class _CrackPainter extends CustomPainter {
  final List<_CrackData> cracks;
  final double t;

  const _CrackPainter(this.cracks, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final refLen = min(size.width, size.height);

    for (final crack in cracks) {
      if (t < crack.startDelay) continue;
      final lt = ((t - crack.startDelay) / crack.duration).clamp(0.0, 1.0);
      final progress = Curves.easeOut.transform(lt);

      final totalLen = crack.lengthFraction * refLen;
      final startFrac = crack.startOffsetFraction;

      final sx = cx + cos(crack.angle) * totalLen * startFrac;
      final sy = cy + sin(crack.angle) * totalLen * startFrac;
      final ex = cx + cos(crack.angle) * totalLen * (startFrac + (1 - startFrac) * progress);
      final ey = cy + sin(crack.angle) * totalLen * (startFrac + (1 - startFrac) * progress);

      canvas.drawLine(
        Offset(sx, sy),
        Offset(ex, ey),
        Paint()
          ..color = crack.isPrimary
              ? const Color(0x9964C8FF)
              : const Color(0x6696DCFF)
          ..strokeWidth = crack.isPrimary ? 2.0 : 1.5
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_CrackPainter old) => old.t != t;
}

class _PentagonPainter extends CustomPainter {
  const _PentagonPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.5, 0)
      ..lineTo(size.width, size.height * 0.4)
      ..lineTo(size.width * 0.8, size.height)
      ..lineTo(size.width * 0.2, size.height)
      ..lineTo(0, size.height * 0.4)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xCCB2EBF2), Color(0x9993C5FD)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        ..style = PaintingStyle.fill,
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0x6667E8F9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }

  @override
  bool shouldRepaint(_PentagonPainter old) => false;
}
