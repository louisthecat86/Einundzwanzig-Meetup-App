import 'package:http/http.dart' as http;
import 'dart:convert';

class MempoolService {
  static const String _baseUrl = 'https://mempool.space/api';

  // Holt die aktuelle Blockhöhe (Tip Height)
  static Future<int> getBlockHeight() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/blocks/tip/height'));
      
      if (response.statusCode == 200) {
        // Die API gibt einfach nur eine Zahl zurück (z.B. 829450)
        return int.parse(response.body);
      } else {
        return 0; // Fehler
      }
    } catch (e) {
      print("Mempool Fehler: $e");
      return 0; // Offline oder Fehler
    }
  }
}