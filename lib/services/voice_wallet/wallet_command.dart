// Gesprochener Wallet-Befehl, ohne Modell.
//
// Die Saetze sind eine feste Liste. Eine Zahl wird aus Ziffern oder aus
// deutschen und englischen Zahlwoertern gelesen. Mehr als ein Bitcoin
// in einem gesprochenen Auftrag nehmen wir nicht an — ein verhoerter
// Satz soll keine grosse Summe vormerken.

enum WalletCommandKind {
  balance,
  scan,
  paste,
  gallery,
  send,
  confirm,
  cancel,
  help,
  output,
  unknown,
}

/// Was die Wallet zeigt und spricht. Beides ist der Anfang.
enum WalletOutput { both, sound, text }

class WalletCommand {
  final WalletCommandKind kind;

  /// Nur bei [WalletCommandKind.send] gesetzt, und nur wenn eine Zahl da war.
  final int? sats;

  /// Nur bei [WalletCommandKind.output] gesetzt.
  final WalletOutput? output;

  const WalletCommand(this.kind, {this.sats, this.output});

  static const unknown = WalletCommand(WalletCommandKind.unknown);
}

const int _maxSpokenSats = 100000000;

WalletCommand parseWalletCommand(String raw) {
  final text = _normalize(raw);
  if (text.isEmpty) return WalletCommand.unknown;

  if (_exact(text, _confirm)) return WalletCommand(WalletCommandKind.confirm);
  final output = _outputOf(text);
  if (output != null) {
    return WalletCommand(WalletCommandKind.output, output: output);
  }
  if (_exact(text, _cancel) || _startsWithWord(text, _cancel)) {
    return WalletCommand(WalletCommandKind.cancel);
  }
  if (_hasPhrase(text, _help)) return WalletCommand(WalletCommandKind.help);

  final sats = parseSpokenSats(text);
  if (_hasPhrase(text, _balance)) {
    return WalletCommand(WalletCommandKind.balance);
  }

  final send = _hasWord(text, _send) || _hasPhrase(text, _sendPhrases);
  if (send && sats != null) {
    return WalletCommand(WalletCommandKind.send, sats: sats);
  }
  if (send) return WalletCommand(WalletCommandKind.send);
  if (_hasWord(text, _gallery)) return WalletCommand(WalletCommandKind.gallery);
  if (_hasWord(text, _paste)) return WalletCommand(WalletCommandKind.paste);
  if (_isScan(text)) return WalletCommand(WalletCommandKind.scan);
  return WalletCommand(WalletCommandKind.unknown);
}

/// Erste Zahl im Satz, oder null.
int? parseSpokenSats(String raw) {
  final text = _normalize(raw);
  final digit = RegExp(r'\d{1,3}(?:\.\d{3})+|\d+').firstMatch(text);
  if (digit != null) {
    final n = int.tryParse(digit.group(0)!.replaceAll('.', ''));
    if (n == null || n <= 0 || n > _maxSpokenSats) return null;
    return n;
  }
  return _parseWords(text);
}

String _normalize(String raw) {
  var s = raw.toLowerCase().trim();
  s = s.replaceAll('ß', 'ss');
  s = s.replaceAll('ä', 'ae').replaceAll('ö', 'oe').replaceAll('ü', 'ue');
  s = s.replaceAll(RegExp(r',(?=\d{3}\b)'), '');
  s = s.replaceAll(RegExp(r"[^a-z0-9.\s]"), ' ');
  return s.replaceAll(RegExp(r'\s+'), ' ').trim();
}

const _confirm = {
  'ja',
  'jawohl',
  'yes',
  'yeah',
  'ok',
  'okay',
  'bestaetigen',
  'confirm',
  'klar',
};

const _cancel = {
  'nein',
  'no',
  'abbrechen',
  'stop',
  'stopp',
  'cancel',
  'zurueck',
};

const _outputBoth = {
  'ton und text',
  'text und ton',
  'beides',
  'sound and text',
  'text and sound',
  'both',
};

const _outputSound = {
  'nur ton',
  'nur stimme',
  'ohne text',
  'sound only',
  'voice only',
  'no text',
};

const _outputText = {
  'nur text',
  'ohne ton',
  'kein ton',
  'stumm',
  'text only',
  'no sound',
  'mute',
};

WalletOutput? _outputOf(String text) {
  if (_hasPhrase(text, _outputBoth)) return WalletOutput.both;
  if (_hasPhrase(text, _outputSound)) return WalletOutput.sound;
  if (_hasPhrase(text, _outputText)) return WalletOutput.text;
  return null;
}

const _help = {
  'hilfe',
  'help',
  'befehle',
  'commands',
  'was kann ich',
  'what can i',
};

const _balance = {
  'kontostand',
  'guthaben',
  'balance',
  'wie viel',
  'wieviel',
  'how much',
  'how many',
};

const _scan = {
  'token',
  'tokens',
  'tocken',
  'kamera',
  'camera',
  'foto',
  'photo',
  'qr',
  'code',
  'einloesen',
  'einloese',
  'empfangen',
  'empfang',
  'receive',
  'redeem',
};

const _scanPhrases = {'ku er', 'q r'};

const _paste = {
  'einfuegen',
  'einfugen',
  'paste',
  'zwischenablage',
  'clipboard',
};

const _gallery = {
  'galerie',
  'gallery',
  'album',
  'bild',
  'bilder',
  'upload',
  'screenshot',
};

const _send = {
  'schick',
  'schicke',
  'schicken',
  'sende',
  'senden',
  'send',
  'zahl',
  'pay',
  'ueberweise',
  'ueberweisen',
};

const _sendPhrases = {
  'token senden',
  'token sende',
  'tokensenden',
  'sats senden',
  'sats sende',
  'satssenden',
  'satz senden',
};

bool _exact(String text, Set<String> words) => words.contains(text);

bool _hasPhrase(String text, Set<String> phrases) =>
    phrases.any((p) => text.contains(p));

bool _hasWord(String text, Set<String> words) => words.any((w) {
  return RegExp('(?:^|\\s)${RegExp.escape(w)}(?:\\s|\$)').hasMatch(text);
});

bool _isScan(String text) {
  if (_hasWord(text, _scan) || _hasPhrase(text, _scanPhrases)) return true;
  return text
      .split(' ')
      .any((w) => w.startsWith('scan') || w.startsWith('skan'));
}

bool _startsWithWord(String text, Set<String> words) =>
    words.any((w) => text == w || text.startsWith('$w '));

const _ones = {
  'ein': 1,
  'eins': 1,
  'eine': 1,
  'one': 1,
  'zwei': 2,
  'two': 2,
  'drei': 3,
  'three': 3,
  'vier': 4,
  'four': 4,
  'fuenf': 5,
  'five': 5,
  'sechs': 6,
  'six': 6,
  'sieben': 7,
  'seven': 7,
  'acht': 8,
  'eight': 8,
  'neun': 9,
  'nine': 9,
};

const _teens = {
  'zehn': 10,
  'ten': 10,
  'elf': 11,
  'eleven': 11,
  'zwoelf': 12,
  'twelve': 12,
  'dreizehn': 13,
  'thirteen': 13,
  'vierzehn': 14,
  'fourteen': 14,
  'fuenfzehn': 15,
  'fifteen': 15,
  'sechzehn': 16,
  'sixteen': 16,
  'siebzehn': 17,
  'seventeen': 17,
  'achtzehn': 18,
  'eighteen': 18,
  'neunzehn': 19,
  'nineteen': 19,
};

const _tens = {
  'zwanzig': 20,
  'twenty': 20,
  'dreissig': 30,
  'thirty': 30,
  'vierzig': 40,
  'forty': 40,
  'fuenfzig': 50,
  'fifty': 50,
  'sechzig': 60,
  'sixty': 60,
  'siebzig': 70,
  'seventy': 70,
  'achtzig': 80,
  'eighty': 80,
  'neunzig': 90,
  'ninety': 90,
};

final _undCompound = RegExp(
  r'^(ein|zwei|drei|vier|fuenf|sechs|sieben|acht|neun)und(zwanzig|dreissig|vierzig|fuenfzig|sechzig|siebzig|achtzig|neunzig)$',
);

int? _small(String token) {
  if (_ones.containsKey(token)) return _ones[token];
  if (_teens.containsKey(token)) return _teens[token];
  if (_tens.containsKey(token)) return _tens[token];
  final und = _undCompound.firstMatch(token);
  if (und != null) return _ones[und.group(1)]! + _tens[und.group(2)]!;
  return null;
}

int? _scaled(String token, String suffix, int scale) {
  if (!token.endsWith(suffix) || token == suffix) return null;
  final prefix = token.substring(0, token.length - suffix.length);
  if (prefix.isEmpty) return scale;
  final p = _small(prefix);
  if (p == null || p >= scale) return null;
  return p * scale;
}

int? _parseWords(String text) {
  final tokens = text.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
  var total = 0;
  var current = 0;
  var seen = false;

  for (var i = 0; i < tokens.length; i++) {
    final token = tokens[i];
    if (token == 'und' || token == 'and') continue;

    if ((token == 'a' || token == 'an') &&
        i + 1 < tokens.length &&
        (tokens[i + 1] == 'hundred' || tokens[i + 1] == 'thousand')) {
      current = current == 0 ? 1 : current;
      seen = true;
      continue;
    }

    if (token == 'hundert' || token == 'hundred') {
      current = (current == 0 ? 1 : current) * 100;
      seen = true;
      continue;
    }
    if (token == 'tausend' || token == 'thousand') {
      total += (current == 0 ? 1 : current) * 1000;
      current = 0;
      seen = true;
      continue;
    }

    final asThousand =
        _scaled(token, 'tausend', 1000) ?? _scaled(token, 'thousand', 1000);
    if (asThousand != null) {
      total += asThousand;
      seen = true;
      continue;
    }
    final asHundred =
        _scaled(token, 'hundert', 100) ?? _scaled(token, 'hundred', 100);
    if (asHundred != null) {
      current += asHundred;
      seen = true;
      continue;
    }

    final value = _small(token);
    if (value == null) continue;
    seen = true;
    if (value < 10 && current >= 20 && current < 100 && current % 10 == 0) {
      current += value;
    } else if (value >= 20 && value < 100 && current > 0 && current < 10) {
      current = value + current;
    } else {
      current += value;
    }
  }

  if (!seen) return null;
  final sum = total + current;
  if (sum <= 0 || sum > _maxSpokenSats) return null;
  return sum;
}
