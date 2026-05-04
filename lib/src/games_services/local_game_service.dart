import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';

import 'package:karma_palace/src/model/firebase/room.dart';
import 'package:karma_palace/src/model/firebase/player.dart';
import 'package:karma_palace/src/model/firebase/card.dart' as game_card;
import 'package:karma_palace/src/games_services/ai_player_service.dart';

class LocalGameService extends ChangeNotifier {
  static final Logger _log = Logger('LocalGameService');
  static final LocalGameService _instance = LocalGameService._internal();

  factory LocalGameService() => _instance;
  LocalGameService._internal();

  static const Uuid _uuid = Uuid();

  // Game state
  Room? _currentRoom;
  String? _currentPlayerId;
  bool _isConnected = false;
  bool _gameInProgress = false;
  AIDifficulty _aiDifficulty = AIDifficulty.medium;
  Timer? _aiTurnTimer;

  // Callback for pick-up notifications
  Function(String)? _onPickUpEffect;

  // Callback for burn effects
  Function(String)? _onBurnEffect;

  // A face-down card that was flipped but couldn't be played — awaiting pick-up
  game_card.Card? _revealedFaceDownCard;

  // Getters
  Room? get currentRoom => _currentRoom;
  String? get currentPlayerId => _currentPlayerId;
  bool get isConnected => _isConnected;
  bool get isHost => true; // Always true in single player
  bool get isInGame => _currentRoom != null;
  bool get gameInProgress => _gameInProgress;
  AIDifficulty get aiDifficulty => _aiDifficulty;
  game_card.Card? get revealedFaceDownCard => _revealedFaceDownCard;

  /// Set callback for pick-up notifications
  void setPickUpEffectCallback(Function(String) callback) {
    _onPickUpEffect = callback;
  }

  /// Clear pick-up effect callback
  void clearPickUpEffectCallback() {
    _onPickUpEffect = null;
  }

  /// Set callback for burn effects
  void setBurnEffectCallback(Function(String) callback) {
    _onBurnEffect = callback;
  }

  /// Clear burn effect callback
  void clearBurnEffectCallback() {
    _onBurnEffect = null;
  }

  String _displayName(String playerId) {
    if (playerId == _currentPlayerId) return 'You';
    return _currentRoom!.players
        .firstWhere(
          (p) => p.id == playerId,
          orElse: () => _currentRoom!.players.first,
        )
        .name;
  }

  /// Create a new single player game
  Future<void> createSinglePlayerGame(
    String playerName,
    AIDifficulty difficulty, {
    int aiPlayerCount = 1,
  }) async {
    try {
      _aiDifficulty = difficulty;
      final playerId = _uuid.v4();
      final totalPlayers = aiPlayerCount + 1;
      final cardsNeeded = totalPlayers * 9;

      // Use a double deck if needed (>52 cards)
      List<game_card.Card> deck = _createShuffledDeck();
      if (cardsNeeded > deck.length) {
        deck = [...deck, ..._createShuffledDeck()]..shuffle();
      }

      // Create human player
      final humanPlayer = Player(
        id: playerId,
        name: playerName,
        isPlaying: true,
        hand: deck.take(3).toList(),
        faceUp: deck.skip(3).take(3).toList(),
        faceDown: deck.skip(6).take(3).toList(),
        isConnected: true,
        lastSeen: DateTime.now(),
        turnOrder: 0,
      );

      // Create AI players
      final players = <Player>[humanPlayer];
      for (int i = 0; i < aiPlayerCount; i++) {
        final offset = 9 + i * 9;
        players.add(
          Player(
            id: _uuid.v4(),
            name: AIPlayerService.generateAIName(),
            isPlaying: false,
            hand: deck.skip(offset).take(3).toList(),
            faceUp: deck.skip(offset + 3).take(3).toList(),
            faceDown: deck.skip(offset + 6).take(3).toList(),
            isConnected: true,
            lastSeen: DateTime.now(),
            turnOrder: i + 1,
          ),
        );
      }

      // Create room
      final room = Room(
        id: 'single-player-${_uuid.v4().substring(0, 8)}',
        players: players,
        currentPlayer: playerId,
        gameState: GameState.waiting,
        deck: deck.skip(cardsNeeded).toList(),
        playPile: [],
        createdAt: DateTime.now(),
        lastActivity: DateTime.now(),
      );

      _currentRoom = room;
      _currentPlayerId = playerId;
      _isConnected = true;
      _gameInProgress = false;

      _log.info('Created single player game with AI difficulty: $difficulty');
      notifyListeners();
    } catch (e) {
      _log.severe('Failed to create single player game: $e');
      rethrow;
    }
  }

  /// Swap a hand card with a face-up card before the game starts
  Future<void> swapPreGameCards(String handCardId, String faceUpCardId) async {
    if (_currentRoom == null || _currentPlayerId == null) {
      throw Exception('Not in a game');
    }
    if (_currentRoom!.gameState != GameState.waiting) {
      throw Exception('Can only swap before the game starts');
    }

    final playerIndex = _currentRoom!.players.indexWhere(
      (p) => p.id == _currentPlayerId,
    );
    if (playerIndex == -1) throw Exception('Player not found');

    final player = _currentRoom!.players[playerIndex];
    final handCardIndex = player.hand.indexWhere((c) => c.id == handCardId);
    final faceUpCardIndex = player.faceUp.indexWhere(
      (c) => c.id == faceUpCardId,
    );

    if (handCardIndex == -1) throw Exception('Hand card not found');
    if (faceUpCardIndex == -1) throw Exception('Face-up card not found');

    final newHand = List<game_card.Card>.from(player.hand);
    final newFaceUp = List<game_card.Card>.from(player.faceUp);
    final temp = newHand[handCardIndex];
    newHand[handCardIndex] = newFaceUp[faceUpCardIndex];
    newFaceUp[faceUpCardIndex] = temp;

    final updatedPlayer = Player(
      id: player.id,
      name: player.name,
      isPlaying: player.isPlaying,
      hand: newHand,
      faceUp: newFaceUp,
      faceDown: player.faceDown,
      isConnected: player.isConnected,
      lastSeen: player.lastSeen,
      turnOrder: player.turnOrder,
      forcedToPlayLow: player.forcedToPlayLow,
    );

    final updatedPlayers = List<Player>.from(_currentRoom!.players);
    updatedPlayers[playerIndex] = updatedPlayer;

    _currentRoom = Room(
      id: _currentRoom!.id,
      players: updatedPlayers,
      currentPlayer: _currentRoom!.currentPlayer,
      gameState: _currentRoom!.gameState,
      deck: _currentRoom!.deck,
      playPile: _currentRoom!.playPile,
      createdAt: _currentRoom!.createdAt,
      lastActivity: DateTime.now(),
    );

    notifyListeners();
  }

  /// Start the single player game
  Future<void> startGame() async {
    if (_currentRoom == null) {
      throw Exception('No game to start');
    }

    try {
      _gameInProgress = true;

      final players = _currentRoom!.players;
      final startIndex = Random().nextInt(players.length);
      final startPlayerId = players[startIndex].id;
      final updatedPlayers = players.map((p) => Player(
        id: p.id,
        name: p.name,
        isPlaying: p.id == startPlayerId,
        hand: p.hand,
        faceUp: p.faceUp,
        faceDown: p.faceDown,
        isConnected: p.isConnected,
        lastSeen: p.lastSeen,
        turnOrder: p.turnOrder,
        forcedToPlayLow: p.forcedToPlayLow,
      )).toList();

      final updatedRoom = Room(
        id: _currentRoom!.id,
        players: updatedPlayers,
        currentPlayer: startPlayerId,
        gameState: GameState.playing,
        deck: _currentRoom!.deck,
        playPile: [],
        createdAt: _currentRoom!.createdAt,
        lastActivity: DateTime.now(),
      );

      _currentRoom = updatedRoom;
      _log.info('Started single player game');
      notifyListeners();

      if (startPlayerId != _currentPlayerId) {
        _scheduleAITurn();
      }
    } catch (e) {
      _log.severe('Failed to start game: $e');
      rethrow;
    }
  }

  /// Play a card (human player)
  Future<void> playCard(game_card.Card card, String sourceZone) async {
    if (_currentRoom == null || _currentPlayerId == null) {
      throw Exception('Not in a game');
    }

    try {
      final currentPlayer = _currentRoom!.players.firstWhere(
        (p) => p.id == _currentPlayerId,
      );

      if (!currentPlayer.isPlaying) {
        throw Exception('Not your turn');
      }

      // For face-down cards: remove first, then check validity (blind flip).
      // If invalid, reveal the card and wait for the player to pick up.
      if (sourceZone == 'faceDown') {
        final flippedPlayer = _removeCardFromPlayer(
          currentPlayer,
          card,
          'faceDown',
        );
        if (!_canPlayCard(card, currentPlayer, sourceZone)) {
          _revealedFaceDownCard = card;
          final updatedPlayers = _currentRoom!.players
              .map((p) => p.id == _currentPlayerId ? flippedPlayer : p)
              .toList();
          _currentRoom = Room(
            id: _currentRoom!.id,
            players: updatedPlayers,
            currentPlayer: _currentRoom!.currentPlayer,
            gameState: _currentRoom!.gameState,
            deck: _currentRoom!.deck,
            playPile: _currentRoom!.playPile,
            createdAt: _currentRoom!.createdAt,
            lastActivity: DateTime.now(),
            resetActive: _currentRoom!.resetActive,
          );
          _log.info(
            'Face-down flip revealed ${card.displayString} — invalid, awaiting pick-up',
          );
          notifyListeners();
          return;
        }
      } else {
        // Validate that the card can be played according to game rules
        if (!_canPlayCard(card, currentPlayer, sourceZone)) {
          throw Exception('Cannot play ${card.displayString} - invalid move');
        }
      }

      // Remove card from player's zone
      final updatedPlayer = _removeCardFromPlayer(
        currentPlayer,
        card,
        sourceZone,
      );

      // Add card to play pile
      final updatedPlayPile = [..._currentRoom!.playPile, card];

      // Draw cards from deck until player has 3 cards in hand (if deck has cards)
      final cardsToDraw = 3 - updatedPlayer.hand.length;
      final cardsDrawn = <game_card.Card>[];
      final remainingDeck = <game_card.Card>[];

      if (cardsToDraw > 0 && _currentRoom!.deck.isNotEmpty) {
        final drawCount = cardsToDraw > _currentRoom!.deck.length
            ? _currentRoom!.deck.length
            : cardsToDraw;
        cardsDrawn.addAll(_currentRoom!.deck.take(drawCount));
        remainingDeck.addAll(_currentRoom!.deck.skip(drawCount));
      } else {
        remainingDeck.addAll(_currentRoom!.deck);
      }

      // Update player with drawn cards
      final finalPlayer = Player(
        id: updatedPlayer.id,
        name: updatedPlayer.name,
        isPlaying: updatedPlayer.isPlaying,
        hand: [...updatedPlayer.hand, ...cardsDrawn],
        faceUp: updatedPlayer.faceUp,
        faceDown: updatedPlayer.faceDown,
        isConnected: updatedPlayer.isConnected,
        lastSeen: updatedPlayer.lastSeen,
        turnOrder: updatedPlayer.turnOrder,
      );

      // Move to next player
      final nextPlayerId = _getNextPlayerId();

      // Update isPlaying status for all players
      final updatedPlayers = _currentRoom!.players.map((p) {
        if (p.id == _currentPlayerId) {
          return finalPlayer;
        } else {
          return Player(
            id: p.id,
            name: p.name,
            isPlaying: p.id == nextPlayerId,
            hand: p.hand,
            faceUp: p.faceUp,
            faceDown: p.faceDown,
            isConnected: p.isConnected,
            lastSeen: p.lastSeen,
            turnOrder: p.turnOrder,
            forcedToPlayLow: p.id == nextPlayerId ? p.forcedToPlayLow : false,
          );
        }
      }).toList();

      // Handle special card effects
      final (
        finalPlayPile,
        finalCurrentPlayer,
        finalNextPlayerId,
      ) = _handleSpecialCardEffects(
        card,
        updatedPlayPile,
        nextPlayerId,
        updatedPlayers,
      );

      final roomId = _currentRoom!.id;
      final gameState = _currentRoom!.gameState;
      final createdAt = _currentRoom!.createdAt;
      final resetActive = card.specialEffect == game_card.SpecialEffect.reset;

      if (finalPlayPile.isEmpty && updatedPlayPile.isNotEmpty) {
        _currentRoom = Room(
          id: roomId,
          players: finalCurrentPlayer,
          currentPlayer: finalNextPlayerId,
          gameState: gameState,
          deck: remainingDeck,
          playPile: updatedPlayPile,
          createdAt: createdAt,
          lastActivity: DateTime.now(),
          resetActive: resetActive,
        );
        notifyListeners();
        await Future.delayed(const Duration(milliseconds: 800));
      }

      final updatedRoom = Room(
        id: roomId,
        players: finalCurrentPlayer,
        currentPlayer: finalNextPlayerId,
        gameState: gameState,
        deck: remainingDeck,
        playPile: finalPlayPile,
        createdAt: createdAt,
        lastActivity: DateTime.now(),
        resetActive: resetActive,
      );

      _currentRoom = updatedRoom;
      _revealedFaceDownCard = null;
      _log.info(
        'Human played card: ${card.displayString}, drew ${cardsDrawn.length} cards',
      );
      notifyListeners();

      // Check if AI should play next
      if (finalNextPlayerId != _currentPlayerId) {
        _scheduleAITurn();
      }
    } catch (e) {
      _log.severe('Failed to play card: $e');
      rethrow;
    }
  }

  /// Play multiple cards at once (human player)
  Future<void> playMultipleCards(
    List<game_card.Card> cards,
    String sourceZone,
  ) async {
    if (_currentRoom == null || _currentPlayerId == null) {
      throw Exception('Not in a game');
    }

    if (sourceZone == 'faceDown') {
      throw Exception('Face-down cards must be played one at a time');
    }

    if (cards.isEmpty) {
      throw Exception('No cards to play');
    }

    try {
      final currentPlayer = _currentRoom!.players.firstWhere(
        (p) => p.id == _currentPlayerId,
      );

      if (!currentPlayer.isPlaying) {
        throw Exception('Not your turn');
      }

      // Validate that all cards can be played according to game rules
      for (final card in cards) {
        if (!_canPlayCard(card, currentPlayer, sourceZone)) {
          throw Exception('Cannot play ${card.displayString} - invalid move');
        }
      }

      // Remove all cards from player's zone
      var updatedPlayer = currentPlayer;
      final updatedPlayPile = <game_card.Card>[..._currentRoom!.playPile];

      for (final card in cards) {
        updatedPlayer = _removeCardFromPlayer(updatedPlayer, card, sourceZone);
        updatedPlayPile.add(card);
      }

      // Draw cards from deck until player has 3 cards in hand (if deck has cards)
      final cardsToDraw = 3 - updatedPlayer.hand.length;
      final cardsDrawn = <game_card.Card>[];
      final remainingDeck = <game_card.Card>[];

      if (cardsToDraw > 0 && _currentRoom!.deck.isNotEmpty) {
        final drawCount = cardsToDraw > _currentRoom!.deck.length
            ? _currentRoom!.deck.length
            : cardsToDraw;
        cardsDrawn.addAll(_currentRoom!.deck.take(drawCount));
        remainingDeck.addAll(_currentRoom!.deck.skip(drawCount));
      } else {
        remainingDeck.addAll(_currentRoom!.deck);
      }

      // Update player with drawn cards
      final finalPlayer = Player(
        id: updatedPlayer.id,
        name: updatedPlayer.name,
        isPlaying: updatedPlayer.isPlaying,
        hand: [...updatedPlayer.hand, ...cardsDrawn],
        faceUp: updatedPlayer.faceUp,
        faceDown: updatedPlayer.faceDown,
        isConnected: updatedPlayer.isConnected,
        lastSeen: updatedPlayer.lastSeen,
        turnOrder: updatedPlayer.turnOrder,
      );

      // Move to next player
      final nextPlayerId = _getNextPlayerId();

      // Update isPlaying status for all players
      final updatedPlayers = _currentRoom!.players.map((p) {
        if (p.id == _currentPlayerId) {
          return finalPlayer;
        } else {
          return Player(
            id: p.id,
            name: p.name,
            isPlaying: p.id == nextPlayerId,
            hand: p.hand,
            faceUp: p.faceUp,
            faceDown: p.faceDown,
            isConnected: p.isConnected,
            lastSeen: p.lastSeen,
            turnOrder: p.turnOrder,
            forcedToPlayLow: p.id == nextPlayerId ? p.forcedToPlayLow : false,
          );
        }
      }).toList();

      // Handle special card effects for the last card played
      final lastCard = cards.last;
      final (
        finalPlayPile,
        finalCurrentPlayer,
        finalNextPlayerId,
      ) = _handleSpecialCardEffects(
        lastCard,
        updatedPlayPile,
        nextPlayerId,
        updatedPlayers,
        skipCount: cards.where((card) => card.value == '9').length,
      );

      final roomId = _currentRoom!.id;
      final gameState = _currentRoom!.gameState;
      final createdAt = _currentRoom!.createdAt;
      final resetActive = lastCard.specialEffect == game_card.SpecialEffect.reset;

      if (finalPlayPile.isEmpty && updatedPlayPile.isNotEmpty) {
        _currentRoom = Room(
          id: roomId,
          players: finalCurrentPlayer,
          currentPlayer: finalNextPlayerId,
          gameState: gameState,
          deck: remainingDeck,
          playPile: updatedPlayPile,
          createdAt: createdAt,
          lastActivity: DateTime.now(),
          resetActive: resetActive,
        );
        notifyListeners();
        await Future.delayed(const Duration(milliseconds: 800));
      }

      final updatedRoom = Room(
        id: roomId,
        players: finalCurrentPlayer,
        currentPlayer: finalNextPlayerId,
        gameState: gameState,
        deck: remainingDeck,
        playPile: finalPlayPile,
        createdAt: createdAt,
        lastActivity: DateTime.now(),
        resetActive: resetActive,
      );

      _currentRoom = updatedRoom;
      _log.info(
        'Human played ${cards.length} cards: ${cards.map((c) => c.displayString).join(', ')}, drew ${cardsDrawn.length} cards',
      );
      notifyListeners();

      // Check if AI should play next
      if (finalNextPlayerId != _currentPlayerId) {
        _scheduleAITurn();
      }
    } catch (e) {
      _log.severe('Failed to play multiple cards: $e');
      rethrow;
    }
  }

  /// Pick up the play pile (human player)
  Future<void> pickUpPile() async {
    if (_currentRoom == null || _currentPlayerId == null) {
      throw Exception('Not in a game');
    }

    try {
      final currentPlayer = _currentRoom!.players.firstWhere(
        (p) => p.id == _currentPlayerId,
      );

      if (!currentPlayer.isPlaying) {
        throw Exception('Not your turn');
      }

      // Add all cards from play pile (plus any revealed face-down card) to player's hand
      final updatedHand = [
        ...currentPlayer.hand,
        ..._currentRoom!.playPile,
        if (_revealedFaceDownCard != null) _revealedFaceDownCard!,
      ];

      // Draw cards from deck until player has 3 cards in hand (if deck has cards)
      final cardsToDraw = 3 - updatedHand.length;
      final cardsDrawn = <game_card.Card>[];
      final remainingDeck = <game_card.Card>[];

      if (cardsToDraw > 0 && _currentRoom!.deck.isNotEmpty) {
        final drawCount = cardsToDraw > _currentRoom!.deck.length
            ? _currentRoom!.deck.length
            : cardsToDraw;
        cardsDrawn.addAll(_currentRoom!.deck.take(drawCount));
        remainingDeck.addAll(_currentRoom!.deck.skip(drawCount));
      } else {
        remainingDeck.addAll(_currentRoom!.deck);
      }

      final updatedPlayer = Player(
        id: currentPlayer.id,
        name: currentPlayer.name,
        isPlaying: currentPlayer.isPlaying,
        hand: [...updatedHand, ...cardsDrawn],
        faceUp: currentPlayer.faceUp,
        faceDown: currentPlayer.faceDown,
        isConnected: currentPlayer.isConnected,
        lastSeen: currentPlayer.lastSeen,
        turnOrder: currentPlayer.turnOrder,
      );

      // Move to next player
      final nextPlayerId = _getNextPlayerId();

      final updatedPlayers = _currentRoom!.players.map((p) {
        if (p.id == _currentPlayerId) {
          return Player(
            id: updatedPlayer.id,
            name: updatedPlayer.name,
            isPlaying: p.id == nextPlayerId,
            hand: updatedPlayer.hand,
            faceUp: updatedPlayer.faceUp,
            faceDown: updatedPlayer.faceDown,
            isConnected: updatedPlayer.isConnected,
            lastSeen: updatedPlayer.lastSeen,
            turnOrder: updatedPlayer.turnOrder,
          );
        } else {
          return Player(
            id: p.id,
            name: p.name,
            isPlaying: p.id == nextPlayerId,
            hand: p.hand,
            faceUp: p.faceUp,
            faceDown: p.faceDown,
            isConnected: p.isConnected,
            lastSeen: p.lastSeen,
            turnOrder: p.turnOrder,
          );
        }
      }).toList();

      final updatedRoom = Room(
        id: _currentRoom!.id,
        players: updatedPlayers,
        currentPlayer: nextPlayerId,
        gameState: _currentRoom!.gameState,
        deck: remainingDeck,
        playPile: [], // Empty the play pile
        createdAt: _currentRoom!.createdAt,
        lastActivity: DateTime.now(),
      );

      _currentRoom = updatedRoom;
      _revealedFaceDownCard = null;
      _log.info('Human picked up play pile, drew ${cardsDrawn.length} cards');
      notifyListeners();

      // Notify UI about pick-up effect
      _onPickUpEffect?.call(_displayName(_currentPlayerId!));

      // Check if AI should play next
      if (nextPlayerId != _currentPlayerId) {
        _scheduleAITurn();
      }
    } catch (e) {
      _log.severe('Failed to pick up pile: $e');
      rethrow;
    }
  }

  /// Stop the game (cancel AI timer and freeze moves) without clearing state.
  /// Called when a result is announced so the game no longer runs in the background.
  void stopGame() {
    _aiTurnTimer?.cancel();
    _aiTurnTimer = null;
    _gameInProgress = false;
    notifyListeners();
  }

  /// Leave the current game
  Future<void> leaveGame() async {
    _aiTurnTimer?.cancel();
    _aiTurnTimer = null;

    _currentRoom = null;
    _currentPlayerId = null;
    _isConnected = false;
    _gameInProgress = false;
    _revealedFaceDownCard = null;

    notifyListeners();
    _log.info('Left single player game');
  }

  /// Schedule AI turn with a delay
  void _scheduleAITurn() {
    if (!_gameInProgress) return;
    _aiTurnTimer?.cancel();
    _aiTurnTimer = Timer(const Duration(milliseconds: 1500), () {
      _playAITurn();
    });
  }

  /// Play AI turn
  Future<void> _playAITurn() async {
    if (_currentRoom == null || !_gameInProgress) return;

    final currentId = _currentRoom!.currentPlayer;
    if (currentId == _currentPlayerId) {
      return; // Human's turn, shouldn't be here
    }

    final aiPlayer = _currentRoom!.players.firstWhere(
      (p) => p.id == currentId,
      orElse: () => throw Exception('AI player not found'),
    );

    if (!aiPlayer.isPlaying) return;

    final choice = AIPlayerService.chooseCardsToPlay(
      aiPlayer,
      _currentRoom!,
      _aiDifficulty,
    );

    if (choice != null) {
      final (cards, sourceZone) = choice;
      _playAICards(cards, sourceZone);
    } else {
      // AI has no playable cards, pick up pile
      _pickUpAIPile();
    }
  }

  /// Play one or more matching cards for the AI
  Future<void> _playAICards(List<game_card.Card> cards, String sourceZone) async {
    if (_currentRoom == null) return;
    if (cards.isEmpty) return;

    try {
      final aiPlayer = _currentRoom!.players.firstWhere(
        (p) => p.id == _currentRoom!.currentPlayer,
      );

      // Remove cards from AI's zone
      var updatedPlayer = aiPlayer;
      for (final card in cards) {
        updatedPlayer = _removeCardFromPlayer(updatedPlayer, card, sourceZone);
      }

      // Add cards to play pile
      final updatedPlayPile = [..._currentRoom!.playPile, ...cards];

      // Draw cards from deck until AI has 3 cards in hand (if deck has cards)
      final cardsToDraw = 3 - updatedPlayer.hand.length;
      final cardsDrawn = <game_card.Card>[];
      final remainingDeck = <game_card.Card>[];

      if (cardsToDraw > 0 && _currentRoom!.deck.isNotEmpty) {
        final drawCount = cardsToDraw > _currentRoom!.deck.length
            ? _currentRoom!.deck.length
            : cardsToDraw;
        cardsDrawn.addAll(_currentRoom!.deck.take(drawCount));
        remainingDeck.addAll(_currentRoom!.deck.skip(drawCount));
      } else {
        remainingDeck.addAll(_currentRoom!.deck);
      }

      // Update AI player with drawn cards
      final finalPlayer = Player(
        id: updatedPlayer.id,
        name: updatedPlayer.name,
        isPlaying: updatedPlayer.isPlaying,
        hand: [...updatedPlayer.hand, ...cardsDrawn],
        faceUp: updatedPlayer.faceUp,
        faceDown: updatedPlayer.faceDown,
        isConnected: updatedPlayer.isConnected,
        lastSeen: updatedPlayer.lastSeen,
        turnOrder: updatedPlayer.turnOrder,
      );

      // Move to next player
      final nextPlayerId = _getNextPlayerId();

      // Update isPlaying status for all players
      final updatedPlayers = _currentRoom!.players.map((p) {
        if (p.id == aiPlayer.id) {
          return finalPlayer;
        } else {
          return Player(
            id: p.id,
            name: p.name,
            isPlaying: p.id == nextPlayerId,
            hand: p.hand,
            faceUp: p.faceUp,
            faceDown: p.faceDown,
            isConnected: p.isConnected,
            lastSeen: p.lastSeen,
            turnOrder: p.turnOrder,
            forcedToPlayLow: p.id == nextPlayerId ? p.forcedToPlayLow : false,
          );
        }
      }).toList();

      // Handle special card effects for the last card played
      final lastCard = cards.last;
      final (
        finalPlayPile,
        finalCurrentPlayer,
        finalNextPlayerId,
      ) = _handleSpecialCardEffects(
        lastCard,
        updatedPlayPile,
        nextPlayerId,
        updatedPlayers,
        skipCount: cards.where((card) => card.value == '9').length,
      );

      final roomId = _currentRoom!.id;
      final gameState = _currentRoom!.gameState;
      final createdAt = _currentRoom!.createdAt;
      final resetActive = lastCard.specialEffect == game_card.SpecialEffect.reset;

      if (finalPlayPile.isEmpty && updatedPlayPile.isNotEmpty) {
        _currentRoom = Room(
          id: roomId,
          players: finalCurrentPlayer,
          currentPlayer: finalNextPlayerId,
          gameState: gameState,
          deck: remainingDeck,
          playPile: updatedPlayPile,
          createdAt: createdAt,
          lastActivity: DateTime.now(),
          resetActive: resetActive,
        );
        notifyListeners();
        await Future.delayed(const Duration(milliseconds: 800));
      }

      final updatedRoom = Room(
        id: roomId,
        players: finalCurrentPlayer,
        currentPlayer: finalNextPlayerId,
        gameState: gameState,
        deck: remainingDeck,
        playPile: finalPlayPile,
        createdAt: createdAt,
        lastActivity: DateTime.now(),
        resetActive: resetActive,
      );

      _currentRoom = updatedRoom;
      _log.info(
        'AI played ${cards.length} card(s): ${cards.map((c) => c.displayString).join(', ')} from $sourceZone, drew ${cardsDrawn.length} cards',
      );
      notifyListeners();

      // Check if AI should continue playing
      if (finalNextPlayerId != _currentPlayerId) {
        _scheduleAITurn();
      }
    } catch (e) {
      _log.severe('Failed to play AI card: $e');
    }
  }

  /// Pick up pile for AI
  void _pickUpAIPile() {
    if (_currentRoom == null) return;

    try {
      final aiPlayer = _currentRoom!.players.firstWhere(
        (p) => p.id == _currentRoom!.currentPlayer,
      );

      // Add all cards from play pile to AI's hand
      final updatedHand = [...aiPlayer.hand, ..._currentRoom!.playPile];

      // Draw cards from deck until AI has 3 cards in hand (if deck has cards)
      final cardsToDraw = 3 - updatedHand.length;
      final cardsDrawn = <game_card.Card>[];
      final remainingDeck = <game_card.Card>[];

      if (cardsToDraw > 0 && _currentRoom!.deck.isNotEmpty) {
        final drawCount = cardsToDraw > _currentRoom!.deck.length
            ? _currentRoom!.deck.length
            : cardsToDraw;
        cardsDrawn.addAll(_currentRoom!.deck.take(drawCount));
        remainingDeck.addAll(_currentRoom!.deck.skip(drawCount));
      } else {
        remainingDeck.addAll(_currentRoom!.deck);
      }

      final updatedPlayer = Player(
        id: aiPlayer.id,
        name: aiPlayer.name,
        isPlaying: aiPlayer.isPlaying,
        hand: [...updatedHand, ...cardsDrawn],
        faceUp: aiPlayer.faceUp,
        faceDown: aiPlayer.faceDown,
        isConnected: aiPlayer.isConnected,
        lastSeen: aiPlayer.lastSeen,
        turnOrder: aiPlayer.turnOrder,
      );

      // Move to next player
      final nextPlayerId = _getNextPlayerId();

      final updatedPlayers = _currentRoom!.players.map((p) {
        if (p.id == aiPlayer.id) {
          return Player(
            id: updatedPlayer.id,
            name: updatedPlayer.name,
            isPlaying: p.id == nextPlayerId,
            hand: updatedPlayer.hand,
            faceUp: updatedPlayer.faceUp,
            faceDown: updatedPlayer.faceDown,
            isConnected: updatedPlayer.isConnected,
            lastSeen: updatedPlayer.lastSeen,
            turnOrder: updatedPlayer.turnOrder,
          );
        } else {
          return Player(
            id: p.id,
            name: p.name,
            isPlaying: p.id == nextPlayerId,
            hand: p.hand,
            faceUp: p.faceUp,
            faceDown: p.faceDown,
            isConnected: p.isConnected,
            lastSeen: p.lastSeen,
            turnOrder: p.turnOrder,
          );
        }
      }).toList();

      final updatedRoom = Room(
        id: _currentRoom!.id,
        players: updatedPlayers,
        currentPlayer: nextPlayerId,
        gameState: _currentRoom!.gameState,
        deck: remainingDeck,
        playPile: [], // Empty the play pile
        createdAt: _currentRoom!.createdAt,
        lastActivity: DateTime.now(),
      );

      _currentRoom = updatedRoom;
      _log.info('AI picked up play pile, drew ${cardsDrawn.length} cards');
      notifyListeners();

      // Check if AI should continue playing
      if (nextPlayerId != _currentPlayerId) {
        _scheduleAITurn();
      }
    } catch (e) {
      _log.severe('Failed to pick up AI pile: $e');
    }
  }

  /// Get next player ID, skipping players who have already won
  String _getNextPlayerId() {
    if (_currentRoom == null) return _currentPlayerId!;

    final players = _currentRoom!.players;
    final currentIndex = players.indexWhere(
      (p) => p.id == _currentRoom!.currentPlayer,
    );
    if (currentIndex == -1) return _currentPlayerId!;

    for (int i = 1; i <= players.length; i++) {
      final candidate = players[(currentIndex + i) % players.length];
      if (!candidate.hasWon) return candidate.id;
    }

    return _currentPlayerId!;
  }

  /// Get next player ID after a specific player, skipping players who have already won
  String _getNextPlayerIdAfter(String playerId) {
    if (_currentRoom == null) return _currentPlayerId!;

    final players = _currentRoom!.players;
    final currentIndex = players.indexWhere((p) => p.id == playerId);
    if (currentIndex == -1) return players.first.id;

    for (int i = 1; i <= players.length; i++) {
      final candidate = players[(currentIndex + i) % players.length];
      if (!candidate.hasWon) return candidate.id;
    }

    return _currentPlayerId!;
  }

  /// Remove card from player's zone
  Player _removeCardFromPlayer(
    Player player,
    game_card.Card card,
    String sourceZone,
  ) {
    switch (sourceZone) {
      case 'hand':
        final updatedHand = player.hand.where((c) => c.id != card.id).toList();
        return Player(
          id: player.id,
          name: player.name,
          isPlaying: player.isPlaying,
          hand: updatedHand,
          faceUp: player.faceUp,
          faceDown: player.faceDown,
          isConnected: player.isConnected,
          lastSeen: player.lastSeen,
          turnOrder: player.turnOrder,
          forcedToPlayLow: player.forcedToPlayLow,
        );
      case 'faceUp':
        final updatedFaceUp = player.faceUp
            .where((c) => c.id != card.id)
            .toList();
        return Player(
          id: player.id,
          name: player.name,
          isPlaying: player.isPlaying,
          hand: player.hand,
          faceUp: updatedFaceUp,
          faceDown: player.faceDown,
          isConnected: player.isConnected,
          lastSeen: player.lastSeen,
          turnOrder: player.turnOrder,
          forcedToPlayLow: player.forcedToPlayLow,
        );
      case 'faceDown':
        final updatedFaceDown = player.faceDown
            .where((c) => c.id != card.id)
            .toList();
        return Player(
          id: player.id,
          name: player.name,
          isPlaying: player.isPlaying,
          hand: player.hand,
          faceUp: player.faceUp,
          faceDown: updatedFaceDown,
          isConnected: player.isConnected,
          lastSeen: player.lastSeen,
          turnOrder: player.turnOrder,
          forcedToPlayLow: player.forcedToPlayLow,
        );
      default:
        throw Exception('Invalid source zone: $sourceZone');
    }
  }

  /// Handle special card effects
  (List<game_card.Card>, List<Player>, String) _handleSpecialCardEffects(
    game_card.Card card,
    List<game_card.Card> playPile,
    String nextPlayerId,
    List<Player> players, {
    int skipCount = 1,
  }) {
    var finalPlayPile = playPile;
    var finalPlayers = players;
    var finalNextPlayerId = nextPlayerId;

    // Handle card 7 effect (force next player to play 7 or lower)
    if (card.value == '7') {
      finalPlayers = finalPlayers.map((p) {
        if (p.id == finalNextPlayerId) {
          return Player(
            id: p.id,
            name: p.name,
            isPlaying: p.isPlaying,
            hand: p.hand,
            faceUp: p.faceUp,
            faceDown: p.faceDown,
            isConnected: p.isConnected,
            lastSeen: p.lastSeen,
            turnOrder: p.turnOrder,
            forcedToPlayLow: true,
          );
        }
        return p;
      }).toList();
    }

    // Handle card 9 effect (skip next player)
    if (card.value == '9') {
      // Skip one active player per 9 played.
      for (int i = 0; i < skipCount; i++) {
        finalNextPlayerId = _getNextPlayerIdAfter(finalNextPlayerId);
      }
    }

    // Handle card 10 effect (burn - clear play pile and same player goes again)
    if (card.value == '10') {
      finalPlayPile = [];
      // Keep whoever just played (not always the human)
      finalNextPlayerId = _currentRoom!.currentPlayer;
      _onBurnEffect?.call(_displayName(_currentRoom!.currentPlayer));
    }

    // Check for 4-of-a-kind burn effect (4 cards of the same value)
    if (_shouldBurnForFourOfAKind(finalPlayPile)) {
      finalPlayPile = [];
      finalNextPlayerId = _currentRoom!.currentPlayer;
      _log.info(
        '4-of-a-kind detected - play pile burned, same player plays again',
      );
      _onBurnEffect?.call(_displayName(_currentRoom!.currentPlayer));
    }

    // If the resolved next player has already won (e.g. they just played a 10 as
    // their last card), advance past them to the next active player.
    final nextTarget = finalPlayers.firstWhere(
      (p) => p.id == finalNextPlayerId,
      orElse: () => finalPlayers.first,
    );
    if (nextTarget.hasWon) {
      final startIndex = finalPlayers.indexWhere(
        (p) => p.id == finalNextPlayerId,
      );
      for (int i = 1; i < finalPlayers.length; i++) {
        final candidate = finalPlayers[(startIndex + i) % finalPlayers.length];
        if (!candidate.hasWon) {
          finalNextPlayerId = candidate.id;
          break;
        }
      }
    }

    // Re-sync isPlaying flags to match finalNextPlayerId (effects may have changed it)
    finalPlayers = finalPlayers
        .map(
          (p) => Player(
            id: p.id,
            name: p.name,
            isPlaying: p.id == finalNextPlayerId,
            hand: p.hand,
            faceUp: p.faceUp,
            faceDown: p.faceDown,
            isConnected: p.isConnected,
            lastSeen: p.lastSeen,
            turnOrder: p.turnOrder,
            forcedToPlayLow: p.forcedToPlayLow,
          ),
        )
        .toList();

    return (finalPlayPile, finalPlayers, finalNextPlayerId);
  }

  /// Check if the play pile should be burned due to 4 cards of the same value
  bool _shouldBurnForFourOfAKind(List<game_card.Card> playPile) {
    if (playPile.length < 4) return false;

    // Get the last 4 cards
    final lastFourCards = playPile.sublist(playPile.length - 4);

    // Check if all 4 cards have the same value
    final firstValue = lastFourCards[0].value;
    final allSameValue = lastFourCards.every(
      (card) => card.value == firstValue,
    );

    if (allSameValue) {
      _log.info(
        '4-of-a-kind detected: ${lastFourCards.map((c) => c.displayString).join(', ')}',
      );
    }

    return allSameValue;
  }

  /// Create a shuffled deck of cards
  List<game_card.Card> _createShuffledDeck() {
    final suits = ['♠', '♥', '♦', '♣'];
    final values = [
      'A',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      '10',
      'J',
      'Q',
      'K',
    ];
    final deck = <game_card.Card>[];

    for (final suit in suits) {
      for (final value in values) {
        deck.add(game_card.Card(suit: suit, value: value, id: _uuid.v4()));
      }
    }

    deck.shuffle();
    return deck;
  }

  /// Get the effective top card (handles glass effect)
  game_card.Card? _getEffectiveTopCard() {
    if (_currentRoom == null || _currentRoom!.playPile.isEmpty) {
      return null;
    }

    // Start from the top and work backwards through 5s
    for (int i = _currentRoom!.playPile.length - 1; i >= 0; i--) {
      final card = _currentRoom!.playPile[i];

      // If we find a non-5 card, that's our effective top card
      if (card.value != '5') {
        return card;
      }
    }

    // All cards are 5s — treat as empty pile, any card can be played
    return null;
  }

  /// Check if a card can be played according to game rules
  bool _canPlayCard(game_card.Card card, Player player, [String? sourceZone]) {
    if (_currentRoom == null) return false;

    // Check zone restrictions if sourceZone is provided
    if (sourceZone != null) {
      if (sourceZone == 'faceUp' && player.hand.isNotEmpty) {
        return false; // Can't play face-up cards if hand has cards
      }
      if (sourceZone == 'faceDown' &&
          (player.hand.isNotEmpty || player.faceUp.isNotEmpty)) {
        return false; // Can't play face-down cards if hand or face-up has cards
      }
    }

    final effectiveTopCard = _getEffectiveTopCard();

    if (effectiveTopCard == null) {
      return true; // First card of the game
    }

    // Check if reset effect is active (2 was played)
    if (_currentRoom!.resetActive == true) {
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

  @override
  void dispose() {
    _aiTurnTimer?.cancel();
    super.dispose();
  }
}
