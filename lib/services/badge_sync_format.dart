// Reine Funktionen für den Badge-Sync: Hülle, Sortierung, Chunking,
// Vereinigung. Kein Netz, kein Signer. Das Netz legt die Chunks in
// 30078-Events, der Signer verschlüsselt. Hier ist nur das Format.

import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../models/badge.dart';

class BadgeSyncFormat {
  BadgeSyncFormat._();

  /// kind 30078 mit d-Tag badges-i, ersetzbar je Chunk.
  static const int kind = 30078;

  /// Höchstens so viele Chunks lesen wir. Weit mehr als je nötig.
  static const int maxChunks = 16;

  /// NIP-44-Payload-Zeichen je Event. Aus der Relay-Sonde.
  static const int chunkPayloadChars = 30000;

  /// d-Tag des Chunks [i].
  static String dTag(int i) => 'badges-$i';

  /// Sortierung nach Meetup-Datum, bei Gleichstand nach Id. Das ist
  /// deterministisch und legt neue Scans fast immer ans Ende, weil das
  /// Meetup in der Regel heute ist. Nicht claimTimestamp: ein nachträglich
  /// geclaimtes Badge mit altem Scan-Datum würde sonst die ganze Liste
  /// nach hinten schieben.
  static List<MeetupBadge> sortBadges(Iterable<MeetupBadge> badges) {
    final list = badges.toList();
    list.sort((a, b) {
      final byDate = a.date.compareTo(b.date);
      if (byDate != 0) return byDate;
      return a.id.compareTo(b.id);
    });
    return list;
  }

  /// Die Hülle als JSON-String für Chunk [index] von [total].
  static String envelopeJson({
    required List<MeetupBadge> badges,
    required int index,
    required int total,
    required int generation,
  }) {
    return jsonEncode({
      'v': 1,
      'i': index,
      'n': total,
      'gen': generation,
      'badges': badges.map((b) => b.toJson()).toList(),
    });
  }

  /// Verteilt [badges] auf Chunks. [measure] ist die Länge der
  /// NIP-44-Payload, die aus dem Klartext [plaintext] entstehen würde.
  /// Der Aufrufer liefert sie, weil sie vom Verschlüsseln abhängt.
  static List<List<MeetupBadge>> chunkBadges(
    List<MeetupBadge> badges,
    int Function(String plaintext) measure,
  ) {
    if (badges.isEmpty) return const [];
    final sorted = sortBadges(badges);
    final chunks = <List<MeetupBadge>>[];
    var current = <MeetupBadge>[];

    // Die Chunk-Zahl ist zum Schätzen der Länge nötig; sie ändert sich
    // beim Wachsen. Zweimal messen reicht, weil n nie kleiner wird.
    int payloadLen(int index, int total) =>
        measure(envelopeJson(
          badges: current,
          index: index,
          total: total,
          generation: 0,
        ));

    for (final badge in sorted) {
      current.add(badge);
      final total = chunks.length + 2; // ein möglicher weiterer Chunk
      if (payloadLen(chunks.length, total) > chunkPayloadChars) {
        // Das letzte Badge passt nicht mehr. Chunk abschließen und neu anfangen.
        final last = current.removeLast();
        if (current.isEmpty) {
          // Ein einzelnes Badge ist größer als die Grenze. Das darf nicht
          // passieren; zur Sicherheit trotzdem ablegen statt Endlosschleife.
          chunks.add([last]);
          current = <MeetupBadge>[];
          continue;
        }
        chunks.add(current);
        current = [last];
      }
    }
    if (current.isNotEmpty) chunks.add(current);
    return chunks;
  }

  /// Klartexte aller Chunks.
  static List<String> plaintexts(
    List<MeetupBadge> badges,
    int generation,
    int Function(String plaintext) measure,
  ) {
    final chunks = chunkBadges(badges, measure);
    return [
      for (var i = 0; i < chunks.length; i++)
        envelopeJson(
          badges: chunks[i],
          index: i,
          total: chunks.length,
          generation: generation,
        ),
    ];
  }

  /// SHA-256 über den Klartext eines Chunks. Der Vergleich muss am
  /// Klartext stattfinden, weil NIP-44 mit frischer Nonce jedes Mal einen
  /// anderen Ciphertext ergibt.
  static String chunkHash(String plaintext) =>
      sha256.convert(utf8.encode(plaintext)).toString();

  /// Hash nur über den Inhalt, nicht über die Generation. Sonst änderte
  /// er sich bei jedem Start und jeder Chunk ginge wieder raus.
  static String contentHash(String plaintext) {
    final env = parseEnvelope(plaintext);
    return chunkHash(jsonEncode({
      'v': 1,
      'badges': env.badges.map((b) => b.toJson()).toList(),
    }));
  }

  /// Länge der NIP-44-Payload aus einer gzip-Bytefolge. Nicht die
  /// Klartext-Länge: das NIP-44-Padding und base64 machen sie größer.
  static int payloadCharsForGzip(int gzipBytes) {
    // Verschlüsselt wird base64(gzip), inklusive NIP-44-Längenpräfix.
    final plaintextBytes = ((gzipBytes + 2) ~/ 3) * 4;
    final padded = 2 + _padLen(plaintextBytes);
    return ((1 + 32 + padded + 32 + 2) ~/ 3) * 4;
  }

  static int _padLen(int len) {
    if (len <= 32) return 32;
    var power = 1;
    while (power < len) {
      power <<= 1;
    }
    final chunk = power <= 256 ? 32 : power ~/ 8;
    return chunk * ((len - 1) ~/ chunk + 1);
  }

  /// Liest eine Hülle. Wirft [FormatException] bei kaputtem JSON oder
  /// fehlenden Feldern. Die Badges kommen als Liste; einzelne defekte
  /// Einträge fallen weg statt den ganzen Chunk zu verwerfen.
  static ({int index, int total, int generation, List<MeetupBadge> badges})
      parseEnvelope(String plaintext) {
    final map = jsonDecode(plaintext);
    if (map is! Map<String, dynamic>) {
      throw const FormatException('Hülle ist kein Objekt');
    }
    if (map['v'] != 1) {
      throw FormatException('Hülle v${map['v']} wird nicht unterstützt');
    }
    final raw = map['badges'];
    if (raw is! List) {
      throw const FormatException('Hülle ohne badges');
    }
    final badges = <MeetupBadge>[];
    for (final entry in raw) {
      if (entry is Map<String, dynamic>) {
        try {
          badges.add(MeetupBadge.fromJson(entry));
        } catch (_) {
          // Defektes Badge weglassen, nicht den ganzen Chunk.
        }
      }
    }
    return (
      index: (map['i'] as num?)?.toInt() ?? 0,
      total: (map['n'] as num?)?.toInt() ?? 1,
      generation: (map['gen'] as num?)?.toInt() ?? 0,
      badges: badges,
    );
  }

  /// Vereinigt lokale und ferne Badges je Veranstaltung, sortiert.
  /// Die Regel steht in [MeetupBadge.unionByIdentity] und ist dieselbe wie
  /// in der Datei und im Wallet. Bei Gleichstand gewinnt das lokale.
  static List<MeetupBadge> merge(
    List<MeetupBadge> local,
    List<MeetupBadge> remote,
  ) =>
      sortBadges(MeetupBadge.unionByIdentity(local, remote));
}
