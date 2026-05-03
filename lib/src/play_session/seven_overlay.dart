import 'package:flutter/material.dart';

class SevenOverlay extends StatefulWidget {
  final bool isActive;
  const SevenOverlay({super.key, required this.isActive});

  @override
  State<SevenOverlay> createState() => _SevenOverlayState();
}

class _SevenOverlayState extends State<SevenOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _arrowController;

  @override
  void initState() {
    super.initState();
    _arrowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _arrowController.dispose();
    super.dispose();
  }

  // Returns the animation phase for an arrow with the given stagger delay fraction.
  double _phase(double delayFraction) =>
      (_arrowController.value + (1.0 - delayFraction)) % 1.0;

  // Maps phase → opacity using keyframes [0, max, max, 0] over 3 equal segments.
  double _opacity(double delayFraction, double max) {
    final p = _phase(delayFraction);
    if (p < 1 / 3) return p * 3 * max;
    if (p < 2 / 3) return max;
    return (1.0 - (p - 2 / 3) * 3) * max;
  }

  // Maps phase → y offset using keyframes [0, half, half, half*2].
  double _yOffset(double delayFraction, double half) {
    final p = _phase(delayFraction);
    if (p < 1 / 3) return p * 3 * half;
    if (p < 2 / 3) return half;
    return half + (p - 2 / 3) * 3 * half;
  }

  Widget _buildOuterArrow(int i) {
    final delay = i * 0.075; // 0.15s stagger / 2s period
    return Opacity(
      opacity: _opacity(delay, 0.8).clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, _yOffset(delay, 80.0)),
        child: const Icon(
          Icons.keyboard_arrow_down,
          size: 48,
          color: Color(0xFF60A5FA),
        ),
      ),
    );
  }

  Widget _buildInnerArrow(int i) {
    final delay = i * 0.10; // 0.2s stagger / 2s period
    return Opacity(
      opacity: _opacity(delay, 0.6).clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, _yOffset(delay, 70.0)),
        child: const Icon(
          Icons.arrow_downward,
          size: 40,
          color: Color(0xFF93C5FD),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: widget.isActive ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: IgnorePointer(
        child: SizedBox.expand(
          child: Stack(
            children: [
              // Blue tint
              Container(color: const Color(0x4D1E3A8A)),

              // Center card
              Center(
                child: AnimatedScale(
                  scale: widget.isActive ? 1.0 : 0.5,
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.elasticOut,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: const Color(0xFF93C5FD), width: 2),
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
                          'Play 7 or Lower',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.arrow_downward,
                                color: Colors.white, size: 28),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_downward,
                                color: Colors.white, size: 28),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_downward,
                                color: Colors.white, size: 28),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Cascading arrows
              Positioned.fill(
                child: ClipRect(
                  child: AnimatedBuilder(
                    animation: _arrowController,
                    builder: (context, _) {
                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final h = constraints.maxHeight;
                          final w = constraints.maxWidth;
                          return Stack(children: [
                            for (int i = 0; i < 4; i++)
                              Positioned(
                                left: 32,
                                top: h * (0.15 + i * 0.20),
                                child: _buildOuterArrow(i),
                              ),
                            for (int i = 0; i < 4; i++)
                              Positioned(
                                right: 32,
                                top: h * (0.15 + i * 0.20),
                                child: _buildOuterArrow(i),
                              ),
                            for (int i = 0; i < 3; i++)
                              Positioned(
                                left: w * 0.25 - 20,
                                top: h * (0.20 + i * 0.25),
                                child: _buildInnerArrow(i),
                              ),
                            for (int i = 0; i < 3; i++)
                              Positioned(
                                right: w * 0.25 - 20,
                                top: h * (0.20 + i * 0.25),
                                child: _buildInnerArrow(i),
                              ),
                          ]);
                        },
                      );
                    },
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
