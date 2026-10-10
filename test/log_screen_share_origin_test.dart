import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:einundzwanzig_meetup_app/screens/log_screen.dart';
import 'package:einundzwanzig_meetup_app/services/app_logger.dart';

/// Issue #73: Ohne `sharePositionOrigin` wirft share_plus auf iOS 26 auch auf
/// dem iPhone. Der Test prüft am Methodenkanal, dass das Teilen einen
/// nicht-leeren Anker innerhalb der Ansicht mitschickt.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Diagnose-Log teilen schickt einen nicht-leeren Anker mit',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    const channel = MethodChannel('dev.fluttercommunity.plus/share');
    Map<Object?, Object?>? params;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel,
        (call) async {
      params = Map<Object?, Object?>.from(call.arguments as Map);
      return 'dev.fluttercommunity.plus/share/unavailable';
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));

    AppLogger.info('Test', 'Eintrag zum Teilen');
    await tester.pumpWidget(const MaterialApp(home: LogScreen()));
    await tester.tap(find.byTooltip('Teilen'));
    await tester.pump();

    expect(params, isNotNull, reason: 'Teilen hat den Kanal nicht erreicht');
    final x = params!['originX'] as double;
    final y = params!['originY'] as double;
    final w = params!['originWidth'] as double;
    final h = params!['originHeight'] as double;
    expect(w, greaterThan(0));
    expect(h, greaterThan(0));
    final view = tester.view.physicalSize / tester.view.devicePixelRatio;
    expect(x, greaterThanOrEqualTo(0));
    expect(y, greaterThanOrEqualTo(0));
    expect(x + w, lessThanOrEqualTo(view.width));
    expect(y + h, lessThanOrEqualTo(view.height));
  });
}
