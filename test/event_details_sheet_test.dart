import 'package:einundzwanzig_meetup_app/l10n/app_localizations.dart';
import 'package:einundzwanzig_meetup_app/widgets/event_details_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final size in [const Size(402, 874), const Size(320, 568)]) {
    testWidgets(
      'lange Meetup-Details bleiben scrollbar und schließbar: $size',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        tester.view.padding = const FakeViewPadding(top: 62, bottom: 34);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetPadding);

        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('de'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(2)),
              child: child!,
            ),
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return TextButton(
                    onPressed: () => showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      constraints: BoxConstraints(maxHeight: size.height * 0.9),
                      builder: (_) => EventDetailsSheet(
                        child: Column(
                          children: [
                            Text('Lange Meetup-Beschreibung. ' * 150),
                            const Text('Zum Kalender'),
                          ],
                        ),
                      ),
                    ),
                    child: const Text('Details öffnen'),
                  );
                },
              ),
            ),
          ),
        );
        await tester.tap(find.text('Details öffnen'));
        await tester.pumpAndSettle();

        final close = find.byTooltip('Schließen');
        final closeRect = tester.getRect(close);
        expect(closeRect.top, greaterThanOrEqualTo(62));
        expect(closeRect.bottom, lessThan(size.height - 34));
        expect(close.hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);

        final scrollable = tester.state<ScrollableState>(
          find.descendant(
            of: find.byType(EventDetailsSheet),
            matching: find.byType(Scrollable),
          ),
        );
        scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
        await tester.pumpAndSettle();
        expect(find.text('Zum Kalender').hitTestable(), findsOneWidget);
        expect(tester.getRect(close), closeRect);
        expect(tester.takeException(), isNull);

        await tester.tap(close);
        await tester.pumpAndSettle();
        expect(find.byType(EventDetailsSheet), findsNothing);
        expect(find.text('Details öffnen'), findsOneWidget);
      },
    );
  }
}
