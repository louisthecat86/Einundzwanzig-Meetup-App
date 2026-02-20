import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';
import '../models/user.dart';
import '../models/meetup.dart';
import '../models/badge.dart';
import '../services/meetup_service.dart';
import '../services/trust_score_service.dart';
import '../services/admin_registry.dart';
import '../services/nostr_service.dart';
import 'meetup_verification.dart';
import 'meetup_selection.dart'; 
import 'badge_details.dart'; 
import 'badge_wallet.dart';
import 'profile_edit.dart'; 
import 'intro.dart'; 
import 'admin_panel.dart'; 

import 'meetup_details.dart'; 
import 'reputation_qr.dart'; 
import 'calendar_screen.dart';
import '../services/backup_service.dart';
import '../services/promotion_claim_service.dart';

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
  
  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  void _loadAll() async {
    await _loadUser();
    await _loadBadges();
    await _calculateTrustScore();
    // Organic Admins von Nostr laden und verifizieren
    _syncOrganicAdminsInBackground();
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
    setState(() {
      myBadges.clear();
      myBadges.addAll(badges);
    });
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
            _buildHomeMeetupCard(),
            const SizedBox(height: 20),
            
            // --- TRUST SCORE CARD ---
            if (_trustScore != null) ...[
              _buildTrustScoreCard(),
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
                  icon: Icons.person, color: Colors.grey, title: "PROFIL", subtitle: "Identität", 
                  onTap: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileEditScreen()));
                    _loadUser();
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
                        ? "✓ Via Trust Score!" 
                        : _user.promotionSource == 'trust_score' 
                            ? "✓ Trust Score" 
                            : _user.promotionSource == 'seed_admin'
                                ? "✓ Seed Admin"
                                : "Tags erstellen",
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AdminPanelScreen()),
                      );
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
  // TRUST SCORE CARD
  // =============================================
  Widget _buildTrustScoreCard() {
    final score = _trustScore!;
    final phase = score.activeThresholds;
    
    // Farbe basierend auf Level
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
        border: Border.all(
          color: score.meetsPromotionThreshold 
              ? Colors.green.withOpacity(0.5)
              : levelColor.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: levelColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_levelIcon(score.level), color: levelColor, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "TRUST SCORE",
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        score.level,
                        style: TextStyle(
                          color: levelColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Score-Zahl
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: levelColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  score.totalScore.toStringAsFixed(1),
                  style: TextStyle(
                    color: levelColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Phase-Info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_phaseIcon(score.currentPhase), color: Colors.grey.shade400, size: 14),
                const SizedBox(width: 6),
                Text(
                  "Netzwerk: ${phase.name}",
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "${score.uniqueSigners} Ersteller aktiv",
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Fortschrittsbalken (wenn noch nicht Organisator)
          if (!score.meetsPromotionThreshold) ...[
            // Gesamtfortschritt
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: score.promotionProgress,
                backgroundColor: Colors.white.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation(levelColor),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 12),
            
            // Einzelne Kriterien
            ...score.progress.entries.map((entry) {
              final p = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(
                      p.met ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: p.met ? Colors.green : Colors.grey.shade600,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "${p.label}: ${p.current}/${p.required}",
                        style: TextStyle(
                          color: p.met ? Colors.green.shade300 : Colors.grey.shade500,
                          fontSize: 12,
                          fontWeight: p.met ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 8),
            Text(
              score.promotionReason,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ] else ...[
            // Organisator Status
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified, color: Colors.green, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Du bist Organisator! Du kannst NFC-Tags und Rolling-QR-Codes erstellen.",
                      style: TextStyle(
                        color: Colors.green.shade300,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Stats
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStat("${score.totalBadges}", "Badges"),
              _buildStat("${score.uniqueMeetups}", "Meetups"),
              _buildStat("${score.uniqueSigners}", "Ersteller"),
              _buildStat("${score.accountAgeDays}d", "Alter"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
        ),
      ],
    );
  }

  // =============================================
  // HOME MEETUP CARD (unverändert)
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