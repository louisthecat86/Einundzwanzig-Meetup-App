import 'package:flutter_test/flutter_test.dart';
import 'package:einundzwanzig_meetup_app/main.dart';

void main() {
  testWidgets('App starts without crash', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.byType(MyApp), findsOneWidget);
  });
}
