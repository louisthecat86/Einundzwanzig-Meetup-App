import 'package:flutter/material.dart';
import '../theme.dart';

class MarketScreen extends StatelessWidget {
  const MarketScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('P2P / MARKT'), automaticallyImplyLeading: false),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _marketItem("SUCHE", "50€ BARGELD", "Tausche gegen Sats", cCyan),
          _marketItem("BIETE", "COLDCARD MK4", "OVP, 120€", cPurple),
        ],
      ),
    );
  }

  Widget _marketItem(String type, String title, String desc, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      color: cCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), color: color, child: Text(type, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Text(desc, style: const TextStyle(color: Colors.grey)),
            ]),
          ),
        ],
      ),
    );
  }
}