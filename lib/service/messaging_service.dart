import 'package:firebase_database/firebase_database.dart';

import '../model/firebase/player.dart' as firebase_player;
import '../model/firebase/room.dart';
import '../model/internal/player.dart';

class MessagingService {
  static final MessagingService _messagingService =
      MessagingService._internal();

  factory MessagingService() {
    return _messagingService;
  }

  MessagingService._internal();

  void createRoom(String id, Player player) async {
    Room room = Room(
      id: id,
      players: [
        firebase_player.Player(
          name: player.name,
          isPlaying: true,
        ),
      ],
      currentPlayer: player.name,
    );

    FirebaseDatabase database = FirebaseDatabase.instance;
    DatabaseReference ref = database.ref('room/${room.id}');
    await ref.set(room.toJson());
  }

  Future<void> joinRoom(String id, Player player) async {
    FirebaseDatabase database = FirebaseDatabase.instance;
    DatabaseReference roomRef = database.ref('room/$id');

    DatabaseEvent event = await roomRef.once();
    if (event.snapshot.exists) {
      DatabaseReference roomPlayerRef = roomRef.child('players');
      DatabaseReference newPlayerRef = roomPlayerRef.push();
      newPlayerRef.set(firebase_player.Player(
        name: player.name,
        isPlaying: false,
      ).toJson());
    }

    throw 'Room does not exist!';
  }
}
