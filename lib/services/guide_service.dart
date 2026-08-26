import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum GuideTour {
  onboarding,
  home,
  settings,
  events,
  portal,     // Community-Bereich
  wallet,     // Badge-Wallet
  reputation, // Vertrauensnetzwerk
  scan,
  myMeetups,  // Portal-Termine des eigenen Meetups
  portalArea, // Portal-Bereich: Meetups, Events, Kurse, Karte
}

/// Ein einzelner Schritt der Spotlight-Tour.
///
/// Neu gegenueber der ersten Fassung sind die Felder fuer die GEFUEHRTE
/// Eingabe: [completeWhen] beschreibt, wann der Schritt erledigt ist,
/// [advanceOnTargetTap] laesst den Tap auf das freigegebene Element den
/// Schritt weiterschalten, und [blockOutside] sperrt alles ausserhalb des
/// Spotlights, damit wirklich nur der erklaerte Bereich bedienbar ist.
class GuideStep {
  /// Widget, das freigegeben und umrahmt wird. null = reiner Dialog.
  final GlobalKey? targetKey;

  final String titleKey;
  final String bodyKey;

  /// Optionale Handlungsaufforderung ("Tippe ins Feld und gib ... ein.").
  /// Wird im Tooltip in Akzentfarbe unter dem Fliesstext gezeigt.
  final String? hintKey;

  /// Nur noch Rueckfallposition, wenn das Ziel nicht messbar ist.
  final Alignment tooltipAlignment;

  /// Reserviert fuer spaetere Touren ueber Routengrenzen hinweg.
  final bool navigateFirst;
  final String? routeName;

  /// Sperrt alles ausserhalb des Spotlights. Nur so ist der Schritt
  /// wirklich gefuehrt — sonst kann der Nutzer ueberall hin tippen.
  final bool blockOutside;

  /// Ist das Loch selbst bedienbar? false = reines Zeigen.
  final bool interactiveTarget;

  /// Tap auf das freigegebene Element schaltet einen Schritt weiter.
  /// Fuer Elemente, die etwas oeffnen (Home-Meetup-Feld -> Sheet).
  final bool advanceOnTargetTap;

  /// Bedingung, die erfuellt sein muss, bevor "Weiter" freigeschaltet
  /// wird. null = Schritt ist reine Erklaerung und sofort abschliessbar.
  /// Wird vom Overlay pro Frame ausgewertet, muss also billig sein.
  final ValueGetter<bool>? completeWhen;

  /// Springt automatisch weiter, sobald [completeWhen] erfuellt ist.
  final bool autoAdvance;

  /// Ziel entsteht erst spaeter im Baum (z. B. in einem Sheet, das sich
  /// gerade oeffnet). Das Overlay wartet dann, statt den Schritt ohne
  /// Loch anzuzeigen.
  final bool waitForTarget;

  /// Wird das Ziel nach dieser Zeit nicht gefunden, laeuft der Schritt
  /// ohne Loch weiter — besser als eine haengende Tour.
  final Duration waitTimeout;

  /// Luft zwischen Ziel-Widget und Lochrand.
  final EdgeInsets holePadding;

  /// Eckenradius des Lochs.
  final double holeRadius;

  /// Ziel automatisch in den sichtbaren Bereich scrollen.
  final bool scrollIntoView;

  const GuideStep({
    this.targetKey,
    required this.titleKey,
    required this.bodyKey,
    this.hintKey,
    this.tooltipAlignment = Alignment.bottomCenter,
    this.navigateFirst = false,
    this.routeName,
    this.blockOutside = true,
    this.interactiveTarget = true,
    this.advanceOnTargetTap = false,
    this.completeWhen,
    this.autoAdvance = false,
    this.waitForTarget = false,
    this.waitTimeout = const Duration(seconds: 6),
    this.holePadding = const EdgeInsets.all(10),
    this.holeRadius = 14,
    this.scrollIntoView = true,
  });

  /// Erwartet dieser Schritt eine Handlung des Nutzers?
  bool get requiresAction => completeWhen != null || advanceOnTargetTap;

  /// Ist die erwartete Handlung erledigt? Ohne Bedingung immer true.
  bool get isComplete {
    final check = completeWhen;
    if (check == null) return true;
    try {
      return check();
    } catch (_) {
      // Lieber durchlassen als die Tour blockieren, wenn ein State
      // waehrend eines Routenwechsels kurz nicht erreichbar ist.
      return true;
    }
  }
}

class GuideService extends ChangeNotifier {
  static const _prefsPrefix = 'guide_completed_';
  static const _onboardingAskedKey = 'guide_onboarding_asked';

  GuideTour? _activeTour;
  List<GuideStep> _steps = [];
  int _currentStep = 0;
  bool _isActive = false;
  bool _isPaused = false;

  bool get isActive => _isActive;

  /// Tour laeuft, ist aber voruebergehend unsichtbar (z. B. waehrend
  /// eine Route wechselt). Das Overlay zeichnet dann nichts.
  bool get isPaused => _isPaused;

  bool get isVisible => _isActive && !_isPaused;

  GuideTour? get activeTour => _activeTour;
  int get currentStepIndex => _currentStep;
  int get totalSteps => _steps.length;

  GuideStep? get currentStep =>
      _steps.isNotEmpty && _currentStep < _steps.length
          ? _steps[_currentStep]
          : null;

  bool get isFirstStep => _currentStep == 0;
  bool get isLastStep => _steps.isNotEmpty && _currentStep == _steps.length - 1;

  /// Darf der Weiter-Knopf gedrueckt werden?
  bool get canAdvance => currentStep?.isComplete ?? false;

  Future<bool> wasTourCompleted(GuideTour tour) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_prefsPrefix${tour.name}') ?? false;
  }

  Future<bool> shouldAskForOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_onboardingAskedKey) ?? false);
  }

  Future<void> markOnboardingAsked() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingAskedKey, true);
  }

  /// Schaltet ALLE Touren ab.
  ///
  /// Wer die Frage auf dem Dashboard mit "Nein, danke" beantwortet, will
  /// keine Fuehrung — und zwar nirgends. Vorher galt die Ablehnung nur fuer
  /// die Dashboard-Tour; kurz darauf sprang der Guide in den Einstellungen
  /// oder im Termin-Editor doch wieder an. Das wirkte, als haette die App
  /// die Antwort ignoriert.
  ///
  /// Umgesetzt als "alle als gesehen markieren" statt als eigener Schalter:
  /// So greift "Tour wiederholen" in den Einstellungen unveraendert weiter —
  /// es raeumt genau diese Markierungen wieder weg.
  Future<void> declineAllTours() async {
    final prefs = await SharedPreferences.getInstance();
    for (final tour in GuideTour.values) {
      await prefs.setBool('$_prefsPrefix${tour.name}', true);
    }
    await prefs.setBool(_onboardingAskedKey, true);
  }

  Future<void> _markCompleted(GuideTour tour) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefsPrefix${tour.name}', true);
  }

  Future<void> resetTour(GuideTour tour) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefsPrefix${tour.name}');
  }

  Future<void> resetAllTours() async {
    final prefs = await SharedPreferences.getInstance();
    for (final tour in GuideTour.values) {
      await prefs.remove('$_prefsPrefix${tour.name}');
    }
    await prefs.remove(_onboardingAskedKey);
  }

  /// Startet eine Tour. [force] ueberspringt die "schon gesehen"-Pruefung,
  /// damit die Tour aus den Einstellungen heraus wiederholt werden kann.
  Future<void> startTour(
    GuideTour tour,
    List<GuideStep> steps, {
    bool force = false,
  }) async {
    if (steps.isEmpty) return;
    if (!force && await wasTourCompleted(tour)) return;

    _activeTour = tour;
    _steps = steps;
    _currentStep = 0;
    _isActive = true;
    _isPaused = false;
    notifyListeners();
  }

  void nextStep() {
    if (!_isActive) return;
    if (_currentStep < _steps.length - 1) {
      _currentStep++;
      _isPaused = false;
      notifyListeners();
    } else {
      finishTour();
    }
  }

  void previousStep() {
    if (!_isActive || _currentStep == 0) return;
    _currentStep--;
    _isPaused = false;
    notifyListeners();
  }

  /// Ueberspringt den laufenden Schritt, ohne die Tour zu beenden.
  /// Wird vom Overlay benutzt, wenn ein Ziel dauerhaft nicht auffindbar
  /// ist — eine haengende Tour waere das schlechtere Ergebnis.
  void skipStep() => nextStep();

  /// Meldet dem Service, dass der Nutzer auf das freigegebene Element
  /// getippt hat. Nur Schritte mit [GuideStep.advanceOnTargetTap]
  /// reagieren darauf.
  void reportTargetTapped() {
    final step = currentStep;
    if (step == null || !step.advanceOnTargetTap) return;
    nextStep();
  }

  /// Wird vom Overlay aufgerufen, sobald die Bedingung des Schritts
  /// erfuellt ist. Schaltet nur bei [GuideStep.autoAdvance] weiter.
  void reportStepCompleted() {
    final step = currentStep;
    if (step == null || !step.autoAdvance || !step.isComplete) return;
    nextStep();
  }

  /// Tour bleibt bestehen, wird aber nicht gezeichnet.
  void pause() {
    if (!_isActive || _isPaused) return;
    _isPaused = true;
    notifyListeners();
  }

  void resume() {
    if (!_isActive || !_isPaused) return;
    _isPaused = false;
    notifyListeners();
  }

  Future<void> finishTour() async {
    final tour = _activeTour;
    if (tour != null) {
      await _markCompleted(tour);
    }
    _clearActiveTour();
  }

  /// Synchrones Beenden — fuer [State.dispose]. SharedPreferences-Schreiben
  /// laeuft im Hintergrund; UI-Zustand wird sofort zurueckgesetzt.
  void finishTourNow() {
    final tour = _activeTour;
    if (tour != null) {
      unawaited(_markCompleted(tour));
    }
    _clearActiveTour();
  }

  void _clearActiveTour() {
    _isActive = false;
    _isPaused = false;
    _steps = [];
    _activeTour = null;
    _currentStep = 0;
    notifyListeners();
  }
}