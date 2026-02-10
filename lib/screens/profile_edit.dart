import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/meetup.dart'; // Für die Liste
import '../services/meetup_service.dart'; // Zum Laden der Liste
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
  final TextEditingController _nostrController = TextEditingController();
  final TextEditingController _telegramController = TextEditingController(); // NEU
  final TextEditingController _twitterController = TextEditingController(); // NEU
  
  // Statt Controller speichern wir das gewählte Meetup direkt
  String _selectedHomeMeetup = "";
  List<Meetup> _allMeetups = [];

  UserProfile? _user;
  bool _isLoading = true;
  bool _isEditing = false; 

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // 1. User laden
    final user = await UserProfile.load();
    // 2. Alle Meetups laden (für die Auswahl)
    final meetups = await MeetupService.fetchMeetups();

    setState(() {
      _user = user;
      _allMeetups = meetups;
      
      // Felder befüllen
      _nicknameController.text = user.nickname;
      _fullNameController.text = user.fullName;
      _nostrController.text = user.nostrNpub;
      _telegramController.text = user.telegramHandle;
      _twitterController.text = user.twitterHandle;
      _selectedHomeMeetup = user.homeMeetupId;
      
      _isEditing = !user.isAdminVerified; 
      _isLoading = false;
    });
  }

  // --- MEETUP AUSWAHL DIALOG ---
  void _showMeetupPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: cCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text("Wähle dein Home-Meetup", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: _allMeetups.length,
                    itemBuilder: (context, index) {
                      final meetup = _allMeetups[index];
                      return ListTile(
                        leading: const Icon(Icons.location_city, color: cOrange),
                        title: Text(meetup.city, style: const TextStyle(color: Colors.white)),
                        subtitle: Text(meetup.country, style: TextStyle(color: Colors.grey.shade400)),
                        onTap: () {
                          setState(() {
                            _selectedHomeMeetup = meetup.city; // Stadtname speichern
                          });
                          Navigator.pop(context); // Schließen
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final newUser = UserProfile(
        nickname: _nicknameController.text.trim(),
        fullName: _fullNameController.text.trim(),
        homeMeetupId: _selectedHomeMeetup, // Das gewählte Meetup
        nostrNpub: _nostrController.text.trim(),
        telegramHandle: _telegramController.text.trim(), // NEU
        twitterHandle: _twitterController.text.trim(), // NEU
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
          "Wenn du bearbeitest, verlierst du deinen 'Verifiziert'-Status und musst neu freigeschaltet werden.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Abbrechen")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: cRed),
            onPressed: () {
              Navigator.pop(context); 
              setState(() => _isEditing = true);
            },
            child: const Text("Bearbeiten", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _user == null) {
      return const Scaffold(backgroundColor: cDark, body: Center(child: CircularProgressIndicator(color: cOrange)));
    }

    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(
        title: Text(_isEditing ? "PROFIL BEARBEITEN" : "DEIN PROFIL"),
        backgroundColor: cDark,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: _isEditing ? _buildEditForm() : _buildReadOnlyView(),
      ),
    );
  }

  // --- ANSICHT: NUR LESEN ---
  Widget _buildReadOnlyView() {
    return Column(
      children: [
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: cGreen, width: 2), color: cGreen.withOpacity(0.1)),
          child: const Icon(Icons.verified_user, size: 50, color: cGreen),
        ),
        const SizedBox(height: 10),
        const Text("VERIFIZIERT", style: TextStyle(color: cGreen, fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 30),
        _buildInfoTile("Nickname", _user!.nickname, Icons.person),
        _buildInfoTile("Home Meetup", _user!.homeMeetupId.isEmpty ? "-" : _user!.homeMeetupId, Icons.home),
        if (_user!.nostrNpub.isNotEmpty) _buildInfoTile("Nostr", _user!.nostrNpub.substring(0, 10) + "...", Icons.key),
        if (_user!.telegramHandle.isNotEmpty) _buildInfoTile("Telegram", _user!.telegramHandle, Icons.send),
        if (_user!.twitterHandle.isNotEmpty) _buildInfoTile("Twitter", _user!.twitterHandle, Icons.alternate_email),
        const SizedBox(height: 30),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(foregroundColor: cRed, side: const BorderSide(color: cRed)),
          icon: const Icon(Icons.edit),
          label: const Text("BEARBEITEN (Status verlieren)"),
          onPressed: _unlockEditMode,
        ),
      ],
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [Icon(icon, color: cOrange, size: 20), const SizedBox(width: 16), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)), Text(value, style: const TextStyle(color: Colors.white, fontSize: 16))])]),
    );
  }

  // --- ANSICHT: BEARBEITEN ---
  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("BASIS DATEN", style: TextStyle(color: cOrange, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _buildTextField(_nicknameController, "Nickname", Icons.person, required: true),
          const SizedBox(height: 10),
          _buildTextField(_fullNameController, "Name (Optional)", Icons.badge),
          const SizedBox(height: 10),
          
          // MEETUP PICKER (Statt Textfeld)
          InkWell(
            onTap: _showMeetupPicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: cBorder)),
              child: Row(
                children: [
                  const Icon(Icons.home, color: cOrange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedHomeMeetup.isEmpty ? "Wähle dein Home-Meetup" : _selectedHomeMeetup,
                      style: TextStyle(color: _selectedHomeMeetup.isEmpty ? Colors.grey : Colors.white, fontSize: 16),
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, color: Colors.grey),
                ],
              ),
            ),
          ),

          const SizedBox(height: 30),
          const Text("SOCIALS (Optional)", style: TextStyle(color: cCyan, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _buildTextField(_nostrController, "Nostr (npub...)", Icons.key),
          const SizedBox(height: 10),
          _buildTextField(_telegramController, "Telegram Handle", Icons.send),
          const SizedBox(height: 10),
          _buildTextField(_twitterController, "Twitter / X Handle", Icons.alternate_email),

          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _saveProfile,
              child: const Text("SPEICHERN & ZUM EINLASS"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool required = false}) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: true, fillColor: cCard,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: required ? (v) => v!.isEmpty ? "Pflichtfeld" : null : null,
    );
  }
}