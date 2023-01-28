import 'package:example/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(myApp());
    await tester.pump(const Duration(seconds: 10)); // Wait for Future and Stream delays

    expect(find.text('0'), findsNWidgets(10));
    expect(find.byType(Fab), findsNWidgets(10));

    final fabs = find.byType(Fab).evaluate().toList();
    for (final fab in fabs) {
      await tester.tap(find.byWidget(fab.widget));
    }
    await tester.pump(const Duration(seconds: 10)); // Wait for Future and Stream delays

    expect(find.text('1'), findsNWidgets(8));
    expect(find.text('2'), findsNWidgets(1));
    expect(find.text('5'), findsNWidgets(1));
  });
}
