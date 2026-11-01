import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keylire/ui/widgets/time_ribbon_timeline.dart';

void main() {
  testWidgets('empty day swipes move to adjacent days', (tester) async {
    var dayOffset = 0;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TimeRibbonTimeline(
          events: const [],
          showNow: true,
          onTapEvent: (_) {},
          onLongPressEvent: (_) {},
          onCompleteGhost: (_) {},
          onPreviousDay: () => dayOffset--,
          onNextDay: () => dayOffset++,
        ),
      ),
    ));

    await tester.fling(
        find.byType(TimeRibbonTimeline), const Offset(0, -320), 900);
    await tester.pumpAndSettle();
    expect(dayOffset, 1);

    await tester.fling(
        find.byType(TimeRibbonTimeline), const Offset(0, 320), 900);
    await tester.pumpAndSettle();
    expect(dayOffset, 0);
  });
}
