import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nostr/nostr.dart';
import '../theme.dart';
import '../models/user.dart';
import '../models/meetup.dart';
import '../models/badge.dart';
import '../services/meetup_service.dart';
import '../services/trust_score_service.dart';
import '../services/admin_registry.dart';
import '../services/nostr_service.dart';
import '../services/badge_claim_service.dart';               // NEU: Badge-Binding
import '../services/reputation_publisher.dart';              // NEU: Auto-Publish
import '../services/rolling_qr_service.dart';               // NEU: Session-Check
import 'meetup_verification.dart';
import 'meetup_selection.dart'; 
import 'badge_details.dart'; 
import 'badge_wallet.dart';
import 'profile_edit.dart'; 
import 'intro.dart'; 
import 'admin_panel.dart'; 
import 'rolling_qr_screen.dart';                            // NEU: Aktives Meetup

import 'meetup_details.dart'; 
import 'reputation_qr.dart'; 
import 'relay_settings_screen.dart';
import 'calendar_screen.dart';
import '../services/backup_service.dart';
import '../services/promotion_claim_service.dart';
import '../services/platform_proof_service.dart';
import '../services/humanity_proof_service.dart';
import '../services/nip05_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  UserProfile _user = UserProfile();
  Meetup? _homeMeetup; 
  TrustScore? _trustScore;
  bool _justPromoted = false;

  // Identity Layer State
  int _platformProofCount = 0;
  bool _humanityVerified = false;
  bool _nip05Verified = false;
  List<String> _platformNames = [];
  
  // Aktive Meetup-Session
  MeetupSession? _activeSession;
  Timer? _sessionTimer;
  String _sessionTimeLeft = '';
  
  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    super.dispose();
  }

  void _loadAll() async {
    await _loadUser();
    await _loadBadges();
    await _calculateTrustScore();
    _loadIdentityData();
    _checkActiveSession();
    // Organic Admins von Nostr laden und verifizieren
    _syncOrganicAdminsInBackground();
  }

  void _loadIdentityData() async {
    try {
      final proofs = await PlatformProofService.getSavedProofs();
      final humanity = await HumanityProofService.getStatus();

      // NIP-05 prüfen (nur wenn Nostr-Key vorhanden)
      bool nip05 = false;
      if (_user.hasNostrKey && _user.nostrNpub.isNotEmpty) {
        try {
          final relays = ['wss://relay.damus.io', 'wss://nos.lol'];
          final pubkeyHex = Nip19.decodePubkey(_user.nostrNpub);
          final nip05Str = await Nip05Service.fetchNip05FromProfile(pubkeyHex, relays)
              .timeout(const Duration(seconds: 8), onTimeout: () => null);
          if (nip05Str != null && nip05Str.isNotEmpty) {
            final result = await Nip05Service.verify(nip05Str, pubkeyHex);
            nip05 = result.valid;
          }
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _platformProofCount = proofs.length;
          _platformNames = proofs.map((p) => p.platform).toList();
          _humanityVerified = humanity.verified;
          _nip05Verified = nip05;
        });
      }
    } catch (_) {}
  }

  // =============================================
  // AKTIVE MEETUP-SESSION PRÜFEN
  // =============================================
  void _checkActiveSession() async {
    final session = await RollingQRService.loadSession();
    if (session != null && !session.isExpired) {
      setState(() => _activeSession = session);
      _startSessionTimer();
    } else {
      _sessionTimer?.cancel();
      if (mounted) setState(() => _activeSession = null);
    }
  }

  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_activeSession == null || _activeSession!.isExpired) {
        _sessionTimer?.cancel();
        if (mounted) setState(() => _activeSession = null);
        return;
      }
      if (mounted) {
        setState(() {
          final r = _activeSession!.remainingTime;
          _sessionTimeLeft = '${r.inHours}h ${(r.inMinutes % 60).toString().padLeft(2, '0')}m';
        });
      }
    });
  }

  /// Lädt Admin Claims von Nostr Relays und verifiziert sie.
  /// Gültige Claims werden in die lokale Admin-Registry aufgenommen.
  void _syncOrganicAdminsInBackground() async {
    try {
      final verified = await PromotionClaimService.syncOrganicAdmins();
      if (verified.isNotEmpty) {
        print('[Dashboard] ${verified.length} organische Admins verifiziert');
      }
    } catch (e) {
      // Stilles Scheitern — kein Netzwerk ist OK
    }
  }

  Future<void> _loadBadges() async {
    final badges = await MeetupBadge.loadBadges();

    // =============================================
    // NEU: Retroaktives Claiming (Badge-Binding)
    // Bindet alte Badges (vor dem Update) an den Nutzer.
    // Läuft einmalig beim ersten App-Start nach Update.
    // Retroaktive Claims werden markiert (reduzierter Wert).
    // =============================================
    final claimedCount = await BadgeClaimService.ensureBadgesClaimed(badges);
    if (claimedCount > 0) {
      print('[Dashboard] $claimedCount Badges retroaktiv gebunden');
    }

    setState(() {
      myBadges.clear();
      myBadges.addAll(badges);
    });

    // NEU: Reputation im Hintergrund auf Relays aktualisieren
    // Publiziert nur wenn sich etwas geändert hat (Change-Detection)
    if (badges.isNotEmpty) {
      ReputationPublisher.publishInBackground(badges);
    }
  }

  Future<void> _loadUser() async {
    final u = await UserProfile.load();
    
    Meetup? homeMeetup;
    if (u.homeMeetupId.isNotEmpty) {
      List<Meetup> meetups = await MeetupService.fetchMeetups();
      if (meetups.isEmpty) meetups = allMeetups;
      homeMeetup = meetups.where((m) => m.city == u.homeMeetupId).firstOrNull;
    }
    
    // --- SEED ADMIN CHECK (nur beim ersten Laden) ---
    // Prüfe ob User ein Seed-Admin ist (z.B. der Gründer)
    if (!u.isAdmin && u.hasNostrKey && u.nostrNpub.isNotEmpty) {
      try {
        final result = await AdminRegistry.checkAdmin(u.nostrNpub);
        if (result.isAdmin) {
          u.isAdmin = true;
          u.isAdminVerified = true;
          u.promotionSource = 'seed_admin';
          await u.save();
          print('[Dashboard] Seed-Admin erkannt: ${result.source}');
        }
      } catch (e) {
        print('[Dashboard] Admin-Check fehlgeschlagen: $e');
      }
    }
    
    if (mounted) {
      setState(() {
        _user = u;
        _homeMeetup = homeMeetup;
      });
    }
  }

  // =============================================
  // TRUST SCORE BERECHNEN + AUTO-PROMOTION
  // =============================================
  Future<void> _calculateTrustScore() async {
    if (myBadges.isEmpty) {
      setState(() {
        _trustScore = TrustScoreService.calculateScore(
          badges: [],
          firstBadgeDate: null,
        );
      });
      return;
    }

    // Ältestes Badge = Account-Alter
    final sortedByDate = List<MeetupBadge>.from(myBadges)
      ..sort((a, b) => a.date.compareTo(b.date));
    final firstBadgeDate = sortedByDate.first.date;

    // TODO: Co-Attestor-Daten von Nostr Relays laden
    // Für jetzt: null (lokale Berechnung ohne Relay-Daten)
    final score = TrustScoreService.calculateScore(
      badges: myBadges,
      firstBadgeDate: firstBadgeDate,
      coAttestorMap: null,
    );

    setState(() => _trustScore = score);

    // =============================================
    // AUTO-PROMOTION: Trust Score → Organisator
    // =============================================
    if (score.meetsPromotionThreshold && !_user.isAdmin) {
      _user.isAdmin = true;
      _user.isAdminVerified = true;
      _user.promotionSource = 'trust_score';
      await _user.save();

      // "Proof of Reputation" auf Nostr publizieren
      // → Andere Apps können diesen Claim verifizieren
      // → Kein Super-Admin nötig für organisches Wachstum
      try {
        final meetupName = _user.homeMeetupId.isNotEmpty
            ? _user.homeMeetupId
            : 'Unbekannt';
        await PromotionClaimService.publishAdminClaim(
          badges: myBadges,
          meetupName: meetupName,
        );
        print('[Dashboard] Admin Claim auf Nostr publiziert ✓');
      } catch (e) {
        print('[Dashboard] Admin Claim konnte nicht publiziert werden: $e');
        // Kein Problem — wird beim nächsten App-Start erneut versucht
      }
      
      if (mounted) {
        setState(() {
          _justPromoted = true;
        });
        
        // Celebration!
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Du bist jetzt ORGANISATOR! Du kannst Meetup-Tags erstellen."),
            backgroundColor: Colors.green.shade700,
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _resetApp() async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cCard,
        title: const Text("App zurücksetzen?", style: TextStyle(color: Colors.white)),
        content: const Text("Alle Badges und dein Profil werden gelöscht. Stelle sicher, dass du ein Backup hast!"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Abbruch")),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text("LÖSCHEN", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
          ),
        ],
      )
    ) ?? false;

    if (!confirm) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); 
    myBadges.clear();    
    await MeetupBadge.saveBadges([]); 
    
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const IntroScreen()), 
        (route) => false
      );
    }
  }

  // =============================================
  // ICON-HELPER
  // =============================================
  static IconData _levelIcon(String level) {
    switch (level) {
      case 'VETERAN': return Icons.bolt;
      case 'ETABLIERT': return Icons.shield;
      case 'AKTIV': return Icons.local_fire_department;
      case 'STARTER': return Icons.eco;
      default: return Icons.fiber_new;
    }
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context, 
      backgroundColor: cCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min, 
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4, 
                decoration: BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            const Text("DATENSICHERUNG", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
            const SizedBox(height: 10),
            
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.blue.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.upload, color: Colors.blue),
              ),
              title: const Text("Backup erstellen", style: TextStyle(color: Colors.white)),
              subtitle: const Text("Sichere deinen Account extern als Datei.", style: TextStyle(color: Colors.grey, fontSize: 12)),
              onTap: () async {
                Navigator.pop(context); 
                await BackupService.createBackup(context);
              },
            ),

            const SizedBox(height: 20),
            const Divider(color: Colors.white10),
            const SizedBox(height: 10),
            
            const Text("NOSTR-NETZWERK", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
            const SizedBox(height: 10),

            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: cCyan.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.hub, color: cCyan),
              ),
              title: const Text("Nostr-Relays", style: TextStyle(color: Colors.white)),
              subtitle: const Text("Relays für Reputation konfigurieren.", style: TextStyle(color: Colors.grey, fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const RelaySettingsScreen()));
              },
            ),

            const SizedBox(height: 20),
            const Divider(color: Colors.white10),
            const SizedBox(height: 10),
            
            const Text("ACCOUNT", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
            const SizedBox(height: 10),

            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.delete_forever, color: Colors.red),
              ),
              title: const Text("App zurücksetzen", style: TextStyle(color: Colors.white)),
              subtitle: const Text("Löscht Profil und Badges vom Gerät.", style: TextStyle(color: Colors.grey, fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                _resetApp();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _scanAnyMeetup() async {
    final dummy = Meetup(id: "global", city: "GLOBAL", country: "", telegramLink: "", lat: 0, lng: 0);
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MeetupVerificationScreen(meetup: dummy)),
    );
    _loadBadges();
    _calculateTrustScore(); // Trust Score nach neuem Badge aktualisieren
  }

  void _selectHomeMeetup() async {
    await Navigator.push(context, MaterialPageRoute(builder: (context) => const MeetupSelectionScreen()));
    _loadUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(
        title: const Text("DASHBOARD"),
        automaticallyImplyLeading: false, 
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettings,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== GREETING =====
            Text(
              "Hallo, ${_user.nickname}!",
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: cText,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _getGreetingSubtitle(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: cTextSecondary,
              ),
            ),
            const SizedBox(height: 28),

            // ===== NÄCHSTE SCHRITTE (nur wenn etwas offen) =====
            if (_hasOpenSteps()) ...[
              _buildNextSteps(),
              const SizedBox(height: 20),
            ],

            // ===== TRUST SCORE =====
            if (_trustScore != null) ...[
              _buildTrustScoreCard(),
              const SizedBox(height: 20),
            ],

            // ===== AKTIVES MEETUP =====
            if (_activeSession != null) ...[
              _buildActiveSessionCard(),
              const SizedBox(height: 20),
            ],

            // ===== HAUPTAKTIONEN =====
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.05,
              children: [
                _buildTile(
                  icon: Icons.military_tech,
                  color: cOrange,
                  title: "BADGES",
                  subtitle: myBadges.isEmpty 
                      ? "Meetup besuchen"
                      : "${myBadges.length} gesammelt",
                  onTap: _scanAnyMeetup, 
                ),
                _buildTile(
                  icon: Icons.collections_bookmark, 
                  color: cPurple, 
                  title: "WALLET", 
                  subtitle: myBadges.isEmpty
                      ? "Deine Sammlung"
                      : "${myBadges.length} Badges", 
                  onTap: () async {
                    await Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (context) => BadgeWalletScreen()),
                    );
                    _loadBadges();
                    _calculateTrustScore();
                  }
                ),
                _buildTile(
                  icon: Icons.workspace_premium,
                  color: Colors.amber,
                  title: "REPUTATION",
                  subtitle: myBadges.isNotEmpty ? "QR teilen" : "Prüfen",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ReputationQRScreen()),
                    );
                  },
                ),
                _buildTile(
                  icon: Icons.person,
                  color: Colors.blueGrey,
                  title: "PROFIL",
                  subtitle: _identitySubtitle(),
                  onTap: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileEditScreen()));
                    _loadAll();
                  }
                ),
                _buildTile(
                  icon: Icons.event,
                  color: cCyan,
                  title: "TERMINE",
                  subtitle: "Events & Kalender",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CalendarScreen()),
                    );
                  },
                ),
                // ORGANISATOR
                if (_user.isAdmin) 
                  _buildTile(
                    icon: Icons.admin_panel_settings,
                    color: _justPromoted ? Colors.green : Colors.redAccent,
                    title: "ORGANISATOR",
                    subtitle: _justPromoted 
                        ? "Freigeschaltet!" 
                        : "Tags erstellen",
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AdminPanelScreen()),
                      );
                      _checkActiveSession();
                    }
                  ),
              ],
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // =============================================
  // DYNAMISCHER GREETING-SUBTITLE
  // =============================================
  String _getGreetingSubtitle() {
    if (myBadges.isEmpty) return "Willkommen! Besuche ein Meetup um loszulegen.";
    if (_trustScore != null && _trustScore!.meetsPromotionThreshold) return "Du bist Organisator. Danke für deinen Einsatz!";
    if (myBadges.length == 1) return "Dein erstes Badge! Weiter so.";
    return "${myBadges.length} Badges gesammelt. Deine Reputation wächst.";
  }

  // =============================================
  // PROFIL-TILE SUBTITLE
  // =============================================
  String _identitySubtitle() {
    final count = _platformProofCount + (_humanityVerified ? 1 : 0) + (_nip05Verified ? 1 : 0);
    if (count == 0) return "Identität aufbauen";
    return "$count Verknüpfung${count > 1 ? 'en' : ''}";
  }

  // =============================================
  // NÄCHSTE SCHRITTE
  // =============================================
  bool _hasOpenSteps() {
    if (myBadges.isEmpty) return true;
    if (!_humanityVerified) return true;
    if (_platformProofCount == 0) return true;
    if (!_nip05Verified) return true;
    return false;
  }

  Widget _buildNextSteps() {
    // Sammle offene Schritte
    final steps = <Widget>[];

    if (myBadges.isEmpty) {
      steps.add(_buildStepRow(
        icon: Icons.military_tech,
        color: cOrange,
        text: "Besuche ein Meetup und scanne deinen ersten Badge",
        onTap: _scanAnyMeetup,
      ));
    }

    if (_platformProofCount == 0) {
      steps.add(_buildStepRow(
        icon: Icons.link,
        color: Colors.green,
        text: "Verknüpfe Telegram, X oder andere Plattformen",
        onTap: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileEditScreen()));
          _loadAll();
        },
      ));
    }

    if (!_humanityVerified) {
      steps.add(_buildStepRow(
        icon: Icons.bolt,
        color: Colors.amber,
        text: "Beweise per Lightning-Zap, dass du ein Mensch bist",
        onTap: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileEditScreen()));
          _loadAll();
        },
      ));
    }

    if (!_nip05Verified && _user.hasNostrKey) {
      steps.add(_buildStepRow(
        icon: Icons.alternate_email,
        color: cCyan,
        text: "Richte eine NIP-05 Adresse in deinem Nostr-Profil ein",
        onTap: () => _showInfoDialog(
          "Was ist NIP-05?",
          "Eine NIP-05 Adresse ist wie eine E-Mail-Adresse für Nostr — "
          "z.B. max@einundzwanzig.space.\n\n"
          "Sie beweist, dass die Domain deine Identität bestätigt. "
          "Du kannst sie in Nostr-Clients wie Damus, Amethyst oder Primal einrichten.\n\n"
          "Je vertrauenswürdiger die Domain, desto stärker der Beweis.",
        ),
      ));
    }

    if (steps.isEmpty) return const SizedBox.shrink();

    // Maximal 3 Schritte anzeigen
    final visibleSteps = steps.take(3).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cOrange.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text("NÄCHSTE SCHRITTE",
                style: TextStyle(color: cOrange.withOpacity(0.8), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
              const Spacer(),
              GestureDetector(
                onTap: () => _showInfoDialog(
                  "Wie funktioniert Trust?",
                  "Dein Trust Score setzt sich aus zwei Bereichen zusammen:\n\n"
                  "1. Meetup-Aktivität\n"
                  "Besuche Meetups und sammle Badges von verschiedenen Organisatoren "
                  "in verschiedenen Städten. Je diverser, desto stärker dein Score.\n\n"
                  "2. Identitäts-Verknüpfungen\n"
                  "Verknüpfe Plattformen (Telegram, X, Kleinanzeigen), beweise per "
                  "Lightning-Zap dass du ein Mensch bist, und richte eine NIP-05 Adresse ein.\n\n"
                  "Ab einem bestimmten Score wirst du automatisch zum Organisator — "
                  "dann kannst du selbst NFC-Tags und QR-Codes für Meetups erstellen.",
                ),
                child: Icon(Icons.info_outline, color: Colors.grey.shade600, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...visibleSteps,
        ],
      ),
    );
  }

  Widget _buildStepRow({
    required IconData icon,
    required Color color,
    required String text,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(icon, color: color, size: 15),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text,
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12, height: 1.3)),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade700, size: 18),
          ],
        ),
      ),
    );
  }

  // =============================================
  // INFO-DIALOG (Tap auf ℹ️ Icons)
  // =============================================
  void _showInfoDialog(String title, String text) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
        content: Text(text, style: TextStyle(color: Colors.grey.shade400, fontSize: 13, height: 1.6)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("VERSTANDEN", style: TextStyle(color: cOrange, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // =============================================
  // TRUST SCORE CARD (einzige Version)
  // =============================================
  Widget _buildTrustScoreCard() {
    final score = _trustScore!;
    
    Color levelColor;
    switch (score.level) {
      case 'VETERAN': levelColor = Colors.amber; break;
      case 'ETABLIERT': levelColor = Colors.green; break;
      case 'AKTIV': levelColor = cCyan; break;
      case 'STARTER': levelColor = cOrange; break;
      default: levelColor = Colors.grey;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: levelColor.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== HEADER =====
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: levelColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(_levelIcon(score.level), color: levelColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(score.level,
                      style: TextStyle(color: levelColor, fontSize: 17, fontWeight: FontWeight.w800)),
                    Text(
                      score.meetsPromotionThreshold
                          ? "Organisator-Status erreicht"
                          : "Nächstes Ziel: Organisator",
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Text(
                score.totalScore.toStringAsFixed(1),
                style: TextStyle(color: levelColor, fontSize: 26, fontWeight: FontWeight.w900, fontFamily: 'monospace'),
              ),
            ],
          ),

          // ===== PROGRESS =====
          if (!score.meetsPromotionThreshold) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: score.promotionProgress,
                backgroundColor: Colors.white.withOpacity(0.06),
                valueColor: AlwaysStoppedAnimation(levelColor.withOpacity(0.7)),
                minHeight: 4,
              ),
            ),
          ],

          // ===== MEETUP-AKTIVITÄT =====
          const SizedBox(height: 16),
          _buildSectionHeader(
            "MEETUP-AKTIVITÄT",
            onInfo: () => _showInfoDialog(
              "Meetup-Aktivität",
              "Dein Score steigt mit jedem Meetup-Badge. Dabei zählt:\n\n"
              "• Badges — Je mehr, desto besser\n"
              "• Verschiedene Meetups — Nicht immer dasselbe\n"
              "• Verschiedene Organisatoren — Zeigt Vernetzung\n"
              "• Account-Alter — Geduld zahlt sich aus\n\n"
              "Ab einem bestimmten Score wirst du automatisch zum Organisator.",
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: score.progress.entries.map<Widget>((entry) {
              final p = entry.value;
              return _buildCriterion(p.label, p.current, p.required, p.met);
            }).toList(),
          ),

          if (score.meetsPromotionThreshold) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.verified, color: Colors.green, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text("Du kannst NFC-Tags und Rolling-QR-Codes erstellen.",
                    style: TextStyle(color: Colors.green.shade400, fontSize: 11)),
                ),
              ],
            ),
          ],

          // ===== IDENTITÄT =====
          const SizedBox(height: 16),
          _buildSectionHeader(
            "IDENTITÄT",
            onInfo: () => _showInfoDialog(
              "Identitäts-Verknüpfungen",
              "Jede Verknüpfung stärkt deine Glaubwürdigkeit:\n\n"
              "Lightning — Beweise per Zap, dass du ein echtes Lightning-Wallet hast. Bots können das nicht.\n\n"
              "NIP-05 — Eine verifizierte Nostr-Adresse (wie max@example.com). Beweist, dass eine Domain für dich bürgt.\n\n"
              "Plattformen — Verknüpfe Telegram, X, Kleinanzeigen etc. mit deinem kryptographischen Schlüssel.\n\n"
              "Alles zusammen macht es praktisch unmöglich, deine Identität zu fälschen.",
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _buildIdDot(Icons.bolt, "Lightning", _humanityVerified, Colors.amber),
              _buildIdDot(Icons.alternate_email, "NIP-05", _nip05Verified, cCyan),
              ..._buildPlatformDots(),
              if (_platformProofCount == 0)
                _buildIdDot(Icons.link, "Plattform", false, Colors.grey),
            ],
          ),

          // Profil-Link wenn etwas offen
          if (!_humanityVerified || !_nip05Verified || _platformProofCount == 0) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () async {
                await Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const ProfileEditScreen()));
                _loadAll();
              },
              child: Row(
                children: [
                  Icon(Icons.arrow_forward_ios, color: cOrange.withOpacity(0.5), size: 10),
                  const SizedBox(width: 4),
                  Text("Im Profil einrichten",
                    style: TextStyle(color: cOrange.withOpacity(0.6), fontSize: 10)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Section Header mit Info-Icon
  Widget _buildSectionHeader(String title, {VoidCallback? onInfo}) {
    return Row(
      children: [
        Text(title,
          style: TextStyle(color: Colors.grey.shade500, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
        if (onInfo != null) ...[
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onInfo,
            child: Icon(Icons.info_outline, color: Colors.grey.shade700, size: 14),
          ),
        ],
      ],
    );
  }

  // Badge-Kriterium
  Widget _buildCriterion(String label, int current, int required, bool met) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          met ? Icons.check_circle : Icons.radio_button_unchecked,
          color: met ? Colors.green : Colors.grey.shade700,
          size: 14,
        ),
        const SizedBox(width: 4),
        Text(
          "$label $current/$required",
          style: TextStyle(
            color: met ? Colors.green.shade400 : Colors.grey.shade600,
            fontSize: 11,
            fontWeight: met ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  // Identity-Dot
  Widget _buildIdDot(IconData icon, String label, bool active, Color activeColor) {
    final color = active ? activeColor : Colors.grey.shade700;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        Text(label,
          style: TextStyle(
            color: active ? color : Colors.grey.shade600,
            fontSize: 11,
            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
          )),
        if (active) ...[
          const SizedBox(width: 3),
          Icon(Icons.check_circle, color: color, size: 11),
        ],
      ],
    );
  }

  // Platform-Dots
  List<Widget> _buildPlatformDots() {
    final iconMap = {
      'telegram': Icons.send,
      'twitter': Icons.alternate_email,
      'satoshikleinanzeigen': Icons.storefront,
      'robosats': Icons.smart_toy,
      'nostr': Icons.hub,
    };
    final labelMap = {
      'telegram': 'Telegram',
      'twitter': 'X',
      'satoshikleinanzeigen': 'Kleinanzeigen',
      'robosats': 'RoboSats',
      'nostr': 'Nostr',
    };
    return _platformNames.map<Widget>((name) {
      return _buildIdDot(
        iconMap[name.toLowerCase()] ?? Icons.link,
        labelMap[name.toLowerCase()] ?? name,
        true,
        Colors.green,
      );
    }).toList();
  }

  // =============================================
  // AKTIVES MEETUP CARD
  // =============================================
  Widget _buildActiveSessionCard() {
    final session = _activeSession!;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const RollingQRScreen()),
          );
          _checkActiveSession(); // Nach Rückkehr Status prüfen
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green.withOpacity(0.5), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Pulsierendes Icon
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.qr_code, color: Colors.green, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8, height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "MEETUP AKTIV",
                          style: TextStyle(
                            color: Colors.green.shade300,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      session.meetupName.isNotEmpty 
                          ? session.meetupName.toUpperCase()
                          : "LAUFENDE SESSION",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Noch $_sessionTimeLeft",
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.green, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  // =============================================
  // HOME MEETUP CARD
  // =============================================
  Widget _buildHomeMeetupCard() {
    bool hasHome = _user.homeMeetupId.isNotEmpty;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: hasHome && _homeMeetup != null ? () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CalendarScreen(
                initialSearch: _homeMeetup!.city 
              ),
            ),
          );
        } : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasHome ? cOrange.withOpacity(0.4) : cBorder,
              width: 1.5,
            ),
            boxShadow: hasHome ? [
              BoxShadow(
                color: cOrange.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              )
            ] : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: cOrange.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.home_filled, color: cOrange, size: 24),
                  ),
                  if (hasHome) 
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: cOrange,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        "DEIN MEETUP",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    )
                ],
              ),
              const SizedBox(height: 16),
              Text(
                _homeMeetup != null ? _homeMeetup!.city.toUpperCase() : (_user.homeMeetupId.isNotEmpty ? "Lade..." : "KEIN HOME MEETUP"),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _homeMeetup != null ? "${_homeMeetup!.country} • Regelmäßige Treffen" : (_user.homeMeetupId.isNotEmpty ? "ID: ${_user.homeMeetupId}" : "Wähle dein Stammtisch-Meetup aus"), 
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _selectHomeMeetup,
                      child: Text(hasHome ? "ÄNDERN" : "AUSWÄHLEN"),
                    ),
                  ),
                  if (hasHome) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (_homeMeetup != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MeetupDetailsScreen(meetup: _homeMeetup!),
                              ),
                            );
                          }
                        },
                        child: const Text("DETAILS"),
                      ),
                    ),
                  ],
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTile({required IconData icon, required Color color, required String title, required String subtitle, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cBorder, width: 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}