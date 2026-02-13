import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/admin_registry.dart';
import '../services/trust_score_service.dart';
import '../services/nostr_service.dart';
import 'badge_wallet.dart';
import 'profile_edit.dart';
import 'meetup_verification.dart';
import 'admin_panel.dart';
import 'reputation_qr.dart';
import 'verification_gate.dart'; // Importiert jetzt OrganisatorLoginScreen

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  UserProfile? _user;
  bool _isAdmin = false;
  TrustScore? _trustScore;
  String _bootstrapPhase = "Initial";

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = await UserProfile.load();
    final isAdminReg = await AdminRegistry().isAdmin(user?.nostrNpub);
    
    // Trust Score berechnen (mit Co-Attestor Daten)
    TrustScore? score;
    if (user != null) {
      // Co-Attestor Daten laden
      final nostr = NostrService();
      Map<String, CoAttestorData> coData = {};
      
      for (var b in user.badges) {
        if (b.meetupEventId != null) {
          final info = await nostr.fetchCoAttestors(b.meetupEventId!);
          coData[b.signature] = CoAttestorData(
            meetupEventId: info.meetupEventId,
            attendeeCount: info.attendeeCount,
            attendeeNpubs: info.attendeeNpubs,
            veteranCount: 0 // Vereinfachung für jetzt
          );
        }
      }
      
      score = await TrustScoreService().calculateScore(user, coData);
    }

    setState(() {
      _user = user;
      _isAdmin = isAdminReg || (score?.meetsPromotionThreshold ?? false) || (user?.isAdmin ?? false);
      _trustScore = score;
      _bootstrapPhase = score?.phaseLabel ?? "Initial";
    });
  }

  void _scanAnyMeetup() {
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => MeetupVerificationScreen(
        meetup: null, // Dummy, wird im Screen behandelt
        initialChefMode: false,
      ),
    )).then((_) => _loadData());
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.orange)));

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("EINUNDZWANZIG", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white70),
            onPressed: () => _showSettings(context),
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: Colors.orange,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildGreeting(),
            const SizedBox(height: 24),
            _buildTile(
              "STEMPEL SAMMELN", "NFC oder QR scannen", Icons.nfc, 
              Colors.orange, () => _scanAnyMeetup()
            ),
            const SizedBox(height: 16),
            _buildTile(
              "MEIN WALLET", "${_user!.badges.length} Stempel", Icons.collections_bookmark, 
              Colors.blueGrey, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BadgeWalletScreen()))
            ),
            const SizedBox(height: 16),
            _buildTile(
              "REPUTATION ZEIGEN", "Dein QR-Code", Icons.qr_code, 
              Colors.white, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ReputationQRScreen()))
            ),
            const SizedBox(height: 16),
            
            // Trust Score oder Admin
            if (_isAdmin)
              _buildTile(
                "ORGANISATOR", "Meetups verwalten", Icons.vpn_key, 
                Colors.purpleAccent, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminPanelScreen()))
              )
            else if (_user!.badges.length >= 2)
              _buildTrustTile(),
          ],
        ),
      ),
    );
  }

  Widget _buildGreeting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Hallo ${_user!.nickname},", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        Text("Reputations-Status: $_bootstrapPhase", style: const TextStyle(color: Colors.white54, fontSize: 14)),
      ],
    );
  }

  Widget _buildTile(String title, String sub, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: color.withOpacity(0.2), radius: 24, child: Icon(icon, color: color)),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                Text(sub, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTrustTile() {
    final progress = (_trustScore?.score ?? 0) / (_trustScore?.activeThreshold ?? 15.0);
    return InkWell(
      onTap: () => _showTrustInfo(),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.trending_up, color: Colors.green),
                const SizedBox(width: 12),
                const Text("TRUST SCORE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text("${_trustScore?.score.toStringAsFixed(1)} / ${_trustScore?.activeThreshold}", style: const TextStyle(color: Colors.white)),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: progress.clamp(0.0, 1.0), backgroundColor: Colors.white12, color: Colors.green),
            const SizedBox(height: 8),
            const Text("Sammle weiter Stempel um Organisator zu werden.", style: TextStyle(color: Colors.white38, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  void _showTrustInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text("Dein Trust Score", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Das Netzwerk bewertet deine Aktivität lokal:", style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            _scoreRow("Anzahl Stempel", "${_user!.badges.length}"),
            _scoreRow("Verschiedene Meetups", "${_trustScore?.uniqueMeetups ?? 0}"),
            _scoreRow("Verschiedene Signer", "${_trustScore?.uniqueSigners ?? 0}"),
            const Divider(color: Colors.white24),
            _scoreRow("Aktueller Score", _trustScore?.score.toStringAsFixed(1) ?? "0"),
            _scoreRow("Benötigt", "${_trustScore?.activeThreshold ?? 15}"),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
      ),
    );
  }

  Widget _scoreRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(color: Colors.white54)),
        Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.person, color: Colors.white),
            title: const Text("Profil bearbeiten", style: TextStyle(color: Colors.white)),
            onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileEditScreen())); }
          ),
          ListTile(
            leading: const Icon(Icons.admin_panel_settings, color: Colors.white54),
            title: const Text("Ich bin bereits Organisator", style: TextStyle(color: Colors.white54)),
            subtitle: const Text("Login mit Passwort", style: TextStyle(color: Colors.white24, fontSize: 10)),
            onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => const OrganisatorLoginScreen())); }
          ),
          const SizedBox(height: 24),
        ],
      )
    );
  }
}