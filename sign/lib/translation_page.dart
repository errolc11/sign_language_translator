import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as imglib;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart'; // for compute()

class TranslationPage extends StatefulWidget {
  @override
  _TranslationPageState createState() => _TranslationPageState();
}

class _TranslationPageState extends State<TranslationPage> {
  List<CameraDescription> cameras = [];
  CameraController? cameraController;
  bool _isCameraInitialized = false;
  bool _isProcessingFrame = false;
  String _translationResult = "Translating...";
  List<List<double>> handKeypointsList = []; // Each detected hand’s keypoints (flat list of 63 floats)
  String interpretedGesture = "";
  int _frameCount = 0; // Throttle frame processing

  // Text-to-Speech variables.
  String lastGesture = "";
  DateTime? lastSpokenTime;
  FlutterTts flutterTts = FlutterTts();

  // Update this URL to match your Flask backend.
  final String backendUrl = 'http://172.20.10.4:5000/detect_hand';

  @override
  void initState() {
    super.initState();
    _setupCamera();
    flutterTts.setLanguage("en-US");
    flutterTts.setPitch(1.0);
  }

  @override
  void dispose() {
    cameraController?.stopImageStream();
    cameraController?.dispose();
    flutterTts.stop();
    super.dispose();
  }

  Future<void> _setupCamera() async {
    try {
      cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        cameraController = CameraController(
          cameras.first,
          ResolutionPreset.high,
          enableAudio: false,
        );
        await cameraController!.initialize();
        if (!mounted) return;
        setState(() {
          _isCameraInitialized = true;
        });
        // Process every 2nd frame to reduce delay.
        cameraController!.startImageStream((CameraImage image) {
          _frameCount++;
          if (_frameCount % 2 == 0 && !_isProcessingFrame) {
            _isProcessingFrame = true;
            _processCameraImage(image);
          }
        });
      }
    } catch (e) {
      print("Error setting up camera: $e");
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    try {
      // Convert the camera image to JPEG in a separate isolate.
      Uint8List jpegBytes = await compute(convertCameraImageToJpeg, image);
      String base64Image = base64Encode(jpegBytes);

      final response = await http.post(
        Uri.parse(backendUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'image': base64Image}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['keypoints'] != null) {
          List<List<double>> keys;
          if (data['keypoints'] is List && data['keypoints'].isNotEmpty) {
            // If a single hand is detected, the backend may return a flat list.
            if (data['keypoints'][0] is num) {
              keys = [List<double>.from(data['keypoints'])];
            } else {
              keys = (data['keypoints'] as List)
                  .map((h) => List<double>.from(h))
                  .toList();
            }
          } else {
            keys = [];
          }
          // The backend returns a single gesture string.
          String gestureText = data['gesture'] ?? "Unknown";
          // If the classifier returns "Unknown", you can choose to display "Sign not recognized".
          if (gestureText.toLowerCase() == "unknown") {
            gestureText = "Sign not recognized";
          }
          if (!mounted) return;
          setState(() {
            handKeypointsList = keys;
            interpretedGesture = gestureText;
            _translationResult = "Detected Gesture: $interpretedGesture";
          });

          print("Gesture Received: $interpretedGesture");
          print("Keypoints received: $handKeypointsList");

          // Use TTS to speak if the gesture changed.
          if (interpretedGesture.isNotEmpty && interpretedGesture != lastGesture) {
            await flutterTts.speak(interpretedGesture);
            lastGesture = interpretedGesture;
            lastSpokenTime = DateTime.now();
          }
        } else {
          if (!mounted) return;
          setState(() {
            _translationResult = "No hand detected";
            handKeypointsList = [];
            interpretedGesture = "";
          });
        }
      } else {
        if (!mounted) return;
        setState(() {
          _translationResult = "Server error: ${response.statusCode}";
        });
      }
    } catch (e) {
      print("Error processing frame: $e");
      if (!mounted) return;
      setState(() {
        _translationResult = "Error processing frame";
      });
    }
    _isProcessingFrame = false;
  }

  // Convert YUV420 CameraImage to JPEG in a separate isolate.
  static Uint8List convertCameraImageToJpeg(CameraImage image) {
    try {
      imglib.Image rgbImage = convertYUV420ToImageStatic(image);
      return Uint8List.fromList(imglib.encodeJpg(rgbImage));
    } catch (e) {
      print("Conversion error in isolate: $e");
      return Uint8List(0);
    }
  }

  // Converts a YUV420 CameraImage to an imglib.Image.
  static imglib.Image convertYUV420ToImageStatic(CameraImage image) {
    final int width = image.width;
    final int height = image.height;
    imglib.Image rgbImage = imglib.Image(width, height);

    final int uvRowStride = image.planes[1].bytesPerRow;
    final int uvPixelStride = image.planes[1].bytesPerPixel ?? 1;

    for (int y = 0; y < height; y++) {
      final int uvRow = y >> 1;
      for (int x = 0; x < width; x++) {
        final int uvCol = x >> 1;
        final int indexY = y * image.planes[0].bytesPerRow + x;
        final int indexU = uvRow * uvRowStride + uvCol * uvPixelStride;
        final int indexV = uvRow * image.planes[2].bytesPerRow + uvCol * (image.planes[2].bytesPerPixel ?? 1);

        final int yValue = image.planes[0].bytes[indexY];
        final int uValue = image.planes[1].bytes[indexU];
        final int vValue = image.planes[2].bytes[indexV];

        int r = (yValue + 1.402 * (vValue - 128)).round();
        int g = (yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128)).round();
        int b = (yValue + 1.772 * (uValue - 128)).round();

        r = r.clamp(0, 255);
        g = g.clamp(0, 255);
        b = b.clamp(0, 255);

        rgbImage.setPixelRgba(x, y, r, g, b, 255);
      }
    }
    return rgbImage;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Translation Page")),
      body: _isCameraInitialized
          ? Stack(
        children: [
          // Rotated camera preview (quarterTurns: 1 rotates preview 90° clockwise).
          Positioned.fill(
            child: RotatedBox(
              quarterTurns: 1,
              child: CameraPreview(cameraController!),
            ),
          ),
          // Skeletal overlay on top of the preview.
          Positioned.fill(
            child: CustomPaint(
              painter: HandSkeletonPainter(handKeypointsList: handKeypointsList),
            ),
          ),
          // Bottom overlay to display the gesture result.
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: EdgeInsets.all(8),
              color: Colors.black.withOpacity(0.5),
              child: Text(
                "$_translationResult\nGesture: $interpretedGesture",
                style: TextStyle(color: Colors.white, fontSize: 20),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      )
          : Center(child: CircularProgressIndicator()),
    );
  }
}

class HandSkeletonPainter extends CustomPainter {
  final List<List<double>> handKeypointsList;
  final double offsetX;
  final double offsetY;

  HandSkeletonPainter({
    required this.handKeypointsList,
    this.offsetX = 0.0,
    this.offsetY = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // For a RotatedBox with quarterTurns: 1, the preview is rotated 90° clockwise.
    // To align the skeletal overlay, we map normalized coordinates using:
    //   newX = (1 - y) * width
    //   newY = x * height
    for (var hand in handKeypointsList) {
      if (hand.isEmpty || hand.length % 3 != 0) continue;
      List<Map<String, double>> keypoints = [];
      for (int i = 0; i < hand.length; i += 3) {
        keypoints.add({
          'x': hand[i],
          'y': hand[i + 1],
          'z': hand[i + 2],
        });
      }
      List<Offset> points = [];
      for (var kp in keypoints) {
        double x = kp['x']!;
        double y = kp['y']!;
        double newX = (1 - y) * size.width + offsetX;
        double newY = x * size.height + offsetY;
        points.add(Offset(newX, newY));
      }
      // Define standard Mediapipe hand connections.
      final List<List<int>> connections = [
        [0, 1], [1, 2], [2, 3], [3, 4],         // Thumb
        [0, 5], [5, 6], [6, 7], [7, 8],         // Index finger
        [0, 9], [9, 10], [10, 11], [11, 12],    // Middle finger
        [0, 13], [13, 14], [14, 15], [15, 16],   // Ring finger
        [0, 17], [17, 18], [18, 19], [19, 20],   // Pinky
      ];
      final pointPaint = Paint()
        ..color = Colors.red
        ..style = PaintingStyle.fill;
      final linePaint = Paint()
        ..color = Colors.green
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;
      for (var connection in connections) {
        int start = connection[0];
        int end = connection[1];
        if (start < points.length && end < points.length) {
          canvas.drawLine(points[start], points[end], linePaint);
        }
      }
      for (var pt in points) {
        canvas.drawCircle(pt, 5, pointPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
