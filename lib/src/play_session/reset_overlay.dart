import 'dart:math';

import 'package:flutter/material.dart';

class ResetOverlay extends StatefulWidget {
  final bool isActive;
  const ResetOverlay({super.key, required this.isActive});

  @override
  State<ResetOverlay> createState() => _ResetOverlayState();
}

class _ResetOverlayState extends State<ResetOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_SparkleData> _sparkles;

  @override
  void initState() {
    super.initState();
    final rng = Random(55);
    _sparkles = List.generate(22, (i) => _SparkleData(
          angle: rng.nextDouble() * 2 * pi,
          distance: 70 + rng.nextDouble() * 190,
          size: 8 + rng.nextDouble() * 10,
          delay: rng.nextDouble() * 0.2,
        ));
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void didUpdateWidget(ResetOverlay old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !old.isActive) _controller.forward(from: 0);
    if (!widget.isActive) _controller.reset();
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
                      // White flash
                      Positioned.fill(
                        child: Opacity(
                          opacity: _whiteFlash(t),
                          child: Container(color: Colors.white),
                        ),
                      ),

                      // Violet tint
                      Positioned.fill(
                        child: Opacity(
                          opacity: (t < 0.1
                                  ? t / 0.1
                                  : 1.0 - (t - 0.1) / 0.9)
                              .clamp(0.0, 0.25),
                          child: Container(color: const Color(0xFF7C3AED)),
                        ),
                      ),

                      // Expanding rings
                      for (int i = 0; i < 3; i++) _buildRing(cx, cy, t, i),

                      // Star sparkles radiating outward
                      for (final s in _sparkles) _buildSparkle(s, cx, cy, t),

                      // Message card
                      _buildMessageCard(t),
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

  double _whiteFlash(double t) {
    if (t < 0.04) return (t / 0.04) * 0.75;
    if (t < 0.18) return ((0.18 - t) / 0.14) * 0.75;
    return 0.0;
  }

  Widget _buildRing(double cx, double cy, double t, int i) {
    final startT = i * 0.09;
    if (t < startT) return const SizedBox.shrink();
    final lt = ((t - startT) / 0.55).clamp(0.0, 1.0);
    final radius = lt * 210;
    final opacity =
        (lt < 0.15 ? lt / 0.15 : 1.0 - (lt - 0.15) / 0.85).clamp(0.0, 0.75);
    return Positioned(
      left: cx - radius,
      top: cy - radius,
      child: Opacity(
        opacity: opacity,
        child: Container(
          width: radius * 2,
          height: radius * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const [
                Color(0xFFC4B5FD),
                Color(0xFFA78BFA),
                Color(0xFF818CF8),
              ][i],
              width: 2.5 - i * 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSparkle(_SparkleData s, double cx, double cy, double t) {
    final startT = s.delay;
    const dur = 0.65;
    if (t < startT) return const SizedBox.shrink();
    final lt = ((t - startT) / dur).clamp(0.0, 1.0);
    final eased = Curves.easeOut.transform(lt);

    final x = cx + cos(s.angle) * s.distance * eased;
    final y = cy + sin(s.angle) * s.distance * eased;
    final opacity =
        (lt < 0.15 ? lt / 0.15 : 1.0 - (lt - 0.15) / 0.85).clamp(0.0, 1.0);
    final scale = lt < 0.15 ? lt / 0.15 : 1.0 - (lt - 0.15) / 0.85 * 0.3;

    return Positioned(
      left: x - s.size / 2,
      top: y - s.size / 2,
      child: Opacity(
        opacity: opacity,
        child: Transform.scale(
          scale: scale.clamp(0.0, 1.0),
          child: Icon(
            Icons.star,
            size: s.size,
            color: lt < 0.5
                ? const Color(0xFFC4B5FD)
                : const Color(0xFF818CF8),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageCard(double t) {
    const startT = 0.18;
    const dur = 0.3;
    if (t < startT) return const SizedBox.shrink();
    final lt = ((t - startT) / dur).clamp(0.0, 1.0);
    final scale = Curves.elasticOut.transform(lt);
    final opacity = (lt * 3).clamp(0.0, 1.0);

    return Align(
      alignment: Alignment.center,
      child: Opacity(
        opacity: opacity,
        child: Transform.scale(
          scale: scale,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFC4B5FD), width: 2),
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
                  '♻️ Reset!',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'Play Anything Next',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SparkleData {
  final double angle, distance, size, delay;
  const _SparkleData({
    required this.angle,
    required this.distance,
    required this.size,
    required this.delay,
  });
}
