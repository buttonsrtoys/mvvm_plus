import 'package:example/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(myApp());
    await tester.pump(const Duration(seconds: 10)); // Wait for Future and Stream delays

    expect(find.text('0'), findsNWidgets(10));
    expect(find.byType(Fab), findsNWidgets(10));

    // await tester.tap(find.byType(Fab));
    // await tester.pump();
  });
}
