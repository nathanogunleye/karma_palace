import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';

import 'package:karma_palace/src/model/firebase/room.dart';
import 'package:karma_palace/src/model/firebase/player.dart';
import 'package:karma_palace/src/model/firebase/card.dart' as game_card;

class FirebaseGameService extends ChangeNotifier {
  static final Logger _log = Logger('FirebaseGameService');
  static final FirebaseGameService _instance = FirebaseGameService._internal();
  
  factory FirebaseGameService() => _instance;
  FirebaseGameService._internal();

  final FirebaseDatabase _database = FirebaseDatabase.instance;
  static const Uuid _uuid = Uuid();
  
  // Current room and player info
  String? _currentRoomId;
  String? _currentPlayerId;
  StreamSubscription<DatabaseEvent>? _roomListener;
  
  // Game state
  Room? _currentRoom;
  bool _isConnected = false;
  bool _isHost = false;

  // Callback for pick-up notifications
  VoidCallback? _onPickUpEffect;

  // Callback for burn effects
  VoidCallback? _onBurnEffect;

  // Getters
  Room? get currentRoom => _currentRoom;
  String? get currentRoomId => _currentRoomId;
  String? get currentPlayerId => _currentPlayerId;
  bool get isConnected => _isConnected;
  bool get isHost => _isHost;
  bool get isInGame => _currentRoom != null;

  /// Set callback for pick-up notifications
  void setPickUpEffectCallback(VoidCallback callback) {
    _onPickUpEffect = callback;
  }

  /// Clear pick-up effect callback
  void clearPickUpEffectCallback() {
    _onPickUpEffect = null;
  }

  /// Set callback for burn effects
  void setBurnEffectCallback(VoidCallback callback) {
    _onBurnEffect = callback;
  }

  /// Clear burn effect callback
  void clearBurnEffectCallback() {
    _onBurnEffect = null;
  }

  /// Create a new room and join as host
  Future<String> createRoom(String playerName) async {
    try {
      final roomId = _uuid.v4().substring(0, 8); // Use first 8 characters for shorter room ID
      final playerId = _uuid.v4();
      
      // Create initial deck
      final deck = _createShuffledDeck();
      
      // Create host player
      final hostPlayer = Player(
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

      // Create room
      final room = Room(
        id: roomId,
        players: [hostPlayer],
        currentPlayer: playerId,
        gameState: GameState.waiting,
        deck: deck.skip(9).toList(),
        playPile: [],
        createdAt: DateTime.now(),
        lastActivity: DateTime.now(),
      );

      // Save to Firebase
      await _database.ref('rooms/$roomId').set(room.toJson());
      
      _log.info('Created room: $roomId');
      
      // Join the room
      await _joinRoom(roomId, playerId, room);
      
      return roomId;
    } catch (e) {
      _log.severe('Failed to create room: $e');
      rethrow;
    }
  }

  /// Join an existing room
  Future<void> joinRoom(String roomId, String playerName) async {
    try {
      final playerId = _uuid.v4();
      _log.info('DEBUG: Joining room $roomId with player name: $playerName');
      _log.info('DEBUG: Generated player ID: $playerId');
      
      // Get current room data
      final roomRef = _database.ref('rooms/$roomId');
      final snapshot = await roomRef.get();
      
      if (!snapshot.exists) {
        throw Exception('Room not found');
      }

      final roomData = snapshot.value;
      if (roomData is! Map) {
        throw Exception('Invalid room data');
      }
      final room = Room.fromJson(_convertFirebaseMap(roomData));
      _log.info('DEBUG: Current room players: ${room.players.map((p) => p.id).toList()}');
      
      if (room.gameState != GameState.waiting) {
        throw Exception('Game already in progress');
      }

      if (room.players.length >= 6) {
        throw Exception('Room is full (maximum 6 players)');
      }

      // Create new player
      final newPlayer = Player(
        id: playerId,
        name: playerName,
        isPlaying: false,
        hand: [],
        faceUp: [],
        faceDown: [],
        isConnected: true,
        lastSeen: DateTime.now(),
        turnOrder: room.players.length,
      );

      // Add player to room
      final updatedPlayers = [...room.players, newPlayer];
      final updatedRoom = Room(
        id: room.id,
        players: updatedPlayers,
        currentPlayer: room.currentPlayer,
        gameState: room.gameState,
        deck: room.deck,
        playPile: room.playPile,
        createdAt: room.createdAt,
        lastActivity: DateTime.now(),
      );

      // Update room in Firebase
      await roomRef.set(updatedRoom.toJson());
      
      _log.info('Joined room: $roomId');
      
      // Join the room
      await _joinRoom(roomId, playerId, updatedRoom);
      
    } catch (e) {
      _log.severe('Failed to join room: $e');
      rethrow;
    }
  }

  /// Start the game (host only)
  Future<void> startGame() async {
    if (!_isHost || _currentRoom == null) {
      throw Exception('Only host can start the game');
    }

    try {
      final roomRef = _database.ref('rooms/$_currentRoomId');
      
      // Deal cards to all players
      final updatedPlayers = <Player>[];
      final deck = _currentRoom!.deck;
      int cardIndex = 0;

      for (int i = 0; i < _currentRoom!.players.length; i++) {
        final player = _currentRoom!.players[i];
        
        // Deal 3 cards to hand, face up, and face down
        final hand = deck.skip(cardIndex).take(3).toList();
        cardIndex += 3;
        final faceUp = deck.skip(cardIndex).take(3).toList();
        cardIndex += 3;
        final faceDown = deck.skip(cardIndex).take(3).toList();
        cardIndex += 3;

        final updatedPlayer = Player(
          id: player.id,
          name: player.name,
          isPlaying: i == 0, // First player starts
          hand: hand,
          faceUp: faceUp,
          faceDown: faceDown,
          isConnected: player.isConnected,
          lastSeen: player.lastSeen,
          turnOrder: player.turnOrder,
        );
        
        updatedPlayers.add(updatedPlayer);
      }

      final remainingDeck = deck.skip(cardIndex).toList();
      
      final updatedRoom = Room(
        id: _currentRoom!.id,
        players: updatedPlayers,
        currentPlayer: updatedPlayers[0].id,
        gameState: GameState.playing,
        deck: remainingDeck,
        playPile: [],
        createdAt: _currentRoom!.createdAt,
        lastActivity: DateTime.now(),
      );

      await roomRef.set(updatedRoom.toJson());
      _log.info('Game started in room: $_currentRoomId');
      
    } catch (e) {
      _log.severe('Failed to start game: $e');
      rethrow;
    }
  }

  /// Play a card
  Future<void> playCard(game_card.Card card, String sourceZone) async {
    if (_currentRoom == null || _currentPlayerId == null) {
      throw Exception('Not in a game');
    }

    try {
      final roomRef = _database.ref('rooms/$_currentRoomId');
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
        // Draw up to the number needed or what's available in deck
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
            isPlaying: p.id == nextPlayerId, // Only the next player is playing
            hand: p.hand,
            faceUp: p.faceUp,
            faceDown: p.faceDown,
            isConnected: p.isConnected,
            lastSeen: p.lastSeen,
            turnOrder: p.turnOrder,
            forcedToPlayLow: p.id == nextPlayerId ? p.forcedToPlayLow : false, // Reset for non-next players
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

      await roomRef.set(updatedRoom.toJson());
      _log.info('Played card: ${card.displayString}, drew ${cardsDrawn.length} cards');
      
    } catch (e) {
      _log.severe('Failed to play card: $e');
      rethrow;
    }
  }

  /// Pick up the play pile
  Future<void> pickUpPile() async {
    if (_currentRoom == null || _currentPlayerId == null) {
      throw Exception('Not in a game');
    }

    try {
      final roomRef = _database.ref('rooms/$_currentRoomId');
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
        // Draw up to the number needed or what's available in deck
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

      await roomRef.set(updatedRoom.toJson());
      _log.info('Picked up play pile, drew ${cardsDrawn.length} cards');
      
      // Notify UI about pick-up effect
      _onPickUpEffect?.call();
      
    } catch (e) {
      _log.severe('Failed to pick up pile: $e');
      rethrow;
    }
  }

  /// Leave the current room
  Future<void> leaveRoom() async {
    if (_currentRoomId == null) return;

    try {
      // Remove player from room
      if (_currentPlayerId != null) {
        final roomRef = _database.ref('rooms/$_currentRoomId');
        final updatedPlayers = _currentRoom!.players
            .where((p) => p.id != _currentPlayerId)
            .toList();

        if (updatedPlayers.isEmpty) {
          // Delete room if no players left
          await roomRef.remove();
        } else {
          // Update room with remaining players
          final updatedRoom = Room(
            id: _currentRoom!.id,
            players: updatedPlayers,
            currentPlayer: updatedPlayers[0].id, // First remaining player
            gameState: _currentRoom!.gameState,
            deck: _currentRoom!.deck,
            playPile: _currentRoom!.playPile,
            createdAt: _currentRoom!.createdAt,
            lastActivity: DateTime.now(),
          );
          await roomRef.set(updatedRoom.toJson());
        }
      }

      await _disconnect();
      _log.info('Left room: $_currentRoomId');
      
    } catch (e) {
      _log.severe('Failed to leave room: $e');
    }
  }

  /// Disconnect from current room
  Future<void> _disconnect() async {
    _roomListener?.cancel();
    _roomListener = null;
    
    _currentRoomId = null;
    _currentPlayerId = null;
    _currentRoom = null;
    _isConnected = false;
    _isHost = false;
    
    notifyListeners();
  }

  /// Join a room and start listening for updates
  Future<void> _joinRoom(String roomId, String playerId, Room room) async {
    _log.info('DEBUG: _joinRoom called for player: $playerId');
    _currentRoomId = roomId;
    _currentPlayerId = playerId;
    _currentRoom = room;
    _isHost = room.players.first.id == playerId;
    _isConnected = true;
    _log.info('DEBUG: Set current player ID to: $_currentPlayerId');
    _log.info('DEBUG: Is host: $_isHost');

    // Start listening for room updates
    final roomRef = _database.ref('rooms/$roomId');
    _roomListener = roomRef.onValue.listen((event) {
      if (event.snapshot.exists) {
        final data = event.snapshot.value;
        if (data is Map) {
          // Convert the map to the correct type recursively
          final convertedData = _convertFirebaseMap(data);
          final updatedRoom = Room.fromJson(convertedData);
          _log.info('DEBUG: Room updated - Game state: ${updatedRoom.gameState}');
          _log.info('DEBUG: Room updated - Current player: ${updatedRoom.currentPlayer}');
          _log.info('DEBUG: Room updated - My player ID: $_currentPlayerId');
          _log.info('DEBUG: Room updated - Players: ${updatedRoom.players.map((p) => p.id).toList()}');
          _currentRoom = updatedRoom;
          notifyListeners();
        }
      }
    });

    notifyListeners();
  }

  /// Create a shuffled deck of cards
  List<game_card.Card> _createShuffledDeck() {
    final suits = ['♥', '♦', '♣', '♠'];
    final values = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A'];
    
    final deck = <game_card.Card>[];
    const uuid = Uuid();
    
    for (final suit in suits) {
      for (final value in values) {
        deck.add(game_card.Card(
          suit: suit,
          value: value,
          id: uuid.v4(),
        ));
      }
    }
    
    deck.shuffle();
    return deck;
  }

  /// Remove a card from a player's zone
  Player _removeCardFromPlayer(Player player, game_card.Card card, String sourceZone) {
    List<game_card.Card> updatedZone;
    
    switch (sourceZone) {
      case 'hand':
        updatedZone = player.hand.where((c) => c.id != card.id).toList();
        break;
      case 'faceUp':
        updatedZone = player.faceUp.where((c) => c.id != card.id).toList();
        break;
      case 'faceDown':
        updatedZone = player.faceDown.where((c) => c.id != card.id).toList();
        break;
      default:
        throw Exception('Invalid source zone');
    }

    return Player(
      id: player.id,
      name: player.name,
      isPlaying: player.isPlaying,
      hand: sourceZone == 'hand' ? updatedZone : player.hand,
      faceUp: sourceZone == 'faceUp' ? updatedZone : player.faceUp,
      faceDown: sourceZone == 'faceDown' ? updatedZone : player.faceDown,
      isConnected: player.isConnected,
      lastSeen: player.lastSeen,
      turnOrder: player.turnOrder,
    );
  }

  /// Convert Firebase map to proper Map<String, dynamic>
  Map<String, dynamic> _convertFirebaseMap(Map map) {
    final result = <String, dynamic>{};
    
    for (final entry in map.entries) {
      final key = entry.key.toString();
      final value = entry.value;
      
      if (value is Map) {
        result[key] = _convertFirebaseMap(value);
      } else if (value is List) {
        result[key] = value.map((item) {
          if (item is Map) {
            return _convertFirebaseMap(item);
          }
          return item;
        }).toList();
      } else {
        result[key] = value;
      }
    }
    
    return result;
  }

  /// Get the next player ID in turn order
  String _getNextPlayerId() {
    if (_currentRoom == null) return '';
    
    final currentIndex = _currentRoom!.players.indexWhere((p) => p.id == _currentRoom!.currentPlayer);
    if (currentIndex == -1) return _currentRoom!.players.first.id;
    
    final nextIndex = (currentIndex + 1) % _currentRoom!.players.length;
    final nextPlayerId = _currentRoom!.players[nextIndex].id;
    
    _log.info('DEBUG: Next player calculation');
    _log.info('DEBUG: Current player: ${_currentRoom!.currentPlayer}');
    _log.info('DEBUG: Current index: $currentIndex');
    _log.info('DEBUG: Next index: $nextIndex');
    _log.info('DEBUG: Next player ID: $nextPlayerId');
    _log.info('DEBUG: All players: ${_currentRoom!.players.map((p) => p.id).toList()}');
    
    return nextPlayerId;
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

    switch (card.specialEffect) {
      case game_card.SpecialEffect.reset:
        // 2 - Resets the count (any card can be played after)
        // Don't clear the play pile, just mark that any card can be played next
        // The play pile stays as is, but the next card can be any card
        _log.info('Card 2 played - count reset, any card can be played next');
        // Note: resetActive will be set in the updatedRoom creation
        break;

      case game_card.SpecialEffect.glass:
        // 5 - Glass (can be played on J, Q, K)
        // No special action needed, just log
        _log.info('Card 5 (glass) played');
        break;

      case game_card.SpecialEffect.forceLow:
        // 7 - Next player has to play 7 or lower
        // Mark the next player as forced to play low
        finalPlayers = players.map((p) {
          if (p.id == nextPlayerId) {
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
              forcedToPlayLow: true, // Add this field to Player model
            );
          }
          return p;
        }).toList();
        _log.info('Card 7 played - next player forced to play 7 or lower');
        break;

      case game_card.SpecialEffect.skip:
        // 9 - Skips the next player
        finalNextPlayerId = _getNextPlayerIdAfter(nextPlayerId);
        _log.info('Card 9 played - skipped player: $nextPlayerId, next player: $finalNextPlayerId');
        break;

      case game_card.SpecialEffect.burn:
        // 10 - Burns the play pile (discards cards from game)
        // Clear the play pile and let the same player play again
        finalPlayPile = [];
        finalNextPlayerId = _currentPlayerId!; // Same player plays again
        _log.info('Card 10 played - play pile burned, same player plays again');
        // Notify UI about burn effect
        _onBurnEffect?.call();
        break;

      case null:
        // No special effect
        break;
    }

    // Check for 4-of-a-kind burn effect (4 cards of the same value)
    if (_shouldBurnForFourOfAKind(finalPlayPile)) {
      finalPlayPile = [];
      finalNextPlayerId = _currentPlayerId!; // Same player plays again
      _log.info('4-of-a-kind detected - play pile burned, same player plays again');
      // Notify UI about burn effect
      _onBurnEffect?.call();
    }

    return (finalPlayPile, finalPlayers, finalNextPlayerId);
  }

  /// Check if the play pile should be burned due to 4 cards of the same value
  bool _shouldBurnForFourOfAKind(List<game_card.Card> playPile) {
    if (playPile.length < 4) return false;
    
    // Get the last 4 cards
    final lastFourCards = playPile.sublist(playPile.length - 4);
    
    // Check if all 4 cards have the same value
    final firstValue = lastFourCards[0].value;
    final allSameValue = lastFourCards.every((card) => card.value == firstValue);
    
    if (allSameValue) {
      _log.info('4-of-a-kind detected: ${lastFourCards.map((c) => c.displayString).join(', ')}');
    }
    
    return allSameValue;
  }

  /// Get next player ID after a specific player
  String _getNextPlayerIdAfter(String playerId) {
    final currentIndex = _currentRoom!.players.indexWhere((p) => p.id == playerId);
    if (currentIndex == -1) {
      return _currentRoom!.players.first.id;
    }
    
    final nextIndex = (currentIndex + 1) % _currentRoom!.players.length;
    return _currentRoom!.players[nextIndex].id;
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

    // Debug logging
    _log.info('DEBUG: Validating card ${card.displayString} on effective top card ${effectiveTopCard.displayString}');
    _log.info('DEBUG: Play pile: ${_currentRoom!.playPile.map((c) => c.displayString).join(' → ')}');
    _log.info('DEBUG: Card has special effect: ${card.hasSpecialEffect}');
    _log.info('DEBUG: Effective top card is high card: ${['J', 'Q', 'K'].contains(effectiveTopCard.value)}');

    // Check if reset effect is active (2 was played)
    if (_currentRoom!.resetActive == true) {
      _log.info('DEBUG: Reset effect active - any card can be played');
      return true; // Any card can be played after a 2
    }

    // Check if current player is forced to play low (from card 7 effect)
    if (player.forcedToPlayLow == true) {
      final canPlay = card.numericValue <= 7;
      _log.info('DEBUG: Player forced to play low - playing ${card.value} (value: ${card.numericValue}) - can play: $canPlay');
      return canPlay;
    }

    // Check if card can be played on high cards (J, Q, K)
    if (['J', 'Q', 'K'].contains(effectiveTopCard.value)) {
      final canPlay = card.canPlayOnHighCard(effectiveTopCard);
      _log.info('DEBUG: Playing on high card ${effectiveTopCard.value} - canPlayOnHighCard result: $canPlay');
      return canPlay;
    }

    // Check if top card is 7 - forces next player to play 7 or lower
    if (effectiveTopCard.value == '7') {
      final canPlay = card.numericValue <= 7;
      _log.info('DEBUG: Top card is 7 - playing ${card.value} (value: ${card.numericValue}) - can play: $canPlay');
      return canPlay;
    }

    // Check if playing a special card on a non-royal card
    if (card.hasSpecialEffect && !['J', 'Q', 'K'].contains(effectiveTopCard.value)) {
      _log.info('DEBUG: Playing special card ${card.value} on non-royal ${effectiveTopCard.value} - can play: true');
      return true; // Special cards can be played on any non-royal card
    }

    // Normal card comparison
    final canPlay = card.numericValue >= effectiveTopCard.numericValue;
    _log.info('DEBUG: Playing ${card.value} on ${effectiveTopCard.value} - normal comparison result: $canPlay');
    return canPlay;
  }

  @override
  void dispose() {
    _roomListener?.cancel();
    super.dispose();
  }
} 