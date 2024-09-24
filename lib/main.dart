import 'package:flutter/material.dart';
import 'package:lastandfinal/constant.dart'; // Ensure this file exists
import 'package:flutter_gemini/flutter_gemini.dart' as flutter_gemini;
import 'package:lastandfinal/cameraScreen.dart';

void main() {
  flutter_gemini.Gemini.init(
    apiKey: GEMINI_API_KEY, // Ensure GEMINI_API_KEY is defined
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: CameraScreen(), // This should be your entry point
    );
  }
}
