import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/meetup.dart';
import '../services/rolling_qr_service.dart';
import '../services/nostr_service.dart';

class RollingQrScreen extends StatefulWidget {
  final Meetup meetup;
  const RollingQrScreen({super.key, required this.meetup});

  @override
  State<RollingQrScreen> createState() => _RollingQrScreenState();
}

class _RollingQrScreenState extends State<RollingQrScreen> {
  late Timer _timer;
  String _qrData = "";
  int _secondsLeft = 5;
  final _qrService = RollingQrService();

  @override
  void initState() {
    super.initState();
    _updateQr();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsLeft--;
        if (_secondsLeft <= 0) {
          _updateQr();
          _secondsLeft = RollingQrService.intervalSeconds;
        }
      });
    });
  }

  Future<void> _updateQr() async {
    final nostr = NostrService();
    final pub = await nostr.getPublicKey();
    final npub = await nostr.getNpub();
    
    // In Produktion würde man hier mit dem privaten Key signieren
    final payload = _qrService.generatePayload(
      widget.meetup.id, 
      widget.meetup.city, 
      widget.meetup.country ?? "DE", 
      "simulated_priv_key", 
      pub ?? "unknown", 
      npub ?? "unknown"
    );

    if (mounted) {
      setState(() => _qrData = payload);
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange, // Auffällig für Organisator
      appBar: AppBar(title: const Text("Rolling Check-In"), backgroundColor: Colors.orange, elevation: 0),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: QrImageView(
                data: _qrData,
                version: QrVersions.auto,
                size: 280.0,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              "Aktualisiert in $_secondsLeft s",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 8),
            const Text(
              "Anti-Screenshot Schutz aktiv (±5 Sek)",
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}