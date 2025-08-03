import 'package:firebase_database/firebase_database.dart';
import 'package:logging/logging.dart';

import 'package:karma_palace/src/model/internal/player.dart' as internal_player;
import 'package:karma_palace/src/model/firebase/player.dart' as firebase_player;

import 'package:karma_palace/src/model/firebase/room.dart';

class RoomNotFoundException implements Exception {
  String cause;

  RoomNotFoundException(this.cause);
}

class MessagingService {
  static final Logger _log = Logger('MessagingService');

  static final MessagingService _messagingService =
      MessagingService._internal();

  factory MessagingService() {
    return _messagingService;
  }

  MessagingService._internal();

  void createRoom(String id, internal_player.Player player) async {
    Room room = Room(
      id: id,
      players: [
        firebase_player.Player(
          id: player.name,
          name: player.name,
          isPlaying: true,
          hand: [],
          faceUp: [],
          faceDown: [],
          isConnected: true,
          lastSeen: DateTime.now(),
          turnOrder: 0,
        ),
      ],
      currentPlayer: player.name,
      gameState: GameState.waiting,
      deck: [],
      playPile: [],
      createdAt: DateTime.now(),
      lastActivity: DateTime.now(),
    );

    _log.fine('Room ID: ${room.id}');

    FirebaseDatabase database = FirebaseDatabase.instance;
    DatabaseReference ref = database.ref('room/${room.id}');
    await ref.set(room.toJson());
  }

  Future<void> joinRoom(String id, firebase_player.Player player) async {
    FirebaseDatabase database = FirebaseDatabase.instance;
    DatabaseReference roomRef = database.ref('room/$id');

    DatabaseEvent event = await roomRef.once();
    if (event.snapshot.exists) {
      DatabaseReference roomPlayerRef = roomRef.child('players');
      DatabaseReference newPlayerRef = roomPlayerRef.push();
      await newPlayerRef.set(firebase_player.Player(
        id: player.name,
        name: player.name,
        isPlaying: false,
        hand: [],
        faceUp: [],
        faceDown: [],
        isConnected: true,
        lastSeen: DateTime.now(),
        turnOrder: 1,
      ).toJson());
      _log.fine('Successfully joined room: $id');
    } else {
      throw RoomNotFoundException('Room does not exist!');
    }
  }
}
