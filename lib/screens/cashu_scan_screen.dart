import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../l10n/app_localizations.dart';
import '../services/voice_wallet/cashu_token.dart';
import '../services/voice_wallet/cashu_ur.dart';
import '../theme.dart';

/// Kamera nur, um einen Cashu-Token zu lesen. Der gescannte Text geht
/// zurueck an die Sprachseite — hier wird nichts gespeichert und nichts
/// eingeloest.
///
/// Ein feststehender Code wird sofort zurueckgegeben. Ein wechselnder
/// Code (mehrere `ur:`-Teile) bleibt offen, bis alle Teile da sind.
class CashuScanScreen extends StatefulWidget {
  const CashuScanScreen({super.key});

  @override
  State<CashuScanScreen> createState() => _CashuScanScreenState();
}

class _CashuScanScreenState extends State<CashuScanScreen> {
  final MobileScannerController _scanner = MobileScannerController(
    detectionSpeed: DetectionSpeed.unrestricted,
    formats: const [BarcodeFormat.qrCode],
  );
  final CashuUrCollector _ur = CashuUrCollector();
  bool _done = false;

  @override
  void dispose() {
    _scanner.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_done) return;
    var changed = false;
    for (final barcode in capture.barcodes) {
      final code = _barcodeText(barcode);
      if (code == null || code.isEmpty) continue;
      if (urPart(code) != null) {
        final beforeReceived = _ur.received;
        final beforeExpected = _ur.expected;
        final token = _ur.add(code);
        if (token != null && token.isNotEmpty) {
          _finish(token);
          return;
        }
        if (_ur.received != beforeReceived || _ur.expected != beforeExpected) {
          changed = true;
        }
        continue;
      }
      if (_cashuScore(code) > 0 || cashuReadHint(code) == 'lightning') {
        _finish(code);
        return;
      }
    }
    if (changed && mounted) setState(() {});
  }

  void _finish(String code) {
    if (_done) return;
    _done = true;
    Navigator.pop(context, code);
  }

  String? _barcodeText(Barcode barcode) {
    final options = <String>[];
    final raw = barcode.rawValue?.trim();
    if (raw != null && raw.isNotEmpty) options.add(raw);
    final bytes = barcode.rawBytes;
    if (bytes != null && bytes.isNotEmpty) {
      options.add(utf8.decode(bytes, allowMalformed: true));
    }
    String? best;
    var bestScore = -1;
    for (final option in options) {
      final score = _cashuScore(option);
      if (score > bestScore) {
        best = option;
        bestScore = score;
      }
    }
    if (bestScore > 0) return best;
    return options.isEmpty ? null : options.first;
  }

  int _cashuScore(String text) {
    final match = RegExp(r'cashu[ABab]', caseSensitive: false).firstMatch(text);
    if (match == null) return 0;
    return text.length - match.start;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final caption = _ur.expected > 0
        ? t.vwUrProgress(_ur.received, _ur.expected)
        : t.vwUrHold;
    return Scaffold(
      backgroundColor: cDark,
      body: Stack(children: [
        MobileScanner(controller: _scanner, onDetect: _onDetect),
        SafeArea(
          child: Align(
            alignment: Alignment.topLeft,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
            ),
          ),
        ),
        SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
              child: Text(
                caption,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  shadows: [Shadow(blurRadius: 12, color: Colors.black)],
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
