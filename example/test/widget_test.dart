import 'package:example/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Press every counter button to ensure every counter works.', (WidgetTester tester) async {
    await tester.pumpWidget(myApp());
    await tester.pump(const Duration(seconds: 10)); // Wait for Future and Stream delays

    expect(find.text('0'), findsNWidgets(10));
    expect(find.byType(Fab), findsNWidgets(10));

    final fabs = find.byType(Fab).evaluate().toList();
    for (final fab in fabs) {
      await tester.tap(find.byWidget(fab.widget));
    }
    await tester.pump(const Duration(seconds: 10)); // Wait for Future and Stream delays

    expect(find.text('1'), findsNWidgets(9));
    expect(find.text('5'), findsNWidgets(1));
  });
}
