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

import 'package:signature/signature.dart';
import '/custom_code/widgets/signature_canvas.dart';

Future<bool> hasSignatureDrawn() async {
  final controller = SignatureCanvasController.instance;
  if (controller == null) return false;
  return controller.isNotEmpty;
}
