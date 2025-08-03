import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:karma_palace/src/game_internals/karma_palace_game_state.dart';
import 'package:karma_palace/src/model/firebase/card.dart' as game_card;
import 'package:karma_palace/src/model/firebase/player.dart';
import 'package:karma_palace/src/model/firebase/room.dart';
import 'package:karma_palace/src/style/palette.dart';
import 'karma_palace_board_widget.dart';

class KarmaPalaceTestScreen extends StatefulWidget {
  const KarmaPalaceTestScreen({super.key});

  @override
  State<KarmaPalaceTestScreen> createState() => _KarmaPalaceTestScreenState();
}

class _KarmaPalaceTestScreenState extends State<KarmaPalaceTestScreen> {
  @override
  void initState() {
    super.initState();
    _initializeTestData();
  }

  void _initializeTestData() {
    final gameState = context.read<KarmaPalaceGameState>();
    
    // Create sample cards
    final sampleCards = [
      game_card.Card(suit: '♥', value: 'A', id: '1'),
      game_card.Card(suit: '♦', value: 'K', id: '2'),
      game_card.Card(suit: '♣', value: 'Q', id: '3'),
      game_card.Card(suit: '♠', value: 'J', id: '4'),
      game_card.Card(suit: '♥', value: '10', id: '5'),
      game_card.Card(suit: '♦', value: '9', id: '6'),
      game_card.Card(suit: '♣', value: '8', id: '7'),
      game_card.Card(suit: '♠', value: '7', id: '8'),
      game_card.Card(suit: '♣', value: '6', id: '9'),
      game_card.Card(suit: '♦', value: '5', id: '10'),
      game_card.Card(suit: '♣', value: '4', id: '11'),
      game_card.Card(suit: '♠', value: '3', id: '12'),
      game_card.Card(suit: '♥', value: '2', id: '13'),
    ];

    // Create sample players
    final players = [
      Player(
        id: 'player1',
        name: 'Alice',
        isPlaying: true,
        hand: [sampleCards[0], sampleCards[1], sampleCards[2]],
        faceUp: [sampleCards[3], sampleCards[4], sampleCards[5]],
        faceDown: [sampleCards[6], sampleCards[7], sampleCards[8]],
        isConnected: true,
        lastSeen: DateTime.now(),
        turnOrder: 0,
      ),
      Player(
        id: 'player2',
        name: 'Bob',
        isPlaying: false,
        hand: [sampleCards[9], sampleCards[10], sampleCards[11]],
        faceUp: [sampleCards[12], sampleCards[0], sampleCards[1]],
        faceDown: [sampleCards[2], sampleCards[3], sampleCards[4]],
        isConnected: true,
        lastSeen: DateTime.now(),
        turnOrder: 1,
      ),
      Player(
        id: 'player3',
        name: 'Charlie',
        isPlaying: false,
        hand: [sampleCards[5], sampleCards[6], sampleCards[7]],
        faceUp: [sampleCards[8], sampleCards[9], sampleCards[10]],
        faceDown: [sampleCards[11], sampleCards[12], sampleCards[0]],
        isConnected: true,
        lastSeen: DateTime.now(),
        turnOrder: 2,
      ),
    ];

    // Create sample room
    final room = Room(
      id: 'test-room',
      players: players,
      currentPlayer: 'player1',
      gameState: GameState.playing,
      deck: sampleCards,
      playPile: [sampleCards[0], sampleCards[1], sampleCards[2]],
      createdAt: DateTime.now(),
      lastActivity: DateTime.now(),
    );

    // Initialize game state
    gameState.initializeGame(room, 'player1');
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();

    return Scaffold(
      backgroundColor: palette.backgroundMain,
      appBar: AppBar(
        title: const Text('Karma Palace - Test'),
        backgroundColor: palette.backgroundPlaySession,
        foregroundColor: palette.ink,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Game status
            Container(
              padding: const EdgeInsets.all(16),
              child: Consumer<KarmaPalaceGameState>(
                builder: (context, gameState, child) {
                  return Column(
                    children: [
                      Text(
                        'Game Status: ${gameState.gameInProgress ? "Playing" : "Waiting"}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: palette.ink,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Current Player: ${gameState.currentPlayer?.name ?? "None"}',
                        style: TextStyle(
                          fontSize: 14,
                          color: palette.ink,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'My Turn: ${gameState.isMyTurn ? "Yes" : "No"}',
                        style: TextStyle(
                          fontSize: 14,
                          color: gameState.isMyTurn ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            
            // Game board
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                child: const KarmaPalaceBoardWidget(),
              ),
            ),
            
            // Control buttons
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      // TODO: Add card play functionality
                    },
                    child: const Text('Play Card'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // TODO: Add pick up pile functionality
                    },
                    child: const Text('Pick Up Pile'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 