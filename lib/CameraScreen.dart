import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';

class Gemini {
  static Future<GeminiResponse> analyzeImage({
    required Uint8List imageBytes,
    required String prompt,
  }) async {
    // Mock implementation
    await Future.delayed(Duration(seconds: 2));
    return GeminiResponse(shapes: ['circle']); // Mock response
  }
}

class GeminiResponse {
  final List<String> shapes;

  GeminiResponse({required this.shapes});
}

class CameraScreen extends StatefulWidget {
  const CameraScreen({Key? key}) : super(key: key);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  String _extractedShape = ""; // State variable to store extracted shape name

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final firstCamera = cameras.first;

      _controller = CameraController(
        firstCamera,
        ResolutionPreset.high,
      );
      _initializeControllerFuture = _controller.initialize();
      await _initializeControllerFuture;
      setState(() {});
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _captureAndProcessImage(BuildContext context) async {
    try {
      await _initializeControllerFuture;
      final image = await _controller.takePicture();

      final directory = await getTemporaryDirectory();
      final imagePath =
          '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';

      final savedImage = File(imagePath);
      await savedImage.writeAsBytes(await image.readAsBytes());

      Uint8List imageBytes = await savedImage.readAsBytes();

      String extractedShape = await sendToGeminiAPI(imageBytes);
      setState(() {
        _extractedShape =
            extractedShape; // Update state with the extracted shape
      });
      print('Extracted Shapes: $_extractedShape');
    } catch (e) {
      print('Error capturing or processing image: $e');
    }
  }

  Future<String> sendToGeminiAPI(Uint8List imageBytes) async {
    final response = await Gemini.analyzeImage(
      imageBytes: imageBytes,
      prompt:
          "Identify all geometric shapes like rectangle, triangle, square, circle, ellipse, hexagon, and complex geometries from the image. Provide only the most suitable one shape name.",
    );

    return response.shapes.first; // Return the first shape
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Camera Screen'),
      ),
      body: Column(
        children: [
          Expanded(child: CameraPreview(_controller)),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _extractedShape.isNotEmpty
                  ? 'Extracted Shape: $_extractedShape'
                  : 'No shape extracted yet.',
              style: TextStyle(fontSize: 20),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.camera),
        onPressed: () => _captureAndProcessImage(context),
      ),
    );
  }
}
