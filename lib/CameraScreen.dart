import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:arcore_flutter_plugin/arcore_flutter_plugin.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

class Gemini {
  static Future<GeminiResponse> analyzeImage({
    required Uint8List imageBytes,
    required String prompt,
    required dynamic http,
  }) async {
    final String apiUrl = 'https://your-api-endpoint.com/analyze_image';
    final Map<String, dynamic> requestBody = {
      'image': base64Encode(imageBytes),
      'prompt': prompt,
    };

    try {
      final http.Response response = await httpClient.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        List<String> shapes = List<String>.from(responseData['shapes'] ?? []);

        return GeminiResponse(shapes: shapes);
      } else {
        print('Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to analyze image');
      }
    } catch (e) {
      print('Error analyzing image: $e');
      throw Exception('Error analyzing image');
    }
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
  String _extractedShape = "";
  ArCoreController? arCoreController;

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
    arCoreController?.dispose();
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
        _extractedShape = extractedShape;
      });
      print('Extracted Shapes: $_extractedShape');

      if (_extractedShape.isNotEmpty) {
        _addShapeToAR(_extractedShape);
      }
    } catch (e) {
      print('Error capturing or processing image: $e');
    }
  }

  Future<String> sendToGeminiAPI(Uint8List imageBytes) async {
    final response = await Gemini.analyzeImage(
      imageBytes: imageBytes,
      prompt:
          "Identify all geometric shapes like rectangle, triangle, square, circle, ellipse, hexagon, and complex geometries from the image. Provide only the most suitable one shape name.",
      http: null,
    );

    return response.shapes.first;
  }

  void _addShapeToAR(String shape) {
    if (arCoreController == null) return;

    ArCoreMaterial material;
    ArCoreNode node;

    switch (shape.toLowerCase()) {
      case 'circle':
        material = ArCoreMaterial(color: Colors.blue);
        final sphere = ArCoreSphere(materials: [material], radius: 0.1);
        node = ArCoreNode(shape: sphere, position: vector.Vector3(0, 0, -1));
        break;
      case 'square':
        material = ArCoreMaterial(color: Colors.red);
        final cube = ArCoreCube(
            materials: [material], size: vector.Vector3(0.2, 0.2, 0.2));
        node = ArCoreNode(shape: cube, position: vector.Vector3(0, 0, -1));
        break;

      default:
        return;
    }

    arCoreController?.addArCoreNode(node);
  }

  void _onArCoreViewCreated(ArCoreController controller) {
    arCoreController = controller;
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
          Expanded(
            child: Stack(
              children: [
                CameraPreview(_controller),
                ArCoreView(
                  onArCoreViewCreated: _onArCoreViewCreated,
                ),
              ],
            ),
          ),
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
