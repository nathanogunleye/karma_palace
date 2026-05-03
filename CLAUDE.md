# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

Karma Palace is a Flutter mobile/web card game implementing the "Shithead" card game. It supports both multiplayer (via Firebase Realtime Database) and single-player (with AI opponents).

## Commands

```bash
# Run the app
flutter run

# Run all tests
flutter test test/*

# Run a single test file
flutter test test/card_playing_test.dart

# Lint
flutter analyze

# Generate code (after modifying JSON-serializable models)
dart run build_runner build --delete-conflicting-outputs

# Build for distribution
flutter build appbundle        # Android
flutter build ipa              # iOS
flutter build web --release    # Web
```

## Architecture

### State Management
The app uses **Provider** with `ChangeNotifier`. Global providers are registered in `lib/main.dart`:
- `KarmaPalaceGameState` — read-only derived game state (is it my turn? can I play this card?) computed from the room object
- `FirebaseGameService` — authoritative state for multiplayer; owns the Firebase Realtime Database listener and performs all write operations
- `LocalGameService` — authoritative state for single-player; holds an in-memory `Room` and drives AI turns via a `Timer`
- `SettingsController`, `Palette`, `PlayerProgress`, `AudioController` — cross-cutting concerns

### Data Models (three layers)
- `lib/src/model/firebase/` — JSON-serializable models (`Room`, `Player`, `Card`) used as the wire format for Firebase and the shared game data structure across both modes. All `.g.dart` files are codegen; do not edit them.
- `lib/src/model/api/` — models for the external Deck of Cards API (retrofit-generated; largely unused in the current flow).
- `lib/src/model/internal/` — lightweight local-only representations (not persisted).

### Game Logic Split
Game rule enforcement lives in two places that must stay in sync:
1. `FirebaseGameService._canPlayCard()` / `_handleSpecialCardEffects()` — server-side-style validation executed before writing to Firebase
2. `KarmaPalaceGameState.canPlayCard()` — client-side preview used to highlight playable cards in the UI
3. `LocalGameService._canPlayCard()` / `_handleSpecialCardEffects()` — mirrors the Firebase logic for single-player

When changing a rule (special card effects, zone restrictions, etc.) update all three locations.

### Routing
Navigation uses **go_router** (`lib/router.dart`). Deep-link entry point: `/join/:roomId` for sharing room invites (Universal Links on iOS/Android).

### Multiplayer Flow
`RoomManagementScreen` → create or join room in Firebase → `KarmaPalaceLiveScreen`. Firebase listener in `FirebaseGameService._joinRoom()` streams `Room` updates; `KarmaPalaceGameState` is then updated by the screen calling `initializeGame()` / `updateRoom()`.

### Single-Player Flow
`SinglePlayerSetupScreen` → `LocalGameService.createSinglePlayerGame()` → `SinglePlayerGameScreen`. AI turns are scheduled with a 1500 ms `Timer` in `LocalGameService._scheduleAITurn()`. AI card selection strategy is in `AIPlayerService` with `easy`, `medium`, and `hard` difficulties.

### Special Card Rules
| Card | Effect |
|------|--------|
| 2    | Reset — any card playable next (`resetActive` flag on `Room`) |
| 5    | Glass — can be played on J/Q/K |
| 7    | Force low — next player must play 7 or lower (`forcedToPlayLow` on `Player`) |
| 9    | Skip — next player's turn is skipped |
| 10   | Burn — play pile discarded, same player goes again |
| Four-of-a-kind | Burn — same effect as 10 |

Face-down cards: blind flip; if invalid, the flipped card is revealed and the player must pick up the entire pile.

### UI / Theming
Colors are centralised in `lib/src/style/palette.dart` (`Palette` class). The background uses a purple→pink gradient (`bgGradientStart`, `bgGradientMid`, `bgGradientEnd`). Action buttons use `playButton` (green) and `pickupButton` (red).

Card widgets use `CardBounceScope` (an `InheritedWidget`) to share a single bounce `AnimationController` so all selected cards animate in sync.

### Code Generation
Models under `lib/src/model/firebase/` and `lib/src/model/api/` use `json_serializable` + `retrofit`. After editing any `@JsonSerializable` class or `@RestApi` interface, re-run:
```bash
dart run build_runner build --delete-conflicting-outputs
```
Never manually edit `*.g.dart` files.
