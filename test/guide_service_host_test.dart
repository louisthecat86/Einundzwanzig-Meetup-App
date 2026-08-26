import 'package:einundzwanzig_meetup_app/mixins/guide_service_host.dart';
import 'package:einundzwanzig_meetup_app/services/guide_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _demoStep = GuideStep(titleKey: 't', bodyKey: 'b');

/// Minimaler Host — startet Tour nach erstem Frame, beendet in dispose.
class _TourHostScreen extends StatefulWidget {
  final GuideTour tour;

  const _TourHostScreen({required this.tour});

  @override
  State<_TourHostScreen> createState() => _TourHostScreenState();
}

class _TourHostScreenState extends State<_TourHostScreen> with GuideServiceHost {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await guide.startTour(
        widget.tour,
        const [_demoStep],
        force: true,
      );
    });
  }

  @override
  void dispose() {
    finishGuideTourIfActive(widget.tour);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('GuideService.finishTourNow', () {
    test('setzt aktiven Tour-Zustand synchron zurueck', () async {
      final guide = GuideService();
      await guide.startTour(
        GuideTour.portal,
        const [_demoStep],
        force: true,
      );
      expect(guide.isActive, isTrue);
      expect(guide.activeTour, GuideTour.portal);

      guide.finishTourNow();

      expect(guide.isActive, isFalse);
      expect(guide.activeTour, isNull);
      expect(guide.currentStep, isNull);
    });

    test('markiert Tour als abgeschlossen (Persistenz)', () async {
      final guide = GuideService();
      await guide.startTour(
        GuideTour.wallet,
        const [_demoStep],
        force: true,
      );

      guide.finishTourNow();
      await Future<void>.delayed(Duration.zero);

      expect(await guide.wasTourCompleted(GuideTour.wallet), isTrue);
    });
  });

  group('GuideServiceHost', () {
    testWidgets('dispose beendet aktive Tour ohne Provider-Fehler', (tester) async {
      final guide = GuideService();
      Object? capturedError;

      final prev = FlutterError.onError;
      FlutterError.onError = (details) {
        capturedError ??= details.exception;
        prev?.call(details);
      };
      addTearDown(() => FlutterError.onError = prev);

      await tester.pumpWidget(
        ChangeNotifierProvider<GuideService>.value(
          value: guide,
          child: const MaterialApp(
            home: _TourHostScreen(tour: GuideTour.portal),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(guide.isActive, isTrue);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      expect(guide.isActive, isFalse);
      expect(capturedError, isNull);
    });

    testWidgets('finishGuideTourIfActive ignoriert andere Touren', (tester) async {
      final guide = GuideService();
      await guide.startTour(
        GuideTour.events,
        const [_demoStep],
        force: true,
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<GuideService>.value(
          value: guide,
          child: const MaterialApp(
            home: _DisposeOnlyHost(tourToFinish: GuideTour.portal),
          ),
        ),
      );
      await tester.pump();

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      expect(guide.isActive, isTrue);
      expect(guide.activeTour, GuideTour.events);
    });

    test('guide wirft vor didChangeDependencies', () {
      final state = _ProbeHostState();
      expect(
        () => state.probeGuide(),
        throwsA(isA<StateError>()),
      );
    });
  });
}

class _DisposeOnlyHost extends StatefulWidget {
  final GuideTour tourToFinish;

  const _DisposeOnlyHost({required this.tourToFinish});

  @override
  State<_DisposeOnlyHost> createState() => _DisposeOnlyHostState();
}

class _DisposeOnlyHostState extends State<_DisposeOnlyHost> with GuideServiceHost {
  @override
  void dispose() {
    finishGuideTourIfActive(widget.tourToFinish);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _ProbeHost extends StatefulWidget {
  const _ProbeHost();

  @override
  State<_ProbeHost> createState() => _ProbeHostState();
}

class _ProbeHostState extends State<_ProbeHost> with GuideServiceHost {
  GuideService probeGuide() => guide;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
