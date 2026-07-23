import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:purple_rain/main.dart';

void main() {
  testWidgets('pressing t triggers lightning without crashing', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyT);
    await tester.pump();

    expect(find.byType(MyHomePage), findsOneWidget);
  });
}
