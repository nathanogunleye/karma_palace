import 'dart:async';
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

  // Getters
  Room? get currentRoom => _currentRoom;
  String? get currentPlayerId => _currentPlayerId;
  bool get isConnected => _isConnected;
  bool get isHost => true; // Always true in single player
  bool get isInGame => _currentRoom != null;
  bool get gameInProgress => _gameInProgress;
  AIDifficulty get aiDifficulty => _aiDifficulty;

  /// Create a new single player game
  Future<void> createSinglePlayerGame(String playerName, AIDifficulty difficulty) async {
    try {
      _aiDifficulty = difficulty;
      final playerId = _uuid.v4();
      final aiPlayerId = _uuid.v4();
      
      // Create initial deck
      final deck = _createShuffledDeck();
      
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

      // Create AI player
      final aiPlayer = Player(
        id: aiPlayerId,
        name: AIPlayerService.generateAIName(),
        isPlaying: false,
        hand: deck.skip(9).take(3).toList(),
        faceUp: deck.skip(12).take(3).toList(),
        faceDown: deck.skip(15).take(3).toList(),
        isConnected: true,
        lastSeen: DateTime.now(),
        turnOrder: 1,
      );

      // Create room
      final room = Room(
        id: 'single-player-${_uuid.v4().substring(0, 8)}',
        players: [humanPlayer, aiPlayer],
        currentPlayer: playerId,
        gameState: GameState.waiting,
        deck: deck.skip(18).toList(),
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

  /// Start the single player game
  Future<void> startGame() async {
    if (_currentRoom == null) {
      throw Exception('No game to start');
    }

    try {
      _gameInProgress = true;
      
      final updatedRoom = Room(
        id: _currentRoom!.id,
        players: _currentRoom!.players,
        currentPlayer: _currentRoom!.currentPlayer,
        gameState: GameState.playing,
        deck: _currentRoom!.deck,
        playPile: [],
        createdAt: _currentRoom!.createdAt,
        lastActivity: DateTime.now(),
      );

      _currentRoom = updatedRoom;
      _log.info('Started single player game');
      notifyListeners();
      
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
      final currentPlayer = _currentRoom!.players.firstWhere((p) => p.id == _currentPlayerId);
      
      if (!currentPlayer.isPlaying) {
        throw Exception('Not your turn');
      }

      // Validate that the card can be played according to game rules
      if (!_canPlayCard(card, currentPlayer, sourceZone)) {
        throw Exception('Cannot play ${card.displayString} - invalid move');
      }

      // Remove card from player's zone
      final updatedPlayer = _removeCardFromPlayer(currentPlayer, card, sourceZone);
      
      // Add card to play pile
      final updatedPlayPile = [..._currentRoom!.playPile, card];
      
      // Draw cards from deck until player has 3 cards in hand (if deck has cards)
      final cardsToDraw = 3 - updatedPlayer.hand.length;
      final cardsDrawn = <game_card.Card>[];
      final remainingDeck = <game_card.Card>[];
      
      if (cardsToDraw > 0 && _currentRoom!.deck.isNotEmpty) {
        final drawCount = cardsToDraw > _currentRoom!.deck.length ? _currentRoom!.deck.length : cardsToDraw;
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
      final (finalPlayPile, finalCurrentPlayer, finalNextPlayerId) = _handleSpecialCardEffects(
        card, 
        updatedPlayPile, 
        nextPlayerId, 
        updatedPlayers
      );

      final updatedRoom = Room(
        id: _currentRoom!.id,
        players: finalCurrentPlayer,
        currentPlayer: finalNextPlayerId,
        gameState: _currentRoom!.gameState,
        deck: remainingDeck,
        playPile: finalPlayPile,
        createdAt: _currentRoom!.createdAt,
        lastActivity: DateTime.now(),
        resetActive: card.specialEffect == game_card.SpecialEffect.reset,
      );

      _currentRoom = updatedRoom;
      _log.info('Human played card: ${card.displayString}, drew ${cardsDrawn.length} cards');
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

  /// Pick up the play pile (human player)
  Future<void> pickUpPile() async {
    if (_currentRoom == null || _currentPlayerId == null) {
      throw Exception('Not in a game');
    }

    try {
      final currentPlayer = _currentRoom!.players.firstWhere((p) => p.id == _currentPlayerId);
      
      if (!currentPlayer.isPlaying) {
        throw Exception('Not your turn');
      }

      // Add all cards from play pile to player's hand
      final updatedHand = [...currentPlayer.hand, ..._currentRoom!.playPile];
      
      // Draw cards from deck until player has 3 cards in hand (if deck has cards)
      final cardsToDraw = 3 - updatedHand.length;
      final cardsDrawn = <game_card.Card>[];
      final remainingDeck = <game_card.Card>[];
      
      if (cardsToDraw > 0 && _currentRoom!.deck.isNotEmpty) {
        final drawCount = cardsToDraw > _currentRoom!.deck.length ? _currentRoom!.deck.length : cardsToDraw;
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
      
      final updatedPlayers = _currentRoom!.players.map((p) => 
        p.id == _currentPlayerId ? updatedPlayer : p
      ).toList();

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
      _log.info('Human picked up play pile, drew ${cardsDrawn.length} cards');
      notifyListeners();
      
      // Check if AI should play next
      if (nextPlayerId != _currentPlayerId) {
        _scheduleAITurn();
      }
      
    } catch (e) {
      _log.severe('Failed to pick up pile: $e');
      rethrow;
    }
  }

  /// Leave the current game
  Future<void> leaveGame() async {
    _aiTurnTimer?.cancel();
    _aiTurnTimer = null;
    
    _currentRoom = null;
    _currentPlayerId = null;
    _isConnected = false;
    _gameInProgress = false;
    
    notifyListeners();
    _log.info('Left single player game');
  }

  /// Schedule AI turn with a delay
  void _scheduleAITurn() {
    _aiTurnTimer?.cancel();
    _aiTurnTimer = Timer(const Duration(milliseconds: 1500), () {
      _playAITurn();
    });
  }

  /// Play AI turn
  void _playAITurn() {
    if (_currentRoom == null) return;
    
    final aiPlayer = _currentRoom!.players.firstWhere(
      (p) => p.id != _currentPlayerId,
      orElse: () => throw Exception('AI player not found'),
    );
    
    if (!aiPlayer.isPlaying) return;
    
    final choice = AIPlayerService.chooseCardToPlay(aiPlayer, _currentRoom!, _aiDifficulty);
    
    if (choice != null) {
      final (card, sourceZone) = choice;
      _playAICard(card, sourceZone);
    } else {
      // AI has no playable cards, pick up pile
      _pickUpAIPile();
    }
  }

  /// Play a card for the AI
  void _playAICard(game_card.Card card, String sourceZone) {
    if (_currentRoom == null) return;
    
    try {
      final aiPlayer = _currentRoom!.players.firstWhere((p) => p.id != _currentPlayerId);
      
      // Remove card from AI's zone
      final updatedPlayer = _removeCardFromPlayer(aiPlayer, card, sourceZone);
      
      // Add card to play pile
      final updatedPlayPile = [..._currentRoom!.playPile, card];
      
      // Draw cards from deck until AI has 3 cards in hand (if deck has cards)
      final cardsToDraw = 3 - updatedPlayer.hand.length;
      final cardsDrawn = <game_card.Card>[];
      final remainingDeck = <game_card.Card>[];
      
      if (cardsToDraw > 0 && _currentRoom!.deck.isNotEmpty) {
        final drawCount = cardsToDraw > _currentRoom!.deck.length ? _currentRoom!.deck.length : cardsToDraw;
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

      // Handle special card effects
      final (finalPlayPile, finalCurrentPlayer, finalNextPlayerId) = _handleSpecialCardEffects(
        card, 
        updatedPlayPile, 
        nextPlayerId, 
        updatedPlayers
      );

      final updatedRoom = Room(
        id: _currentRoom!.id,
        players: finalCurrentPlayer,
        currentPlayer: finalNextPlayerId,
        gameState: _currentRoom!.gameState,
        deck: remainingDeck,
        playPile: finalPlayPile,
        createdAt: _currentRoom!.createdAt,
        lastActivity: DateTime.now(),
        resetActive: card.specialEffect == game_card.SpecialEffect.reset,
      );

      _currentRoom = updatedRoom;
      _log.info('AI played card: ${card.displayString} from $sourceZone, drew ${cardsDrawn.length} cards');
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
      final aiPlayer = _currentRoom!.players.firstWhere((p) => p.id != _currentPlayerId);
      
      // Add all cards from play pile to AI's hand
      final updatedHand = [...aiPlayer.hand, ..._currentRoom!.playPile];
      
      // Draw cards from deck until AI has 3 cards in hand (if deck has cards)
      final cardsToDraw = 3 - updatedHand.length;
      final cardsDrawn = <game_card.Card>[];
      final remainingDeck = <game_card.Card>[];
      
      if (cardsToDraw > 0 && _currentRoom!.deck.isNotEmpty) {
        final drawCount = cardsToDraw > _currentRoom!.deck.length ? _currentRoom!.deck.length : cardsToDraw;
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
      
      final updatedPlayers = _currentRoom!.players.map((p) => 
        p.id == aiPlayer.id ? updatedPlayer : p
      ).toList();

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

  /// Get next player ID
  String _getNextPlayerId() {
    if (_currentRoom == null) return _currentPlayerId!;
    
    final currentIndex = _currentRoom!.players.indexWhere((p) => p.id == _currentRoom!.currentPlayer);
    final nextIndex = (currentIndex + 1) % _currentRoom!.players.length;
    return _currentRoom!.players[nextIndex].id;
  }

  /// Get next player ID after a specific player
  String _getNextPlayerIdAfter(String playerId) {
    if (_currentRoom == null) return _currentPlayerId!;
    
    final currentIndex = _currentRoom!.players.indexWhere((p) => p.id == playerId);
    if (currentIndex == -1) {
      return _currentRoom!.players.first.id;
    }
    
    final nextIndex = (currentIndex + 1) % _currentRoom!.players.length;
    return _currentRoom!.players[nextIndex].id;
  }

  /// Remove card from player's zone
  Player _removeCardFromPlayer(Player player, game_card.Card card, String sourceZone) {
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
        final updatedFaceUp = player.faceUp.where((c) => c.id != card.id).toList();
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
        final updatedFaceDown = player.faceDown.where((c) => c.id != card.id).toList();
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
    List<Player> players,
  ) {
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
      // Skip the next player by moving to the player after next
      finalNextPlayerId = _getNextPlayerIdAfter(nextPlayerId);
    }

    // Handle card 10 effect (burn - clear play pile and same player goes again)
    if (card.value == '10') {
      finalPlayPile = [];
      // Keep the same player's turn (don't change finalNextPlayerId)
      finalNextPlayerId = _currentPlayerId!;
    }

    return (finalPlayPile, finalPlayers, finalNextPlayerId);
  }

  /// Create a shuffled deck of cards
  List<game_card.Card> _createShuffledDeck() {
    final suits = ['♠', '♥', '♦', '♣'];
    final values = ['A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K'];
    final deck = <game_card.Card>[];
    
    for (final suit in suits) {
      for (final value in values) {
        deck.add(game_card.Card(
          suit: suit,
          value: value,
          id: _uuid.v4(),
        ));
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
    
    final topCard = _currentRoom!.playPile.last;
    
    // If the top card is glass (5), look at the card below it
    if (topCard.value == '5' && _currentRoom!.playPile.length > 1) {
      return _currentRoom!.playPile[_currentRoom!.playPile.length - 2];
    }
    
    return topCard;
  }

  /// Check if a card can be played according to game rules
  bool _canPlayCard(game_card.Card card, Player player, [String? sourceZone]) {
    if (_currentRoom == null) return false;
    
    // Check zone restrictions if sourceZone is provided
    if (sourceZone != null) {
      if (sourceZone == 'faceUp' && player.hand.isNotEmpty) {
        return false; // Can't play face-up cards if hand has cards
      }
      if (sourceZone == 'faceDown' && (player.hand.isNotEmpty || player.faceUp.isNotEmpty)) {
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
    if (card.hasSpecialEffect && !['J', 'Q', 'K'].contains(effectiveTopCard.value)) {
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
