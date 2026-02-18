// ============================================
// REPUTATION QR-CODE SCREEN v3 — WASSERDICHT
// ============================================
//
// Die kryptographische Kette im QR-Code:
//
//   Schicht 1 — IDENTITÄT
//     npub, Nickname, Telegram, Twitter
//
//   Schicht 2 — REPUTATION
//     Trust Score, Level, Badges, Meetups, Signers, Account-Alter
//
//   Schicht 3 — BADGE-PROOF (NEU!)
//     SHA-256 über alle Badge-Signaturen
//     → Ändert man ein Badge → Hash ändert sich → QR ungültig
//
//   Schicht 4 — QR-SIGNATUR
//     Nostr Event (Kind 21001) über ALLES
//     → Event-ID + created_at im QR eingebettet
//     → Scanner rekonstruiert Event → echte Schnorr-Verifikation
//
// Format: "21v3:BASE64.SIG.EVENTID.CREATEDAT.PUBKEY"
//
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';
import '../theme.dart';
import '../models/badge.dart';
import '../models/user.dart';
import '../services/badge_security.dart';
import '../services/nostr_service.dart';
import '../services/trust_score_service.dart';
import 'qr_scanner.dart';

class ReputationQRScreen extends StatefulWidget {
  const ReputationQRScreen({super.key});

  @override
  State<ReputationQRScreen> createState() => _ReputationQRScreenState();
}

class _ReputationQRScreenState extends State<ReputationQRScreen> {
  String _qrData = '';
  String _fullJson = '';
  bool _isLoading = true;
  late UserProfile _user;
  TrustScore? _trustScore;
  int _verifiedBadgeCount = 0;

  @override
  void initState() {
    super.initState();
    _generateQRData();
  }

  void _generateQRData() async {
    final user = await UserProfile.load();
    final uniqueMeetups = myBadges.map((b) => b.meetupName).toSet();
    final uniqueSigners = myBadges.map((b) => b.signerNpub).where((s) => s.isNotEmpty).toSet();

    // Trust Score
    final sortedByDate = List<MeetupBadge>.from(myBadges)
      ..sort((a, b) => a.date.compareTo(b.date));
    final firstBadgeDate = sortedByDate.isNotEmpty ? sortedByDate.first.date : null;
    
    final trustScore = TrustScoreService.calculateScore(
      badges: myBadges,
      firstBadgeDate: firstBadgeDate,
      coAttestorMap: null,
    );

    // Badge-Proof (SHA-256 über alle Badge-Signaturen)
    final badgeProof = MeetupBadge.generateBadgeProof(myBadges);
    final verifiedCount = MeetupBadge.countVerifiedBadges(myBadges);

    // 1. Identität
    final Map<String, dynamic> identity = {
      'n': user.nickname.isEmpty ? 'Anon' : user.nickname,
    };
    if (user.nostrNpub.isNotEmpty) identity['np'] = user.nostrNpub;
    if (user.telegramHandle.isNotEmpty) identity['tg'] = user.telegramHandle;
    if (user.twitterHandle.isNotEmpty) identity['tw'] = user.twitterHandle;

    // 2. Reputation
    final Map<String, dynamic> reputation = {
      'sc': double.parse(trustScore.totalScore.toStringAsFixed(1)),
      'lv': trustScore.level,
      'bc': myBadges.length,
      'vc': verifiedCount,
      'mc': uniqueMeetups.length,
      'si': uniqueSigners.length,
      'ad': trustScore.accountAgeDays,
    };
    if (uniqueMeetups.isNotEmpty) {
      reputation['ml'] = uniqueMeetups.take(10).toList();
    }

    // 3. Proof
    final Map<String, dynamic> proof = {
      'bp': badgeProof,
      'vc': verifiedCount,
      'tc': myBadges.length,
    };

    // 4. Payload
    final Map<String, dynamic> qrPayload = {
      'v': 3,
      'id': identity,
      'rp': reputation,
      'pf': proof,
      't': DateTime.now().millisecondsSinceEpoch,
    };

    final jsonString = jsonEncode(qrPayload);

    // 5. Signatur mit Event-Metadaten
    final signResult = await BadgeSecurity.signQRv3(jsonString);

    // 6. Format: "21v3:BASE64.SIG.EVENTID.CREATEDAT.PUBKEY"
    final base64Json = base64Encode(utf8.encode(jsonString));
    String secureQrData;

    if (signResult.isNostr) {
      secureQrData = "21v3:$base64Json"
          ".${signResult.signature}"
          ".${signResult.eventId}"
          ".${signResult.createdAt}"
          ".${signResult.pubkeyHex}";
    } else {
      secureQrData = "21:$base64Json.${signResult.signature}";
    }

    // JSON Export
    final fullJsonExport = MeetupBadge.exportBadgesForReputation(
      myBadges, user.nostrNpub,
      nickname: user.nickname,
      telegram: user.telegramHandle,
      twitter: user.twitterHandle,
    );

    setState(() {
      _qrData = secureQrData;
      _fullJson = fullJsonExport;
      _user = user;
      _trustScore = trustScore;
      _verifiedBadgeCount = verifiedCount;
      _isLoading = false;
    });
  }

  bool get _hasIdentity {
    if (_isLoading) return false;
    return _user.nostrNpub.isNotEmpty ||
        _user.telegramHandle.isNotEmpty ||
        _user.twitterHandle.isNotEmpty;
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label kopiert'), backgroundColor: cOrange, duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(title: const Text("REPUTATION")),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SecureQRScanner())),
        backgroundColor: cCyan,
        icon: const Icon(Icons.qr_code_scanner, color: Colors.black),
        label: const Text("PRÜFEN", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: cOrange))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (!_hasIdentity) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade900.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade700),
                      ),
                      child: Row(children: [
                        const Icon(Icons.warning_amber, color: Colors.red, size: 28),
                        const SizedBox(width: 12),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text("KEINE IDENTITÄT VERKNÜPFT", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13)),
                            SizedBox(height: 4),
                            Text("Gehe in dein Profil und füge Telegram oder Twitter hinzu.",
                              style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4)),
                          ],
                        )),
                      ]),
                    ),
                    const SizedBox(height: 20),
                  ],

                  if (_trustScore != null) _buildTrustScoreHero(),
                  const SizedBox(height: 24),
                  _buildIdentityCard(),
                  const SizedBox(height: 24),

                  // QR Code
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: cOrange.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))],
                    ),
                    child: Column(children: [
                      QrImageView(data: _qrData, version: QrVersions.auto, size: 260, backgroundColor: Colors.white, errorCorrectionLevel: QrErrorCorrectLevel.L),
                      const SizedBox(height: 10),
                      Text(
                        _hasIdentity ? "🔐 Schnorr-signiert & identitätsgebunden" : "🔐 Schnorr-signiert (ohne Identität)",
                        style: TextStyle(color: _hasIdentity ? Colors.green.shade700 : Colors.red.shade700, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 16),

                  _buildBadgeProofCard(),
                  const SizedBox(height: 24),
                  _buildStatsRow(),
                  const SizedBox(height: 24),

                  // Buttons
                  Row(children: [
                    Expanded(child: ElevatedButton.icon(
                      onPressed: () => _copyToClipboard(_qrData, 'QR-Code'),
                      icon: const Icon(Icons.copy, size: 20),
                      label: const Text('CODE KOPIEREN'),
                      style: ElevatedButton.styleFrom(backgroundColor: cOrange, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 14)),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: OutlinedButton.icon(
                      onPressed: () => _copyToClipboard(_fullJson, 'JSON'),
                      icon: const Icon(Icons.code, size: 20),
                      label: const Text('JSON EXPORT'),
                      style: OutlinedButton.styleFrom(foregroundColor: cCyan, side: const BorderSide(color: cCyan), padding: const EdgeInsets.symmetric(vertical: 14)),
                    )),
                  ]),
                  const SizedBox(height: 24),

                  // Erklärung
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: cBorder)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: const [
                        Icon(Icons.info_outline, color: cCyan, size: 20), SizedBox(width: 8),
                        Text("KRYPTOGRAPHISCHE KETTE", style: TextStyle(color: cCyan, fontWeight: FontWeight.bold, fontSize: 12)),
                      ]),
                      const SizedBox(height: 12),
                      const Text(
                        "1. Du warst physisch beim Meetup → Organisator hat Tag signiert (Schnorr)\n"
                        "2. Jedes Badge speichert die Original-Signatur des Organisators\n"
                        "3. Dieser QR enthält einen Hash über ALLE deine Badge-Signaturen\n"
                        "4. Der QR selbst ist mit DEINEM Key signiert (Schnorr)\n\n"
                        "→ Ändert man irgendwas → Hash stimmt nicht → Signatur ungültig → Fälschung\n"
                        "→ Kein Server nötig — Mathe reicht",
                        style: TextStyle(color: cTextSecondary, fontSize: 12, height: 1.6),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 60),
                ],
              ),
            ),
    );
  }

  Widget _buildTrustScoreHero() {
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
      width: double.infinity, padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: levelColor.withOpacity(0.4), width: 1.5)),
      child: Column(children: [
        Text(score.levelEmoji, style: const TextStyle(fontSize: 40)),
        const SizedBox(height: 8),
        Text(score.level, style: TextStyle(color: levelColor, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 2)),
        const SizedBox(height: 4),
        Text("Trust Score: ${score.totalScore.toStringAsFixed(1)}", style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
        const SizedBox(height: 16),
        Text("VERIFIZIERTE MEETUP-REPUTATION", style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
      ]),
    );
  }

  Widget _buildBadgeProofCard() {
    final total = myBadges.length;
    final verified = _verifiedBadgeCount;
    final allVerified = total > 0 && verified == total;
    final Color c = allVerified ? Colors.green : (verified > 0 ? Colors.orange : Colors.red);
    final String label = allVerified ? "ALLE BADGES KRYPTOGRAPHISCH BEWIESEN"
        : verified > 0 ? "$verified VON $total MIT SCHNORR-BEWEIS" : "KEINE KRYPTOGRAPHISCHEN BEWEISE";
    final String desc = allVerified ? "Jedes Badge hat eine unfälschbare Organisator-Signatur."
        : verified > 0 ? "Ältere Badges werden durch neue Meetup-Besuche ersetzt."
        : "Besuche ein Meetup für dein erstes kryptographisches Badge.";

    return Container(
      width: double.infinity, padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: c.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: c.withOpacity(0.3))),
      child: Row(children: [
        Icon(allVerified ? Icons.verified : Icons.shield, color: c, size: 28),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(desc, style: TextStyle(color: c.withOpacity(0.8), fontSize: 11, height: 1.4)),
        ])),
      ]),
    );
  }

  Widget _buildIdentityCard() {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: cPurple.withOpacity(0.4))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: const [
          Icon(Icons.fingerprint, color: cPurple, size: 20), SizedBox(width: 8),
          Text("VERKNÜPFTE IDENTITÄT", style: TextStyle(color: cPurple, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
        ]),
        const SizedBox(height: 12),
        _buildIdentityRow("Nickname", _user.nickname.isEmpty ? 'Anon' : _user.nickname, Icons.person, true),
        if (_user.nostrNpub.isNotEmpty) _buildIdentityRow("Nostr", _user.nostrNpub.length > 24 ? "${_user.nostrNpub.substring(0, 24)}..." : _user.nostrNpub, Icons.key, true),
        if (_user.telegramHandle.isNotEmpty) _buildIdentityRow("Telegram", "@${_user.telegramHandle}", Icons.send, true),
        if (_user.twitterHandle.isNotEmpty) _buildIdentityRow("Twitter/X", "@${_user.twitterHandle}", Icons.alternate_email, true),
        if (!_hasIdentity) _buildIdentityRow("Status", "Keine verifizierbare Identität", Icons.warning_amber, false),
      ]),
    );
  }

  Widget _buildStatsRow() {
    final score = _trustScore;
    return Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      _buildStatCard(icon: Icons.military_tech, label: "Badges", value: "${myBadges.length}", color: cOrange),
      _buildStatCard(icon: Icons.location_on, label: "Meetups", value: "${score?.uniqueMeetups ?? 0}", color: cCyan),
      _buildStatCard(icon: Icons.people, label: "Ersteller", value: "${score?.uniqueSigners ?? 0}", color: cPurple),
      _buildStatCard(icon: Icons.calendar_today, label: "Tage", value: "${score?.accountAgeDays ?? 0}", color: Colors.green),
    ]);
  }

  Widget _buildIdentityRow(String label, String value, IconData icon, bool ok) {
    return Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [
      Icon(icon, size: 16, color: ok ? cOrange : Colors.red.withOpacity(0.7)), const SizedBox(width: 8),
      Text("$label: ", style: const TextStyle(color: Colors.white54, fontSize: 12)),
      Expanded(child: Text(value, style: TextStyle(color: ok ? Colors.white : Colors.red.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.w600, fontFamily: label == "Nostr" ? 'monospace' : null), overflow: TextOverflow.ellipsis)),
    ]));
  }

  Widget _buildStatCard({required IconData icon, required String label, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.3))),
      child: Column(children: [
        Icon(icon, color: color, size: 24), const SizedBox(height: 6),
        Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w800)), const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: cTextSecondary, fontSize: 10)),
      ]),
    );
  }
}