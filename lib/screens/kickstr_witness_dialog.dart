import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/kickstr_witness.dart';

/// Price field after scanning the QR on Kickstr `/forecast`.
class KickstrWitnessDialog extends StatefulWidget {
  final KickstrRound round;

  const KickstrWitnessDialog({super.key, required this.round});

  @override
  State<KickstrWitnessDialog> createState() => _KickstrWitnessDialogState();
}

class _KickstrWitnessDialogState extends State<KickstrWitnessDialog> {
  final _name = TextEditingController();
  final _price = TextEditingController();
  final _lud16 = TextEditingController();
  int _badges = 0;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    KickstrWitness.heldBadges().then((badges) {
      if (mounted) setState(() => _badges = badges.length);
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _lud16.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    final price = int.tryParse(_price.text.trim());
    if (name.isEmpty || name.length > 24 || price == null || price <= 0) {
      setState(() => _error = 'Name und ein Preis in ganzen Dollar.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final error = await KickstrWitness.submit(
        round: widget.round,
        name: name,
        price: price,
        lud16: _lud16.text,
      );
      if (!mounted) return;
      if (error == null) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _busy = false;
          _error = _text(error);
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Kickstr nicht erreicht.';
      });
    }
  }

  String _text(String error) {
    switch (error) {
      case 'round_closed':
        return 'Die Runde ist gerade zu.';
      case 'badge_unproven':
        return 'Die Badge-Claims passen nicht zum Schlüssel.';
      case 'clock_off':
        return 'Die Uhr dieses Geräts geht um mehr als zwei Minuten falsch.';
      case 'invalid_guess':
        return 'Name und ein Preis in ganzen Dollar.';
      default:
        return 'Der Tipp wurde nicht angenommen.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Kickstr bezeugen'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _badges == 1
                  ? 'Signiert mit deinem Schlüssel. 1 Badge-Claim geht mit.'
                  : 'Signiert mit deinem Schlüssel. $_badges Badge-Claims gehen mit.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              maxLength: 24,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Name', counterText: ''),
            ),
            TextField(
              controller: _price,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'Bitcoin-Preis in USD'),
            ),
            TextField(
              controller: _lud16,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Lightning-Adresse, optional'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: Text(_busy ? '…' : 'Tippen'),
        ),
      ],
    );
  }
}
