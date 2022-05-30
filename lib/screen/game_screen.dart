import 'package:flutter/material.dart';
import 'package:karma_palace/model/draw_a_card_response.dart';
import 'package:karma_palace/model/playing_card.dart';
import 'package:karma_palace/model/shuffle_cards_response.dart';
import 'package:karma_palace/service/card_service.dart';
import 'package:logger/logger.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({Key? key}) : super(key: key);

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final Logger _logger = Logger();
  final CardService _cardService = CardService();

  late String _pileNamePrefix;
  late String _pileNameHand;
  late String _pileNameCardsFaceDown;
  late String _pileNameCardsFaceUp;

  String _deckId = '';
  List<PlayingCard> _hand = [];
  List<PlayingCard> _cardsFaceDown = [];
  List<PlayingCard> _cardsFaceUp = [];

  @override
  void initState() {
    super.initState();
    _pileNamePrefix = const Uuid().v4().split('-')[0];
    _pileNameHand = '${_pileNamePrefix}_hand';
    _pileNameCardsFaceDown = '${_pileNamePrefix}_face_down';
    _pileNameCardsFaceUp = '${_pileNamePrefix}_face_up';
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
                                      .createNewShuffledDeck();
                                  setState(() {
                                    _deckId = deckResponse.deckId ?? '';
                                    _drawInitialPiles();
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
                                                hintText:
                                                    'Fucking join already!',
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
                                    }),
                                  );
                                },
                                child: const Text('Join Room'),
                              ),
                            ],
                          )
                        : TextButton(
                            onPressed: () {
                              Share.share(_deckId);
                            },
                            child: Text(_deckId),
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

  Widget _buildCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildCardsSet(_hand),
        _buildCardsSet(_cardsFaceDown),
        _buildCardsSet(_cardsFaceUp),
      ],
    );
  }

  Row _buildCardsSet(List<PlayingCard> cards) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: cards.map((c) {
        return Expanded(
          child: IconButton(
            icon: Image.network(c.image),
            iconSize: 72,
            onPressed: () {},
          ),
        );
      }).toList(),
    );
  }

  void _drawInitialPiles() async {
    List<PlayingCard> hand = [];
    List<PlayingCard> cardsFaceDown = [];
    List<PlayingCard> cardsFaceUp = [];

    DrawCardResponse drawCardResponse =
        await _cardService.drawCards(_deckId, 9);

    hand = drawCardResponse.cards!.getRange(0, 3).toList();
    cardsFaceDown = drawCardResponse.cards!.getRange(3, 6).toList();
    cardsFaceUp = drawCardResponse.cards!.getRange(6, 9).toList();

    await _cardService.addToPile(
        _deckId, _pileNameHand, hand.map((e) => e.code).toList());

    await _cardService.addToPile(_deckId, _pileNameCardsFaceDown,
        cardsFaceDown.map((e) => e.code).toList());

    await _cardService.addToPile(
        _deckId, _pileNameCardsFaceUp, cardsFaceUp.map((e) => e.code).toList());

    setState(() {
      _hand = hand;
      _cardsFaceDown = cardsFaceDown;
      _cardsFaceUp = cardsFaceUp;
    });

    _logger.d('_deckId: $_deckId');
  }
}
