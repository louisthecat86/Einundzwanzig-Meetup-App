// ============================================
// WEB OF TRUST DASHBOARD
// ============================================
//
// Übersichtliche Gesamtoberfläche für alles Administrative:
//
//   Tab 1: NETZWERK  — Gesundheitsstatus, alle Admins, Konsens-Meter
//   Tab 2: BÜRGEN    — Eigene Vouching-Liste verwalten
//   Tab 3: MELDUNGEN — Distrust-Reports einsehen + erstellen
//
// ============================================

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:convert';
import '../theme.dart';
import '../services/vouching_service.dart';
import '../services/admin_registry.dart';
import '../services/nostr_service.dart';

class WotDashboardScreen extends StatefulWidget {
  const WotDashboardScreen({super.key});

  @override
  State<WotDashboardScreen> createState() => _WotDashboardScreenState();
}

class _WotDashboardScreenState extends State<WotDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // State
  NetworkConsensus? _consensus;
  List<AdminEntry> _myVouches = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isPublishing = false;
  String? _myNpub;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {}); // FAB aktualisieren
    });
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);

    try {
      _myNpub = await NostrService.getNpub();
      _myVouches = await AdminRegistry.getAdminList();

      // Konsens parallel laden
      try {
        _consensus = await VouchingService.calculateConsensus();
      } catch (e) {
        // Offline-Fallback: Lokale Daten zeigen
        _consensus = null;
      }
    } catch (e) {
      _statusMessage = 'Fehler beim Laden: $e';
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _refresh() async {
    setState(() => _isRefreshing = true);
    try {
      _consensus = await VouchingService.calculateConsensus(forceRefresh: true);
      _myVouches = await AdminRegistry.getAdminList();
      _statusMessage = '';
    } catch (e) {
      _statusMessage = 'Sync fehlgeschlagen: $e';
    }
    if (mounted) setState(() => _isRefreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(
        title: const Text('WEB OF TRUST'),
        actions: [
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: cCyan))
                : const Icon(Icons.sync, color: cCyan),
            tooltip: 'Netzwerk synchronisieren',
            onPressed: _isRefreshing ? null : _refresh,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: cOrange,
          labelColor: cOrange,
          unselectedLabelColor: cTextTertiary,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.5),
          tabs: [
            Tab(icon: const Icon(Icons.hub, size: 20), text: 'NETZWERK'),
            Tab(icon: const Icon(Icons.shield, size: 20), text: 'BÜRGEN'),
            Tab(icon: const Icon(Icons.report_outlined, size: 20), text: 'MELDUNGEN'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: cOrange))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildNetworkTab(),
                _buildVouchingTab(),
                _buildDistrustTab(),
              ],
            ),
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton.extended(
              onPressed: _showAddVouchDialog,
              backgroundColor: cPurple,
              icon: const Icon(Icons.shield, color: Colors.white),
              label: const Text('RITTERSCHLAG',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700,
                      letterSpacing: 0.5)),
            )
          : null,
    );
  }

  // =============================================
  // TAB 1: NETZWERK-ÜBERSICHT
  // =============================================

  Widget _buildNetworkTab() {
    final consensus = _consensus;

    return RefreshIndicator(
      onRefresh: _refresh,
      color: cOrange,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Netzwerk-Status-Header
          _buildNetworkHealthCard(consensus),
          const SizedBox(height: 16),

          // Schwellenwerte-Info
          if (consensus != null) ...[
            _buildThresholdsCard(consensus),
            const SizedBox(height: 16),
          ],

          // Mein Status
          _buildMyStatusCard(consensus),
          const SizedBox(height: 24),

          // Admin-Liste
          _buildSectionHeader('AKTIVE ORGANISATOREN', Icons.verified_user),
          const SizedBox(height: 12),

          if (consensus == null)
            _buildEmptyState(
              icon: Icons.cloud_off,
              title: 'Offline',
              subtitle: 'Netzwerk-Daten konnten nicht geladen werden.\nZiehe zum Aktualisieren nach unten.',
            )
          else if (consensus.effectiveAdmins.isEmpty)
            _buildEmptyState(
              icon: Icons.group_off,
              title: 'Keine aktiven Admins',
              subtitle: 'Das Netzwerk hat noch keine Organisatoren mit genug Bürgschaften.',
            )
          else
            ...consensus.effectiveAdmins.map((admin) =>
                _buildAdminCard(admin, consensus)),

          // Suspendierte (wenn vorhanden)
          if (consensus != null && consensus.suspendedAdmins.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildSectionHeader('SUSPENDIERT', Icons.block, color: cRed),
            const SizedBox(height: 12),
            ...consensus.suspendedAdmins.map((admin) =>
                _buildAdminCard(admin, consensus, suspended: true)),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildNetworkHealthCard(NetworkConsensus? consensus) {
    final effectiveCount = consensus?.effectiveAdmins.length ?? 0;
    final totalVoters = consensus?.totalVoters ?? 0;
    final isSunset = consensus?.isSunset ?? false;
    final suspendedCount = consensus?.suspendedAdmins.length ?? 0;

    // Gesundheits-Score: 0.0 - 1.0
    double health = 0.0;
    if (consensus != null && effectiveCount > 0) {
      health = (effectiveCount / (effectiveCount + suspendedCount + 1)).clamp(0.0, 1.0);
      if (effectiveCount >= 5) health = (health + 0.2).clamp(0.0, 1.0);
      if (totalVoters >= 3) health = (health + 0.1).clamp(0.0, 1.0);
    }

    final healthColor = health > 0.7
        ? Colors.green
        : health > 0.4
            ? Colors.orange
            : cRed;
    final healthLabel = health > 0.7
        ? 'GESUND'
        : health > 0.4
            ? 'AUFBAU'
            : 'KRITISCH';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: healthColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: healthColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.hub, color: healthColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('NETZWERK $healthLabel',
                        style: TextStyle(color: healthColor, fontWeight: FontWeight.w800,
                            fontSize: 14, letterSpacing: 0.5)),
                    const SizedBox(height: 4),
                    Text(
                      isSunset ? 'Dezentral (Web of Trust)' : 'Bootstrap-Phase',
                      style: TextStyle(color: cTextSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Statistik-Reihe
          Row(
            children: [
              _buildStatBox(effectiveCount.toString(), 'Aktive', Colors.green),
              const SizedBox(width: 12),
              _buildStatBox(totalVoters.toString(), 'Stimmen', cCyan),
              const SizedBox(width: 12),
              _buildStatBox(suspendedCount.toString(), 'Suspendiert',
                  suspendedCount > 0 ? cRed : cTextTertiary),
            ],
          ),

          // Gesundheitsbalken
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: health,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation(healthColor),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w800,
                fontSize: 22, fontFamily: 'monospace')),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: color.withOpacity(0.7), fontSize: 10,
                fontWeight: FontWeight.w600, letterSpacing: 0.3)),
          ],
        ),
      ),
    );
  }

  Widget _buildThresholdsCard(NetworkConsensus consensus) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildThresholdItem(
              icon: Icons.how_to_vote,
              label: 'Min. Bürgen',
              value: '${consensus.minVouches}',
              color: cCyan,
            ),
          ),
          Container(width: 1, height: 40, color: cBorder),
          Expanded(
            child: _buildThresholdItem(
              icon: Icons.report,
              label: 'Distrust-Schwelle',
              value: '${consensus.distrustThreshold}',
              color: Colors.orange,
            ),
          ),
          Container(width: 1, height: 40, color: cBorder),
          Expanded(
            child: _buildThresholdItem(
              icon: Icons.landscape,
              label: 'Phase',
              value: consensus.isSunset ? 'Dezentral' : 'Bootstrap',
              color: consensus.isSunset ? Colors.green : cPurple,
              small: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThresholdItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool small = false,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w800,
            fontSize: small ? 11 : 16, fontFamily: small ? null : 'monospace')),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: cTextTertiary, fontSize: 9,
            fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildMyStatusCard(NetworkConsensus? consensus) {
    if (_myNpub == null || _myNpub!.isEmpty) return const SizedBox.shrink();

    final myStatus = consensus?.allAdmins
        .where((a) => a.npub == _myNpub)
        .firstOrNull;

    final isAdmin = myStatus?.isEffectiveAdmin ?? false;
    final vouchCount = myStatus?.vouchCount ?? 0;
    final distrustCount = myStatus?.distrustCount ?? 0;
    final minV = consensus?.minVouches ?? 2;

    final statusColor = isAdmin ? Colors.green : Colors.orange;
    final statusIcon = isAdmin ? Icons.verified : Icons.pending;
    final statusLabel = isAdmin ? 'AKTIVER ORGANISATOR' : 'NOCH NICHT GENUG BÜRGEN';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 20),
              const SizedBox(width: 8),
              Text('DEIN STATUS', style: TextStyle(color: statusColor,
                  fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 12),
          Text(statusLabel, style: TextStyle(color: Colors.white,
              fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildMiniStat(Icons.how_to_vote, '$vouchCount / $minV Bürgen',
                  vouchCount >= minV ? Colors.green : Colors.orange),
              const SizedBox(width: 16),
              if (distrustCount > 0)
                _buildMiniStat(Icons.warning_amber, '$distrustCount Meldungen', cRed),
            ],
          ),
          if (!isAdmin && vouchCount < minV) ...[
            const SizedBox(height: 12),
            Text(
              'Du brauchst noch ${minV - vouchCount} Bürgschaft${minV - vouchCount != 1 ? "en" : ""} '
              'von anderen Organisatoren.',
              style: TextStyle(color: cTextTertiary, fontSize: 11, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildAdminCard(VouchingStatus admin, NetworkConsensus consensus,
      {bool suspended = false}) {
    final isMe = admin.npub == _myNpub;
    final color = suspended ? cRed : (isMe ? cOrange : Colors.white);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: suspended ? cRed.withOpacity(0.3) : (isMe ? cOrange.withOpacity(0.3) : cBorder),
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (suspended ? cRed : cPurple).withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            suspended ? Icons.block : Icons.verified_user,
            color: suspended ? cRed : cPurple,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                admin.name.isNotEmpty ? admin.name : NostrService.shortenNpub(admin.npub),
                style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
            if (isMe)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: cOrange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('DU', style: TextStyle(color: cOrange,
                    fontSize: 9, fontWeight: FontWeight.w800)),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (admin.meetup.isNotEmpty)
              Text(admin.meetup, style: TextStyle(color: cOrange.withOpacity(0.8),
                  fontSize: 11, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            // Vouches-Balken
            _buildVouchBar(admin.vouchCount, consensus.minVouches, suspended),
          ],
        ),
        children: [
          // Erweiterte Details
          _buildDetailRow(Icons.how_to_vote, 'Bürgen',
              '${admin.vouchCount} / ${consensus.minVouches} benötigt'),
          if (admin.distrustCount > 0)
            _buildDetailRow(Icons.warning_amber, 'Meldungen',
                '${admin.distrustCount} / ${consensus.distrustThreshold} Suspendierung',
                color: cRed),
          _buildDetailRow(Icons.fingerprint, 'npub',
              NostrService.shortenNpub(admin.npub, chars: 12)),

          if (admin.vouchers.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('BÜRGEN:', style: TextStyle(color: cTextTertiary, fontSize: 9,
                fontWeight: FontWeight.w700, letterSpacing: 0.5)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6, runSpacing: 4,
              children: admin.vouchers.map((v) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: cPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  v == _myNpub ? 'Du' : NostrService.shortenNpub(v, chars: 6),
                  style: TextStyle(
                    color: v == _myNpub ? cOrange : cPurple,
                    fontSize: 10, fontFamily: 'monospace',
                    fontWeight: v == _myNpub ? FontWeight.w700 : FontWeight.normal,
                  ),
                ),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVouchBar(int count, int required, bool suspended) {
    final ratio = count / max(required, 1);
    final color = suspended ? cRed : (ratio >= 1.0 ? Colors.green : Colors.orange);

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 3,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text('$count', style: TextStyle(color: color, fontSize: 10,
            fontWeight: FontWeight.w700, fontFamily: 'monospace')),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value,
      {Color color = cTextSecondary}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, color: color.withOpacity(0.6), size: 14),
          const SizedBox(width: 8),
          Text('$label: ', style: TextStyle(color: cTextTertiary, fontSize: 11)),
          Expanded(
            child: Text(value, style: TextStyle(color: color, fontSize: 11,
                fontFamily: 'monospace')),
          ),
        ],
      ),
    );
  }

  // =============================================
  // TAB 2: BÜRGEN (Meine Vouching-Liste)
  // =============================================

  Widget _buildVouchingTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Erklärungs-Header
        _buildInfoCard(
          icon: Icons.shield,
          color: cPurple,
          title: 'DEINE BÜRGSCHAFTEN',
          body: 'Du bürgst für ${_myVouches.length} Organisator${_myVouches.length != 1 ? "en" : ""}. '
              'Jede Bürgschaft ist dein persönliches Vertrauens-Votum — '
              'nach dem Publishen sieht das gesamte Netzwerk, für wen du stehst.',
        ),
        const SizedBox(height: 16),

        // Publish-Button
        _buildPublishButton(),
        const SizedBox(height: 24),

        // Vouching-Liste
        _buildSectionHeader('FÜR WEN DU BÜRGST', Icons.people),
        const SizedBox(height: 12),

        if (_myVouches.isEmpty)
          _buildEmptyState(
            icon: Icons.group_add,
            title: 'Noch niemand',
            subtitle: 'Tippe auf + um deinen ersten Ritterschlag\nzu vergeben.',
          )
        else
          ..._myVouches.map(_buildVouchEntry),

        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildPublishButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _isPublishing ? null : _publishToRelays,
        icon: _isPublishing
            ? const SizedBox(width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.satellite_alt, color: Colors.white),
        label: Text(
          _isPublishing
              ? 'SIGNIERE & PUBLIZIERE...'
              : _myVouches.isEmpty
                  ? 'WIDERRUF PUBLISHEN'
                  : 'AUF NOSTR PUBLISHEN',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700,
              fontSize: 13, letterSpacing: 0.5),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _myVouches.isEmpty ? cRed.withOpacity(0.8) : cOrange,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildVouchEntry(AdminEntry admin) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cBorder),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: cPurple.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.verified_user, color: cPurple, size: 22),
        ),
        title: Text(
          admin.name.isNotEmpty ? admin.name : NostrService.shortenNpub(admin.npub),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (admin.meetup.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(admin.meetup, style: TextStyle(color: cOrange, fontSize: 11,
                    fontWeight: FontWeight.w600)),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(NostrService.shortenNpub(admin.npub, chars: 10),
                  style: TextStyle(color: cTextTertiary, fontSize: 10,
                      fontFamily: 'monospace')),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.remove_circle_outline, color: cRed, size: 22),
          tooltip: 'Bürgschaft entziehen',
          onPressed: () => _revokeVouch(admin),
        ),
      ),
    );
  }

  // =============================================
  // TAB 3: MELDUNGEN (Distrust-Reports)
  // =============================================

  Widget _buildDistrustTab() {
    final distrusts = _consensus?.allAdmins
        .where((a) => a.distrustCount > 0)
        .toList() ?? [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Erklärungs-Header
        _buildInfoCard(
          icon: Icons.shield_outlined,
          color: Colors.orange,
          title: 'GEWICHTETES MELDESYSTEM',
          body: 'Eine einzelne Meldung hat kein Gewicht — '
              'erst wenn mehrere unabhängige Organisatoren '
              'warnen, wird jemand suspendiert. '
              'Niemand hat allein Macht über andere.',
        ),
        const SizedBox(height: 16),

        // Melden-Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: _showReportDialog,
            icon: const Icon(Icons.report_outlined, size: 20),
            label: const Text('NPUB MELDEN', style: TextStyle(fontWeight: FontWeight.w700,
                letterSpacing: 0.3)),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orange,
              side: const BorderSide(color: Colors.orange, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Aktive Meldungen
        _buildSectionHeader('AKTIVE WARNUNGEN', Icons.warning_amber,
            color: distrusts.isNotEmpty ? Colors.orange : cTextTertiary),
        const SizedBox(height: 12),

        if (distrusts.isEmpty)
          _buildEmptyState(
            icon: Icons.check_circle_outline,
            title: 'Keine Meldungen',
            subtitle: 'Aktuell gibt es keine offenen Warnungen\nim Netzwerk. Alles sauber.',
            color: Colors.green,
          )
        else
          ...distrusts.map(_buildDistrustEntry),

        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildDistrustEntry(VouchingStatus admin) {
    final threshold = _consensus?.distrustThreshold ?? 3;
    final ratio = admin.distrustCount / max(threshold, 1);
    final isNearSuspension = ratio >= 0.66;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: admin.isSuspended
              ? cRed.withOpacity(0.4)
              : (isNearSuspension ? Colors.orange.withOpacity(0.4) : cBorder),
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (admin.isSuspended ? cRed : Colors.orange).withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            admin.isSuspended ? Icons.block : Icons.warning_amber,
            color: admin.isSuspended ? cRed : Colors.orange,
            size: 20,
          ),
        ),
        title: Text(
          admin.name.isNotEmpty ? admin.name : NostrService.shortenNpub(admin.npub),
          style: TextStyle(
            color: admin.isSuspended ? cRed : Colors.white,
            fontWeight: FontWeight.w600, fontSize: 14,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            // Distrust-Balken
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: ratio.clamp(0.0, 1.0),
                      backgroundColor: Colors.white10,
                      valueColor: AlwaysStoppedAnimation(
                        admin.isSuspended ? cRed : Colors.orange),
                      minHeight: 3,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${admin.distrustCount} / $threshold',
                  style: TextStyle(
                    color: admin.isSuspended ? cRed : Colors.orange,
                    fontSize: 10, fontWeight: FontWeight.w700, fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              admin.isSuspended ? 'SUSPENDIERT' : 'Aktive Warnung',
              style: TextStyle(
                color: admin.isSuspended ? cRed : Colors.orange,
                fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        children: [
          // Details der einzelnen Reports
          for (final report in admin.distrusts) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cRed.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: cRed.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person_outline, color: cTextTertiary, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        report.authorNpub == _myNpub
                            ? 'Du'
                            : NostrService.shortenNpub(report.authorNpub, chars: 8),
                        style: TextStyle(color: cTextSecondary, fontSize: 10,
                            fontFamily: 'monospace'),
                      ),
                      const Spacer(),
                      if (report.timestamp > 0)
                        Text(
                          _formatTimestamp(report.timestamp),
                          style: TextStyle(color: cTextTertiary, fontSize: 9),
                        ),
                    ],
                  ),
                  if (report.reason.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(report.reason, style: TextStyle(color: cTextSecondary,
                        fontSize: 11, height: 1.3)),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // =============================================
  // DIALOGE
  // =============================================

  void _showReportDialog() {
    final npubController = TextEditingController();
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cCard,
        title: Row(
          children: [
            Icon(Icons.report_outlined, color: Colors.orange, size: 22),
            const SizedBox(width: 8),
            const Text('NPUB MELDEN', style: TextStyle(color: Colors.white,
                fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Deine Meldung allein hat kein Gewicht. Erst wenn '
                '${_consensus?.distrustThreshold ?? 3} unabhängige '
                'Organisatoren warnen, wird der npub suspendiert.',
                style: TextStyle(color: cTextTertiary, fontSize: 11, height: 1.4),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: npubController,
                      style: const TextStyle(color: Colors.white, fontFamily: 'monospace',
                          fontSize: 11),
                      decoration: InputDecoration(
                        labelText: 'npub (Pflicht)',
                        labelStyle: TextStyle(color: cTextTertiary),
                        hintText: 'npub1...',
                        filled: true, fillColor: cDark,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: cCyan.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.qr_code_scanner, color: cCyan, size: 22),
                      onPressed: () async {
                        final scanned = await _scanNpub();
                        if (scanned != null) npubController.text = scanned;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                maxLines: 3,
                maxLength: 200,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Grund (Pflicht)',
                  labelStyle: TextStyle(color: cTextTertiary),
                  hintText: 'z.B. Fälscht Badges, kein echtes Meetup...',
                  hintStyle: TextStyle(color: cTextTertiary.withOpacity(0.5)),
                  filled: true, fillColor: cDark,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ABBRECHEN', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final npub = npubController.text.trim();
              final reason = reasonController.text.trim();
              if (npub.isEmpty || reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('npub und Grund sind Pflicht.'),
                      backgroundColor: Colors.red),
                );
                return;
              }
              Navigator.pop(context);
              await _submitDistrust(npub, reason);
            },
            child: const Text('MELDEN', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _revokeVouch(AdminEntry admin) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cCard,
        title: const Text('BÜRGSCHAFT ENTZIEHEN?',
            style: TextStyle(color: cRed, fontWeight: FontWeight.w700, fontSize: 16)),
        content: Text(
          '${admin.name.isNotEmpty ? admin.name : NostrService.shortenNpub(admin.npub)} '
          'wird von deiner Vouching-Liste entfernt.\n\n'
          'Publishe danach deine aktualisierte Liste, '
          'damit das Netzwerk davon erfährt.',
          style: TextStyle(color: cTextSecondary, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ABBRECHEN', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: cRed),
            onPressed: () async {
              await AdminRegistry.removeAdmin(admin.npub);
              if (mounted) {
                Navigator.pop(context);
                _myVouches = await AdminRegistry.getAdminList();
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Bürgschaft entzogen. Vergiss nicht zu publishen.'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            child: const Text('ENTZIEHEN', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddVouchDialog() {
    final npubController = TextEditingController();
    final meetupController = TextEditingController();
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cCard,
        title: Row(
          children: [
            const Icon(Icons.shield, color: cPurple, size: 22),
            const SizedBox(width: 8),
            const Text('RITTERSCHLAG', style: TextStyle(color: Colors.white,
                fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Du bürgst mit deiner eigenen Reputation für diesen Organisator.',
                style: TextStyle(color: cTextTertiary, fontSize: 11, height: 1.4),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: npubController,
                      style: const TextStyle(color: Colors.white, fontFamily: 'monospace',
                          fontSize: 11),
                      decoration: InputDecoration(
                        labelText: 'npub (Pflicht)',
                        labelStyle: TextStyle(color: cTextTertiary),
                        hintText: 'npub1...',
                        filled: true, fillColor: cDark,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: cCyan.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.qr_code_scanner, color: cCyan, size: 22),
                      onPressed: () async {
                        final scanned = await _scanNpub();
                        if (scanned != null) npubController.text = scanned;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: meetupController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Meetup (z.B. München)',
                  labelStyle: TextStyle(color: cTextTertiary),
                  filled: true, fillColor: cDark,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Name / Alias (optional)',
                  labelStyle: TextStyle(color: cTextTertiary),
                  filled: true, fillColor: cDark,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ABBRECHEN', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: cPurple,
                foregroundColor: Colors.white),
            onPressed: () async {
              try {
                await AdminRegistry.addAdmin(AdminEntry(
                  npub: npubController.text.trim(),
                  meetup: meetupController.text.trim(),
                  name: nameController.text.trim(),
                ));
                if (mounted) {
                  Navigator.pop(context);
                  _myVouches = await AdminRegistry.getAdminList();
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ritterschlag vergeben! Vergiss nicht zu publishen.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$e'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('VERBÜRGEN', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // =============================================
  // AKTIONEN
  // =============================================

  Future<void> _publishToRelays() async {
    setState(() => _isPublishing = true);
    try {
      final result = await AdminRegistry.createAndPublishAdminListEvent();
      final data = jsonDecode(result);
      final sentTo = data['sent_to'] ?? 0;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dein Web of Trust ist live ($sentTo Relays)!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e'), backgroundColor: Colors.red),
        );
      }
    }
    if (mounted) setState(() => _isPublishing = false);
  }

  Future<void> _submitDistrust(String npub, String reason) async {
    try {
      final count = await VouchingService.publishDistrust(
        targetNpub: npub,
        reason: reason,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Meldung publiziert an $count Relays.'),
            backgroundColor: Colors.orange,
          ),
        );
        _refresh(); // Netzwerk-Daten neu laden
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<String?> _scanNpub() async {
    return await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const _NpubScannerScreen()),
    );
  }

  // =============================================
  // WIEDERVERWENDBARE WIDGETS
  // =============================================

  Widget _buildSectionHeader(String title, IconData icon, {Color color = cTextTertiary}) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w700,
            fontSize: 11, letterSpacing: 0.8)),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color color,
    required String title,
    required String body,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w700,
                  fontSize: 12, letterSpacing: 0.3)),
            ],
          ),
          const SizedBox(height: 8),
          Text(body, style: TextStyle(color: cTextSecondary, fontSize: 12, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    Color color = cTextTertiary,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(icon, size: 48, color: color.withOpacity(0.3)),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(color: color, fontSize: 14,
              fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(subtitle, style: TextStyle(color: cTextTertiary, fontSize: 12,
              height: 1.4), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  String _formatTimestamp(int unixSeconds) {
    final dt = DateTime.fromMillisecondsSinceEpoch(unixSeconds * 1000);
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 30) return '${dt.day}.${dt.month}.${dt.year}';
    if (diff.inDays > 0) return 'vor ${diff.inDays}d';
    if (diff.inHours > 0) return 'vor ${diff.inHours}h';
    return 'vor ${diff.inMinutes}min';
  }
}

// ============================================
// HELPER: NPUB QR SCANNER (wiederverwendbar)
// ============================================

class _NpubScannerScreen extends StatefulWidget {
  const _NpubScannerScreen();

  @override
  State<_NpubScannerScreen> createState() => _NpubScannerScreenState();
}

class _NpubScannerScreenState extends State<_NpubScannerScreen> {
  bool _isScanned = false;

  void _onDetect(BarcodeCapture capture) {
    if (_isScanned) return;
    for (final barcode in capture.barcodes) {
      String? code = barcode.rawValue;
      if (code != null) {
        code = code.trim().toLowerCase();
        if (code.startsWith('nostr:')) code = code.replaceFirst('nostr:', '');
        if (code.startsWith('npub1') && code.length > 50) {
          setState(() => _isScanned = true);
          Navigator.pop(context, code);
          return;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('NPUB SCANNEN'),
          backgroundColor: Colors.transparent, elevation: 0),
      body: Stack(
        children: [
          MobileScanner(onDetect: _onDetect),
          Positioned(
            bottom: 60, left: 40, right: 40,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cPurple),
              ),
              child: const Text(
                'Scanne den Nostr-QR-Code (npub)\ndes Organisators.',
                style: TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
