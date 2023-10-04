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

/// Changes its children after a delay. Used to test whether a stream cancels when disposed.
class DelaySwitch extends StatefulWidget {
  final int delaySeconds;

  const DelaySwitch({
    Key? key,
    required this.delaySeconds,
  }) : super(key: key);

  @override
  State<DelaySwitch> createState() => _DelaySwitchState();
}

class _DelaySwitchState extends State<DelaySwitch> {
  bool timesUp = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(
      Duration(seconds: widget.delaySeconds),
      () => setState(
        () => timesUp = true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return timesUp ? const Text('Done') : StreamWidget();
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
    streamProperty.dispose();
    super.dispose();
  }
}

void main() {
  group('StreamProperty', () {
    testWidgets('listen to a stream', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: StreamWidget()));

      expect(find.text('Nothing yet'), findsOneWidget);
      // pump to give time for the stream to end
      await tester.pump(const Duration(seconds: 20)); // Allow stream to finish
      expect(find.text('10'), findsOneWidget);
    });

    testWidgets('dispose a stream', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: DelaySwitch(delaySeconds: 5)));
      expect(find.text('Nothing yet'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      expect(find.text('Done'), findsOneWidget);
      await tester.pump(const Duration(seconds: 20)); // Allow stream to finish
    });
  });
}
