import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme.dart';

/// Öffnet Meetup-Details mit begrenzter Höhe und festem Schließen-Button.
/// Der Builder liefert nur den Inhalt; Route und Layout bleiben hier gebündelt.
Future<void> showEventDetailsSheet({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: cCard,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => LayoutBuilder(
      // Nach Abzug des oberen Sicherheitsabstands berechnen. LayoutBuilder
      // passt die Grenze auch beim Drehen eines bereits offenen Sheets an.
      builder: (context, constraints) => ConstrainedBox(
        constraints: BoxConstraints(maxHeight: constraints.maxHeight * 0.9),
        child: _EventDetailsSheet(child: builder(sheetContext)),
      ),
    ),
  );
}

class _EventDetailsSheet extends StatelessWidget {
  const _EventDetailsSheet({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cTileBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    tooltip: AppLocalizations.of(context).actionClose,
                    icon: const Icon(Icons.close_rounded, color: cText),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
