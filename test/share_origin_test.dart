import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:einundzwanzig_meetup_app/utils/share_origin.dart';

void main() {
  testWidgets('shareOriginFor liefert das globale Rechteck des Widgets',
      (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 10, top: 20),
            child: SizedBox(
              width: 100,
              height: 50,
              child: Builder(builder: (c) {
                ctx = c;
                return const SizedBox.expand();
              }),
            ),
          ),
        ),
      ),
    ));

    expect(shareOriginFor(ctx), const Rect.fromLTWH(10, 20, 100, 50));
  });

  testWidgets('shareOriginFor ist für eine ganze Seite nie leer',
      (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (c) {
        ctx = c;
        return const Scaffold(body: SizedBox.expand());
      }),
    ));

    final rect = shareOriginFor(ctx);
    // iOS lehnt {{0,0},{0,0}} ab — genau das darf hier nie herauskommen.
    expect(rect.isEmpty, isFalse);
    expect(rect.topLeft, Offset.zero);
    expect(rect.size, tester.view.physicalSize / tester.view.devicePixelRatio);
  });

  testWidgets('shareOriginFor schneidet überstehende Kanten auf die Ansicht',
      (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: Transform.translate(
            offset: const Offset(-20, 10),
            child: SizedBox(
              width: 50,
              height: 40,
              child: Builder(builder: (c) {
                ctx = c;
                return const SizedBox.expand();
              }),
            ),
          ),
        ),
      ),
    ));

    // Roh wäre (-20, 10, 50×40). iOS will die Fläche ganz innerhalb.
    expect(shareOriginFor(ctx), const Rect.fromLTWH(0, 10, 30, 40));
  });

  testWidgets(
      'shareOriginFor kürzt einen scrollbaren Inhalt auf den sichtbaren Teil',
      (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: OverflowBox(
            alignment: Alignment.topLeft,
            minWidth: 0,
            maxWidth: double.infinity,
            minHeight: 0,
            maxHeight: double.infinity,
            child: Transform.translate(
              offset: const Offset(0, 100),
              child: SizedBox(
                width: 80,
                height: 100000,
                child: Builder(builder: (c) {
                  ctx = c;
                  return const SizedBox.expand();
                }),
              ),
            ),
          ),
        ),
      ),
    ));

    final view = tester.view.physicalSize / tester.view.devicePixelRatio;
    expect(shareOriginFor(ctx), Rect.fromLTWH(0, 100, 80, view.height - 100));
  });

  testWidgets(
      'shareOriginFor nimmt die Ansicht, wenn das Widget ganz außerhalb liegt',
      (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: Transform.translate(
            offset: const Offset(0, -10000),
            child: SizedBox(
              width: 20,
              height: 20,
              child: Builder(builder: (c) {
                ctx = c;
                return const SizedBox.expand();
              }),
            ),
          ),
        ),
      ),
    ));

    final view = tester.view.physicalSize / tester.view.devicePixelRatio;
    expect(shareOriginFor(ctx), Offset.zero & view);
  });
}
