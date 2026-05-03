import 'package:flutter/material.dart';

/// Provides a single shared bounce animation to all descendant card widgets.
/// Selected cards read from this shared animation so they bounce in sync.
class CardBounceScope extends StatefulWidget {
  final Widget child;

  const CardBounceScope({super.key, required this.child});

  static Animation<double>? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_CardBounceScopeInherited>()
        ?.animation;
  }

  @override
  State<CardBounceScope> createState() => _CardBounceScopeState();
}

class _CardBounceScopeState extends State<CardBounceScope>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0, end: -5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _CardBounceScopeInherited(
      animation: _animation,
      child: widget.child,
    );
  }
}

class _CardBounceScopeInherited extends InheritedWidget {
  final Animation<double> animation;

  const _CardBounceScopeInherited({
    required this.animation,
    required super.child,
  });

  @override
  bool updateShouldNotify(_CardBounceScopeInherited old) => false;
}
