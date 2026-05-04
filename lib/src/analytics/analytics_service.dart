import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  Future<void> logGameStarted({
    required String mode,
    int playerCount = 1,
    String? difficulty,
  }) =>
      _analytics.logEvent(
        name: 'game_started',
        parameters: {
          'mode': mode,
          'player_count': playerCount,
          if (difficulty != null) 'difficulty': difficulty,
        },
      );

  Future<void> logGameEnded({
    required String mode,
    required String outcome,
  }) =>
      _analytics.logEvent(
        name: 'game_ended',
        parameters: {'mode': mode, 'outcome': outcome},
      );

  Future<void> logRoomCreated() =>
      _analytics.logEvent(name: 'room_created');

  Future<void> logRoomJoined() =>
      _analytics.logEvent(name: 'room_joined');

  Future<void> logPickupPile({required String mode}) =>
      _analytics.logEvent(
        name: 'pickup_pile',
        parameters: {'mode': mode},
      );
}
