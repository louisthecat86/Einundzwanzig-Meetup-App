import 'dart:convert';

import 'package:einundzwanzig_meetup_app/services/voice_wallet/cashu_token.dart';
import 'package:flutter_test/flutter_test.dart';

String _token(Object json) => 'cashuA${base64Url.encode(utf8.encode(jsonEncode(json)))}';

void main() {
  test('cashuA summiert die Proofs in Satoshi', () {
    final token = _token({
      'token': [
        {
          'mint': 'https://mint.example',
          'proofs': [
            {'amount': 21, 'id': '00', 'secret': 'a', 'C': 'b'},
            {'amount': 2, 'id': '00', 'secret': 'c', 'C': 'd'},
          ],
        },
      ],
      'unit': 'sat',
    });

    final peek = peekCashuToken(token);
    expect(peek.isCashu, isTrue);
    expect(peek.sats, 23);
  });

  test('cashuB und andere Einheiten bleiben ohne Betrag', () {
    expect(peekCashuToken('cashuBabc').isCashu, isTrue);
    expect(peekCashuToken('cashuBabc').sats, isNull);

    final msat = _token({
      'token': [
        {
          'proofs': [
            {'amount': 1000},
          ],
        },
      ],
      'unit': 'msat',
    });
    expect(peekCashuToken(msat).isCashu, isTrue);
    expect(peekCashuToken(msat).sats, isNull);
  });

  test('normaler Text ist kein Token', () {
    expect(peekCashuToken('21v3:irgendwas').isCashu, isFalse);
  });

  test('cashuB aus der Spezifikation hat den Betrag 4', () {
    const token =
        'cashuBo2F0gqJhaUgA_9SLj17PgGFwgaNhYQFhc3hAYWNjMTI0MzVlN2I4NDg0YzNjZjE4NTAxNDkyMThhZjkwZjcxNmE1MmJmNGE1ZWQzNDdlNDhlY2MxM2Y3NzM4OGFjWCECRFODGd5IXVW-07KaZCvuWHk3WrnnpiDhHki6SCQh88-iYWlIAK0mjE0fWCZhcIKjYWECYXN4QDEzMjNkM2Q0NzA3YTU4YWQyZTIzYWRhNGU5ZjFmNDlmNWE1YjRhYzdiNzA4ZWIwZDYxZjczOGY0ODMwN2U4ZWVhY1ghAjRWqhENhLSsdHrr2Cw7AFrKUL9Ffr1XN6RBT6w659lNo2FhAWFzeEA1NmJjYmNiYjdjYzY0MDZiM2ZhNWQ1N2QyMTc0ZjRlZmY4YjQ0MDJiMTc2OTI2ZDNhNTdkM2MzZGNiYjU5ZDU3YWNYIQJzEpxXGeWZN5qXSmJjY8MzxWyvwObQGr5G1YCCgHicY2FtdWh0dHA6Ly9sb2NhbGhvc3Q6MzMzOGF1Y3NhdA';
    final parsed = parseCashuToken(token);
    expect(parsed.mint, 'http://localhost:3338');
    expect(parsed.sats, 4);
    expect(peekCashuToken(token).sats, 4);
  });

  test('Token in einem Link und mit normalem Base64', () {
    const wrapped =
        'https://wallet.example/redeem#cashuBo2F0gqJhaUgA_9SLj17PgGFwgaNhYQFhc3hAYWNjMTI0MzVlN2I4NDg0YzNjZjE4NTAxNDkyMThhZjkwZjcxNmE1MmJmNGE1ZWQzNDdlNDhlY2MxM2Y3NzM4OGFjWCECRFODGd5IXVW-07KaZCvuWHk3WrnnpiDhHki6SCQh88-iYWlIAK0mjE0fWCZhcIKjYWECYXN4QDEzMjNkM2Q0NzA3YTU4YWQyZTIzYWRhNGU5ZjFmNDlmNWE1YjRhYzdiNzA4ZWIwZDYxZjczOGY0ODMwN2U4ZWVhY1ghAjRWqhENhLSsdHrr2Cw7AFrKUL9Ffr1XN6RBT6w659lNo2FhAWFzeEA1NmJjYmNiYjdjYzY0MDZiM2ZhNWQ1N2QyMTc0ZjRlZmY4YjQ0MDJiMTc2OTI2ZDNhNTdkM2MzZGNiYjU5ZDU3YWNYIQJzEpxXGeWZN5qXSmJjY8MzxWyvwObQGr5G1YCCgHicY2FtdWh0dHA6Ly9sb2NhbGhvc3Q6MzMzOGF1Y3NhdA danke';
    expect(parseCashuToken(wrapped).sats, 4);

    const spec =
        'cashuBo2F0gqJhaUgA_9SLj17PgGFwgaNhYQFhc3hAYWNjMTI0MzVlN2I4NDg0YzNjZjE4NTAxNDkyMThhZjkwZjcxNmE1MmJmNGE1ZWQzNDdlNDhlY2MxM2Y3NzM4OGFjWCECRFODGd5IXVW-07KaZCvuWHk3WrnnpiDhHki6SCQh88-iYWlIAK0mjE0fWCZhcIKjYWECYXN4QDEzMjNkM2Q0NzA3YTU4YWQyZTIzYWRhNGU5ZjFmNDlmNWE1YjRhYzdiNzA4ZWIwZDYxZjczOGY0ODMwN2U4ZWVhY1ghAjRWqhENhLSsdHrr2Cw7AFrKUL9Ffr1XN6RBT6w659lNo2FhAWFzeEA1NmJjYmNiYjdjYzY0MDZiM2ZhNWQ1N2QyMTc0ZjRlZmY4YjQ0MDJiMTc2OTI2ZDNhNTdkM2MzZGNiYjU5ZDU3YWNYIQJzEpxXGeWZN5qXSmJjY8MzxWyvwObQGr5G1YCCgHicY2FtdWh0dHA6Ly9sb2NhbGhvc3Q6MzMzOGF1Y3NhdA';
    final standard = spec.replaceAll('-', '+').replaceAll('_', '/');
    expect(parseCashuToken(standard).sats, 4);
    expect(parseCashuToken(spec.replaceFirst('cashuB', 'CASHUB')).sats, 4);
    expect(cashuReadHint(spec).startsWith('B:'), isTrue);
    expect(cashuReadHint('lnbc1qqq'), 'lightning');
    expect(cashuReadHint('hallo'), 'none');
  });
}
