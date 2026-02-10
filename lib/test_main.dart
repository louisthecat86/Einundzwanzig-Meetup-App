import 'package:flutter/material.dart';

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.blue,
        body: Center(
          child: Text(
            "WENN DU DAS SIEHST, GEHT ES!",
            style: TextStyle(color: Colors.white, fontSize: 24),
            textDirection: TextDirection.ltr,
          ),
        ),
      ),
    ),
  );
}