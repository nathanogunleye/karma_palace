import 'dart:math';

import 'package:flutter/material.dart';

class BurnOverlay extends StatefulWidget {
  final bool isActive;
  const BurnOverlay({super.key, required this.isActive});

  @override
  State<BurnOverlay> createState() => _BurnOverlayState();
}

class _BurnOverlayState extends State<BurnOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_EmberData> _embers;
  late final List<_FlameData> _flames;

  @override
  void initState() {
    super.initState();
    final rng = Random(77);

    _embers = List.generate(25, (i) {
      final angle = -pi / 2 + (rng.nextDouble() - 0.5) * pi * 1.2;
      return _EmberData(
        angle: angle,
        speed: 180 + rng.nextDouble() * 280,
        size: 4 + rng.nextDouble() * 6,
        delay: rng.nextDouble() * 0.3,
        color: const [
          Color(0xFFFF6B00),
          Color(0xFFFF9900),
          Color(0xFFFFCC00),
          Color(0xFFFF4500),
        ][rng.nextInt(4)],
      );
    });

    _flames = List.generate(9, (i) => _FlameData(
          xFraction: 0.04 + rng.nextDouble() * 0.92,
          width: 18 + rng.nextDouble() * 36,
          height: 70 + rng.nextDouble() * 130,
          delay: rng.nextDouble() * 0.25,
          hue: rng.nextDouble(),
        ));

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
  }

  @override
  void didUpdateWidget(BurnOverlay old) {
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
                  final w = constraints.maxWidth;
                  final h = constraints.maxHeight;
                  final cx = w / 2;
                  final cy = h / 2;
                  return Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
                      // Orange-red tint
                      Positioned.fill(
                        child: Opacity(
                          opacity: (t < 0.08
                                  ? t / 0.08
                                  : 1.0 - (t - 0.08) / 0.92)
                              .clamp(0.0, 0.45),
                          child: Container(color: const Color(0xFFFF4500)),
                        ),
                      ),

                      // Expanding fireball rings from center
                      for (int i = 0; i < 3; i++)
                        _buildRing(cx, cy, t, i),

                      // Flames rising from bottom
                      for (final f in _flames) _buildFlame(f, w, h, t),

                      // Ember sparks
                      for (final e in _embers) _buildEmber(e, cx, cy, t),

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

  Widget _buildRing(double cx, double cy, double t, int i) {
    final startT = i * 0.07;
    if (t < startT) return const SizedBox.shrink();
    final lt = ((t - startT) / 0.45).clamp(0.0, 1.0);
    final radius = lt * 180;
    final opacity =
        (lt < 0.25 ? lt / 0.25 : 1.0 - (lt - 0.25) / 0.75).clamp(0.0, 0.7);
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
                Color(0xFFFF4500),
                Color(0xFFFF8C00),
                Color(0xFFFFCC00),
              ][i],
              width: 3.0 - i * 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFlame(_FlameData f, double w, double h, double t) {
    if (t < f.delay) return const SizedBox.shrink();
    const dur = 0.8;
    final lt = ((t - f.delay) / dur).clamp(0.0, 1.0);

    final travel = h * 0.72;
    final startY = h - f.height * 0.3;
    final y = startY - lt * travel;
    final x = f.xFraction * w + sin(lt * pi * 3) * 9;
    final opacity =
        (lt < 0.08 ? lt / 0.08 : lt < 0.7 ? 1.0 : 1.0 - (lt - 0.7) / 0.3)
            .clamp(0.0, 0.85);
    final topColor = Color.lerp(
        const Color(0xFFFF4500), const Color(0xFFFFEE00), f.hue)!;

    return Positioned(
      left: x - f.width / 2,
      top: y - f.height / 2,
      child: Opacity(
        opacity: opacity,
        child: Container(
          width: f.width,
          height: f.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(f.width / 2),
              topRight: Radius.circular(f.width / 2),
              bottomLeft: const Radius.circular(3),
              bottomRight: const Radius.circular(3),
            ),
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [const Color(0xFFCC1100), topColor],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmber(_EmberData e, double cx, double cy, double t) {
    final startT = e.delay / 2.0;
    const dur = 0.6;
    if (t < startT) return const SizedBox.shrink();
    final lt = ((t - startT) / dur).clamp(0.0, 1.0);
    final eased = Curves.easeOut.transform(lt);

    final x = cx + cos(e.angle) * e.speed * eased;
    final y = cy + sin(e.angle) * e.speed * eased + lt * lt * 50;
    final opacity =
        (lt < 0.25 ? lt / 0.25 : 1.0 - (lt - 0.25) / 0.75).clamp(0.0, 1.0);

    return Positioned(
      left: x - e.size / 2,
      top: y - e.size / 2,
      child: Opacity(
        opacity: opacity,
        child: Container(
          width: e.size,
          height: e.size,
          decoration: BoxDecoration(shape: BoxShape.circle, color: e.color),
        ),
      ),
    );
  }

  Widget _buildMessageCard(double t) {
    const startT = 0.28;
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
                colors: [Color(0xFFEF4444), Color(0xFFB91C1C)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFCA5A5), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '🔥 Burn! 🔥',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'Pile Cleared — Play Again',
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

class _EmberData {
  final double angle, speed, size, delay;
  final Color color;
  const _EmberData({
    required this.angle,
    required this.speed,
    required this.size,
    required this.delay,
    required this.color,
  });
}

class _FlameData {
  final double xFraction, width, height, delay, hue;
  const _FlameData({
    required this.xFraction,
    required this.width,
    required this.height,
    required this.delay,
    required this.hue,
  });
}
