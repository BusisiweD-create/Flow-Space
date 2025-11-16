import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class SignatureCaptureWidget extends StatefulWidget {
  final Function(String? signatureData)? onSignatureCaptured;
  final String? existingSignature; // Base64 encoded signature image
  
  const SignatureCaptureWidget({
    super.key,
    this.onSignatureCaptured,
    this.existingSignature,
  });

  @override
  State<SignatureCaptureWidget> createState() => _SignatureCaptureWidgetState();
}

// Export the state class for external access
abstract class SignatureCaptureWidgetState extends State<SignatureCaptureWidget> {
  Future<String?> getSignature();
}

// Make the private state class extend the abstract one

class _SignatureCaptureWidgetState extends SignatureCaptureWidgetState {
  final GlobalKey _signatureKey = GlobalKey();
  List<Offset?> _points = <Offset?>[];
  bool _hasSignature = false;

  @override
  void initState() {
    super.initState();
    _hasSignature = widget.existingSignature != null;
  }
  
  @override
  Future<String?> getSignature() async {
    if (_hasSignature) {
      return await _captureSignature();
    }
    return widget.existingSignature;
  }

  void _addPoint(Offset? point) {
    if (point == null) {
      setState(() {
        _points = List.from(_points)..add(null);
      });
      return;
    }
    setState(() {
      _points = List.from(_points)..add(point);
      _hasSignature = true;
      widget.onSignatureCaptured?.call(null); // Notify signature started
    });
  }

  void _clearSignature() {
    setState(() {
      _points.clear();
      _hasSignature = false;
      widget.onSignatureCaptured?.call(null);
    });
  }

  Future<String?> _captureSignature() async {
    try {
      final RenderRepaintBoundary boundary = _signatureKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List pngBytes = byteData!.buffer.asUint8List();
      final String base64Image = base64Encode(pngBytes);
      widget.onSignatureCaptured?.call(base64Image);
      return base64Image;
    } catch (e) {
      debugPrint('Error capturing signature: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Digital Signature',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Sign your name in the box below to approve this report',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          height: 150,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: GestureDetector(
            onPanUpdate: (DragUpdateDetails details) {
              final RenderBox? renderBox =
                  context.findRenderObject() as RenderBox?;
              if (renderBox != null) {
                final Offset localPosition =
                    renderBox.globalToLocal(details.globalPosition);
                _addPoint(localPosition);
              }
            },
            onPanEnd: (DragEndDetails details) {
              _addPoint(null);
            },
            child: RepaintBoundary(
              key: _signatureKey,
                child: Stack(
                  children: [
                    // Render existing signature if available
                    if (widget.existingSignature != null)
                      Positioned.fill(
                        child: Image.memory(
                          base64Decode(widget.existingSignature!),
                          fit: BoxFit.contain,
                        ),
                      ),
                    // Draw signature canvas
                    CustomPaint(
                      painter: SignaturePainter(_points),
                      child: _hasSignature || widget.existingSignature != null
                          ? null
                          : const Center(
                              child: Text(
                                'Sign here',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _hasSignature ? _clearSignature : null,
              icon: const Icon(Icons.clear, size: 18),
              label: const Text('Clear'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[700],
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            if (widget.existingSignature != null)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    border: Border.all(color: Colors.green),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Signature captured',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class SignaturePainter extends CustomPainter {
  final List<Offset?> points;

  SignaturePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.black
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;

    // If there's an existing signature (base64), render it
    // For now, we'll just draw the points
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(SignaturePainter oldDelegate) =>
      oldDelegate.points != points;
}

