import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'dart:io';

class OcrScanner extends StatefulWidget {
  final Function(String) onTextDetected;

  const OcrScanner({super.key, required this.onTextDetected});

  @override
  State<OcrScanner> createState() => _OcrScannerState();
}

class _OcrScannerState extends State<OcrScanner> {
  CameraController? _controller;
  final TextRecognizer _textRecognizer = TextRecognizer();
  bool _isProcessing = false;
  bool _isVisible = true;
  List<CameraDescription>? _cameras;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      _controller = CameraController(
        _cameras![0],
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await _controller?.initialize();
      if (!mounted) return;

      _controller?.startImageStream((image) => _processCameraImage(image));
      setState(() {});
    }
  }

  void _processCameraImage(CameraImage image) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final InputImage inputImage = _inputImageFromCameraImage(image);
      final RecognizedText recognizedText = await _textRecognizer.processImage(
        inputImage,
      );

      final List<TextElement> allElements = [];
      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          final String text = line.text.replaceAll(RegExp(r'\s+'), '');

          // 1. Standard horizontal detection (e.g., 123456)
          if (RegExp(r'^\d{4,10}$').hasMatch(text)) {
            widget.onTextDetected(text);
            await Future.delayed(const Duration(seconds: 2));
            return;
          }

          for (TextElement element in line.elements) {
            allElements.add(element);
          }
        }
      }

      // 2. Vertical Digit Detection (for medical records with vertical boxes)
      // Group elements by X-coordinate (similar column)
      final Map<int, List<TextElement>> columns = {};
      for (var element in allElements) {
        // Filter for single digits or small numeric chunks
        if (RegExp(r'^\d{1,2}$').hasMatch(element.text)) {
          final x =
              element.boundingBox.left.toInt() ~/ 20; // Group by 20px bins
          columns.putIfAbsent(x, () => []).add(element);
        }
      }

      for (var col in columns.values) {
        if (col.length >= 4) {
          // Typical RM has 6 digits, allow 4+ for vertical
          col.sort((a, b) => a.boundingBox.top.compareTo(b.boundingBox.top));
          final String combined = col.map((e) => e.text).join('');
          if (combined.length >= 6 && combined.length <= 10) {
            widget.onTextDetected(combined);
            await Future.delayed(const Duration(seconds: 2));
            return;
          }
        }
      }
    } catch (e) {
      debugPrint("OCR Error: $e");
    } finally {
      _isProcessing = false;
    }
  }

  InputImage _inputImageFromCameraImage(CameraImage image) {
    final sensorOrientation = _cameras![0].sensorOrientation;
    final InputImageRotation rotation =
        InputImageRotationValue.fromRawValue(sensorOrientation) ??
        InputImageRotation.rotation0deg;
    final InputImageFormat format =
        InputImageFormatValue.fromRawValue(image.format.raw) ??
        InputImageFormat.nv21;

    final plane = image.planes[0];

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return VisibilityDetector(
      key: const Key('ocr_camera'),
      onVisibilityChanged: (visibilityInfo) {
        final visiblePercentage = visibilityInfo.visibleFraction * 100;
        if (visiblePercentage < 10 && _isVisible) {
          _isVisible = false;
          _controller?.stopImageStream();
        } else if (visiblePercentage > 80 && !_isVisible) {
          _isVisible = true;
          _controller?.startImageStream((image) => _processCameraImage(image));
        }
      },
      child: CameraPreview(_controller!),
    );
  }
}
