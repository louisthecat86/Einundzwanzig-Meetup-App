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
import 'community_portal_screen.dart';                      // NEU: Community Portal
import 'meetup_details.dart'; 
import 'reputation_qr.dart'; 
import 'relay_settings_screen.dart';
import 'calendar_screen.dart';
import '../services/backup_service.dart';
import '../services/promotion_claim_service.dart';
import '../services/admin_status_verifier.dart';  // Security Audit C2
import '../services/platform_proof_service.dart';
import '../services/humanity_proof_service.dart';
import '../services/nip05_service.dart';
import '../services/app_logger.dart';
import '../services/device_integrity_service.dart';  // Security Audit M5

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

  // Security Audit M5: Device Integrity
  bool _deviceCompromised = false;
  
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

    // Guard: Unvollständiges Profil → erst zur Registrierung
    if (_user.nickname == 'Anon' || _user.nickname.isEmpty) {
      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProfileEditScreen()),
        );
        // Nach Rückkehr: User neu laden
        await _loadUser();
      }
    }

    await _loadBadges();
    await _calculateTrustScore();
    
    // Security Audit C2: Admin-Status kryptographisch re-verifizieren
    // Muss NACH _loadBadges() laufen da Badges für Trust Score nötig
    await _reVerifyAdminStatus();
    
    _loadIdentityData();
    _checkActiveSession();
    // Organic Admins von Nostr laden und verifizieren
    _syncOrganicAdminsInBackground();
    // Security Audit M5: Root/Jailbreak-Prüfung
    _checkDeviceIntegrity();
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
        AppLogger.debug('Dashboard', '${verified.length} organische Admins verifiziert');
      }
    } catch (e) {
      // Stilles Scheitern — kein Netzwerk ist OK
    }
  }

  // Security Audit M5: Root/Jailbreak-Warnung
  void _checkDeviceIntegrity() async {
    try {
      final report = await DeviceIntegrityService.check();
      if (report.isCompromised && mounted) {
        setState(() => _deviceCompromised = true);
        AppLogger.security('Dashboard',
            'Gerät möglicherweise kompromittiert: ${report.findings.length} Befunde');
      }
    } catch (_) {
      // Integritätsprüfung darf App nicht crashen
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
      AppLogger.debug('Dashboard', '$claimedCount Badges retroaktiv gebunden');
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
    
    // --- SEED ADMIN CHECK ENTFERNT (Security Audit C2) ---
    // Admin-Status wird jetzt kryptographisch nach dem Laden
    // der Badges über _reVerifyAdminStatus() verifiziert.
    // Der alte Ansatz (SharedPrefs is_admin direkt setzen)
    // war auf gerooteten Geräten manipulierbar.
    
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
    // AUTO-PROMOTION ENTFERNT (Security Audit C2)
    // =============================================
    // Admin-Status wird jetzt zentral über
    // _reVerifyAdminStatus() → UserProfile.reVerifyAdmin()
    // kryptographisch verifiziert.
    // Siehe _reVerifyAdminStatus() weiter unten.
    // =============================================
  }

  // =============================================
  // SECURITY AUDIT C2: Kryptographische Admin-Re-Verifikation
  // =============================================
  // Wird nach _loadBadges() + _calculateTrustScore() aufgerufen.
  // Ersetzt den alten Seed-Admin-Check und die Auto-Promotion.
  // =============================================
  Future<void> _reVerifyAdminStatus() async {
    try {
      final verification = await _user.reVerifyAdmin(myBadges);
      
      if (mounted) {
        setState(() {});  // UI aktualisieren mit neuem Admin-Status
      }

      // Promotion-Event publizieren wenn neu zum Admin geworden
      if (verification.isAdmin && verification.source == 'trust_score') {
        try {
          final meetupName = _user.homeMeetupId.isNotEmpty
              ? _user.homeMeetupId
              : 'Unbekannt';
          await PromotionClaimService.publishAdminClaim(
            badges: myBadges,
            meetupName: meetupName,
          );
        } catch (_) {
          // Kein Problem — wird beim nächsten App-Start erneut versucht
        }

        if (mounted) {
          setState(() {
            _justPromoted = true;
          });

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
    } catch (e) {
      // Re-Verifikation fehlgeschlagen — sicherheitshalber Admin entziehen
      if (mounted) {
        setState(() {
          _user.isAdmin = false;
          _user.isAdminVerified = false;
          _user.promotionSource = '';
        });
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

            // Security Audit M5: Root/Jailbreak-Warnung
            if (_deviceCompromised) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        DeviceIntegrityService.warningMessage,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.orange.shade200,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

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
                  subtitle: _platformProofCount > 0 || _humanityVerified || _nip05Verified
                      ? "${ _platformProofCount + (_humanityVerified ? 1 : 0) + (_nip05Verified ? 1 : 0)} Verknüpfungen"
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
                // =============================================
                // NEU: Community Portal Kachel
                // =============================================
                _buildTile(
                  icon: Icons.hub,
                  color: cCyan,
                  title: "COMMUNITY",
                  subtitle: "Portal & mehr",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CommunityPortalScreen()),
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
    final identityCount = _platformProofCount + (_humanityVerified ? 1 : 0) + (_nip05Verified ? 1 : 0);
    final hasIdentityGaps = _platformProofCount == 0 || !_humanityVerified || !_nip05Verified;

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
          // ===== HEADER: Level + Score + Info-Button =====
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
              // ========================================
              // NEU: Info-Button
              // ========================================
              const SizedBox(width: 6),
              GestureDetector(
                onTap: _showScoreInfoSheet,
                child: Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.info_outline, color: Colors.grey.shade500, size: 16),
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
                    _buildIdDot(
                      Icons.alternate_email,
                      "NIP-05",
                      _nip05Verified,
                      _nip05Verified ? cCyan : null,
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

  void _showScoreInfoSheet() {
    final score = _trustScore;

    showModalBottomSheet(
      context: context,
      backgroundColor: cCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.80,
        maxChildSize: 0.95,
        minChildSize: 0.4,
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
              const SizedBox(height: 20),

              const Text("DEIN TRUST SCORE",
                style: TextStyle(color: cOrange, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1)),
              const SizedBox(height: 6),
              Text(
                "Der Trust Score misst deine Vertrauenswürdigkeit in der Bitcoin-Community. "
                "Er basiert auf kryptographischen Beweisen — niemand kann ihn fälschen.",
                style: TextStyle(color: Colors.grey.shade400, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 24),

              // ===== LEVEL-ÜBERSICHT =====
              const Text("TRUST LEVEL",
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              const SizedBox(height: 12),

              _scoreLevel(Icons.fiber_new, "NEU", "Score < 3", Colors.grey,
                "Startlevel. Besuche Meetups um Badges zu sammeln.",
                isActive: score != null && score.level == 'NEU'),
              _scoreLevel(Icons.eco, "STARTER", "Score 3 – 9", cOrange,
                "Du bist dabei. Deine ersten Badges zeigen, dass du Teil der Community bist.",
                isActive: score != null && score.level == 'STARTER'),
              _scoreLevel(Icons.local_fire_department, "AKTIV", "Score 10 – 19", cCyan,
                "Regelmäßiger Teilnehmer. Verschiedene Meetups und Organisatoren stärken dein Profil.",
                isActive: score != null && score.level == 'AKTIV'),
              _scoreLevel(Icons.shield, "ETABLIERT", "Score 20 – 39", Colors.green,
                "Vertrauenswürdiges Community-Mitglied. Du bist breit vernetzt und lange dabei.",
                isActive: score != null && score.level == 'ETABLIERT'),
              _scoreLevel(Icons.bolt, "VETERAN", "Score 40+", Colors.amber,
                "Höchstes Trust Level. Deine Reputation hat sich über Monate bewiesen.",
                isActive: score != null && score.level == 'VETERAN'),

              const SizedBox(height: 24),
              const Divider(color: Colors.white10),
              const SizedBox(height: 16),

              // ===== WIE WIRD DER SCORE BERECHNET =====
              const Text("WIE WIRD DER SCORE BERECHNET?",
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              const SizedBox(height: 12),

              _scoreFactorTile(Icons.military_tech, cOrange,
                "Meetup-Badges",
                "Jedes Badge hat einen Basiswert. Badges von gut besuchten Meetups "
                "mit erfahrenen Teilnehmern sind mehr wert."),
              _scoreFactorTile(Icons.location_on, cCyan,
                "Verschiedene Meetups & Städte",
                "Diversität wird belohnt. Badges aus verschiedenen Städten und "
                "von verschiedenen Organisatoren zählen mehr als immer das gleiche Meetup."),
              _scoreFactorTile(Icons.people_outline, cPurple,
                "Verschiedene Organisatoren",
                "Badges von mehreren unabhängigen Signern beweisen, dass du nicht nur "
                "von einer Person bestätigt wirst — das schützt vor Manipulation."),
              _scoreFactorTile(Icons.schedule, Colors.green,
                "Regelmäßigkeit & Alter",
                "Ein älterer Account mit regelmäßiger Teilnahme bekommt einen Reife-Bonus. "
                "Alte Badges verlieren langsam an Wert (Halbwertszeit ~6 Monate)."),
              _scoreFactorTile(Icons.speed, Colors.red.shade300,
                "Frequency Cap",
                "Maximal 2 Badges pro Woche zählen zum Score. "
                "Das verhindert, dass jemand in einer Woche endlos Badges sammelt."),

              const SizedBox(height: 24),
              const Divider(color: Colors.white10),
              const SizedBox(height: 16),

              // ===== ORGANISATOR WERDEN =====
              const Text("ORGANISATOR WERDEN",
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              const SizedBox(height: 12),
              Text(
                "Wenn dein Trust Score hoch genug ist, wirst du automatisch "
                "zum Organisator befördert. Dann kannst du selbst NFC-Tags und "
                "Rolling QR-Codes für dein Meetup erstellen — keine Anmeldung nötig.",
                style: TextStyle(color: Colors.grey.shade400, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 16),

              // Aktuelle Promotion-Anforderungen
              if (score != null && !score.meetsPromotionThreshold) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cOrange.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cOrange.withOpacity(0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "DEIN FORTSCHRITT (${score.activeThresholds.name})",
                        style: TextStyle(color: cOrange, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 10),
                      ...score.progress.entries.map((entry) => _progressRow(entry.value)),
                    ],
                  ),
                ),
              ] else if (score != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withOpacity(0.25)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.verified, color: Colors.green, size: 20),
                    const SizedBox(width: 10),
                    Expanded(child: Text(
                      "Du bist bereits Organisator! Du kannst eigene Meetups verifizieren.",
                      style: TextStyle(color: Colors.green.shade300, fontSize: 13),
                    )),
                  ]),
                ),
              ],

              const SizedBox(height: 24),
              const Divider(color: Colors.white10),
              const SizedBox(height: 16),

              // ===== SCORE ERHÖHEN =====
              const Text("SO ERHÖHST DU DEINEN SCORE",
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              const SizedBox(height: 12),
              _tipRow(Icons.event, "Besuche regelmäßig verschiedene Meetups"),
              _tipRow(Icons.explore, "Scanne Badges bei Meetups in anderen Städten"),
              _tipRow(Icons.group_add, "Sammle Badges von verschiedenen Organisatoren"),
              _tipRow(Icons.bolt, "Verifiziere deine Identität mit einem Lightning-Zap"),
              _tipRow(Icons.alternate_email, "Richte NIP-05 ein (z.B. name@einundzwanzig.space)"),
              _tipRow(Icons.link, "Verknüpfe Plattformen (Telegram, RoboSats, etc.)"),
              _tipRow(Icons.link, "Binde deine Badges (stärkt den kryptographischen Beweis)"),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper-Widgets für Score Info Sheet ---

  Widget _scoreLevel(IconData icon, String name, String range, Color color, String description, {bool isActive = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isActive ? Border.all(color: color.withOpacity(0.3)) : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: color.withOpacity(isActive ? 0.15 : 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isActive ? color : color.withOpacity(0.5), size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(name, style: TextStyle(
                    color: isActive ? color : Colors.white.withOpacity(0.7),
                    fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 8),
                  Text(range, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                  if (isActive) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text("DU", style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ]),
                const SizedBox(height: 2),
                Text(description, style: TextStyle(color: Colors.grey.shade500, fontSize: 11, height: 1.3)),
              ],
            )),
          ],
        ),
      ),
    );
  }

  Widget _scoreFactorTile(IconData icon, Color color, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(description, style: TextStyle(color: Colors.grey.shade500, fontSize: 12, height: 1.4)),
            ],
          )),
        ],
      ),
    );
  }

  Widget _progressRow(PromotionProgress p) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Icon(
          p.met ? Icons.check_circle : Icons.radio_button_unchecked,
          color: p.met ? Colors.green : Colors.grey.shade600,
          size: 16,
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(
          "${p.label}: ${p.current}/${p.required}",
          style: TextStyle(
            color: p.met ? Colors.green.shade300 : Colors.grey.shade400,
            fontSize: 12,
            fontWeight: p.met ? FontWeight.w600 : FontWeight.normal,
          ),
        )),
        // Mini Progress
        SizedBox(
          width: 40, height: 4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: p.percentage,
              backgroundColor: Colors.white.withOpacity(0.06),
              valueColor: AlwaysStoppedAnimation(p.met ? Colors.green : cOrange),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _tipRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: cOrange.withOpacity(0.6), size: 16),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(color: Colors.grey.shade400, fontSize: 12, height: 1.4))),
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            decoration: BoxDecoration(
              color: cCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cBorder),
            ),
            child: Row(
              children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.home_outlined, color: Colors.grey.shade600, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "HOME MEETUP WÄHLEN",
                        style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Wähle dein Stammtisch-Meetup für schnellen Zugriff auf Termine",
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12, height: 1.3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, color: Colors.grey.shade600, size: 22),
              ],
            ),
          ),
        ),
      );
    }

    // Home Meetup gesetzt → Karte mit Schnellzugriff
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cOrange.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          // Oberer Bereich: Tap → Kalender
          Material(
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
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Row(
                  children: [
                    // Meetup-Bild oder Fallback-Icon
                    Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        color: cOrange.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: hasHome && _homeMeetup!.coverImagePath.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.network(
                                _homeMeetup!.coverImagePath,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.home_filled, color: cOrange, size: 28),
                              ),
                            )
                          : const Icon(Icons.home_filled, color: cOrange, size: 28),
                    ),
                    const SizedBox(width: 16),

                    // Name + Meta
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: cOrange.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(5),
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
                          const SizedBox(height: 6),
                          Text(
                            hasHome
                                ? _homeMeetup!.city.toUpperCase()
                                : _user.homeMeetupId.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            hasHome
                                ? [
                                    _homeMeetup!.country,
                                    if (badgesHere > 0) "$badgesHere Badge${badgesHere > 1 ? 's' : ''} hier",
                                  ].join(' · ')
                                : "Lade...",
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                          ),
                        ],
                      ),
                    ),

                    Icon(Icons.chevron_right, color: Colors.grey.shade600, size: 20),
                  ],
                ),
              ),
            ),
          ),

          // Unterer Bereich: Schnellzugriff-Buttons
          if (hasHome)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Row(
                children: [
                  Expanded(
                    child: _buildQuickAction(
                      icon: Icons.event,
                      label: "TERMINE",
                      color: cOrange,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CalendarScreen(initialSearch: _homeMeetup!.city),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildQuickAction(
                      icon: Icons.info_outline,
                      label: "DETAILS",
                      color: Colors.grey.shade500,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MeetupDetailsScreen(meetup: _homeMeetup!),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildQuickAction(
                      icon: Icons.swap_horiz,
                      label: "ÄNDERN",
                      color: Colors.grey.shade500,
                      onTap: _selectHomeMeetup,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 15),
              const SizedBox(width: 5),
              Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
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