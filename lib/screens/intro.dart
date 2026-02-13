import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/nostr_service.dart';
import 'dashboard.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final TextEditingController _nicknameController = TextEditingController();
  bool _isLoading = false;

  void _finishSetup() async {
    if (_nicknameController.text.isEmpty) return;

    setState(() => _isLoading = true);

    // 1. Heimlich Nostr Key generieren, falls noch keiner da ist
    final nostr = NostrService();
    if (!await nostr.hasKey()) {
      await nostr.generatePrivateKey();
    }
    
    // 2. User anlegen
    final newUser = UserProfile(
      nickname: _nicknameController.text,
      homeMeetup: "Global", 
    );
    await newUser.save();

    if (!mounted) return;
    
    // 3. Direkt ins Dashboard
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const DashboardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.qr_code_2, size: 80, color: Colors.orange),
              const SizedBox(height: 24),
              const Text(
                "Willkommen",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 16),
              const Text(
                "Sammle Stempel bei Einundzwanzig Meetups und baue deine Reputation auf.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _nicknameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Dein Nickname",
                  labelStyle: const TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white24), borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.orange), borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white10,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _finishSetup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.black) 
                    : const Text("LOS GEHT'S", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}