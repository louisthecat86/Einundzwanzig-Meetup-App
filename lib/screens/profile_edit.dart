import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user.dart';
import '../models/meetup.dart';
import '../services/meetup_service.dart';
import '../services/nostr_service.dart';
import '../theme.dart';
import 'dashboard.dart';
import 'profile_review.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _telegramController = TextEditingController();
  final TextEditingController _twitterController = TextEditingController();

  String _selectedHomeMeetup = "";
  List<Meetup> _allMeetups = [];

  UserProfile? _user;
  bool _isLoading = true;
  bool _isEditing = false;

  // Nostr Key State
  bool _hasNostrKey = false;
  String _nostrNpub = "";
  bool _isGeneratingKey = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = await UserProfile.load();
    final meetups = await MeetupService.fetchMeetups();
    meetups.sort((a, b) => a.city.compareTo(b.city));

    // Nostr Key Status prüfen
    final hasKey = await NostrService.hasKey();
    final npub = await NostrService.getNpub();

    if (mounted) {
      setState(() {
        _user = user;
        _allMeetups = meetups;

        _nicknameController.text = user.nickname;
        _fullNameController.text = user.fullName;
        _telegramController.text = user.telegramHandle;
        _twitterController.text = user.twitterHandle;
        _selectedHomeMeetup = user.homeMeetupId;

        _hasNostrKey = hasKey;
        _nostrNpub = npub ?? user.nostrNpub;

        _isEditing = !user.isAdminVerified;
        _isLoading = false;
      });
    }
  }

  // --- NOSTR KEY GENERIEREN ---
  void _generateNostrKey() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cCard,
        title: const Text("NOSTR KEY ERSTELLEN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          "Es wird ein neues Schlüsselpaar erstellt. Dein privater Schlüssel (nsec) wird sicher auf deinem Gerät gespeichert.\n\n"
          "⚠️ WICHTIG: Sichere deinen nsec! Wenn du dein Gerät verlierst, ist dein Key weg.",
          style: TextStyle(color: Colors.white70, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("ABBRECHEN", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: cOrange),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("ERSTELLEN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isGeneratingKey = true);

    try {
      final keys = await NostrService.generateKeyPair();

      setState(() {
        _hasNostrKey = true;
        _nostrNpub = keys['npub']!;
        _isGeneratingKey = false;
      });

      if (mounted) {
        // nsec anzeigen zum Sichern
        _showNsecBackupDialog(keys['nsec']!);
      }
    } catch (e) {
      setState(() => _isGeneratingKey = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Fehler: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- NSEC IMPORTIEREN ---
  void _importNsec() {
    final nsecController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cCard,
        title: const Text("NSEC IMPORTIEREN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Gib deinen privaten Nostr-Schlüssel ein (beginnt mit nsec1...):",
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nsecController,
              obscureText: true,
              style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 13),
              maxLines: 1,
              decoration: InputDecoration(
                hintText: "nsec1...",
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: cDark,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: cOrange),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "⚠️ Dein nsec verlässt niemals dein Gerät.",
              style: TextStyle(color: Colors.orange, fontSize: 11),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ABBRECHEN", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: cOrange),
            onPressed: () async {
              final nsec = nsecController.text.trim();
              if (nsec.isEmpty) return;

              try {
                final keys = await NostrService.importNsec(nsec);
                if (mounted) {
                  Navigator.pop(context);
                  setState(() {
                    _hasNostrKey = true;
                    _nostrNpub = keys['npub']!;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("✅ Key importiert!"),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("❌ $e"), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text("IMPORTIEREN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // --- NSEC BACKUP DIALOG ---
  void _showNsecBackupDialog(String nsec) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: cCard,
        title: Row(
          children: const [
            Icon(Icons.warning_amber, color: Colors.orange, size: 24),
            SizedBox(width: 8),
            Text("SICHERE DEINEN KEY!", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Dies ist dein privater Schlüssel. Speichere ihn an einem sicheren Ort! "
              "Wer diesen Key hat, HAT deine Identität.",
              style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cDark,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.5)),
              ),
              child: SelectableText(
                nsec,
                style: const TextStyle(
                  color: Colors.orange,
                  fontFamily: 'monospace',
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "⚠️ Dieser Key wird NICHT nochmal angezeigt!",
              style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: cOrange),
            icon: const Icon(Icons.copy, color: Colors.white, size: 18),
            label: const Text("KOPIEREN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: nsec));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("nsec kopiert! Jetzt sicher abspeichern."), backgroundColor: cOrange),
              );
            },
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ICH HAB IHN GESICHERT", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // --- NSEC ANZEIGEN (für bestehende Keys) ---
  void _showExistingNsec() async {
    final keys = await NostrService.loadKeys();
    if (keys == null || !mounted) return;

    // Sicherheitsabfrage
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cCard,
        title: const Text("NSEC ANZEIGEN?", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: const Text(
          "Dein privater Schlüssel wird angezeigt. Stelle sicher, dass niemand auf deinen Bildschirm schaut!",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("ABBRECHEN", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("ANZEIGEN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      _showNsecBackupDialog(keys['nsec']!);
    }
  }

  // --- MEETUP PICKER ---
  void _showMeetupPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: cCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return MeetupSearchSheet(
          meetups: _allMeetups,
          onSelect: (cityName) {
            setState(() {
              _selectedHomeMeetup = cityName;
            });
          },
        );
      },
    );
  }

  // --- SPEICHERN ---
  Future<void> _saveAndVerify() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final newUser = UserProfile(
        nickname: _nicknameController.text.trim(),
        fullName: _fullNameController.text.trim(),
        homeMeetupId: _selectedHomeMeetup,
        nostrNpub: _nostrNpub, // Kommt jetzt vom Key (oder leer)
        telegramHandle: _telegramController.text.trim(),
        twitterHandle: _twitterController.text.trim(),
        isAdminVerified: false,
        isAdmin: _user?.isAdmin ?? false,
        isNostrVerified: _hasNostrKey,
        hasNostrKey: _hasNostrKey,
      );

      await newUser.save();

      setState(() {
        _user = newUser;
        _isLoading = false;
      });

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileReviewScreen(
            user: newUser,
            onConfirm: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const DashboardScreen()),
                (route) => false,
              );
            },
          ),
        ),
      );
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

  // =============================================
  // READ-ONLY ANSICHT (verifiziertes Profil)
  // =============================================
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
        if (_hasNostrKey)
          _buildInfoTile("Nostr", NostrService.shortenNpub(_nostrNpub), Icons.key),
        if (!_hasNostrKey && _user!.nostrNpub.isNotEmpty)
          _buildInfoTile("Nostr (manuell)", _user!.nostrNpub.length > 16 ? "${_user!.nostrNpub.substring(0, 16)}..." : _user!.nostrNpub, Icons.key),
        if (_user!.telegramHandle.isNotEmpty)
          _buildInfoTile("Telegram", _user!.telegramHandle, Icons.send),
        if (_user!.twitterHandle.isNotEmpty)
          _buildInfoTile("Twitter", _user!.twitterHandle, Icons.alternate_email),
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
      child: Row(children: [
        Icon(icon, color: cOrange, size: 20),
        const SizedBox(width: 16),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 16)),
        ]),
      ]),
    );
  }

  // =============================================
  // EDIT-FORMULAR
  // =============================================
  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- BASIS DATEN ---
          const Text("BASIS DATEN", style: TextStyle(color: cOrange, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _buildTextField(_nicknameController, "Nickname", Icons.person, required: true),
          const SizedBox(height: 10),
          _buildTextField(_fullNameController, "Name (Optional)", Icons.badge),
          const SizedBox(height: 10),

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

          // =============================================
          // NOSTR IDENTITÄT (ersetzt das alte npub-Textfeld)
          // =============================================
          const Text("NOSTR IDENTITÄT", style: TextStyle(color: cPurple, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text(
            "Dein kryptografischer Schlüssel – damit werden Badges signiert.",
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 12),

          if (_hasNostrKey) ...[
            // KEY VORHANDEN → Anzeigen
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.check_circle, color: Colors.green, size: 18),
                      SizedBox(width: 8),
                      Text("SCHLÜSSEL AKTIV", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // npub anzeigen
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: cDark,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _nostrNpub,
                      style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _nostrNpub));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("npub kopiert!"), backgroundColor: cOrange, duration: Duration(seconds: 1)),
                            );
                          },
                          icon: const Icon(Icons.copy, size: 16),
                          label: const Text("NPUB", style: TextStyle(fontSize: 11)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: cCyan,
                            side: const BorderSide(color: cCyan),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _showExistingNsec,
                          icon: const Icon(Icons.key, size: 16),
                          label: const Text("NSEC", style: TextStyle(fontSize: 11)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange,
                            side: const BorderSide(color: Colors.orange),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            // KEIN KEY → Generieren oder Importieren
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cBorder),
              ),
              child: Column(
                children: [
                  const Icon(Icons.key_off, color: Colors.grey, size: 32),
                  const SizedBox(height: 8),
                  const Text(
                    "Noch kein Nostr-Key vorhanden",
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 16),

                  // GENERIEREN
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isGeneratingKey ? null : _generateNostrKey,
                      icon: _isGeneratingKey
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.add_circle_outline, color: Colors.white),
                      label: Text(
                        _isGeneratingKey ? "WIRD ERSTELLT..." : "NEUEN KEY ERSTELLEN",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cPurple,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // IMPORTIEREN
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _importNsec,
                      icon: const Icon(Icons.download, size: 18),
                      label: const Text("BESTEHENDEN NSEC IMPORTIEREN"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: cOrange,
                        side: const BorderSide(color: cOrange),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  const Text(
                    "Du brauchst kein Nostr-Konto. Die App erstellt dir einen Schlüssel – das dauert eine Sekunde.",
                    style: TextStyle(color: Colors.grey, fontSize: 11, height: 1.4),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 30),

          // --- SOCIALS ---
          const Text("SOCIALS (Optional)", style: TextStyle(color: cCyan, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _buildTextField(_telegramController, "Telegram Handle", Icons.send),
          const SizedBox(height: 10),
          _buildTextField(_twitterController, "Twitter / X Handle", Icons.alternate_email),

          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _saveAndVerify,
              child: const Text("SPEICHERN & ZUR PRÜFUNG"),
            ),
          ),
          const SizedBox(height: 300),
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
        filled: true,
        fillColor: cCard,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: required ? (v) => v!.isEmpty ? "Pflichtfeld" : null : null,
    );
  }
}

// --- MEETUP SUCHE (unverändert) ---
class MeetupSearchSheet extends StatefulWidget {
  final List<Meetup> meetups;
  final Function(String) onSelect;

  const MeetupSearchSheet({super.key, required this.meetups, required this.onSelect});

  @override
  State<MeetupSearchSheet> createState() => _MeetupSearchSheetState();
}

class _MeetupSearchSheetState extends State<MeetupSearchSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<Meetup> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.meetups;
  }

  void _filter(String query) {
    if (mounted) {
      setState(() {
        _filtered = widget.meetups.where((m) => m.city.toLowerCase().contains(query.toLowerCase())).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: "Stadt suchen...",
                  prefixIcon: Icon(Icons.search, color: cOrange),
                  filled: true,
                  fillColor: cDark,
                ),
                onChanged: _filter,
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: _filtered.length,
                itemBuilder: (context, index) {
                  final meetup = _filtered[index];
                  return ListTile(
                    leading: const Icon(Icons.location_city, color: cOrange),
                    title: Text(meetup.city, style: const TextStyle(color: Colors.white)),
                    subtitle: Text(meetup.country, style: TextStyle(color: Colors.grey.shade400)),
                    onTap: () {
                      widget.onSelect(meetup.city);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}