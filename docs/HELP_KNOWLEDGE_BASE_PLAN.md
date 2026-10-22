# Hilfe in der App: Wissensbasis, Selbst-Check und Rückkanal

**Status:** Vorschlag zur Diskussion. Noch kein Code.
**Ziel:** Nutzer finden Antworten auf ihre Fragen selbst in der App, ohne dass jede Frage beim Maintainer landet.

## Ausgangslage

Die App ist groß geworden: rund 166 Dart-Dateien und 66.000 Zeilen. Davon sind etwa **10.700 Zeilen Kommentare**, und die meisten erklären das *Warum*. Beispiele: „Badge nur vor Ort, weil …“, „Netzwerk leer, weil Events nicht als Begegnung zählen“, „Kennung mit Land, weil `bad-neuenahr` sonst zerlegt wird“. Das ist die eigentliche Wissensbasis des Projekts, nur liegt sie dort, wo Nutzer nie hinschauen.

Was es heute an Hilfe gibt:

| Quelle | Umfang | Problem |
|---|---|---|
| Glossar (`lib/screens/glossary_screen.dart`) | ~55 Einträge, durchsuchbar, DE/EN/ES | Jeder Eintrag von Hand, hinkt hinterher |
| Touren (`lib/tours/`) | einmalig beim ersten Start | Weggetippt = weg |
| README, `docs/`, Release-Notes | ausführlich | Für Entwickler geschrieben, nicht in der App |
| Issues | echte Nutzerfragen | Antworten fließen nicht zurück in die App |

Dazu kommt: Viele Fragen sind **Zustandsfragen**, keine Wissensfragen. „Warum sehe ich keinen Termin?“, „Warum geht der Chat nicht?“, „Warum ist mein Netzwerk leer?“ Die Antwort steht oft schon im Diagnose-Log, zum Beispiel `Standort: Berechtigung denied`, `Failed host lookup` (offline), `Signatur-Modus: amber` oder `3 Teilnahmen nicht angekommen`. Die App sagt sie dem Nutzer nur nicht.

## Vorschlag: vier Bausteine

### 1. Wissensbasis, die mit jedem Release mitwächst

Die Antworten werden **beim Release erzeugt**, nicht zur Laufzeit.

```
Code-Kommentare ─┐
README, docs/  ──┤
Release-Notes  ──┼─► tool/kb/collect ─► KI formuliert Fragen und Antworten ─► Pull Request ─► Review ─► assets/kb/kb_<lang>.json
geschl. Issues ──┘   (nur Änderungen      (DE/EN/ES, für Nutzer,
                      seit letztem Tag)     nicht für Entwickler)
```

- **Sammeln:** Ein Skript unter `tool/kb/` liest die Quellen und nimmt nur das, was sich seit dem letzten Tag geändert hat.
- **Formulieren:** Eine KI schreibt daraus kurze Fragen und Antworten in Nutzersprache. Das läuft beim Maintainer oder in einer Action, **nie in der App**.
- **Prüfen:** Das Ergebnis kommt als Pull Request. Ein Mensch prüft, besonders alles zu Schlüsseln, Backups und Signierern.
- **Ausliefern:** Die Wissensbasis liegt als JSON in `assets/` und funktioniert damit offline.

Vorschlag für ein Format je Eintrag:

```json
{
  "id": "network-empty-events-only",
  "q": "Warum ist mein Vertrauensnetzwerk leer, obwohl ich auf Events war?",
  "a": "Events zählen nicht als Begegnung …",
  "category": "network",
  "screens": ["my_network"],
  "since": "1.6.6",
  "related": ["network-degrees", "attendance-retry"],
  "action": {"label": "Vertrauensnetzwerk öffnen", "route": "my_network"},
  "sources": ["lib/services/coattendance_service.dart", "issue#57"]
}
```

- `screens` erlaubt die kontextbezogene Hilfe (Baustein 3).
- `since` erlaubt die Rubrik „Neu in dieser Version“.
- `action` springt direkt an die richtige Stelle der App.
- `sources` macht nachvollziehbar, woher eine Antwort stammt. Das hilft beim Review und später gegen veraltete Antworten.

In der App wird aus dem Glossar eine **Hilfe** mit Volltextsuche, Kategorien, „Neu in 1.x“ und verwandten Einträgen. Die bestehenden Glossar-Einträge werden übernommen.

### 2. Selbst-Check: „Warum geht das nicht?“

Ein Bildschirm, der den Zustand der App prüft und bekannte Probleme **mit Lösung** benennt:

| Erkannt an | Antwort | Knopf |
|---|---|---|
| Alle Dienste melden `Failed host lookup` | Gerät ist offline | – |
| Standort-Berechtigung verweigert | Badges brauchen den Standort vor Ort | Einstellungen öffnen |
| Teilnahmen mit Status 0 | n Teilnahmen nicht angekommen | Erneut senden |
| Kein Home-Meetup gesetzt | Termine und Chat brauchen ein Home-Meetup | Meetup wählen |
| Signierer Amber/Bunker, Chat-Anmeldung zu spät | Anmeldung im Signierer bestätigen | – |
| mempool.space nicht erreichbar, Tor aktiv | Onion-Adresse nutzen | Mempool-Einstellungen |

- Läuft **regelbasiert auf dem Gerät**. Keine Daten gehen nach außen, keine KI.
- Die Regeln liegen ebenfalls als Daten vor. Eine neue Regel braucht nur eine Prüffunktion und einen Eintrag in der Wissensbasis.
- Der Diagnose-Log (`AppLogger`) und `DiagnosticsService` liefern schon fast alles, was nötig ist.

### 3. Hilfe dort, wo die Frage entsteht

Ein kleines „?“ in der Kopfzeile jedes größeren Bildschirms. Es zeigt nur die Einträge, deren `screens` den Bildschirm enthält, und oben die passenden Selbst-Check-Ergebnisse.

### 4. Rückkanal für offene Fragen

Liefert die Suche keinen Treffer, steht dort: „Frage nicht beantwortet? → stellen“.

- Der Nutzer wählt den Weg: vorbereitetes GitHub-Issue oder Nachricht in einen Support-Raum auf dem Gruppen-Relay.
- Gesendet wird **nur auf Knopfdruck**. Suchbegriffe werden nicht heimlich mitgezählt.
- Beantwortete Fragen fließen beim nächsten Release über Baustein 1 in die Wissensbasis.

## Bewusst nicht (vorerst): KI-Chat in der App

- **Schlüssel und Kosten:** Ein API-Schlüssel kann nicht in eine Open-Source-App. Es bräuchte einen eigenen Server, den jemand betreibt und bezahlt.
- **Privatsphäre:** Fragen würden das Gerät verlassen.
- **Risiko:** Eine falsche Antwort zu nsec, Backup oder Signierer kann echten Schaden anrichten.
- **Auf dem Gerät:** Ein lokales Modell bräuchte Hunderte Megabyte bis Gigabyte.

Falls später gewünscht, dann nur mit der geprüften Wissensbasis als **einziger** Quelle und mit Verweis auf den Eintrag, aus dem die Antwort stammt.

## Vorgeschlagene Reihenfolge

1. **Selbst-Check** mit den sechs Regeln oben. Das bringt den schnellsten Nutzen für den Support.
2. **Format und Hilfe-Bildschirm**: Die bestehenden Glossar-Einträge in das neue Format überführen und die Suche ausbauen.
3. **`tool/kb/`**: das Skript, das Quellen sammelt und einen Pull Request vorbereitet. Erster Lauf über den gesamten Code.
4. **Kontext-„?“** auf den wichtigsten Bildschirmen: Home, Badges, Vertrauensnetzwerk, Chat, Events, Einstellungen.
5. **Rückkanal**.

## Offene Fragen an alle Mitwirkenden

1. **Wer prüft die erzeugten Einträge?** Reicht ein Review durch eine Person, oder braucht alles zu Schlüsseln, Backups und Signierern zwei Augenpaare?
2. **Wann läuft die Erzeugung?** Von Hand vor jedem Release, oder per GitHub Action mit einem KI-Schlüssel als Secret?
3. **Rückkanal:** GitHub-Issue, ein Support-Raum auf `group.einundzwanzig.space`, oder beides?
4. **Welche Selbst-Check-Regeln fehlen?** Welche Fragen bekommt ihr selbst am häufigsten?
5. **Sprache:** Entsteht Deutsch zuerst und wird übersetzt, oder alle drei Sprachen gleichzeitig?
6. **Glossar:** Geht es in der Hilfe auf, oder bleibt es als eigener Bereich für Begriffe (Blockhöhe, nsec, NIP-29 …)?
