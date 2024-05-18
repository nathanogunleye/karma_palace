import 'package:karma_palace/model/internal/card.dart';
import 'package:karma_palace/model/internal/player.dart';

class Room {
  List<Player> players;
  List<Card> deck;
  List<Card> playingPile;
  List<Card> discardPile;

  Room({
    required this.players,
    required this.deck,
    required this.playingPile,
    required this.discardPile,
  });
}
