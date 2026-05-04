import 'package:flutter/material.dart';

class TutorialOverlay extends StatefulWidget {
  final int step;
  final int total;
  final GlobalKey? playerZonesKey;
  final GlobalKey? deckPileRowKey;
  final GlobalKey? handKey;
  final GlobalKey? actionButtonsKey;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onClose;

  const TutorialOverlay({
    super.key,
    required this.step,
    this.total = 13,
    this.playerZonesKey,
    this.deckPileRowKey,
    this.handKey,
    this.actionButtonsKey,
    required this.onNext,
    required this.onBack,
    required this.onClose,
  });

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay> {
  Rect? _highlightRect;

  static const _steps = [
    (
      title: 'Welcome to Karma Palace! 🎉',
      body:
          "Don't be the last player with cards! Get rid of all your cards to win. Let's learn how to play.",
    ),
    (
      title: 'Your Cards Setup 🎴',
      body:
          'You start with 3 face-down cards, 3 face-up cards on top of them, and 3 cards in your hand.',
    ),
    (
      title: 'Playing Cards 🎯',
      body:
          'You must play hand cards first. Select cards of the same rank and click "Play Cards". Cards must be equal or higher than the pile.',
    ),
    (
      title: 'The Pile 📚',
      body:
          'Cards are played onto the pile in the center. You must match or beat the top card value.',
    ),
    (
      title: "Can't Play? Pick Up! ⬆️",
      body:
          'If you have no valid cards to play, click "Pick Up Pile" to take all the cards. Try to avoid this!',
    ),
    (
      title: 'Special Card: 2 🔄',
      body:
          '2s reset the pile! They can be played on anything, and the next player starts fresh.',
    ),
    (
      title: 'Special Card: 5 💎',
      body:
          '5s are "Glass" – they can be played on anything and are transparent (invisible) to the next play.',
    ),
    (
      title: 'Special Card: 7 ⬇️',
      body: '7s force low! The next player must play a 7 or lower.',
    ),
    (
      title: 'Special Card: 9 ⏭️',
      body: '9s skip the next player\'s turn entirely.',
    ),
    (
      title: 'Special Card: 10 🔥',
      body:
          '10s burn the pile! All cards in the pile are discarded and you get to play again.',
    ),
    (
      title: 'Four of a Kind 💥',
      body:
          'Playing 4 cards of the same rank also burns the pile. Collect matching cards for this power move!',
    ),
    (
      title: 'Face-Up & Face-Down Cards 🎲',
      body:
          'After your hand is empty, play face-up cards. After those, play face-down cards blind – you won\'t know what they are!',
    ),
    (
      title: "You're Ready! 🎉",
      body:
          'First to get rid of all cards wins. Last player standing loses. Good luck!',
    ),
  ];

  GlobalKey? _activeKey() {
    switch (widget.step) {
      case 1:
        return widget.playerZonesKey;
      case 2:
        return widget.handKey;
      case 3:
        return widget.deckPileRowKey;
      case 4:
        return widget.actionButtonsKey;
      case 11:
        return widget.playerZonesKey;
      default:
        return null;
    }
  }

  void _updateHighlightRect() {
    final key = _activeKey();
    if (key == null) {
      if (_highlightRect != null) {
        setState(() => _highlightRect = null);
      }
      return;
    }
    final context = key.currentContext;
    if (context == null) return;
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final rect = offset & size;
    if (mounted) {
      setState(() => _highlightRect = rect);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateHighlightRect());
  }

  @override
  void didUpdateWidget(TutorialOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.step != widget.step) {
      _highlightRect = null;
      WidgetsBinding.instance.addPostFrameCallback((_) => _updateHighlightRect());
    }
  }

  Widget _buildPositionedCard(
    BuildContext context,
    ({String title, String body}) stepData,
    bool isLast,
  ) {
    final screenHeight = MediaQuery.of(context).size.height;
    // Put the card at the top when the highlight is in the lower half of the screen
    final pinToTop =
        _highlightRect != null &&
        _highlightRect!.center.dy > screenHeight / 2;

    final card = SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, pinToTop ? 24 : 0, 16, pinToTop ? 0 : 24),
        child: _TutorialCard(
          step: widget.step,
          total: widget.total,
          title: stepData.title,
          body: stepData.body,
          isFirst: widget.step == 0,
          isLast: isLast,
          onNext: isLast ? widget.onClose : widget.onNext,
          onBack: widget.onBack,
          onClose: widget.onClose,
        ),
      ),
    );

    return pinToTop
        ? Positioned(top: 0, left: 0, right: 0, child: card)
        : Positioned(bottom: 0, left: 0, right: 0, child: card);
  }

  @override
  Widget build(BuildContext context) {
    final stepData = _steps[widget.step.clamp(0, _steps.length - 1)];
    final isLast = widget.step == widget.total - 1;

    return Stack(
      children: [
        // Dim overlay — blocks touches to game beneath
        Positioned.fill(
          child: AbsorbPointer(
            child: Container(color: Colors.black38),
          ),
        ),

        // Golden highlight border around active zone
        if (_highlightRect != null)
          Positioned(
            left: _highlightRect!.left - 6,
            top: _highlightRect!.top - 6,
            width: _highlightRect!.width + 12,
            height: _highlightRect!.height + 12,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFFFBBF24),
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFBBF24).withValues(alpha: 0.45),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Tutorial card — sits on whichever half the highlight isn't on
        _buildPositionedCard(context, stepData, isLast),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Tutorial card
// ---------------------------------------------------------------------------

class _TutorialCard extends StatelessWidget {
  final int step;
  final int total;
  final String title;
  final String body;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onClose;

  const _TutorialCard({
    required this.step,
    required this.total,
    required this.title,
    required this.body,
    required this.isFirst,
    required this.isLast,
    required this.onNext,
    required this.onBack,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7C3AED), Color(0xFFDB2777)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress row
          Row(
            children: [
              Expanded(child: _ProgressDots(step: step, total: total)),
              const SizedBox(width: 8),
              Text(
                '${step + 1}/$total',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (isFirst) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onClose,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 16),

          // Title
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),

          const SizedBox(height: 10),

          // Body
          Text(
            body,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 15,
              height: 1.45,
            ),
          ),

          const SizedBox(height: 24),

          // Navigation
          Row(
            children: [
              if (!isFirst)
                GestureDetector(
                  onTap: onBack,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_back, color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Back',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const Spacer(),
              GestureDetector(
                onTap: onNext,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFACC15), Color(0xFFF97316)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFACC15).withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isLast ? "Let's Play!" : 'Next',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressDots extends StatelessWidget {
  final int step;
  final int total;
  const _ProgressDots({required this.step, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final isActiveOrPast = i <= step;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.only(right: 3),
          height: 5,
          width: isActiveOrPast ? 16 : 5,
          decoration: BoxDecoration(
            color: isActiveOrPast
                ? Colors.white
                : Colors.white.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}
