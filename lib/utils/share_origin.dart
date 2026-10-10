import 'package:flutter/widgets.dart';

/// Ankerpunkt für das Teilen-Blatt von share_plus.
///
/// iOS verlangt ein nicht-leeres `sharePositionOrigin`, das vollständig
/// innerhalb der Ansicht liegt, sobald UIKit das Teilen als Popover
/// darstellt. Bis iOS 18 galt das nur auf dem iPad, seit iOS 26 auch auf
/// dem iPhone — ohne gültigen Anker wirft share_plus 10.x
/// „sharePositionOrigin: argument must be set, {{0, 0}, {0, 0}} must be
/// non-zero …“ (Issue #73). share_plus 10.x prüft das mit
/// `CGRectContainsRect` gegen die ganze Fläche, nicht nur gegen „nicht leer“.
///
/// Das Rechteck muss bestimmt werden, solange das Widget gebaut ist: also
/// vor längerer Arbeit und vor jedem `await`, nach dem der Kontext
/// verschwunden sein könnte.
///
/// Ein Widget in einem scrollbaren Sheet kann größer als die Ansicht sein
/// oder nach dem Scrollen teilweise darüber hinausragen. Zurückgegeben wird
/// deshalb nur der Ausschnitt, der in der Ansicht liegt.
Rect shareOriginFor(BuildContext context) {
  final screen = _screenRect(context);
  final renderObject = context.findRenderObject();
  final renderBox = renderObject is RenderBox ? renderObject : null;
  if (renderBox != null &&
      renderBox.hasSize &&
      renderBox.size.width > 0 &&
      renderBox.size.height > 0) {
    final clipped = (renderBox.localToGlobal(Offset.zero) & renderBox.size)
        .intersect(screen);
    if (clipped.width > 0 && clipped.height > 0) return clipped;
  }
  // Komplett außerhalb oder noch nicht gelegt: die Bildschirmfläche ist ein
  // gültiger Anker, {{0,0},{0,0}} nicht. Auf dem iPad ergibt das ein
  // zentriertes Popover.
  return screen;
}

Rect _screenRect(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  if (size.width <= 0 || size.height <= 0) {
    return const Rect.fromLTWH(0, 0, 1, 1);
  }
  return Offset.zero & size;
}
