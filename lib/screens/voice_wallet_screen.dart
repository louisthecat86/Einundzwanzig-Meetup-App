import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../services/speech/on_device_speech.dart';
import '../services/speech/on_device_voice.dart';
import '../services/speech/system_on_device_speech.dart';
import '../services/speech/system_on_device_voice.dart';
import '../services/voice_wallet/cashu_image.dart';
import '../services/voice_wallet/clipboard_picture.dart';
import '../services/voice_wallet/cashu_mint.dart';
import '../services/voice_wallet/cashu_token.dart';
import '../services/voice_wallet/cashu_ur.dart';
import '../services/voice_wallet/cashu_wallet.dart';
import '../services/voice_wallet/spoken_reply.dart';
import '../services/voice_wallet/wallet_command.dart';
import '../theme.dart';
import 'cashu_scan_screen.dart';

/// Leere Wallet-Seite. Ein Mikrofon, sonst nichts.
///
/// Scannen löst den Token beim Mint ein. Senden zeigt den neuen Token
/// als QR, der Rest bleibt auf dem Gerät.
class VoiceWalletScreen extends StatefulWidget {
  final OnDeviceSpeech? speech;
  final OnDeviceVoice? voice;
  final CashuWallet? wallet;

  const VoiceWalletScreen({
    super.key,
    this.speech,
    this.voice,
    this.wallet,
  });

  @override
  State<VoiceWalletScreen> createState() => _VoiceWalletScreenState();
}

class _VoiceWalletScreenState extends State<VoiceWalletScreen>
    with SingleTickerProviderStateMixin {
  late final OnDeviceSpeech _speech;
  late final OnDeviceVoice _voice;
  late final CashuWallet _wallet;
  late final AnimationController _pulse;

  bool _listening = false;
  bool _handsFree = false;
  bool _turn = false;
  int _loop = 0;
  bool _busy = false;
  bool _awaitingAmount = false;
  int? _pendingSats;
  String? _outgoing;
  int _watchGen = 0;

  String _primary = '';
  String _caption = '';
  bool _huge = false;
  bool _speaking = false;
  WalletOutput _output = WalletOutput.both;

  static const _outputKey = 'voice_wallet_output_v1';

  @override
  void initState() {
    super.initState();
    _speech = widget.speech ?? SystemOnDeviceSpeech();
    _voice = widget.voice ?? SystemOnDeviceVoice();
    _wallet = widget.wallet ?? CashuWallet();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _loadOutput();
  }

  @override
  void dispose() {
    _handsFree = false;
    _loop++;
    _watchGen++;
    _pulse.dispose();
    _speech.stop();
    _voice.stop();
    super.dispose();
  }

  String _localeId() =>
      onDeviceSpeechLocale(Localizations.localeOf(context).languageCode);

  Future<void> _toggle() async {
    if (_handsFree) {
      await _endLoop();
      return;
    }
    await _voice.stop();
    if (_listening) {
      await _speech.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }
    await _beginListen();
  }

  /// Gehalten: nach jeder Antwort wieder zuhören, bis man tippt oder
  /// noch einmal hält.
  Future<void> _hold() async {
    if (_handsFree) {
      await _endLoop();
      return;
    }
    setState(() => _handsFree = true);
    if (_listening) return;
    await _voice.stop();
    await _beginListen();
  }

  Future<void> _endLoop() async {
    _handsFree = false;
    _loop++;
    await _voice.stop();
    await _speech.stop();
    if (mounted) setState(() => _listening = false);
  }

  Future<void> _beginListen() async {
    final loop = _loop;
    await _voice.stop();
    if (!mounted || loop != _loop) return;
    final failure = await _speech.listen(
      localeId: _localeId(),
      onWords: _onWords,
    );
    if (!mounted || loop != _loop) {
      await _speech.stop();
      return;
    }
    if (failure != null) {
      _handsFree = false;
      final failureText = _failureText(failure);
      setState(() {
        _listening = false;
        _huge = false;
        _primary = failureText;
        _caption = '';
      });
      await _say(failureText);
      return;
    }
    setState(() => _listening = true);
  }

  String _failureText(SpeechFailure failure) {
    final t = AppLocalizations.of(context);
    switch (failure) {
      case SpeechFailure.denied:
        return t.vwSpeechDenied;
      case SpeechFailure.unavailable:
        return Theme.of(context).platform == TargetPlatform.android
            ? t.vwAndroidOff
            : t.vwSpeechOff;
    }
  }

  Future<void> _onWords(String words, bool isFinal) async {
    if (!mounted || _busy || _turn) return;
    if (!isFinal) {
      setState(() {
        _huge = false;
        _primary = words;
        _caption = '';
      });
      return;
    }
    _turn = true;
    final loop = _loop;
    try {
      await _speech.stop();
      if (!mounted || loop != _loop) return;
      setState(() => _listening = false);
      await _apply(words);
      if (!_handsFree || !mounted || loop != _loop) return;
      await Future<void>.delayed(const Duration(milliseconds: 350));
      if (!_handsFree || !mounted || loop != _loop) return;
      await _beginListen();
    } finally {
      _turn = false;
    }
  }

  Future<void> _say(String? text) async {
    if (!mounted || text == null || text.isEmpty) return;
    if (_output == WalletOutput.text) return;
    setState(() => _speaking = true);
    try {
      final language = Localizations.localeOf(context).languageCode;
      await _voice.speak(text, languageCode: language);
    } finally {
      if (mounted) setState(() => _speaking = false);
    }
  }

  Future<void> _loadOutput() async {
    final prefs = await SharedPreferences.getInstance();
    final next = switch (prefs.getString(_outputKey)) {
      'sound' => WalletOutput.sound,
      'text' => WalletOutput.text,
      _ => WalletOutput.both,
    };
    if (!mounted) return;
    setState(() {
      _output = next;
    });
  }

  Future<void> _setOutput(WalletOutput next) async {
    final line = _outputLine(next);
    setState(() {
      _output = next;
      _huge = false;
      _caption = '';
      _primary = next == WalletOutput.sound ? '' : line;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_outputKey, next.name);
    if (!mounted) return;
    await _say(line);
  }

  String _outputLine(WalletOutput mode) {
    final t = AppLocalizations.of(context);
    return switch (mode) {
      WalletOutput.both => t.vwOutBothSay,
      WalletOutput.sound => t.vwOutSoundSay,
      WalletOutput.text => t.vwOutTextSay,
    };
  }

  Future<void> _apply(String words) async {
    final t = AppLocalizations.of(context);
    var command = parseWalletCommand(words);

    if (_awaitingAmount && command.kind == WalletCommandKind.unknown) {
      final sats = parseSpokenSats(words);
      if (sats != null) {
        command = WalletCommand(WalletCommandKind.send, sats: sats);
      }
    }

    if (_pendingSats != null) {
      if (command.kind == WalletCommandKind.confirm) {
        final amount = _pendingSats!;
        _stopWatch();
        setState(() {
          _pendingSats = null;
          _awaitingAmount = false;
          _busy = true;
          _outgoing = null;
          _huge = false;
          _primary = t.vwWorking;
          _caption = '';
        });
        await _send(amount);
        return;
      }
      if (command.kind == WalletCommandKind.cancel) {
        await _clearPending();
        return;
      }
    } else if (command.kind == WalletCommandKind.cancel) {
      await _clearPending();
      return;
    }

    switch (command.kind) {
      case WalletCommandKind.balance:
        _stopWatch();
        setState(() {
          _awaitingAmount = false;
          _pendingSats = null;
          _outgoing = null;
          _busy = true;
          _huge = false;
          _primary = t.vwWorking;
          _caption = '';
        });
        await _showBalance();
      case WalletCommandKind.scan:
        setState(() {
          _awaitingAmount = false;
          _pendingSats = null;
          _outgoing = null;
        });
        await _scan();
      case WalletCommandKind.paste:
        setState(() {
          _awaitingAmount = false;
          _pendingSats = null;
          _outgoing = null;
        });
        await _paste();
      case WalletCommandKind.gallery:
        setState(() {
          _awaitingAmount = false;
          _pendingSats = null;
          _outgoing = null;
        });
        await _gallery();
      case WalletCommandKind.send:
        if (command.sats == null) {
          setState(() {
            _awaitingAmount = true;
            _pendingSats = null;
            _outgoing = null;
            _huge = false;
            _primary = t.vwAskAmount;
            _caption = '';
          });
          await _say(t.vwAskAmount);
          return;
        }
        setState(() {
          _awaitingAmount = false;
          _pendingSats = command.sats;
          _outgoing = null;
          _huge = true;
          _primary = _group(command.sats!);
          _caption = t.vwHintConfirm;
        });
        await _say(spokenReply(amount: command.sats, sentence: t.vwHintConfirm));
      case WalletCommandKind.output:
        await _setOutput(command.output ?? WalletOutput.both);
      case WalletCommandKind.help:
        setState(() {
          _outgoing = null;
          _huge = false;
          _primary = t.vwHelp;
          _caption = '';
        });
        await _say(t.vwHelp);
      case WalletCommandKind.confirm:
      case WalletCommandKind.cancel:
      case WalletCommandKind.unknown:
        {
          final pending = _pendingSats;
          setState(() {
            if (pending != null) {
              _huge = true;
              _primary = _group(pending);
              _caption = t.vwUnknown;
            } else {
              _huge = false;
              _primary = t.vwUnknown;
              _caption = '';
            }
          });
          await _say(spokenReply(amount: pending, sentence: t.vwUnknown));
        }
    }
  }

  Future<void> _clearPending() async {
    _stopWatch();
    await _voice.stop();
    if (!mounted) return;
    setState(() {
      _pendingSats = null;
      _awaitingAmount = false;
      _outgoing = null;
      _huge = false;
      _primary = '';
      _caption = '';
    });
  }

  void _stopWatch() => _watchGen++;

  Future<void> _showBalance() async {
    try {
      final balance = await _wallet.balance();
      if (!mounted) return;
      final t = AppLocalizations.of(context);
      setState(() {
        _busy = false;
        _huge = true;
        _primary = _group(balance);
        _caption = balance == 0 ? t.vwEmpty : t.vwBalanceCaption;
      });
      await _say(spokenReply(amount: balance));
    } on CashuException catch (e) {
      await _showFail(e.fail);
    }
  }

  Future<void> _send(int amount) async {
    try {
      final sent = await _wallet.send(amount);
      if (!mounted) return;
      final t = AppLocalizations.of(context);
      setState(() {
        _busy = false;
        _huge = true;
        _primary = _group(sent.amount);
        _caption = t.vwSent(sent.balance);
        _outgoing = sent.token;
      });
      await _say(
        spokenReply(amount: sent.amount, sentence: t.vwSent(sent.balance)),
      );
    } on CashuException catch (e) {
      await _showFail(e.fail);
    }
  }

  Future<void> _scan() async {
    final code = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => const CashuScanScreen(),
      ),
    );
    if (!mounted || code == null) return;
    await _redeem(code);
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (!mounted) return;
    final t = AppLocalizations.of(context);
    final token = _tokenFromText(text);
    if (token != null) {
      if (token.isEmpty) {
        await _tell(t.vwUrPart);
        return;
      }
      await _redeem(token);
      return;
    }
    final path = await ClipboardPicture.file();
    if (!mounted) return;
    if (path != null) {
      try {
        await _readPicture(path);
      } finally {
        try {
          await File(path).delete();
        } on Object {
          // Die temporäre Datei darf bleiben.
        }
      }
      return;
    }
    await _tell(text.isEmpty ? t.vwClipEmpty : t.vwClipNone);
  }

  String? _tokenFromText(String text) {
    if (text.isEmpty) return null;
    if (urPart(text) != null && cashuReadHint(text) == 'none') {
      final picture = readCashuPicture([Barcode(rawValue: text)]);
      return picture.code ?? '';
    }
    if (cashuReadHint(text) == 'none') return null;
    return text;
  }

  Future<void> _gallery() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (!mounted || file == null) return;
    await _readPicture(file.path);
  }

  Future<void> _readPicture(String path) async {
    final t = AppLocalizations.of(context);
    final scanner = MobileScannerController(autoStart: false);
    try {
      final capture = await scanner.analyzeImage(
        path,
        formats: const [BarcodeFormat.qrCode],
      );
      final barcodes = capture?.barcodes ?? const <Barcode>[];
      final picture = readCashuPicture(barcodes);
      if (picture.code != null) {
        await _redeem(picture.code!);
        return;
      }
      await _tell(picture.partial ? t.vwUrPart : t.vwNotCashu);
    } on Object {
      if (mounted) await _tell(t.vwNotCashu);
    } finally {
      await scanner.dispose();
    }
  }

  Future<void> _redeem(String code) async {
    setState(() {
      _busy = true;
      _outgoing = null;
      _huge = false;
      _primary = AppLocalizations.of(context).vwWorking;
      _caption = '';
    });
    try {
      final received = await _wallet.receive(code);
      if (!mounted) return;
      final t = AppLocalizations.of(context);
      setState(() {
        _busy = false;
        _huge = true;
        _primary = _group(received.received);
        _caption = t.vwReceived(received.balance);
      });
      await _say(
        spokenReply(
          amount: received.received,
          sentence: t.vwReceived(received.balance),
        ),
      );
    } on CashuException catch (e) {
      await _showFail(e.fail, e.detail);
    }
  }

  Future<void> _showFail(CashuFail fail, [String? detail]) async {
    if (!mounted) return;
    final t = AppLocalizations.of(context);
    final text = switch (fail) {
      CashuFail.already => t.vwAlready,
      CashuFail.spent => t.vwSpent,
      CashuFail.notEnough => t.vwNotEnough,
      CashuFail.network => t.vwNet,
      CashuFail.mintRejected => t.vwMintNo,
      CashuFail.badMint => t.vwBadMint,
      CashuFail.unknownKeyset => t.vwUnknownKeyset,
      CashuFail.unsupportedUnit => t.vwOnlySat,
      CashuFail.feeTooHigh => t.vwFeeHigh,
      CashuFail.noSatKey => t.vwNoSat,
      CashuFail.badToken => switch (detail) {
        'lightning' => t.vwLightning,
        'none' => t.vwNotCashu,
        _ => t.vwBadToken,
      },
    };
    final parts = detail?.split(':');
    final caption =
        fail == CashuFail.badToken && parts != null && parts.length == 2
        ? t.vwReadDetail(parts[0], int.tryParse(parts[1]) ?? 0)
        : '';
    setState(() {
      _busy = false;
      _huge = false;
      _outgoing = null;
      _primary = text;
      _caption = caption;
    });
    await _say(text);
  }

  Future<void> _tell(String text) async {
    if (!mounted) return;
    setState(() {
      _busy = false;
      _huge = false;
      _outgoing = null;
      _primary = text;
      _caption = '';
    });
    await _say(text);
  }

  String _group(int sats) {
    final s = sats.toString();
    return s.replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.');
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final pad = MediaQuery.paddingOf(context);
    final soundOnly = _output == WalletOutput.sound && !_listening;
    final hint = _listening
        ? t.vwHintListening
        : (_pendingSats != null
              ? t.vwHintConfirm
              : (_handsFree || soundOnly ? '' : t.vwHintIdle));
    final showDots = soundOnly && (_speaking || _busy);

    // Derselbe Rand links und rechts. Ein einseitiger Zuschlag
    // wuerde Text und Mikrofon aus der Mitte schieben.
    final side = pad.left > pad.right ? pad.left : pad.right;

    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(
        backgroundColor: cDark,
        elevation: 0,
        foregroundColor: cTextSecondary,
        centerTitle: true,
        title: _outputSwitch(t),
      ),
      body: Padding(
        padding: EdgeInsets.fromLTRB(28 + side, 0, 28 + side, 28 + pad.bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Spacer(),
            if (showDots)
              const _SpeakDots()
            else if (!soundOnly)
              SizedBox(
                width: double.infinity,
                child: Text(
                  _primary,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: cText,
                    fontSize: _huge ? 84 : 28,
                    fontWeight: FontWeight.w700,
                    height: 1.05,
                  ),
                ),
              ),
            if (!soundOnly && _caption.isNotEmpty) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: Text(
                  _caption,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: cTextSecondary,
                    fontSize: 18,
                    height: 1.3,
                  ),
                ),
              ),
            ],
            if (_outgoing != null) ...[
              const SizedBox(height: 22),
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(8),
                child: QrImageView(
                  data: _outgoing!,
                  size: _outgoing!.length > 180 ? 260 : 220,
                  errorCorrectionLevel: _outgoing!.length > 180
                      ? QrErrorCorrectLevel.L
                      : QrErrorCorrectLevel.M,
                  padding: EdgeInsets.zero,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(color: Colors.black),
                  dataModuleStyle: const QrDataModuleStyle(color: Colors.black),
                ),
              ),
            ],
            const Spacer(),
            Center(
              child: GestureDetector(
                onTap: _toggle,
                onLongPress: _hold,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 1, end: _listening ? 1.12 : 1.05)
                      .animate(
                        CurvedAnimation(
                          parent: _pulse,
                          curve: Curves.easeInOut,
                        ),
                      ),
                  child: Container(
                    width: 168,
                    height: 168,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cOrange.withValues(
                        alpha: _listening ? 0.22 : 0.12,
                      ),
                      border: Border.all(
                        color: cOrange,
                        width: _listening ? 3 : 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.mic_rounded,
                      color: cOrange,
                      size: 84,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: Text(
                hint,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: cTextTertiary,
                  fontSize: 15,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _outputSwitch(AppLocalizations t) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _outputPill(WalletOutput.both, t.vwOutBoth),
        _outputPill(WalletOutput.sound, t.vwOutSound),
        _outputPill(WalletOutput.text, t.vwOutText),
      ],
    );
  }

  Widget _outputPill(WalletOutput mode, String label) {
    final on = _output == mode;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: GestureDetector(
        onTap: () {
          if (mode != _output) {
            _setOutput(mode);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: on ? cOrange.withValues(alpha: 0.18) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: on ? cOrange : cTileBorder,
              width: on ? 1.4 : 0.6,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: on ? cOrange : cTextTertiary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _SpeakDots extends StatefulWidget {
  const _SpeakDots();

  @override
  State<_SpeakDots> createState() => _SpeakDotsState();
}

class _SpeakDotsState extends State<_SpeakDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounce;

  @override
  void initState() {
    super.initState();
    _bounce = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bounce,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final phase = (_bounce.value + i * 0.18) % 1;
            final lift = phase < 0.5 ? phase * 2 : (1 - phase) * 2;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Transform.translate(
                offset: Offset(0, -14 * lift),
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: cOrange.withValues(alpha: 0.35 + 0.65 * lift),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
