import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:logging/logging.dart';

import 'package:karma_palace/src/audio/audio_controller.dart';
import 'package:karma_palace/src/audio/sounds.dart';
import 'package:karma_palace/src/games_services/firebase_game_service.dart';
import 'package:karma_palace/src/game_internals/karma_palace_game_state.dart';
import 'package:karma_palace/src/model/firebase/card.dart' as game_card;
import 'package:karma_palace/src/model/firebase/player.dart';
import 'package:karma_palace/src/model/firebase/room.dart';
import 'karma_palace_card_widget.dart';
import 'live_board_widget.dart';

class KarmaPalaceLiveScreen extends StatefulWidget {
  const KarmaPalaceLiveScreen({super.key});

  @override
  State<KarmaPalaceLiveScreen> createState() => _KarmaPalaceLiveScreenState();
}

class _KarmaPalaceLiveScreenState extends State<KarmaPalaceLiveScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  static final Logger _log = Logger('KarmaPalaceLiveScreen');

  int _previousPlayPileLength = 0;
  int _previousWinnerCount = 0;
  bool _winAnnounced = false;
  bool _loserAnnounced = false;

  // Card fly animation — single card
  final GlobalKey _playAreaKey = GlobalKey();
  final GlobalKey _pileKey = GlobalKey();
  final GlobalKey _playerAreaKey = GlobalKey();
  late AnimationController _cardFlyController;
  late Animation<Offset> _flyAnimation;
  late Animation<double> _flyOpacity;
  late Animation<double> _flyScale;
  late Animation<double> _flyRotation;
  game_card.Card? _flyingCard;
  int _flyRun = 0;

  // Card fly animation — multiple cards
  late AnimationController _multiCardController;
  List<game_card.Card> _flyingCards = [];
  List<Animation<Offset>> _multiCardPositions = [];
  List<Animation<double>> _multiCardOpacities = [];
  List<Animation<double>> _multiCardScales = [];
  List<Animation<double>> _multiCardRotations = [];
  int _multiCardFlyRun = 0;

  final Set<String> _selectedCardIds = <String>{};
  bool _isMultiSelectMode = false;
  String? _multiSelectSourceZone;
  String? _multiSelectValue;

  String? _inlineMessage;
  Color _inlineMessageColor = Colors.grey;
  Timer? _messageTimer;

  @override
  void initState() {
    super.initState();
    _cardFlyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _multiCardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeGameState();
    });

    // Listen for pick-up effects
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gameService = context.read<FirebaseGameService>();
      gameService.setPickUpEffectCallback(_onPickUpEffect);
      gameService.setBurnEffectCallback(_onBurnEffect);
      gameService.addListener(_onGameStateChanged);
    });
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _cardFlyController.dispose();
    _multiCardController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    final gameService = context.read<FirebaseGameService>();
    gameService.clearPickUpEffectCallback();
    gameService.clearBurnEffectCallback();
    gameService.removeListener(_onGameStateChanged);
    super.dispose();
  }

  void _showMessage(String text,
      {Color color = Colors.grey,
      Duration duration = const Duration(seconds: 3)}) {
    _messageTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _inlineMessage = text;
      _inlineMessageColor = color;
    });
    _messageTimer = Timer(duration, () {
      if (mounted) setState(() => _inlineMessage = null);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Listen for Firebase service changes and update game state
    final gameService = context.read<FirebaseGameService>();
    final gameState = context.read<KarmaPalaceGameState>();

    // Update game state whenever Firebase room changes
    if (gameService.currentRoom != null &&
        gameService.currentPlayerId != null) {
      _log.info(
          'DEBUG: Updating game state for player: ${gameService.currentPlayerId}');
      _log.info(
          'DEBUG: Current game state player ID: ${gameState.currentPlayerId}');

      // Initialize game state if not already done for this player
      if (gameState.currentPlayerId == null ||
          gameState.currentPlayerId != gameService.currentPlayerId) {
        _log.info(
            'DEBUG: Initializing game state for new player: ${gameService.currentPlayerId}');
        _log.info(
            'DEBUG: Previous player ID was: ${gameState.currentPlayerId}');

        // Reset game state completely for new player
        if (gameState.currentPlayerId != null) {
          _log.info('DEBUG: Resetting game state for different player');
          gameState.resetForNewPlayer();
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          gameState.initializeGame(
              gameService.currentRoom!, gameService.currentPlayerId!);
        });
      } else {
        // Just update the room data
        _log.info('DEBUG: Updating room data for existing player');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          gameState.updateRoom(gameService.currentRoom!);
        });
      }
    }
  }

  void _initializeGameState() {
    final gameService = context.read<FirebaseGameService>();
    final gameState = context.read<KarmaPalaceGameState>();

    if (gameService.currentRoom != null &&
        gameService.currentPlayerId != null) {
      _log.info(
          'DEBUG: Initializing game state for player: ${gameService.currentPlayerId}');
      _log.info(
          'DEBUG: Current game state player ID: ${gameState.currentPlayerId}');
      gameState.initializeGame(
          gameService.currentRoom!, gameService.currentPlayerId!);
      _log.info(
          'Initialized game state for room: ${gameService.currentRoomId}');
    } else {
      _log.info(
          'DEBUG: Cannot initialize game state - room or playerId is null');
    }
  }

  Future<void> _startGame() async {
    try {
      final gameService = context.read<FirebaseGameService>();
      await gameService.startGame();
      _log.info('Game started');
    } catch (e) {
      _log.severe('Failed to start game: $e');
      _showMessage('Failed to start game: $e', color: Colors.red);
    }
  }

  Future<void> _playCard(game_card.Card card, String sourceZone) async {
    try {
      // Face-down cards are blind flips — skip client-side validation so we
      // never reveal the card's identity before or after the play.
      if (sourceZone != 'faceDown') {
        final gameState = context.read<KarmaPalaceGameState>();

        _log.info('DEBUG: Validating card play: ${card.displayString}');
        _log.info(
            'DEBUG: Game state can play card: ${gameState.canPlayCard(card)}');
        _log.info('DEBUG: Is my turn: ${gameState.isMyTurn}');
        _log.info('DEBUG: Game in progress: ${gameState.gameInProgress}');
        _log.info('DEBUG: Current player ID: ${gameState.currentPlayerId}');
        _log.info(
            'DEBUG: Room current player: ${gameState.room?.currentPlayer}');

        if (!gameState.canPlayCard(card)) {
          _log.info('DEBUG: Card play validation failed');
          _showMessage('Cannot play ${card.displayString}', color: Colors.red);
          return;
        }
        _log.info('DEBUG: Card play validation passed');
      }

      final gameService = context.read<FirebaseGameService>();
      await gameService.playCard(card, sourceZone);
      _log.info('Played card: ${card.displayString} from $sourceZone');
      if (sourceZone != 'faceDown') {
        _showMessage('Played ${card.displayString}',
            color: Colors.green, duration: const Duration(seconds: 1));
      }
    } catch (e) {
      _log.severe('Failed to play card: $e');
      _showMessage(e.toString().replaceFirst('Exception: ', ''),
          color: Colors.red);
    }
  }

  Future<void> _pickUpPile() async {
    HapticFeedback.mediumImpact();
    context.read<AudioController>().playSfx(SfxType.huhsh);
    try {
      final gameService = context.read<FirebaseGameService>();
      await gameService.pickUpPile();
      _log.info('Picked up play pile');
    } catch (e) {
      _log.severe('Failed to pick up pile: $e');
      _showMessage('Failed to pick up pile: $e', color: Colors.red);
    }
  }

  Future<void> _leaveRoom() async {
    final gameService = context.read<FirebaseGameService>();

    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => const _ConfirmLeaveDialog(
        title: 'Leave Room?',
        body:
            'Are you sure you want to leave? You will be removed from the game.',
        confirmLabel: 'Leave',
      ),
    );
    if (confirmed != true) return;

    try {
      await gameService.leaveRoom();
      if (mounted) context.go('/');
    } catch (e) {
      _log.severe('Failed to leave room: $e');
    }
  }

  void _triggerCardFly(game_card.Card card, Offset tapCenter) {
    final playAreaBox =
        _playAreaKey.currentContext?.findRenderObject() as RenderBox?;
    final pileBox = _pileKey.currentContext?.findRenderObject() as RenderBox?;
    if (playAreaBox == null || pileBox == null) return;

    final begin = playAreaBox.globalToLocal(tapCenter);
    final pileDest = playAreaBox.globalToLocal(
      pileBox.localToGlobal(pileBox.size.center(Offset.zero)),
    );

    final curved = CurvedAnimation(
        parent: _cardFlyController, curve: Curves.easeInOutCubic);
    _flyAnimation = Tween<Offset>(begin: begin, end: pileDest).animate(curved);
    _flyOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 70),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_cardFlyController);
    _flyScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.12), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.12, end: 0.82), weight: 65),
    ]).animate(curved);
    _flyRotation = Tween<double>(begin: -0.06, end: 0.05).animate(curved);

    final run = ++_flyRun;
    setState(() => _flyingCard = card);
    _cardFlyController.forward(from: 0).then((_) {
      if (mounted && run == _flyRun) setState(() => _flyingCard = null);
    });
  }

  void _triggerMultiCardFly(List<game_card.Card> cards) {
    if (cards.isEmpty) return;
    final playAreaBox =
        _playAreaKey.currentContext?.findRenderObject() as RenderBox?;
    final pileBox = _pileKey.currentContext?.findRenderObject() as RenderBox?;
    final playerAreaBox =
        _playerAreaKey.currentContext?.findRenderObject() as RenderBox?;
    if (playAreaBox == null || pileBox == null) return;

    final n = cards.length;
    final pileDest = playAreaBox.globalToLocal(
      pileBox.localToGlobal(pileBox.size.center(Offset.zero)),
    );

    // Fan cards out from the centre of the current player's card area.
    // Fall back to bottom-centre of the play area if the key isn't ready.
    final Offset baseStart;
    if (playerAreaBox != null) {
      baseStart = playAreaBox.globalToLocal(
        playerAreaBox.localToGlobal(playerAreaBox.size.center(Offset.zero)),
      );
    } else {
      final areaSize = playAreaBox.size;
      baseStart = Offset(areaSize.width / 2, areaSize.height - 120);
    }
    const spread = 30.0; // horizontal gap between card start positions

    // Stagger: each card departs 10 % of the total duration after the previous
    const stagger = 0.10;
    _multiCardController.duration = Duration(
      milliseconds: 320 + (n - 1) * 70,
    );
    _multiCardController.reset();

    final positions = <Animation<Offset>>[];
    final opacities = <Animation<double>>[];
    final scales = <Animation<double>>[];
    final rotations = <Animation<double>>[];

    for (int i = 0; i < n; i++) {
      final t0 = (i * stagger).clamp(0.0, 1.0);
      final t1 = (t0 + (1.0 - stagger * (n - 1))).clamp(t0 + 0.01, 1.0);
      final interval = Interval(t0, t1, curve: Curves.easeInOutCubic);

      final xOffset = (i - (n - 1) / 2.0) * spread;
      final start = baseStart + Offset(xOffset, 0);

      positions.add(
        Tween<Offset>(begin: start, end: pileDest).animate(
          CurvedAnimation(parent: _multiCardController, curve: interval),
        ),
      );
      opacities.add(
        TweenSequence<double>([
          TweenSequenceItem(tween: ConstantTween(1.0), weight: 70),
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
        ]).animate(
          CurvedAnimation(parent: _multiCardController, curve: interval),
        ),
      );
      scales.add(
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.12), weight: 35),
          TweenSequenceItem(tween: Tween(begin: 1.12, end: 0.82), weight: 65),
        ]).animate(
          CurvedAnimation(parent: _multiCardController, curve: interval),
        ),
      );
      rotations.add(
        Tween<double>(
          begin: -0.06 + i * 0.04,
          end: 0.05 - i * 0.02,
        ).animate(
          CurvedAnimation(parent: _multiCardController, curve: interval),
        ),
      );
    }

    final run = ++_multiCardFlyRun;
    setState(() {
      _flyingCards = List<game_card.Card>.from(cards);
      _multiCardPositions = positions;
      _multiCardOpacities = opacities;
      _multiCardScales = scales;
      _multiCardRotations = rotations;
    });

    _multiCardController.forward(from: 0).then((_) {
      if (mounted && run == _multiCardFlyRun) {
        setState(() => _flyingCards = []);
      }
    });
  }

  void _onCardTap(game_card.Card card, String sourceZone, Offset tapCenter) {
    HapticFeedback.lightImpact();
    final gameService = context.read<FirebaseGameService>();
    if (gameService.currentRoom?.gameState != GameState.playing) return;
    _log.info('DEBUG: Card tapped: ${card.displayString} from $sourceZone');

    final canPlayTappedCard = _canCurrentPlayerPlayCard(card, sourceZone);

    // Face-down cards are blind flips, so they must always be played one at a time.
    if (!_isMultiSelectMode && sourceZone != 'faceDown' && canPlayTappedCard) {
      final sameValueCards = _getSameValueCards(card.value, sourceZone);
      if (sameValueCards.length > 1) {
        _startMultiSelectMode(card.value, sourceZone);
        _toggleCardSelection(card.id);
        return;
      }
    }

    if (_isMultiSelectMode &&
        _multiSelectValue == card.value &&
        _multiSelectSourceZone == sourceZone) {
      _toggleCardSelection(card.id);
      return;
    }

    final gameState = context.read<KarmaPalaceGameState>();
    // Face-down cards are always flipped blind — always animate.
    if (sourceZone == 'faceDown' || gameState.canPlayCard(card)) {
      _triggerCardFly(card, tapCenter);
    }
    _playCard(card, sourceZone);
  }

  bool _canCurrentPlayerPlayCard(game_card.Card card, String sourceZone) {
    final gameService = context.read<FirebaseGameService>();
    final room = gameService.currentRoom;
    if (room == null || gameService.currentPlayerId == null) return false;

    final currentPlayer = room.players.firstWhere(
      (p) => p.id == gameService.currentPlayerId,
      orElse: () => room.players.first,
    );

    return _canPlayCard(card, currentPlayer, sourceZone);
  }

  List<game_card.Card> _getSameValueCards(String value, String sourceZone) {
    if (sourceZone == 'faceDown') return [];

    final gameService = context.read<FirebaseGameService>();
    final room = gameService.currentRoom;
    if (room == null || gameService.currentPlayerId == null) return [];
    final currentPlayer = room.players.firstWhere(
      (p) => p.id == gameService.currentPlayerId,
      orElse: () => room.players.first,
    );
    List<game_card.Card> cards;
    switch (sourceZone) {
      case 'hand':
        cards = currentPlayer.hand;
        break;
      case 'faceUp':
        cards = currentPlayer.faceUp;
        break;
      case 'faceDown':
        cards = currentPlayer.faceDown;
        break;
      default:
        return [];
    }
    return cards.where((c) => c.value == value).toList();
  }

  void _startMultiSelectMode(String value, String sourceZone) {
    setState(() {
      _isMultiSelectMode = true;
      _multiSelectValue = value;
      _multiSelectSourceZone = sourceZone;
      _selectedCardIds.clear();
    });
  }

  void _toggleCardSelection(String cardId) {
    setState(() {
      if (_selectedCardIds.contains(cardId)) {
        _selectedCardIds.remove(cardId);
      } else {
        _selectedCardIds.add(cardId);
      }
    });
  }

  void _cancelMultiSelect() {
    setState(() {
      _isMultiSelectMode = false;
      _multiSelectValue = null;
      _multiSelectSourceZone = null;
      _selectedCardIds.clear();
    });
  }

  void _playSelectedCards() {
    if (_selectedCardIds.isEmpty || _multiSelectSourceZone == null) return;
    if (_multiSelectSourceZone == 'faceDown') {
      _cancelMultiSelect();
      return;
    }
    final gameService = context.read<FirebaseGameService>();
    final room = gameService.currentRoom;
    if (room == null || gameService.currentPlayerId == null) return;
    final currentPlayer = room.players.firstWhere(
      (p) => p.id == gameService.currentPlayerId,
      orElse: () => room.players.first,
    );
    List<game_card.Card> sourceCards;
    switch (_multiSelectSourceZone!) {
      case 'hand':
        sourceCards = currentPlayer.hand;
        break;
      case 'faceUp':
        sourceCards = currentPlayer.faceUp;
        break;
      case 'faceDown':
        sourceCards = currentPlayer.faceDown;
        break;
      default:
        return;
    }
    final selectedCards =
        sourceCards.where((c) => _selectedCardIds.contains(c.id)).toList();
    if (selectedCards.isNotEmpty) {
      _triggerMultiCardFly(selectedCards);
      _playMultipleCards(selectedCards, _multiSelectSourceZone!);
    }
    _cancelMultiSelect();
  }

  Future<void> _playMultipleCards(
      List<game_card.Card> cards, String sourceZone) async {
    try {
      final gameService = context.read<FirebaseGameService>();
      await gameService.playMultipleCards(cards, sourceZone);
      _log.info('Played ${cards.length} cards from $sourceZone');
    } catch (e) {
      _log.severe('Failed to play multiple cards: $e');
      _showMessage(e.toString().replaceFirst('Exception: ', ''),
          color: Colors.red);
    }
  }

  /// Check if the current player can play any cards
  bool _canCurrentPlayerPlayAnyCard() {
    final gameService = context.read<FirebaseGameService>();
    final room = gameService.currentRoom;

    if (room == null || gameService.currentPlayerId == null) return false;

    final currentPlayer = room.players.firstWhere(
      (p) => p.id == gameService.currentPlayerId,
      orElse: () => room.players.first,
    );

    // Check hand cards
    for (final card in currentPlayer.hand) {
      if (_canPlayCard(card, currentPlayer, 'hand')) {
        return true;
      }
    }

    // Check face-up cards if hand is empty
    if (currentPlayer.hand.isEmpty) {
      for (final card in currentPlayer.faceUp) {
        if (_canPlayCard(card, currentPlayer, 'faceUp')) {
          return true;
        }
      }
    }

    // Check face-down cards if hand and face-up are empty
    if (currentPlayer.hand.isEmpty && currentPlayer.faceUp.isEmpty) {
      for (final card in currentPlayer.faceDown) {
        if (_canPlayCard(card, currentPlayer, 'faceDown')) {
          return true;
        }
      }
    }

    return false;
  }

  /// True when the player has only face-down cards left (must flip one before picking up).
  bool _isInFaceDownOnlyPhase() {
    final gameService = context.read<FirebaseGameService>();
    final room = gameService.currentRoom;
    if (room == null || gameService.currentPlayerId == null) return false;
    final currentPlayer = room.players.firstWhere(
      (p) => p.id == gameService.currentPlayerId,
      orElse: () => room.players.first,
    );
    return currentPlayer.hand.isEmpty &&
        currentPlayer.faceUp.isEmpty &&
        currentPlayer.faceDown.isNotEmpty;
  }

  /// Get the effective top card (handles glass effect)
  game_card.Card? _getEffectiveTopCard() {
    final gameService = context.read<FirebaseGameService>();
    final room = gameService.currentRoom;

    if (room == null || room.playPile.isEmpty) {
      return null;
    }

    // Start from the top and work backwards through 5s
    for (int i = room.playPile.length - 1; i >= 0; i--) {
      final card = room.playPile[i];

      // If we find a non-5 card, that's our effective top card
      if (card.value != '5') {
        return card;
      }
    }

    // All cards are 5s — treat as empty pile, any card can be played
    return null;
  }

  /// Check if a specific card can be played by the current player
  bool _canPlayCard(game_card.Card card, Player player, String sourceZone) {
    final gameService = context.read<FirebaseGameService>();
    final room = gameService.currentRoom;

    if (room == null) return false;

    // Check zone restrictions
    if (sourceZone == 'faceUp' && player.hand.isNotEmpty) {
      return false; // Can't play face-up cards if hand has cards
    }
    if (sourceZone == 'faceDown' &&
        (player.hand.isNotEmpty || player.faceUp.isNotEmpty)) {
      return false; // Can't play face-down cards if hand or face-up has cards
    }

    final effectiveTopCard = _getEffectiveTopCard();

    if (effectiveTopCard == null) {
      return true; // First card of the game
    }

    // Check if reset effect is active (2 was played)
    if (room.resetActive == true) {
      return true; // Any card can be played after a 2
    }

    // Check if current player is forced to play low (from card 7 effect)
    if (player.forcedToPlayLow == true) {
      return card.numericValue <= 7;
    }

    // Check if card can be played on high cards (J, Q, K)
    if (['J', 'Q', 'K'].contains(effectiveTopCard.value)) {
      return card.canPlayOnHighCard(effectiveTopCard);
    }

    // Check if top card is 7 - forces next player to play 7 or lower
    if (effectiveTopCard.value == '7') {
      return card.numericValue <= 7;
    }

    // Check if playing a special card on a non-royal card
    if (card.hasSpecialEffect &&
        !['J', 'Q', 'K'].contains(effectiveTopCard.value)) {
      return true; // Special cards can be played on any non-royal card
    }

    // Normal card comparison
    return card.numericValue >= effectiveTopCard.numericValue;
  }

  void _onPickUpEffect() {
    if (mounted) {
      context.read<AudioController>().playSfx(SfxType.huhsh);
      _showPickUpNotification();
    }
  }

  void _onBurnEffect() {
    if (mounted) {
      context.read<AudioController>().playSfx(SfxType.erase);
      _showBurnNotification();
    }
  }

  void _showPickUpNotification() {
    _showMessage('📦 Player picked up the pile!', color: Colors.blue);
  }

  void _showBurnNotification() {
    _showMessage('🔥 Play pile burned! Same player goes again.',
        color: Colors.deepOrange);
  }

  void _onGameStateChanged() {
    final gameService = context.read<FirebaseGameService>();
    final room = gameService.currentRoom;

    if (room != null && mounted) {
      final currentPileLength = room.playPile.length;

      if (currentPileLength > _previousPlayPileLength) {
        context.read<AudioController>().playSfx(SfxType.wssh);
      }

      // Detect if pile was emptied (either by burn or pick-up)
      if (_previousPlayPileLength > 0 && currentPileLength == 0) {
        // Pile was emptied - determine if it was a pick-up or burn
        // We'll use a simple heuristic: if it's not our turn, it's likely a pick-up
        final isMyTurn = room.currentPlayer == gameService.currentPlayerId;

        if (!isMyTurn) {
          // Opponent likely picked up the pile
          _onPickUpEffect();
        }
        // If it is our turn, the callbacks will handle burn/pick-up detection
      }

      _previousPlayPileLength = currentPileLength;

      // Check for win condition
      _checkWinCondition(room);
    }
  }

  void _checkWinCondition(Room room) {
    if (room.gameState != GameState.playing) return;
    final gameService = context.read<FirebaseGameService>();
    final humanPlayer = room.players.firstWhere(
      (p) => p.id == gameService.currentPlayerId,
      orElse: () => room.players.last,
    );
    final currentWinnerCount = room.players.where((p) => p.hasWon).length;
    if (currentWinnerCount > _previousWinnerCount) {
      _previousWinnerCount = currentWinnerCount;
      context.read<AudioController>().playSfx(SfxType.congrats);
    }

    if (humanPlayer.hasWon && !_winAnnounced) {
      _winAnnounced = true;
      _showWinNotification(room.playPile.lastOrNull);
      return;
    }

    // Loser detection: only one player still has cards
    if (!_loserAnnounced && room.players.length > 1) {
      final playersWithCards = room.players.where((p) => !p.hasWon).toList();
      if (playersWithCards.length == 1) {
        _loserAnnounced = true;
        final loser = playersWithCards.first;
        final isMe = loser.id == gameService.currentPlayerId;
        _showLoserNotification(
            isMe ? 'You' : loser.name, room.playPile.lastOrNull);
      }
    }
  }

  void _showWinNotification(game_card.Card? winningCard) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierColor: Colors.black,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF3B1461),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x8022C55E)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              const Text(
                'You\'re Out!',
                style: TextStyle(
                  color: Color(0xFF86EFAC),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (winningCard != null) ...[
                _DialogCard(card: winningCard),
                const SizedBox(height: 12),
              ],
              const Text(
                'You\'ve played all your cards! The game continues with the remaining players.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0x1AFFFFFF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0x33FFFFFF)),
                        ),
                        child: const Text(
                          'Watch',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        context.go('/');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0x1A22C55E),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0x5522C55E)),
                        ),
                        child: const Text(
                          'Leave',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Color(0xFF86EFAC),
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLoserNotification(String name, game_card.Card? winningCard) {
    if (!mounted) return;
    final isMe = name == 'You';
    showDialog(
      context: context,
      barrierColor: Colors.black,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF3B1461),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x80EF4444)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('💀', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text(
                isMe ? 'You Lost!' : '$name Lost!',
                style: const TextStyle(
                  color: Color(0xFFFC8181),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (winningCard != null) ...[
                _DialogCard(card: winningCard),
                const SizedBox(height: 12),
              ],
              Text(
                isMe
                    ? 'You\'re the last one holding cards. Better luck next time!'
                    : '$name is the last one holding cards.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {
                  Navigator.pop(ctx);
                  context.go('/');
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0x1AFFFFFF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0x33FFFFFF)),
                  ),
                  child: const Text(
                    'Back to Menu',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRulesDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF3B1461),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x66FFFFFF)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'How to Play Karma Palace',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _RuleSection('Goal'),
                    _RuleText(
                        'Get rid of all your cards. The last player with cards loses!'),
                    SizedBox(height: 12),
                    _RuleSection('Setup'),
                    _RuleText(
                        'Each player gets 3 face-down, 3 face-up, and 3 hand cards.'),
                    SizedBox(height: 12),
                    _RuleSection('Playing'),
                    _RuleBullet(
                        'Play cards equal to or higher than the top card'),
                    _RuleBullet(
                        'Play multiple cards of the same rank together'),
                    _RuleBullet("If you can't play, pick up the entire pile"),
                    SizedBox(height: 12),
                    _RuleSection('Special Cards'),
                    _RuleBullet('2 — Reset, can be played on anything'),
                    _RuleBullet(
                        '5 — Glass (transparent), see through to card below'),
                    _RuleBullet('7 — Next player must play 7 or lower'),
                    _RuleBullet('9 — Skip the next player\'s turn'),
                    _RuleBullet('10 — Burns the pile, same player goes again'),
                    _RuleBullet('Four of a kind also burns the pile'),
                    SizedBox(height: 12),
                    _RuleSection('Card Order'),
                    _RuleText(
                        'Hand first, then face-up, then face-down (blind!).'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0x1AFFFFFF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0x33FFFFFF)),
                  ),
                  child: const Text(
                    'Got it!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildMultiCardOverlays() {
    const cardW = 56.0;
    const cardH = 56.0 * 46 / 32;
    final overlays = <Widget>[];
    for (int i = 0; i < _flyingCards.length && i < _multiCardPositions.length; i++) {
      final card = _flyingCards[i];
      final posAnim = _multiCardPositions[i];
      final opAnim = _multiCardOpacities[i];
      final scAnim = _multiCardScales[i];
      final rotAnim = _multiCardRotations[i];
      overlays.add(
        AnimatedBuilder(
          animation: _multiCardController,
          builder: (context, child) {
            return Positioned(
              left: posAnim.value.dx - cardW / 2,
              top: posAnim.value.dy - cardH / 2,
              child: IgnorePointer(
                child: Transform.rotate(
                  angle: rotAnim.value,
                  child: Transform.scale(
                    scale: scAnim.value,
                    child: Opacity(
                      opacity: opAnim.value.clamp(0.0, 1.0),
                      child: child,
                    ),
                  ),
                ),
              ),
            );
          },
          child: KarmaPalaceCardWidget(
            card: card,
            isFaceDown: false,
            isPlayable: false,
            size: const Size(cardW, cardH),
          ),
        ),
      );
    }
    return overlays;
  }

  @override
  Widget build(BuildContext context) {
    final gameService = context.watch<FirebaseGameService>();

    const gradientDecoration = BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF581C87), Color(0xFF6B21A8), Color(0xFF831843)],
      ),
    );

    if (!gameService.isConnected || gameService.currentRoom == null) {
      return PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            decoration: gradientDecoration,
            child: SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Not connected to a room',
                      style: TextStyle(fontSize: 24, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    _LiveGlassButton(
                        label: 'Back to Main Menu',
                        onTap: () => context.go('/')),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final room = gameService.currentRoom!;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: gradientDecoration,
          child: SafeArea(
            child: Stack(
              key: _playAreaKey,
              clipBehavior: Clip.none,
              children: [
                Column(
                  children: [
                    // Header — Exit | Title/Turn | Rules
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _LiveGlassButton(
                            label: 'Exit',
                            icon: Icons.arrow_back,
                            onTap: _leaveRoom,
                          ),
                          Column(
                            children: [
                              const Text(
                                'Karma Palace',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Consumer<FirebaseGameService>(
                                builder: (context, svc, _) {
                                  final r = svc.currentRoom;
                                  if (r == null || r.gameState != GameState.playing) return const SizedBox.shrink();
                                  final isMyTurn =
                                      r.currentPlayer == svc.currentPlayerId;
                                  final turnName = isMyTurn
                                      ? 'Your Turn'
                                      : "${r.players.firstWhere((p) => p.id == r.currentPlayer, orElse: () => r.players.first).name}'s Turn";
                                  return Text(
                                    turnName,
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 12),
                                  );
                                },
                              ),
                            ],
                          ),
                          _LiveGlassButton(
                            label: 'Rules',
                            onTap: () => _showRulesDialog(context),
                          ),
                        ],
                      ),
                    ),

                    // Game board
                    Expanded(
                      child: LiveBoardWidget(
                        pileKey: _pileKey,
                        playerAreaKey: _playerAreaKey,
                        onCardTap: _onCardTap,
                        selectedCardIds: _selectedCardIds,
                        isMultiSelectMode: _isMultiSelectMode,
                        multiSelectValue: _multiSelectValue,
                        multiSelectSourceZone: _multiSelectSourceZone,
                        inlineMessage: _inlineMessage,
                        inlineMessageColor: _inlineMessageColor,
                      ),
                    ),

                    // Action buttons
                    if (room.gameState == GameState.playing)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _isMultiSelectMode
                                      ? _LiveGameButton(
                                          label:
                                              'Play ${_selectedCardIds.length} Cards',
                                          color: const Color(0xFF22C55E),
                                          onTap: _selectedCardIds.isNotEmpty
                                              ? _playSelectedCards
                                              : null,
                                        )
                                      : _LiveGameButton(
                                          label: 'Play Cards',
                                          color: Colors.grey.shade700,
                                          onTap: null,
                                        ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _isMultiSelectMode
                                      ? _LiveGameButton(
                                          label: 'Cancel',
                                          color: Colors.grey.shade700,
                                          onTap: _cancelMultiSelect,
                                        )
                                      : _LiveGameButton(
                                          label: 'Pick Up Pile',
                                          color: gameService.currentPlayerId ==
                                                      room.currentPlayer &&
                                                  !_canCurrentPlayerPlayAnyCard() &&
                                                  !_isInFaceDownOnlyPhase()
                                              ? const Color(0xFFF97316)
                                              : Colors.grey.shade700,
                                          onTap: gameService.currentPlayerId ==
                                                      room.currentPlayer &&
                                                  !_canCurrentPlayerPlayAnyCard() &&
                                                  !_isInFaceDownOnlyPhase()
                                              ? _pickUpPile
                                              : null,
                                        ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _isMultiSelectMode
                                  ? 'Select ${_multiSelectValue}s to play together'
                                  : '',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white70,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (room.gameState == GameState.waiting)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: _LiveGameButton(
                          label: 'Start Game',
                          color: const Color(0xFF22C55E),
                          onTap: gameService.isHost ? _startGame : null,
                        ),
                      ),
                  ],
                ),
                // Flying card overlay — single card
                if (_flyingCard != null)
                  AnimatedBuilder(
                    animation: _cardFlyController,
                    builder: (context, child) {
                      const cardW = 56.0;
                      const cardH = 56.0 * 46 / 32;
                      return Positioned(
                        left: _flyAnimation.value.dx - cardW / 2,
                        top: _flyAnimation.value.dy - cardH / 2,
                        child: IgnorePointer(
                          child: Transform.rotate(
                            angle: _flyRotation.value,
                            child: Transform.scale(
                              scale: _flyScale.value,
                              child: Opacity(
                                opacity: _flyOpacity.value.clamp(0.0, 1.0),
                                child: child,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    child: KarmaPalaceCardWidget(
                      card: _flyingCard!,
                      isFaceDown: false,
                      isPlayable: false,
                      size: const Size(56, 56 * 46 / 32),
                    ),
                  ),

                // Flying card overlay — multiple cards (multi-select play)
                ..._buildMultiCardOverlays(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Helper widgets ──────────────────────────────────────────────────────────

class _DialogCard extends StatelessWidget {
  final game_card.Card card;
  const _DialogCard({required this.card});

  @override
  Widget build(BuildContext context) {
    final isRed = card.suit == '♥' || card.suit == '♦';
    final color = isRed ? Colors.red : Colors.black;
    return Container(
      width: 72,
      height: 108,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 6,
            left: 7,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(card.value,
                    style: TextStyle(
                        color: color,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        height: 1.1)),
                Text(card.suit,
                    style: TextStyle(color: color, fontSize: 13, height: 1.0)),
              ],
            ),
          ),
          Center(
            child:
                Text(card.suit, style: TextStyle(color: color, fontSize: 34)),
          ),
          Positioned(
            bottom: 6,
            right: 7,
            child: RotatedBox(
              quarterTurns: 2,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(card.value,
                      style: TextStyle(
                          color: color,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          height: 1.1)),
                  Text(card.suit,
                      style:
                          TextStyle(color: color, fontSize: 13, height: 1.0)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveGlassButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;

  const _LiveGlassButton({required this.label, this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0x1AFFFFFF),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 4),
            ],
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

class _LiveGameButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _LiveGameButton({required this.label, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: onTap != null ? color : Colors.grey.shade600,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            textAlign: TextAlign.center),
      ),
    );
  }
}

class _RuleSection extends StatelessWidget {
  final String text;
  const _RuleSection(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          text,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
        ),
      );
}

class _RuleText extends StatelessWidget {
  final String text;
  const _RuleText(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(color: Colors.white70, fontSize: 13),
      );
}

class _RuleBullet extends StatelessWidget {
  final String text;
  const _RuleBullet(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 2),
        child: Text(
          '• $text',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
      );
}

class _ConfirmLeaveDialog extends StatelessWidget {
  final String title;
  final String body;
  final String confirmLabel;

  const _ConfirmLeaveDialog({
    required this.title,
    required this.body,
    required this.confirmLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF3B1461),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x66FFFFFF)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              body,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0x1AFFFFFF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0x33FFFFFF)),
                      ),
                      child: const Text(
                        'Cancel',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0x33EF4444),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0x80EF4444)),
                      ),
                      child: Text(
                        confirmLabel,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFFC8181),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
