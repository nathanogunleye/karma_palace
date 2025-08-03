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
    _room = room;
    _currentPlayerId = playerId;
    _gameInProgress = room.gameState == GameState.playing;
    _updateTurnStatus();
    notifyListeners();
  }

  // Update room data
  void updateRoom(Room room) {
    _room = room;
    _gameInProgress = room.gameState == GameState.playing;
    _updateTurnStatus();
    notifyListeners();
  }

  // Update turn status
  void _updateTurnStatus() {
    if (_room == null || _currentPlayerId == null) return;
    
    _isMyTurn = _room!.currentPlayer == _currentPlayerId;
  }

  // Check if a card can be played
  bool canPlayCard(game_card.Card card) {
    if (!_isMyTurn || !_gameInProgress) return false;
    
    final topCard = this.topCard;
    if (topCard == null) return true; // First card of the game

    // Check if card can be played on high cards (J, Q, K)
    if (['J', 'Q', 'K'].contains(topCard.value)) {
      return card.canPlayOnHighCards;
    }

    // Normal card comparison
    return card.numericValue >= topCard.numericValue;
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
    
    return _room!.players.firstWhere(
      (p) => p.id == playerId,
      orElse: null,
    );
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