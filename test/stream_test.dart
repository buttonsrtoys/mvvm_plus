import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mvvm_plus/mvvm_plus.dart';

Stream<int> countSlowly({
  int total = 10,
  int delayMs = 1000,
}) async* {
  for (int i = 0; i <= total; i++) {
    await Future.delayed(Duration(milliseconds: delayMs));
    yield i;
  }
}

class StreamWidget extends ViewWidget<StreamWidgetViewModel> {
  StreamWidget({super.key})
      : super(
          builder: () => StreamWidgetViewModel(),
        );

  @override
  Widget build(BuildContext context) {
    return Text(
      viewModel.streamProperty.hasData ? viewModel.streamProperty.data.toString() : 'Nothing yet',
    );
  }
}

class StreamWidgetViewModel extends ViewModel {
  late StreamProperty<int> streamProperty = createStreamProperty(countSlowly());
  @override
  void dispose() {
    streamProperty.subscription.cancel();
    super.dispose();
  }
}

Widget testApp() => MaterialApp(
      home: StreamWidget(),
    );

void main() {
  setUp(() {
    //
  });

  tearDown(() {
//
  });

  group('MyWidget', () {
    testWidgets('not listening to Registrar, not registered, and not named ViewModel does not update value',
        (WidgetTester tester) async {
      await tester.pumpWidget(testApp());
      expect(find.text('Nothing yet'), findsOneWidget);
      // pump to give time for the stream to end
      await tester.pumpWidget(testApp(), const Duration(seconds: 20));
      expect(find.text('10'), findsOneWidget);
    });
  });
}
