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
import 'package:supabase_flutter/supabase_flutter.dart';

class SignatureCanvas extends StatefulWidget {
  const SignatureCanvas({
    super.key,
    this.width,
    this.height,
    this.penColor,
    this.backgroundColor,
    this.existingSignatureUrl,
    this.userId,
    this.triggerExport,
    this.triggerClear,
  });

  final double? width;
  final double? height;
  final Color? penColor;
  final Color? backgroundColor;
  final String? existingSignatureUrl;
  final String? userId;
  final bool? triggerExport;
  final bool? triggerClear;

  @override
  State<SignatureCanvas> createState() => _SignatureCanvasState();
}

class _SignatureCanvasState extends State<SignatureCanvas> {
  late SignatureController _controller;
  bool _isEditing = false;
  bool _showExisting = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _controller = SignatureController(
      penStrokeWidth: 3.0,
      penColor: widget.penColor ?? Colors.black,
      exportBackgroundColor: widget.backgroundColor ?? Colors.white,
      exportPenColor: widget.penColor ?? Colors.black,
    );
    _showExisting = widget.existingSignatureUrl != null &&
        widget.existingSignatureUrl!.isNotEmpty;
  }

  @override
  void didUpdateWidget(covariant SignatureCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.triggerExport == true && oldWidget.triggerExport != true) {
      _handleExport();
    }

    if (widget.triggerClear == true && oldWidget.triggerClear != true) {
      _controller.clear();
      setState(() {
        _isEditing = true;
        _showExisting = false;
      });
    }

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
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleExport() async {
    if (_controller.isEmpty || _isUploading) return;
    if (widget.userId == null || widget.userId!.isEmpty) return;

    setState(() => _isUploading = true);

    try {
      final bytes = await _controller.toPngBytes(
        height: 400,
        width: 1200,
      );
      if (bytes == null || bytes.isEmpty) return;

      final path = '${widget.userId}/signature_pro.png';
      await Supabase.instance.client.storage.from('signatures').uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(upsert: true, contentType: 'image/png'),
      );
    } catch (e) {
      debugPrint('SignatureCanvas export error: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
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

  String _urlWithCacheBust(String url) {
    final separator = url.contains('?') ? '&' : '?';
    return '$url${separator}t=${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.backgroundColor ?? Colors.white;
    final canvasWidth = widget.width ?? 600;
    final canvasHeight = widget.height ?? 200;

    if (_isUploading) {
      return Container(
        width: canvasWidth,
        height: canvasHeight,
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

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
                _urlWithCacheBust(widget.existingSignatureUrl!),
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
