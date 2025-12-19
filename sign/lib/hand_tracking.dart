import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

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

  @override
  void initState() {
    super.initState();
    _lockPortraitMode();
    _setupCameraController();
  }

  @override
  void dispose() {
    cameraController?.dispose();
    super.dispose();
  }

  // Lock the orientation to portrait mode.
  void _lockPortraitMode() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Translation Page"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: _buildUI(),
    );
  }

  Widget _buildUI() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFB2EBF2), Color(0xFFCE93D8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: _isCameraInitialized
          ? Stack(
        children: [
          // Center the camera preview using AspectRatio and Transform.
          Positioned.fill(
            child: Center(
              child: Transform(
                alignment: Alignment.center,
                // Rotate by +90° (clockwise) to match the orientation of the capture version.
                transform: Matrix4.rotationZ(90 * math.pi / 180),
                child: AspectRatio(
                  aspectRatio:
                  1 / cameraController!.value.aspectRatio,
                  child: CameraPreview(cameraController!),
                ),
              ),
            ),
          ),
          // Overlay for real-time translation result.
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(10),
              color: Colors.black.withOpacity(0.5),
              child: Text(
                _translationResult,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      )
          : Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.camera_alt, size: 80, color: Colors.black),
            const SizedBox(height: 20),
            const Text(
              'Camera initializing...',
              style: TextStyle(fontSize: 20, color: Colors.black),
            ),
            ElevatedButton(
              onPressed: _setupCameraController,
              child: const Text('Retry Camera'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setupCameraController() async {
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

        // Start processing frames in real time.
        cameraController!.startImageStream((CameraImage image) {
          if (!_isProcessingFrame) {
            _processFrame(image);
          }
        });
      }
    } catch (e) {
      print("Error initializing camera: $e");
    }
  }

  Future<void> _processFrame(CameraImage image) async {
    _isProcessingFrame = true;

    // Dummy processing: simulate a delay and update the translation result.
    // Replace this with your actual model inference.
    await Future.delayed(const Duration(milliseconds: 100));
    setState(() {
      _translationResult = "Detected sign: Hello";
    });

    _isProcessingFrame = false;
  }
}
