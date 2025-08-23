import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import 'package:karma_palace/src/model/firebase/card.dart' as game_card;
import 'package:karma_palace/src/model/firebase/player.dart';
import 'package:karma_palace/src/model/firebase/room.dart';

class KarmaPalaceGameState extends ChangeNotifier {
  Room? _room;
  String? _currentPlayerId;
  bool _isMyTurn = false;
  bool _gameInProgress = false;

  // Getters
  Room? get room => _room;
  String? get currentPlayerId => _currentPlayerId;
  bool get isMyTurn => _isMyTurn;
  bool get gameInProgress => _gameInProgress;
  
  Player? get currentPlayer => _room?.players.firstWhere(
    (p) => p.id == _currentPlayerId,
    orElse: () => Player(
      id: '',
      name: '',
      isPlaying: false,
      hand: [],
      faceUp: [],
      faceDown: [],
      isConnected: false,
      lastSeen: DateTime.now(),
      turnOrder: 0,
    ),
  );

  Player? get myPlayer => _room?.players.firstWhere(
    (p) => p.id == _currentPlayerId,
    orElse: () => Player(
      id: '',
      name: '',
      isPlaying: false,
      hand: [],
      faceUp: [],
      faceDown: [],
      isConnected: false,
      lastSeen: DateTime.now(),
      turnOrder: 0,
    ),
  );

  List<game_card.Card> get playPile => _room?.playPile ?? [];

  game_card.Card? get topCard => playPile.isNotEmpty ? playPile.last : null;

  // Initialize game state
  void initializeGame(Room room, String playerId) {
    dev.log('DEBUG: Initializing game state');
    dev.log('DEBUG: Room game state: ${room.gameState}');
    dev.log('DEBUG: Room current player: ${room.currentPlayer}');
    dev.log('DEBUG: My player ID: $playerId');
    dev.log('DEBUG: Previous player ID was: $_currentPlayerId');
    
    // Reset state completely for new player
    _room = room;
    _currentPlayerId = playerId;
    _gameInProgress = room.gameState == GameState.playing;
    _isMyTurn = false; // Reset turn status
    _updateTurnStatus();
    notifyListeners();
  }

  // Update room data
  void updateRoom(Room room) {
    dev.log('DEBUG: Updating room data');
    dev.log('DEBUG: Room game state: ${room.gameState}');
    dev.log('DEBUG: Room current player: ${room.currentPlayer}');
    
    _room = room;
    _gameInProgress = room.gameState == GameState.playing;
    _updateTurnStatus();
    notifyListeners();
  }

  // Set current player ID
  void setCurrentPlayerId(String playerId) {
    dev.log('DEBUG: Setting current player ID: $playerId');
    _currentPlayerId = playerId;
    _updateTurnStatus();
    notifyListeners();
  }

  // Reset game state for new player
  void resetForNewPlayer() {
    dev.log('DEBUG: Resetting game state for new player');
    _room = null;
    _currentPlayerId = null;
    _isMyTurn = false;
    _gameInProgress = false;
    notifyListeners();
  }

  // Update turn status
  void _updateTurnStatus() {
    if (_room == null || _currentPlayerId == null) {
      dev.log('DEBUG: Cannot update turn status - room or playerId is null');
      return;
    }
    
    _isMyTurn = _room!.currentPlayer == _currentPlayerId;
    dev.log('DEBUG: Turn status - Room current player: ${_room!.currentPlayer}, My ID: $_currentPlayerId, Is my turn: $_isMyTurn');
    dev.log('DEBUG: Game in progress: $_gameInProgress');
  }

  // Check if a card can be played
  bool canPlayCard(game_card.Card card) {
    dev.log('DEBUG: canPlayCard called');
    dev.log('DEBUG: _isMyTurn: $_isMyTurn');
    dev.log('DEBUG: _gameInProgress: $_gameInProgress');
    dev.log('DEBUG: _currentPlayerId: $_currentPlayerId');
    dev.log('DEBUG: Room current player: ${_room?.currentPlayer}');
    
    if (!_isMyTurn || !_gameInProgress) {
      dev.log('DEBUG: Not my turn or game not in progress');
      return false;
    }
    
    final topCard = this.topCard;
    dev.log('DEBUG: Top card: ${topCard?.displayString ?? "null"}');
    dev.log('DEBUG: Play pile length: ${playPile.length}');
    
    if (topCard == null) {
      dev.log('DEBUG: No top card - any card can be played');
      return true; // First card of the game
    }

    // Check if reset effect is active (2 was played)
    if (_room?.resetActive == true) {
      const canPlay = true; // Any card can be played after a 2
      dev.log('DEBUG: Reset effect active - any card can be played');
      return canPlay;
    }

    // Check if current player is forced to play low (from card 7 effect)
    if (myPlayer?.forcedToPlayLow == true) {
      final canPlay = card.numericValue <= 7;
      dev.log('DEBUG: Player forced to play low - playing ${card.value} (value: ${card.numericValue}) - can play: $canPlay');
      return canPlay;
    }

    // Check if card can be played on high cards (J, Q, K)
    if (['J', 'Q', 'K'].contains(topCard.value)) {
      final canPlay = card.canPlayOnHighCard(topCard);
      dev.log('DEBUG: Playing on high card ${topCard.value} - can play: $canPlay');
      return canPlay;
    }

    // Check if top card is 7 - forces next player to play 7 or lower
    if (topCard.value == '7') {
      final canPlay = card.numericValue <= 7;
      dev.log('DEBUG: Top card is 7 - playing ${card.value} (value: ${card.numericValue}) - can play: $canPlay');
      return canPlay;
    }

    // Check if playing a special card on a non-royal card
    if (card.hasSpecialEffect && !['J', 'Q', 'K'].contains(topCard.value)) {
      const canPlay = true; // Special cards can be played on any non-royal card
      dev.log('DEBUG: Playing special card ${card.value} on non-royal ${topCard.value} - can play: $canPlay');
      return canPlay;
    }

    // Normal card comparison
    final canPlay = card.numericValue >= topCard.numericValue;
    dev.log('DEBUG: Playing ${card.value} on ${topCard.value} - can play: $canPlay');
    return canPlay;
  }

  // Get playable cards from player's hand
  List<game_card.Card> getPlayableCards() {
    if (myPlayer == null) return [];
    
    return myPlayer!.hand.where((card) => canPlayCard(card)).toList();
  }

  // Check if player needs to pick up pile
  bool needsToPickUpPile() {
    if (!_isMyTurn || !_gameInProgress) return false;
    
    final playableCards = getPlayableCards();
    return playableCards.isEmpty && myPlayer!.hand.isNotEmpty;
  }

  // Get next player in turn order
  String? getNextPlayer() {
    if (_room == null) return null;
    
    final currentIndex = _room!.players.indexWhere((p) => p.id == _room!.currentPlayer);
    if (currentIndex == -1) return null;
    
    final nextIndex = (currentIndex + 1) % _room!.players.length;
    return _room!.players[nextIndex].id;
  }

  // Check if game is finished
  bool get isGameFinished {
    if (_room == null) return false;
    
    // Only consider game finished if it's actually in playing state and someone won
    return _room!.gameState == GameState.finished ||
           (_room!.gameState == GameState.playing && _room!.players.any((p) => p.hasWon));
  }

  // Get winner
  Player? get winner {
    if (_room == null) return null;
    
    final winningPlayer = _room!.players.where((p) => p.hasWon).firstOrNull;
    return winningPlayer;
  }

  // Get connected players
  List<Player> get connectedPlayers {
    if (_room == null) return [];
    
    return _room!.players.where((p) => p.isConnected).toList();
  }

  // Get disconnected players
  List<Player> get disconnectedPlayers {
    if (_room == null) return [];
    
    return _room!.players.where((p) => !p.isConnected).toList();
  }

  // Check if game can start
  bool get canStartGame {
    if (_room == null) return false;
    
    final connectedPlayers = this.connectedPlayers;
    return connectedPlayers.length >= 2 && 
           _room!.gameState == GameState.waiting;
  }

  // Get player by ID
  Player? getPlayerById(String playerId) {
    if (_room == null) return null;
    
    try {
      return _room!.players.firstWhere((p) => p.id == playerId);
    } catch (e) {
      return null;
    }
  }

      // Get player position (0-5 for 6 player positions)
  int getPlayerPosition(String playerId) {
    if (_room == null) return 0;
    
    final player = getPlayerById(playerId);
    if (player == null) return 0;
    
    return player.turnOrder;
  }

  // Check if it's a valid move to play from face up
  bool canPlayFromFaceUp() {
    if (!_isMyTurn || !_gameInProgress) return false;
    
    return myPlayer?.canPlayFromFaceUp ?? false;
  }

  // Check if it's a valid move to play from face down
  bool canPlayFromFaceDown() {
    if (!_isMyTurn || !_gameInProgress) return false;
    
    return myPlayer?.canPlayFromFaceDown ?? false;
  }
} 