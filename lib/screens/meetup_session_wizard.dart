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
        title: const Text("MEETUP ABLAUF"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fortschritts-Anzeige
            Row(
              children: [
                _buildStep(context, 1, "NFC", true),
                Expanded(child: Container(height: 2, color: cOrange.withOpacity(0.5))),
                _buildStep(context, 2, "QR", false),
              ],
            ),
            const SizedBox(height: 40),

            const Icon(Icons.nfc, size: 60, color: cOrange),
            const SizedBox(height: 20),
            Text(
              "SCHRITT 1: NFC TAG BESCHREIBEN",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            Text(
              "Möchtest du physische NFC-Tags (NTAG215) für dieses Meetup auslegen? Der kryptographische Beweis (Blockzeit & Signatur) wird darauf fixiert.",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5, color: Colors.grey.shade400),
            ),
            
            const Spacer(),

            // Actions
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: cOrange, foregroundColor: Colors.black),
                onPressed: () {
                  // Leitet zum NFC Writer weiter
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NFCWriterScreen()),
                  );
                },
                icon: const Icon(Icons.tap_and_play),
                label: const Text("NFC TAG BESCHREIBEN"),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.grey, width: 1.5),
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  // Überspringt NFC und geht direkt zum Rolling QR Screen.
                  // Ersetzt den aktuellen Screen, damit "Zurück" ins Admin Panel führt.
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const RollingQRScreen()),
                  );
                },
                child: const Text("ÜBERSPRINGEN / NUR QR NUTZEN"),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(BuildContext context, int number, String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive ? cOrange : cDark,
            shape: BoxShape.circle,
            border: Border.all(color: isActive ? cOrange : Colors.grey, width: 2),
          ),
          child: Text(
            number.toString(),
            style: TextStyle(
              color: isActive ? Colors.black : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: isActive ? cOrange : Colors.grey,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        )
      ],
    );
  }
}