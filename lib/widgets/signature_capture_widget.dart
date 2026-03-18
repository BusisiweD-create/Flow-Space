import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../services/signature_service.dart';
import '../services/api_client.dart';
import '../models/user_signature.dart';

class SignatureCaptureWidget extends StatefulWidget {
  final Function(String? signatureData)? onSignatureCaptured;
  final String? existingSignature; // Base64 encoded signature image
  final bool allowSignatureReuse;
  final bool showAuditInfo;
  final String? reportId; // For audit tracking
  
  const SignatureCaptureWidget({
    super.key,
    this.onSignatureCaptured,
    this.existingSignature,
    this.allowSignatureReuse = true,
    this.showAuditInfo = true,
    this.reportId,
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
  bool _showSavedSignatures = false;
  List<UserSignature> _savedSignatures = [];
  UserSignature? _selectedSignature;
  late final SignatureService _signatureService;
  String? _currentSignatureData;
  DateTime? _signatureTime;

  @override
  void initState() {
    super.initState();
    _signatureService = SignatureService(ApiClient());
    _hasSignature = widget.existingSignature != null;
    if (widget.allowSignatureReuse) {
      _loadSavedSignatures();
    }
  }

  Future<void> _loadSavedSignatures() async {
    try {
      final signatures = await _signatureService.getUserSignatures();
      if (mounted) {
        setState(() {
          _savedSignatures = signatures;
        });
      }
    } catch (e) {
      debugPrint('Error loading saved signatures: $e');
    }
  }
  
  @override
  Future<String?> getSignature() async {
    if (_hasSignature) {
      if (_currentSignatureData != null) {
        return _currentSignatureData;
      }
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
    
    // Constrain points to canvas bounds
    final constrainedPoint = _constrainPointToCanvas(point);
    if (constrainedPoint != null) {
      setState(() {
        _points = List.from(_points)..add(constrainedPoint);
        _hasSignature = true;
        _signatureTime = DateTime.now();
        _currentSignatureData = null; // Clear saved signature when drawing new one
        widget.onSignatureCaptured?.call(null); // Notify signature started
      });
    }
  }

  /// Constrain drawing points to stay within canvas boundaries
  Offset? _constrainPointToCanvas(Offset point) {
    const canvasWidth = 400.0; // Approximate canvas width
    const canvasHeight = 150.0; // Canvas height from Container
    const padding = 2.0; // Small padding from edges
    
    final constrainedX = point.dx.clamp(padding, canvasWidth - padding);
    final constrainedY = point.dy.clamp(padding, canvasHeight - padding);
    
    return Offset(constrainedX, constrainedY);
  }

  void _clearSignature() {
    setState(() {
      _points.clear();
      _hasSignature = false;
      _currentSignatureData = null;
      _signatureTime = null;
      _selectedSignature = null;
      widget.onSignatureCaptured?.call(null);
    });
  }

  Future<void> _saveSignatureForReuse() async {
    if (!_hasSignature || _currentSignatureData == null) return;
    
    try {
      await _signatureService.saveSignature(
        _currentSignatureData!,
        'drawn',
        false,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Signature saved for future use'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      // Reload saved signatures
      await _loadSavedSignatures();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving signature: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _useSavedSignature(UserSignature signature) {
    setState(() {
      _selectedSignature = signature;
      _currentSignatureData = signature.signatureData;
      _hasSignature = true;
      _signatureTime = DateTime.now();
      _points.clear(); // Clear drawn points
      widget.onSignatureCaptured?.call(signature.signatureData);
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
      
      setState(() {
        _currentSignatureData = base64Image;
      });
      
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
        Row(
          children: [
            const Text(
              'Digital Signature',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (widget.showAuditInfo && widget.reportId != null) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.verified,
                size: 16,
                color: Colors.green[400],
              ),
              const SizedBox(width: 4),
              Text(
                'Audit Trail Enabled',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.green[400],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Sign your name in the box below to approve this report',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        if (widget.allowSignatureReuse && _savedSignatures.isNotEmpty) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _showSavedSignatures = !_showSavedSignatures;
                    });
                  },
                  icon: Icon(
                    _showSavedSignatures ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 16,
                  ),
                  label: Text(
                    _showSavedSignatures ? 'Hide Saved Signatures' : 'Use Saved Signature',
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ),
              if (_hasSignature && _currentSignatureData != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _saveSignatureForReuse,
                  icon: const Icon(Icons.save, size: 16),
                  tooltip: 'Save signature for future use',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ],
        if (_showSavedSignatures && _savedSignatures.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[600]!),
            ),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(8),
              itemCount: _savedSignatures.length,
              itemBuilder: (context, index) {
                final signature = _savedSignatures[index];
                final isSelected = _selectedSignature?.id == signature.id;
                return GestureDetector(
                  onTap: () => _useSavedSignature(signature),
                  child: Container(
                    width: 120,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue[700] : Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected ? Colors.blue[400]! : Colors.grey[400]!,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.memory(
                              base64Decode(signature.signatureData.split(',').last),
                              height: 60,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return const SizedBox(height: 60);
                              },
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Positioned(
                            top: 2,
                            right: 2,
                            child: Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 16,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          height: 150,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: _hasSignature ? Colors.green[600]! : Colors.grey,
              width: _hasSignature ? 3 : 2,
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRect(
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
                    // Grid pattern for better visual guidance
                    Positioned.fill(
                      child: CustomPaint(
                        painter: GridPainter(),
                      ),
                    ),
                    // Render existing or selected signature
                    if (_currentSignatureData != null)
                      Positioned.fill(
                        child: _buildSignatureImage(_currentSignatureData!),
                      ),
                    if (widget.existingSignature != null && _currentSignatureData == null)
                      Positioned.fill(
                        child: _buildExistingSignature(),
                      ),
                    // Draw signature canvas
                    if (_points.isNotEmpty && _selectedSignature == null)
                      CustomPaint(
                        painter: SignaturePainter(_points),
                        child: const SizedBox.shrink(),
                      ),
                    // Placeholder text
                    if (!_hasSignature && widget.existingSignature == null && _selectedSignature == null)
                      const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.create,
                              size: 32,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Sign here',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Drawing will be constrained to this area',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
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
            if (_hasSignature)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    border: Border.all(color: Colors.green),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Signature captured',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (_signatureTime != null && widget.showAuditInfo)
                              Text(
                                'Signed: ${_signatureTime!.toString().substring(0, 19)}',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontSize: 10,
                                ),
                              ),
                            if (_selectedSignature != null)
                              Text(
                                'Using saved signature: ${_selectedSignature!.signatureTypeDisplay}',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontSize: 10,
                                ),
                              ),
                          ],
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

  /// Build signature image from base64 data
  Widget _buildSignatureImage(String base64Data) {
    try {
      final Uint8List imageBytes = base64Decode(
        base64Data.contains(',') 
          ? base64Data.split(',').last 
          : base64Data
      );
      
      return Image.memory(
        imageBytes,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[200],
            child: const Center(
              child: Text('Failed to load signature'),
            ),
          );
        },
      );
    } catch (e) {
      return Container(
        color: Colors.grey[200],
        child: const Center(
          child: Text('Invalid signature format'),
        ),
      );
    }
  }

  /// Build existing signature with error handling
  Widget _buildExistingSignature() {
    try {
      // Check if existingSignature looks like JSON
      final trimmedData = widget.existingSignature!.trim();
      if (trimmedData.startsWith('{') || trimmedData.startsWith('[') || 
          trimmedData.startsWith('"success"') || trimmedData.startsWith('"error"')) {
        return Container(
          color: Colors.grey[200],
          child: const Center(
            child: Text('Invalid signature data'),
          ),
        );
      }

      final Uint8List imageBytes = base64Decode(
        widget.existingSignature!.contains(',') 
          ? widget.existingSignature!.split(',').last 
          : widget.existingSignature!
      );
      
      return Image.memory(
        imageBytes,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[200],
            child: const Center(
              child: Text('Failed to load signature'),
            ),
          );
        },
      );
    } catch (e) {
      return Container(
        color: Colors.grey[200],
        child: const Center(
          child: Text('Invalid signature format'),
        ),
      );
    }
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

    // Draw the signature with smooth lines
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        // Add smooth line drawing
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(SignaturePainter oldDelegate) =>
      oldDelegate.points != points;
}

/// Grid painter for signature canvas background
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.1)
      ..strokeWidth = 0.5;

    const gridSize = 20.0;
    
    // Draw vertical lines
    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }
    
    // Draw horizontal lines
    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(GridPainter oldDelegate) => false;
}
