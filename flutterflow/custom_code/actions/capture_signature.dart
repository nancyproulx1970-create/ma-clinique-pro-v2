// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart';
import '/custom_code/actions/index.dart';
import '/flutter_flow/custom_functions.dart';
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'dart:typed_data';
import 'package:signature/signature.dart';
import '/custom_code/widgets/signature_canvas.dart';

Future<FFUploadedFile?> captureSignature() async {
  final controller = SignatureCanvasController.instance;
  if (controller == null || controller.isEmpty) {
    return null;
  }

  final Uint8List? bytes = await controller.toPngBytes();
  if (bytes == null || bytes.isEmpty) {
    return null;
  }

  return FFUploadedFile(
    name: 'signature.png',
    bytes: bytes,
  );
}
