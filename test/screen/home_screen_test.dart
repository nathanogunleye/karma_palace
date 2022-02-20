import 'package:flutter_test/flutter_test.dart';
import 'package:karma_palace/constants/text_constants.dart';
import 'package:karma_palace/main.dart';

void main() {
  testWidgets('Home Screen test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our counter starts at 0.
    expect(find.text(kAppName), findsOneWidget);
    expect(find.text('Play'), findsOneWidget);
    expect(find.text('Rules'), findsOneWidget);
    expect(find.text('Exit'), findsOneWidget);

    // // Tap the '+' icon and trigger a frame.
    // await tester.tap(find.byIcon(Icons.add));
    // await tester.pump();
    //
    // // Verify that our counter has incremented.
    // expect(find.text('0'), findsNothing);
    // expect(find.text('1'), findsOneWidget);
  });
}
