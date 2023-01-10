import 'package:firebase_database/firebase_database.dart';
import 'package:karma_palace/model/player.dart';
import 'package:karma_palace/model/room.dart';
import 'package:logger/logger.dart';

class MessagingService {
  final Logger _logger = Logger();

  static final MessagingService _messagingService =
      MessagingService._internal();

  factory MessagingService() {
    return _messagingService;
  }

  MessagingService._internal();

  void saveNewRoom(String roomId, Player player) async {
    Room room = Room(players: [
      player,
    ]);

    FirebaseDatabase database = FirebaseDatabase.instance;
    DatabaseReference ref = database.ref('room/$roomId');
    await ref.set(room.toJson());
  }

  Future<void> joinExistingRoom(String roomId, Player player) async {
    FirebaseDatabase database = FirebaseDatabase.instance;
    DatabaseReference roomRef = database.ref('room/$roomId');
    DatabaseEvent event = await roomRef.once();
    if (event.snapshot.exists) {
      DatabaseReference roomPlayerRef = roomRef.child('players');
      DatabaseReference newPlayerRef = roomPlayerRef.push();
      newPlayerRef.set(player.toJson());
    }

    throw 'Room does not exist!';
  }
}
