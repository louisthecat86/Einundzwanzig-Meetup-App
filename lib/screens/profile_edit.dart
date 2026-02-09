import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/user.dart'; 

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _nameController = TextEditingController();
  final _tgController = TextEditingController();
  final _twitterController = TextEditingController();
  final _npubController = TextEditingController();
  
  bool _isNostrVerified = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final user = await UserProfile.load();
    setState(() {
      _nameController.text = user.nickname;
      _tgController.text = user.telegramHandle;
      _twitterController.text = user.twitterHandle;
      _npubController.text = user.nostrNpub;
      _isNostrVerified = user.isNostrVerified;
      _isLoading = false;
    });
  }

  void _saveData() async {
    String npub = _npubController.text.trim();
    
    // Einfache Validierung: Wenn eingegeben, sollte es mindestens wie ein Key aussehen
    if (npub.isNotEmpty && npub.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Das sieht nicht wie ein gültiger npub/Nostr-Key aus.")),
      );
      return;
    }

    final user = UserProfile(
      nickname: _nameController.text.trim(),
      telegramHandle: _tgController.text.trim(),
      twitterHandle: _twitterController.text.trim(),
      nostrNpub: npub,
      isNostrVerified: _isNostrVerified,
    );
    await user.save();
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("IDENTITÄT")),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: cOrange))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    "DEINE IDENTITÄT",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: cOrange,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Erstelle dein Profil für die Einundzwanzig Community.",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 32),
                  
                  _buildInput("NICKNAME / NYM", "Satoshi", _nameController, Icons.person),
                  const SizedBox(height: 20),
                  
                  // --- NOSTR AREA ---
                  const Text(
                    "NOSTR IDENTITÄT (OPTIONAL)",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status wenn verifiziert
                        if (_isNostrVerified) ...[
                          Row(
                            children: const [
                              Icon(Icons.verified, color: cPurple, size: 20),
                              SizedBox(width: 8),
                              Text(
                                "VOM ADMIN VERIFIZIERT",
                                style: TextStyle(
                                  color: cPurple,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                        
                        // Info Text
                        Text(
                          _isNostrVerified
                              ? "Dein npub wurde von einem Admin vor Ort bestätigt."
                              : "Gib deinen npub oder hex-Key ein. Ein Admin kann deine Identität vor Ort bestätigen.",
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cTextSecondary,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // npub Eingabefeld
                        TextField(
                          controller: _npubController,
                          style: TextStyle(
                            color: _isNostrVerified ? cPurple : cText,
                            fontFamily: 'monospace',
                            fontSize: 13,
                          ),
                          decoration: InputDecoration(
                            hintText: "npub1... oder hex key",
                            prefixIcon: Icon(
                              Icons.key,
                              color: _isNostrVerified ? cPurple : cOrange,
                            ),
                            suffixIcon: _npubController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, color: cTextTertiary),
                                    onPressed: () {
                                      _npubController.clear();
                                      setState(() {});
                                    },
                                  )
                                : null,
                          ),
                          onChanged: (value) => setState(() {}),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  _buildInput("TELEGRAM (OPTIONAL)", "@username", _tgController, Icons.send),
                  const SizedBox(height: 20),
                  _buildInput("TWITTER / X (OPTIONAL)", "@username", _twitterController, Icons.alternate_email),

                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _saveData,
                      icon: const Icon(Icons.save),
                      label: const Text("PROFIL SPEICHERN"),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // DEBUG: Admin-Rechte zurücksetzen
                  Center(
                    child: TextButton(
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: cCard,
                            title: const Text("Admin-Rechte zurücksetzen?", style: TextStyle(color: Colors.white)),
                            content: const Text(
                              "Dies entfernt Admin-Rechte von deinem Account. Du kannst dich jederzeit wieder als Admin anmelden.",
                              style: TextStyle(color: Colors.grey),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text("ABBRECHEN"),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                child: const Text("ZURÜCKSETZEN"),
                              ),
                            ],
                          ),
                        );
                        
                        if (confirmed == true) {
                          final user = await UserProfile.load();
                          user.isAdmin = false;
                          await user.save();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("✅ Admin-Rechte entfernt"),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        }
                      },
                      child: const Text(
                        "Admin-Rechte zurücksetzen",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInput(String label, String hint, TextEditingController controller, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: cOrange),
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: cTextTertiary),
                    onPressed: () {
                      controller.clear();
                      setState(() {});
                    },
                  )
                : null,
          ),
          onChanged: (value) => setState(() {}),
        ),
      ],
    );
  }
}