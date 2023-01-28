import 'package:example/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(myApp());

    expect(find.text('a'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);

    // Rich, fix tests
    /*
    await tester.tap(find.byType(IncrementButton));
    await tester.pump();

    expect(find.text('b'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);

    await tester.tap(find.byType(IncrementButton));
    await tester.pump();

    expect(find.text('b'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
     */
  });
}
