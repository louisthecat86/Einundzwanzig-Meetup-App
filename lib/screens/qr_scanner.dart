import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:convert';
import '../services/badge_security.dart';
import '../theme.dart';

class SecureQRScanner extends StatefulWidget {
  const SecureQRScanner({super.key});

  @override
  State<SecureQRScanner> createState() => _SecureQRScannerState();
}

class _SecureQRScannerState extends State<SecureQRScanner> {
  bool _isScanned = false;

  void _onDetect(BarcodeCapture capture) {
    if (_isScanned) return;
    final List<Barcode> barcodes = capture.barcodes;
    
    for (final barcode in barcodes) {
      final String? code = barcode.rawValue;
      if (code != null && code.startsWith("21:")) {
        setState(() => _isScanned = true);
        _verifyAndShow(code);
        break;
      }
    }
  }

  void _verifyAndShow(String fullCode) {
    // Format: 21:BASE64_DATEN.SIGNATUR
    try {
      // 1. Das "21:" am Anfang wegmachen
      final cleanCode = fullCode.substring(3);
      
      // 2. Am Punkt trennen (Daten vs. Signatur)
      final parts = cleanCode.split('.');
      if (parts.length != 2) throw Exception("Format ungültig");

      final dataBase64 = parts[0];
      final signatureOnQr = parts[1];

      // 3. Daten decodieren
      final jsonString = utf8.decode(base64.decode(dataBase64));

      // 4. NACHRECHNEN: Stimmt die Unterschrift?
      // Wir nutzen dieselbe Funktion wie beim Erstellen
      final calculatedSignature = BadgeSecurity.sign(jsonString, "QR", 0);

      if (signatureOnQr == calculatedSignature) {
        // ✅ ECHT!
        final data = jsonDecode(jsonString);
        _showResultDialog(
          title: "VERIFIZIERT ✅",
          content: "User: ${data['u']}\nBadges: ${data['c']}\n\nDieser Code ist echt und wurde von der App signiert.",
          isSuccess: true
        );
      } else {
        // ❌ FÄLSCHUNG!
        _showResultDialog(
          title: "ALARM ❌",
          content: "Die Signatur stimmt nicht! Dieser QR-Code wurde manipuliert.",
          isSuccess: false
        );
      }
    } catch (e) {
      _showResultDialog(title: "Fehler", content: "Ungültiger Code.", isSuccess: false);
    }
  }

  void _showResultDialog({required String title, required String content, required bool isSuccess}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cCard,
        title: Text(title, style: TextStyle(color: isSuccess ? Colors.green : Colors.red)),
        content: Text(content, style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Dialog zu
              Navigator.pop(context); // Scanner zu
            },
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("REPUTATION PRÜFEN")),
      body: MobileScanner(
        onDetect: _onDetect,
      ),
    );
  }
}