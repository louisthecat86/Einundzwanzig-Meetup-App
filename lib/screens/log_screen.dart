// ============================================
//  Diagnose-Log — klassische Protokoll-Ansicht
// ============================================
//  Zeigt die persistent gespeicherten Diagnose-Ereignisse als ruhiges,
//  technisches Logprotokoll (monospace, eine Zeile pro Eintrag).
//  Zum Teilen/Kopieren und Leeren. Enthält bewusst KEINE Secrets.
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../theme.dart';
import '../services/app_logger.dart';
import '../utils/share_origin.dart';

class LogScreen extends StatefulWidget {
  const LogScreen({super.key});

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  bool _onlyProblems = false; // Filter: nur WARN/ERROR

  Color _levelColor(String level) {
    switch (level) {
      case 'ERROR': return cRed;
      case 'WARN': return cOrange;
      case 'SEC': return cPurple;
      case 'DEBUG': return cTextTertiary;
      default: return cTextSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final all = AppLogger.entries
        .where((e) => !_onlyProblems || e.level == 'ERROR' || e.level == 'WARN')
        .toList(); // chronologisch (älteste oben, wie ein Logfile)

    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(
        backgroundColor: cDark,
        elevation: 0,
        title: const Text('Diagnose-Log', style: TextStyle(color: cText, fontWeight: FontWeight.w700, fontSize: 16)),
        actions: [
          IconButton(
            icon: Icon(_onlyProblems ? Icons.filter_alt_rounded : Icons.filter_alt_outlined,
                color: _onlyProblems ? cOrange : cTextSecondary, size: 20),
            tooltip: 'Nur Warnungen/Fehler',
            onPressed: () => setState(() => _onlyProblems = !_onlyProblems),
          ),
          // AUSFUEHRLICH-SCHALTER: Vor dem Nachstellen eines Fehlers
          // einschalten — dann landen auch Detailmeldungen im Log.
          IconButton(
            icon: Icon(
                AppLogger.isVerbose ? Icons.zoom_in_rounded : Icons.zoom_out_map_rounded,
                color: AppLogger.isVerbose ? cOrange : cTextSecondary, size: 20),
            tooltip: AppLogger.isVerbose
                ? 'Ausführliches Log AN — tippen zum Ausschalten'
                : 'Ausführliches Log einschalten (mehr Details für die Fehlersuche)',
            onPressed: () async {
              await AppLogger.setVerbose(!AppLogger.isVerbose);
              if (context.mounted) {
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(AppLogger.isVerbose
                      ? 'Ausführliches Log an — Fehler jetzt nachstellen, dann Log teilen.'
                      : 'Ausführliches Log aus.'),
                  behavior: SnackBarBehavior.floating));
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.copy_rounded, color: cTextSecondary, size: 20),
            tooltip: 'Kopieren',
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: AppLogger.exportText()));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Log kopiert'), behavior: SnackBarBehavior.floating));
              }
            },
          ),
          Builder(builder: (btnCtx) => IconButton(
            icon: const Icon(Icons.share_rounded, color: cTextSecondary, size: 20),
            tooltip: 'Teilen',
            onPressed: () async {
              final text = AppLogger.exportText();
              if (text.isEmpty) return;
              try {
                await Share.share(text,
                    subject: '21Meetup Diagnose-Log',
                    sharePositionOrigin: shareOriginFor(btnCtx));
              } catch (_) {
                // Teilen fehlgeschlagen: wie der Kopieren-Button daneben.
                await Clipboard.setData(ClipboardData(text: text));
                if (btnCtx.mounted) {
                  ScaffoldMessenger.of(btnCtx).showSnackBar(const SnackBar(
                      content: Text('Log kopiert'),
                      behavior: SnackBarBehavior.floating));
                }
              }
            },
          )),
        ],
      ),
      body: all.isEmpty
          ? const Center(child: Text('Keine Einträge', style: TextStyle(color: cTextTertiary)))
          : Container(
              color: const Color(0xFF0D0D0F), // Terminal-artiger, ruhiger Grund
              width: double.infinity,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: SelectableText.rich(
                  TextSpan(
                    style: const TextStyle(fontSize: 11.5, height: 1.6).copyWith(fontFamily: fontMono),
                    children: [
                      for (final e in all) ..._line(e),
                    ],
                  ),
                ),
              ),
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
          child: Row(children: [
            Expanded(
              child: Text('${all.length} Einträge',
                  style: const TextStyle(color: cTextTertiary, fontSize: 12)),
            ),
            GestureDetector(
              onTap: () async {
                await AppLogger.clear();
                if (mounted) setState(() {});
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: cRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: cRed.withValues(alpha: 0.3), width: 0.5),
                ),
                child: const Text('Log leeren', style: TextStyle(color: cRed, fontSize: 13, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  /// Eine Protokollzeile: "HH:MM:SS  LEVEL  [tag]  message\n"
  List<TextSpan> _line(LogEntry e) {
    String two(int n) => n.toString().padLeft(2, '0');
    final ts = '${two(e.time.hour)}:${two(e.time.minute)}:${two(e.time.second)}';
    return [
      TextSpan(text: '$ts  ', style: const TextStyle(color: cTextTertiary)),
      TextSpan(text: e.level.padRight(5), style: TextStyle(color: _levelColor(e.level), fontWeight: FontWeight.w700)),
      TextSpan(text: '  ${e.tag}: ', style: const TextStyle(color: cOrange)),
      TextSpan(text: '${e.message}\n', style: const TextStyle(color: cText)),
    ];
  }
}
