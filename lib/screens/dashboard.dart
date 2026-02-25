import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
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
      if (mounted) {
        setState(() {
          _platformProofCount = proofs.length;
          _platformNames = proofs.map((p) => p.platform).toList();
          _humanityVerified = humanity.verified;
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
  // ICON-HELPER (statt Emojis)
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

  static IconData _phaseIcon(BootstrapPhase phase) {
    switch (phase) {
      case BootstrapPhase.keimphase: return Icons.eco;
      case BootstrapPhase.wachstum: return Icons.park;
      case BootstrapPhase.stabil: return Icons.forest;
    }
  }

  // =============================================
  // HILFE & INFO
  // =============================================
  void _showHelpSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: cCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(2)),
              )),
              const SizedBox(height: 24),

              const Text("SO FUNKTIONIERT'S",
                style: TextStyle(color: cOrange, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1)),
              const SizedBox(height: 20),

              _helpSection(
                icon: Icons.military_tech,
                color: cOrange,
                title: "BADGES SAMMELN",
                text: "Geh zu einem Einundzwanzig-Meetup und scanne den NFC-Tag oder Rolling-QR-Code des Organisators. "
                    "Für jeden Besuch bekommst du ein kryptographisch signiertes Badge — ein unfälschbarer Beweis, dass du physisch dort warst.",
              ),

              _helpSection(
                icon: Icons.workspace_premium,
                color: Colors.amber,
                title: "REPUTATION AUFBAUEN",
                text: "Dein Trust Score steigt mit jedem Badge. Er berücksichtigt verschiedene Meetups, verschiedene Organisatoren, "
                    "und die Regelmäßigkeit deiner Teilnahme. Je diverser deine Badges, desto höher dein Score.",
              ),

              _helpSection(
                icon: Icons.admin_panel_settings,
                color: Colors.green,
                title: "ORGANISATOR WERDEN",
                text: "Ab einem bestimmten Trust Score wirst du automatisch zum Organisator befördert. "
                    "Dann kannst du selbst NFC-Tags und QR-Codes für dein eigenes Meetup erstellen. "
                    "Keine Anmeldung nötig — das Netzwerk wächst organisch.",
              ),

              _helpSection(
                icon: Icons.verified_user,
                color: cCyan,
                title: "KRYPTOGRAPHISCHE SICHERHEIT",
                text: "Jedes Badge enthält eine BIP-340 Schnorr-Signatur. Diese beweist mathematisch, welcher Organisator den Tag erstellt hat. "
                    "Niemand kann Badges fälschen — auch wir nicht. Kein Server, kein Login, keine persönlichen Daten.",
              ),

              _helpSection(
                icon: Icons.qr_code_scanner,
                color: cPurple,
                title: "REPUTATION PRÜFEN",
                text: "Unter 'Reputation' kannst du deinen QR-Code anzeigen und teilen. "
                    "Andere können ihn scannen und sehen sofort dein Trust Level — kryptographisch verifiziert. "
                    "Du kannst auch die Reputation anderer prüfen, auch ohne eigene Badges.",
              ),

              _helpSection(
                icon: Icons.upload,
                color: Colors.blue,
                title: "BACKUP",
                text: "Sichere deinen Account über die Einstellungen (Zahnrad oben rechts). "
                    "Das Backup enthält deinen Nostr-Key und alle Badges. Ohne Backup sind die Daten bei einer Neuinstallation verloren.",
              ),

              const SizedBox(height: 16),
              const Divider(color: Colors.white10),
              const SizedBox(height: 12),

              Row(children: [
                const Icon(Icons.lock_outline, color: Colors.grey, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(
                  "Alle Daten bleiben auf deinem Gerät. Kein Account, kein Server, kein Tracking.",
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12, height: 1.4),
                )),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _helpSection({required IconData icon, required Color color, required String title, required String text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
          const SizedBox(height: 6),
          Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5)),
        ])),
      ]),
    );
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
            icon: const Icon(Icons.help_outline, color: cCyan),
            tooltip: 'Hilfe & Info',
            onPressed: _showHelpSheet,
          ),
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
            Text(
              "Hallo, ${_user.nickname}!",
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: cText,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Willkommen zurück in der Community.",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: cTextSecondary,
              ),
            ),
            const SizedBox(height: 32),

            // ===== HOME MEETUP =====
            _buildHomeMeetupCard(),
            const SizedBox(height: 20),
            
            // --- TRUST SCORE CARD ---
            if (_trustScore != null) ...[
              _buildTrustScoreCard(),
              const SizedBox(height: 20),
            ],

            // --- AKTIVES MEETUP (Session-Kachel) ---
            if (_activeSession != null) ...[
              _buildActiveSessionCard(),
              const SizedBox(height: 20),
            ],

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              children: [
                _buildTile(
                  icon: Icons.military_tech,
                  color: cOrange,
                  title: "BADGES",
                  subtitle: "Jetzt scannen",
                  onTap: _scanAnyMeetup, 
                ),
                _buildTile(
                  icon: Icons.collections_bookmark, 
                  color: cPurple, 
                  title: "WALLET", 
                  subtitle: "${myBadges.length} Badges", 
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
                  icon: Icons.event,
                  color: cCyan,
                  title: "TERMINE",
                  subtitle: "Kalender & Events",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CalendarScreen()),
                    );
                  },
                ),
                _buildTile(
                  icon: Icons.person, color: Colors.grey, title: "PROFIL",
                  subtitle: _platformProofCount > 0 || _humanityVerified
                      ? "${ _platformProofCount + (_humanityVerified ? 1 : 0)} Verknüpfungen"
                      : "Identität aufbauen",
                  onTap: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileEditScreen()));
                    _loadAll();
                  }
                ),
                _buildTile(
                    icon: Icons.workspace_premium,
                    color: Colors.amber,
                    title: "REPUTATION",
                    subtitle: myBadges.isNotEmpty ? "Badges teilen" : "Scannen & prüfen",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ReputationQRScreen()),
                      );
                    },
                  ),
                // ORGANISATOR-TILE: Erscheint automatisch via Trust Score!
                if (_user.isAdmin) 
                  _buildTile(
                    icon: Icons.admin_panel_settings,
                    color: _justPromoted ? Colors.green : Colors.redAccent,
                    title: "ORGANISATOR",
                    subtitle: _justPromoted 
                        ? "Via Trust Score!" 
                        : _user.promotionSource == 'trust_score' 
                            ? "Trust Score" 
                            : _user.promotionSource == 'seed_admin'
                                ? "Seed Admin"
                                : "Tags erstellen",
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AdminPanelScreen()),
                      );
                      _checkActiveSession(); // Session-Status aktualisieren
                    }
                  ),
              ],
            )
          ],
        ),
      ),
    );
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
  // TRUST SCORE CARD
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

    // Zähle aktive Identity-Layer
    final identityCount = _platformProofCount + (_humanityVerified ? 1 : 0);
    final hasIdentityGaps = _platformProofCount == 0 || !_humanityVerified;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: levelColor.withOpacity(0.25),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== HEADER: Level + Score =====
          Row(
            children: [
              // Level Icon
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: levelColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(_levelIcon(score.level), color: levelColor, size: 22),
              ),
              const SizedBox(width: 12),
              // Level + Label
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      score.level,
                      style: TextStyle(color: levelColor, fontSize: 17, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      "${score.totalBadges} Badges · ${score.uniqueMeetups} Meetups · ${score.uniqueSigners} Ersteller",
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                    ),
                  ],
                ),
              ),
              // Score Zahl
              Text(
                score.totalScore.toStringAsFixed(1),
                style: TextStyle(
                  color: levelColor,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),

          // ===== PROGRESS BAR (nur wenn noch nicht Organisator) =====
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
          ] else ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.verified, color: Colors.green, size: 15),
                const SizedBox(width: 6),
                Text("Organisator", style: TextStyle(color: Colors.green.shade400, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ],

          // ===== IDENTITY LAYER =====
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Identity Dots
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _buildIdDot(
                      Icons.bolt,
                      "Lightning",
                      _humanityVerified,
                      _humanityVerified ? Colors.amber : null,
                    ),
                    ..._buildPlatformDots(),
                    if (_platformProofCount == 0)
                      _buildIdDot(Icons.link, "Plattform", false, null),
                  ],
                ),

                // Hint
                if (hasIdentityGaps) ...[
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ProfileEditScreen()),
                      );
                      _loadAll();
                    },
                    child: Row(
                      children: [
                        Icon(Icons.arrow_forward_ios, color: cOrange.withOpacity(0.5), size: 10),
                        const SizedBox(width: 4),
                        Text(
                          "Verknüpfe Plattformen in deinem Profil um Trust aufzubauen",
                          style: TextStyle(color: cOrange.withOpacity(0.6), fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Einzelner Identity-Dot
  Widget _buildIdDot(IconData icon, String label, bool active, Color? activeColor) {
    final color = active ? (activeColor ?? Colors.green) : Colors.grey.shade700;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: active ? color : Colors.grey.shade600,
            fontSize: 11,
            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        if (active) ...[
          const SizedBox(width: 3),
          Icon(Icons.check_circle, color: color, size: 11),
        ],
      ],
    );
  }

  // Platform-Proof Dots generieren
  List<Widget> _buildPlatformDots() {
    final iconMap = {
      'telegram': Icons.send,
      'twitter': Icons.alternate_email,
      'nostr': Icons.key,
      'kleinanzeigen': Icons.storefront,
    };
    final labelMap = {
      'telegram': 'Telegram',
      'twitter': 'X',
      'nostr': 'NIP-05',
      'kleinanzeigen': 'Kleinanzeigen',
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
  // HOME MEETUP CARD (kompakt mit Schnellzugriff)
  // =============================================
  Widget _buildHomeMeetupCard() {
    final hasHome = _homeMeetup != null;
    final badgesHere = hasHome
        ? myBadges.where((b) => b.meetupName == _homeMeetup!.city).length
        : 0;

    // Kein Home Meetup gesetzt → Auswahl anbieten
    if (!_user.homeMeetupId.isNotEmpty) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _selectHomeMeetup,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cBorder),
            ),
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.home_outlined, color: Colors.grey.shade600, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "HOME MEETUP WÄHLEN",
                        style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Wähle dein Stammtisch-Meetup aus",
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey.shade600, size: 20),
              ],
            ),
          ),
        ),
      );
    }

    // Home Meetup gesetzt → Kompakte Karte mit Schnellzugriff
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: hasHome
            ? () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CalendarScreen(initialSearch: _homeMeetup!.city),
                  ),
                )
            : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cOrange.withOpacity(0.25)),
          ),
          child: Row(
            children: [
              // Meetup-Bild oder Fallback-Icon
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: cOrange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: hasHome && _homeMeetup!.coverImagePath.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          _homeMeetup!.coverImagePath,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.home_filled, color: cOrange, size: 24),
                        ),
                      )
                    : const Icon(Icons.home_filled, color: cOrange, size: 24),
              ),
              const SizedBox(width: 14),

              // Name + Meta
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            hasHome
                                ? _homeMeetup!.city.toUpperCase()
                                : _user.homeMeetupId.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: cOrange.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            "HOME",
                            style: TextStyle(
                              color: cOrange.withOpacity(0.9),
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hasHome
                          ? [
                              _homeMeetup!.country,
                              if (badgesHere > 0) "$badgesHere Badge${badgesHere > 1 ? 's' : ''}",
                            ].join(' · ')
                          : "Lade...",
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    ),
                  ],
                ),
              ),

              // Schnellzugriff-Buttons
              if (hasHome) ...[
                _buildMiniAction(
                  icon: Icons.info_outline,
                  color: Colors.grey.shade600,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MeetupDetailsScreen(meetup: _homeMeetup!),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                _buildMiniAction(
                  icon: Icons.event,
                  color: cOrange,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CalendarScreen(initialSearch: _homeMeetup!.city),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Mini-Action-Button für Home Meetup Card
  Widget _buildMiniAction({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 18),
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