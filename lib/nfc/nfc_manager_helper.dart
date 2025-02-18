// nfc_manager_helper.dart
import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';

void startNfcSessionWithHelper(Function(NfcTag) onTagDetected) {
  debugPrint('startNfcSessionWithHelper called');

  NfcManager.instance.startSession(
    onDiscovered: (tag) async {
      debugPrint('Tag detected in helper: ${tag.runtimeType}');
      onTagDetected(tag);
    },
  );
}
