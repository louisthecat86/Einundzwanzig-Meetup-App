import 'package:flutter/material.dart';
import '../models/user.dart';
import '../theme.dart';
import 'verification_gate.dart'; 

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _homeMeetupController = TextEditingController();
  final TextEditingController _nostrController = TextEditingController();

  UserProfile? _user;
  bool _isLoading = true;
  bool _isEditing = false; 

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await UserProfile.load();
    setState(() {
      _user = user;
      _nicknameController.text = user.nickname;
      _fullNameController.text = user.fullName;
      _homeMeetupController.text = user.homeMeetupId;
      _nostrController.text = user.nostrNpub; // <--- Hier geändert zu nostrNpub
      
      _isEditing = !user.isAdminVerified; 
      
      _isLoading = false;
    });
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final newUser = UserProfile(
        nickname: _nicknameController.text.trim(),
        fullName: _fullNameController.text.trim(),
        homeMeetupId: _homeMeetupController.text.trim(),
        nostrNpub: _nostrController.text.trim(), // <--- Hier geändert zu nostrNpub
        isAdminVerified: false, 
        isAdmin: _user?.isAdmin ?? false, 
      );

      await newUser.save();

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => VerificationGateScreen()),
          (route) => false, 
        );
      }
    }
  }

  void _unlockEditMode() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cCard,
        title: const Text("Achtung!", style: TextStyle(color: Colors.white)),
        content: const Text(
          "Wenn du dein Profil bearbeitest, verlierst du deinen 'Verifiziert'-Status.\n\nDu wirst sofort aus dem Dashboard ausgeloggt und musst dich beim nächsten Meetup erneut von einem Admin freischalten lassen.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Abbrechen"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context); 
              setState(() {
                _isEditing = true; 
              });
            },
            child: const Text("Verstanden & Bearbeiten", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _user == null) {
      return const Scaffold(
        backgroundColor: cDark,
        body: Center(child: CircularProgressIndicator(color: cOrange)),
      );
    }

    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(
        title: Text(_isEditing ? "PROFIL BEARBEITEN" : "DEIN PROFIL"),
        backgroundColor: cDark,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: _isEditing ? _buildEditForm() : _buildReadOnlyView(),
      ),
    );
  }

  // --- ANSICHT 1: NUR LESEN (VERIFIZIERT) ---
  Widget _buildReadOnlyView() {
    return Column(
      children: [
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: cGreen.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: cGreen, width: 2),
          ),
          child: const Icon(Icons.verified_user, size: 60, color: cGreen),
        ),
        const SizedBox(height: 20),
        const Text(
          "VERIFIZIERTE IDENTITÄT",
          style: TextStyle(color: cGreen, fontWeight: FontWeight.bold, letterSpacing: 1.5),
        ),
        const SizedBox(height: 10),
        const Text(
          "Deine Identität wurde bestätigt. Änderungen erfordern eine neue Prüfung.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 40),

        _buildInfoTile("Nickname", _user!.nickname, Icons.person),
        _buildInfoTile("Voller Name", _user!.fullName.isEmpty ? "-" : _user!.fullName, Icons.badge),
        _buildInfoTile("Home Meetup", _user!.homeMeetupId.isEmpty ? "-" : _user!.homeMeetupId, Icons.home),
        _buildInfoTile("Nostr Pubkey", _user!.nostrNpub.isEmpty ? "-" : _user!.nostrNpub, Icons.key), // <--- Hier geändert

        const SizedBox(height: 40),

        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.redAccent),
              foregroundColor: Colors.redAccent,
            ),
            icon: const Icon(Icons.edit),
            label: const Text("DATEN ÄNDERN & NEU PRÜFEN"),
            onPressed: _unlockEditMode,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: cOrange, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const Icon(Icons.lock, color: Colors.grey, size: 16),
        ],
      ),
    );
  }

  // --- ANSICHT 2: BEARBEITEN ---
  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "DATEN EINGEBEN",
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Hinweis: Nach dem Speichern musst du dich erneut am Einlass scannen lassen.",
            style: TextStyle(color: Colors.redAccent),
          ),
          const SizedBox(height: 30),

          // Nickname
          TextFormField(
            controller: _nicknameController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: "Nickname / Pseudonym",
              labelStyle: const TextStyle(color: Colors.grey),
              prefixIcon: const Icon(Icons.person, color: cOrange),
              filled: true,
              fillColor: cCard,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (value) => value!.isEmpty ? "Bitte Nickname eingeben" : null,
          ),
          const SizedBox(height: 20),

          // Full Name
          TextFormField(
            controller: _fullNameController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: "Name (Optional)",
              labelStyle: const TextStyle(color: Colors.grey),
              prefixIcon: const Icon(Icons.badge, color: cOrange),
              filled: true,
              fillColor: cCard,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 20),

          // Home Meetup
          TextFormField(
            controller: _homeMeetupController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: "Dein Home-Meetup (Stadt)",
              labelStyle: const TextStyle(color: Colors.grey),
              prefixIcon: const Icon(Icons.home, color: cOrange),
              filled: true,
              fillColor: cCard,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 20),

          // Nostr
          TextFormField(
            controller: _nostrController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: "Nostr Pubkey (npub...)",
              labelStyle: const TextStyle(color: Colors.grey),
              prefixIcon: const Icon(Icons.key, color: cOrange),
              filled: true,
              fillColor: cCard,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),

          const SizedBox(height: 40),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: cOrange,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                "SPEICHERN & ZUR VERIFIZIERUNG",
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}