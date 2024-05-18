import 'package:flutter/material.dart';
import 'package:karma_palace/model/draw_a_card_response.dart';
import 'package:karma_palace/model/piles_response.dart';
import 'package:karma_palace/model/player.dart';
import 'package:karma_palace/model/playing_card.dart';
import 'package:karma_palace/model/shuffle_cards_response.dart';
import 'package:karma_palace/service/card_service.dart';
import 'package:karma_palace/service/messaging_service.dart';
import 'package:logger/logger.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final Logger _logger = Logger();
  final CardService _cardService = CardService();
  final MessagingService _messagingService = MessagingService();
  final String _pileNameMiddle = 'middle';

  late String _pileNameHand;
  late String _pileNameCardsFaceDown;
  late String _pileNameCardsFaceUp;

  late String _deckId = '';
  late String _playerId;
  late Player _player;

  List<PlayingCard> _middle = [];
  List<PlayingCard> _hand = [];
  List<PlayingCard> _cardsFaceDown = [];
  List<PlayingCard> _cardsFaceUp = [];

  @override
  void initState() {
    super.initState();
    _setUp();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      // floatingActionButton: backFloatingActionButton(context),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              flex: 2,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Flexible(
                    child: Center(child: Text('1')),
                  ),
                  Expanded(
                    flex: 3,
                    child: Container(
                      color: Colors.green,
                      child: const Center(child: Text('2')),
                    ),
                  ),
                  const Flexible(
                    child: Center(child: Text('3')),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 5,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Container(
                      color: Colors.green,
                      child: const Center(child: Text('4')),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: _deckId.isEmpty
                        ? Column(
                            children: [
                              TextButton(
                                onPressed: () async {
                                  DeckResponse deckResponse = await _cardService
                                      .createNewShuffledDeck(false);
                                  setState(() {
                                    _startNewGame(deckResponse);
                                  });
                                },
                                child: const Text('Create Room'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  String roomId = '';
                                  showDialog<String>(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text('Enter room code:'),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            TextField(
                                              onChanged: (value) =>
                                                  roomId = value,
                                              decoration: const InputDecoration(
                                                hintText: 'Enter room code...',
                                                prefixIcon: Icon(Icons.code),
                                              ),
                                              autocorrect: false,
                                            ),
                                          ],
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop(roomId);
                                            },
                                            child: const Text('OK'),
                                          ),
                                        ],
                                      );
                                    },
                                  ).then(
                                    (value) => setState(() {
                                      _deckId = value!;
                                      if (_deckId.isNotEmpty) {
                                        _messagingService.joinExistingRoom(
                                            _deckId, _player);
                                        _drawInitialPiles().catchError(
                                            (Object error,
                                                StackTrace stackTrace) {
                                          _deckId = '';
                                          _showErrorMessage(context);
                                        });
                                      }
                                    }),
                                  );
                                },
                                child: const Text('Join Room'),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton(
                                onPressed: () {
                                  Share.share(_deckId);
                                },
                                child: Text(_deckId),
                              ),
                              if (_middle.isNotEmpty)
                                IconButton(
                                  icon: Image.network(_middle.last.image),
                                  iconSize: 100,
                                  onPressed: () async {
                                    // TODO: Pick up if you cannot play
                                  },
                                ),
                            ],
                          ),
                  ),
                  Flexible(
                    child: Container(
                      color: Colors.green,
                      child: const Center(child: Text('6')),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 5,
                    child: _buildCards(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startNewGame(DeckResponse deckResponse) {
    _deckId = deckResponse.deckId ?? '';
    _messagingService.saveNewRoom(_deckId, _player);
    _drawInitialPiles();
  }

  void _showErrorMessage(BuildContext context) {
    showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Could not enter room'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Fuck'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Dammit'),
            ),
          ],
        );
      },
    );
  }

  void _setUp() {
    _playerId = const Uuid().v4().split('-')[0];
    _player = Player(
      id: _playerId,
      name: 'Player_$_playerId',
    );

    _pileNameHand = '${_playerId}_hand';
    _pileNameCardsFaceDown = '${_playerId}_face_down';
    _pileNameCardsFaceUp = '${_playerId}_face_up';
  }

  Widget _buildCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildCardsSet(_hand, _pileNameHand),
        Stack(
          alignment: Alignment.center,
          children: [
            _buildCardsSet(_cardsFaceDown, _pileNameCardsFaceDown, true),
            Positioned.fill(
              top: 5,
              bottom: -5,
              left: 5,
              right: -5,
              child: _buildCardsSet(_cardsFaceUp, _pileNameCardsFaceUp),
              // child: Container(height: 50, width: 50, color: Colors.purple),
            ),
          ],
        ),
      ],
    );
  }

  Row _buildCardsSet(List<PlayingCard> cards, String pileName,
      [bool faceDown = false]) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: cards.map((c) {
        return Flexible(
          child: IconButton(
            icon: faceDown
                ? Image.asset('assets/images/card_back.png')
                : Image.network(c.image),
            iconSize: 60,
            onPressed: () async {
              // TODO: Check card is a valid play
              // TODO: Draw cards from pile
              PilesResponse p =
                  await _cardService.drawFromPile(_deckId, pileName, [c.code]);

              // Put cards into 'middle' pile
              await _cardService.addToPile(
                  _deckId, _pileNameMiddle, _extractPlayingCardCodes(p.cards!));
              p = await _cardService.listPile(_deckId, _pileNameMiddle);
              setState(() {
                _middle = p.piles![_pileNameMiddle]!.cards!;
              });

              // If pile is the hand, then draw from deck
              if (pileName == _pileNameHand) {
                // TODO: Draw card from deck if hand <= 2 && deck is not empty
                DrawCardResponse dcr = await _cardService.drawCards(_deckId, 1);
                await _cardService.addToPile(_deckId, _pileNameHand,
                    _extractPlayingCardCodes(dcr.cards!));
                setState(() {
                  _hand.remove(c);
                  _hand.addAll(dcr.cards!);
                });
              } else if (pileName == _pileNameCardsFaceUp) {
                setState(() {
                  _cardsFaceUp.remove(c);
                });
              } else if (pileName == _pileNameCardsFaceDown) {
                _cardsFaceDown.remove(c);
              }
            },
          ),
        );
      }).toList(),
    );
  }

  List<String> _extractPlayingCardCodes(List<PlayingCard> cards) {
    return cards.map((c) => c.code).toList();
  }

  Future<void> _drawInitialPiles() async {
    List<PlayingCard> hand = [];
    List<PlayingCard> cardsFaceDown = [];
    List<PlayingCard> cardsFaceUp = [];

    DrawCardResponse drawCardResponse =
        await _cardService.drawCards(_deckId, 9);

    hand = drawCardResponse.cards!.getRange(0, 3).toList();
    cardsFaceDown = drawCardResponse.cards!.getRange(3, 6).toList();
    cardsFaceUp = drawCardResponse.cards!.getRange(6, 9).toList();

    await _cardService.addToPile(
        _deckId, _pileNameHand, _extractPlayingCardCodes(hand));
    await _cardService.addToPile(_deckId, _pileNameCardsFaceDown,
        _extractPlayingCardCodes(cardsFaceDown));
    await _cardService.addToPile(
        _deckId, _pileNameCardsFaceUp, _extractPlayingCardCodes(cardsFaceUp));

    setState(() {
      _hand = hand;
      _cardsFaceDown = cardsFaceDown;
      _cardsFaceUp = cardsFaceUp;
    });

    _logger.d('_deckId: $_deckId');
  }
}
