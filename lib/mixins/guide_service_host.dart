import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/guide_service.dart';

/// Haelt [GuideService] fuer [State.dispose].
///
/// context.read dort wirft: Das Element wird gerade abgebaut, Provider findet
/// kein InheritedWidget mehr (Null check in _inheritedElementOf).
mixin GuideServiceHost<T extends StatefulWidget> on State<T> {
  GuideService? _guideHost;

  /// Nur nach [didChangeDependencies] verfuegbar — kein context.read-Fallback.
  GuideService get guide {
    final g = _guideHost;
    if (g == null) {
      throw StateError(
        'GuideServiceHost.guide vor didChangeDependencies aufgerufen',
      );
    }
    return g;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _guideHost ??= context.read<GuideService>();
  }

  void finishGuideTourIfActive(GuideTour tour) {
    final g = _guideHost;
    if (g != null && g.activeTour == tour) {
      g.finishTourNow();
    }
  }
}
