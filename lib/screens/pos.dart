import 'package:flutter/material.dart';
import '../theme.dart';

class PosScreen extends StatelessWidget {
  const PosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('LIGHTNING / POS'), automaticallyImplyLeading: false),
      body: const Center(child: Text("21.000 SATS", style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: cOrange))),
    );
  }
}