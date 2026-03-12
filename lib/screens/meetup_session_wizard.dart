import 'package:flutter/material.dart';
import '../theme.dart';
import 'nfc_writer.dart';
import 'rolling_qr_screen.dart';

class MeetupSessionWizard extends StatelessWidget {
  const MeetupSessionWizard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(
        title: const Text('MEETUP STARTEN'),
        backgroundColor: cDark,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: cTextSecondary),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Schritt-Indikator
            Row(children: [
              _step(1, 'NFC', true),
              Expanded(child: Container(height: 0.5, color: cTileBorder)),
              _step(2, 'QR', false),
            ]),
            const SizedBox(height: 32),

            // Icon
            const Icon(Icons.nfc_rounded, size: 40, color: cOrange),
            const SizedBox(height: 16),

            // Titel
            const Text('SCHRITT 1: NFC TAG',
              style: TextStyle(color: cText, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
            const SizedBox(height: 10),

            // Beschreibung
            const Text(
              'Möchtest du physische NFC-Tags (NTAG215) für dieses Meetup auslegen? '
              'Der kryptographische Beweis (Blockzeit & Signatur) wird darauf fixiert.',
              style: TextStyle(color: cTextSecondary, fontSize: 13, height: 1.6)),

            const Spacer(),

            // NFC schreiben Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: cOrange, foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kTileRadius))),
                onPressed: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const NFCWriterScreen())),
                icon: const Icon(Icons.nfc_rounded, size: 18),
                label: const Text('NFC TAG BESCHREIBEN',
                  style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              ),
            ),
            const SizedBox(height: 10),

            // Überspringen
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const RollingQRScreen()),
                  (route) => route.isFirst),
                child: const Text('ÜBERSPRINGEN — NUR QR NUTZEN',
                  style: TextStyle(color: cTextTertiary, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _step(int number, String label, bool isActive) {
    return Column(children: [
      Container(
        width: 28, height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? cOrange : cCard,
          shape: BoxShape.circle,
          border: Border.all(color: isActive ? cOrange : cTileBorder, width: 0.5)),
        child: Text('$number', style: TextStyle(
          color: isActive ? Colors.black : cTextTertiary,
          fontSize: 12, fontWeight: FontWeight.w800))),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(
        color: isActive ? cOrange : cTextTertiary,
        fontSize: 10, fontWeight: FontWeight.w700)),
    ]);
  }
}
