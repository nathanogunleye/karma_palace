import 'package:flutter/material.dart';

class SkipOverlay extends StatefulWidget {
  final bool isActive;
  const SkipOverlay({super.key, required this.isActive});

  @override
  State<SkipOverlay> createState() => _SkipOverlayState();
}

class _SkipOverlayState extends State<SkipOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void didUpdateWidget(SkipOverlay old) {
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
                  return Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
                      // Slate-blue tint
                      Positioned.fill(
                        child: Opacity(
                          opacity: (t < 0.08
                                  ? t / 0.08
                                  : 1.0 - (t - 0.08) / 0.92)
                              .clamp(0.0, 0.38),
                          child: Container(color: const Color(0xFF1E293B)),
                        ),
                      ),

                      // Sweeping double-arrow rows
                      for (int i = 0; i < 3; i++)
                        _buildSweepRow(i, w, h, t),

                      // Big skip icon scaling in at center
                      _buildSkipIcon(t),

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

  Widget _buildSweepRow(int row, double w, double h, double t) {
    // Each row sweeps left → right with a stagger
    final offset = row * 0.12;
    final p = (t - offset).clamp(0.0, 1.0);
    if (p <= 0) return const SizedBox.shrink();

    final x = -80.0 + p * (w + 160);
    final y = h * (0.28 + row * 0.22);
    final opacity =
        (p < 0.06 ? p / 0.06 : p > 0.88 ? (1.0 - p) / 0.12 : 1.0)
            .clamp(0.0, 0.8);

    return Positioned(
      left: x,
      top: y - 22,
      child: Opacity(
        opacity: opacity,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.double_arrow,
                color: row == 1
                    ? const Color(0xFFCBD5E1)
                    : const Color(0xFF94A3B8),
                size: row == 1 ? 44 : 36),
            const SizedBox(width: 2),
            Icon(Icons.double_arrow,
                color: const Color(0xFF64748B),
                size: row == 1 ? 36 : 28),
          ],
        ),
      ),
    );
  }

  Widget _buildSkipIcon(double t) {
    const startT = 0.04;
    const dur = 0.32;
    if (t < startT) return const SizedBox.shrink();
    final lt = ((t - startT) / dur).clamp(0.0, 1.0);
    final scale = Curves.elasticOut.transform(lt);
    final opacity =
        (t < 0.65 ? 1.0 : 1.0 - (t - 0.65) / 0.35).clamp(0.0, 1.0);

    return Center(
      child: Opacity(
        opacity: opacity,
        child: Transform.scale(
          scale: scale,
          child: const Icon(
            Icons.skip_next_rounded,
            color: Colors.white,
            size: 110,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageCard(double t) {
    const startT = 0.3;
    const dur = 0.28;
    if (t < startT) return const SizedBox.shrink();
    final lt = ((t - startT) / dur).clamp(0.0, 1.0);
    final scale = Curves.elasticOut.transform(lt);
    final opacity = (lt * 3).clamp(0.0, 1.0);

    return Align(
      alignment: const Alignment(0, 0.42),
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
                colors: [Color(0xFF475569), Color(0xFF0F172A)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF94A3B8), width: 2),
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
                  '⏭ Skipped!',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'Next Player Loses Their Turn',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
