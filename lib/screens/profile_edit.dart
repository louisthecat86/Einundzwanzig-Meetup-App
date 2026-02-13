import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user.dart';
import '../services/nostr_service.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});
  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  UserProfile? _user;
  final _nickController = TextEditingController();
  final _tgController = TextEditingController();
  final _twController = TextEditingController();
  
  bool _showAdvanced = false;
  String? _npub;
  String? _nsec;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final u = await UserProfile.load();
    if (u != null) {
      _nickController.text = u.nickname;
      _tgController.text = u.telegramHandle;
      _twController.text = u.twitterHandle;
      
      final nostr = NostrService();
      _npub = await nostr.getNpub();
      
      setState(() => _user = u);
    }
  }

  Future<void> _save() async {
    if (_user == null) return;
    _user!.nickname = _nickController.text;
    _user!.telegramHandle = _tgController.text;
    _user!.twitterHandle = _twController.text;
    await _user!.save();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text("Dein Profil"), backgroundColor: Colors.black),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildField("Nickname", _nickController, Icons.person),
          _buildField("Telegram (optional)", _tgController, Icons.send),
          _buildField("Twitter/X (optional)", _twController, Icons.alternate_email),
          
          const SizedBox(height: 32),
          
          // Advanced Section Toggle
          ListTile(
            title: const Text("Erweiterte Einstellungen", style: TextStyle(color: Colors.white)),
            trailing: Icon(_showAdvanced ? Icons.expand_less : Icons.expand_more, color: Colors.white),
            onTap: () => setState(() => _showAdvanced = !_showAdvanced),
          ),
          
          if (_showAdvanced) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Digitale Identität (Nostr)", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text("Deine Reputation ist an diesen Schlüssel gebunden.", style: TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 16),
                  if (_npub != null) ...[
                     Text(_npub!, style: const TextStyle(color: Colors.white, fontFamily: "Monospace", fontSize: 10)),
                     const SizedBox(height: 8),
                     OutlinedButton.icon(
                       icon: const Icon(Icons.copy, size: 16),
                       label: const Text("ID kopieren"),
                       onPressed: () => Clipboard.setData(ClipboardData(text: _npub!)),
                     ),
                  ] else 
                    const Text("Kein Schlüssel gefunden.", style: TextStyle(color: Colors.red)),
                ],
              ),
            )
          ],

          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, padding: const EdgeInsets.all(16)),
            child: const Text("SPEICHERN", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: ctrl,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.white54),
          filled: true,
          fillColor: Colors.white10,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}