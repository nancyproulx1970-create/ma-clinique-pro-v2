// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart';
import '/custom_code/actions/index.dart';
import '/flutter_flow/custom_functions.dart';
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'package:signature/signature.dart';

class SignatureCanvasController {
  static SignatureController? instance;
}

class SignatureCanvas extends StatefulWidget {
  const SignatureCanvas({
    super.key,
    this.width,
    this.height,
    this.penColor,
    this.backgroundColor,
    this.existingSignatureUrl,
  });

  final double? width;
  final double? height;
  final Color? penColor;
  final Color? backgroundColor;
  final String? existingSignatureUrl;

  @override
  State<SignatureCanvas> createState() => _SignatureCanvasState();
}

class _SignatureCanvasState extends State<SignatureCanvas> {
  late SignatureController _controller;
  bool _isEditing = false;
  bool _showExisting = false;

  @override
  void initState() {
    super.initState();
    _controller = SignatureController(
      penStrokeWidth: 2.5,
      penColor: widget.penColor ?? Colors.black,
      exportBackgroundColor: widget.backgroundColor ?? Colors.white,
      exportPenColor: widget.penColor ?? Colors.black,
    );
    SignatureCanvasController.instance = _controller;
    _showExisting = widget.existingSignatureUrl != null &&
        widget.existingSignatureUrl!.isNotEmpty;
  }

  @override
  void didUpdateWidget(covariant SignatureCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.existingSignatureUrl != oldWidget.existingSignatureUrl) {
      setState(() {
        _showExisting = widget.existingSignatureUrl != null &&
            widget.existingSignatureUrl!.isNotEmpty;
        if (_showExisting) _isEditing = false;
      });
    }
  }

  @override
  void dispose() {
    if (SignatureCanvasController.instance == _controller) {
      SignatureCanvasController.instance = null;
    }
    _controller.dispose();
    super.dispose();
  }

  void _switchToEditing() {
    _controller.clear();
    setState(() {
      _showExisting = false;
      _isEditing = true;
    });
  }

  void _activateEditing() {
    setState(() => _isEditing = true);
  }

  void _deactivateEditing() {
    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.backgroundColor ?? Colors.white;
    final canvasWidth = widget.width ?? 380;
    final canvasHeight = widget.height ?? 160;

    // Mode 1: Show existing signature image
    if (_showExisting) {
      return Container(
        width: canvasWidth,
        height: canvasHeight,
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Image.network(
                widget.existingSignatureUrl!,
                width: canvasWidth,
                height: canvasHeight,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Center(
                  child: Icon(Icons.broken_image,
                      size: 32, color: Colors.grey.shade400),
                ),
              ),
            ),
            Positioned(
              bottom: 6,
              right: 6,
              child: GestureDetector(
                onTap: _switchToEditing,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit, size: 14, color: Colors.grey.shade700),
                      const SizedBox(width: 4),
                      Text(
                        'Modifier',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Mode 2: Canvas for drawing
    return Container(
      width: canvasWidth,
      height: canvasHeight,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(
          color: _isEditing ? Colors.blue.shade400 : Colors.grey.shade300,
          width: _isEditing ? 2.0 : 1.0,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: Stack(
          children: [
            IgnorePointer(
              ignoring: !_isEditing,
              child: Signature(
                controller: _controller,
                backgroundColor: bgColor,
              ),
            ),
            if (!_isEditing)
              Positioned.fill(
                child: GestureDetector(
                  onTap: _activateEditing,
                  child: Container(
                    color: Colors.white.withOpacity(0.6),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.touch_app,
                            size: 20, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Text(
                          'Appuyez pour signer',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (_isEditing)
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: _deactivateEditing,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '✓ Terminé',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
