// lib/managers/nfc_manager.dart

import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import '../controllers/home_page_controller.dart';

class NFCManager {
  final HomePageController controller;  // Changed to HomePageController
  final Function(String) onTagRead;
  final Function(String, Color) onShowSnackBar;
  final Function(String) onError;

  NFCManager({
    required this.controller,
    required this.onTagRead,
    required this.onShowSnackBar,
    required this.onError,
  });

  Future<void> startNFCSession() async {
    try {
      debugPrint('Starting NFC session');
      
      bool isAvailable = await NfcManager.instance.isAvailable();
      if (!isAvailable) {
        onShowSnackBar('NFC is not available on this device.', Colors.red);
        return;
      }

      NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          await _handleTagDiscovered(tag);
        },
        onError: (error) async {
          debugPrint('Error in NFC session: $error');
          onError('NFC Session Error: $error');
        },
      );
    } catch (e) {
      debugPrint('Error starting NFC session: $e');
      onError('Error starting NFC session: $e');
    }
  }

  Future<void> _handleTagDiscovered(NfcTag tag) async {
    try {
      debugPrint('Raw tag data: ${tag.data}');

    if (_isSupportedTag(tag)) {
      List<int> identifierBytes = List<int>.from(tag.data['nfca']['identifier']);
      String tagId = identifierBytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join().toUpperCase();
      debugPrint('Hex Tag ID: $tagId');
      onTagRead(tagId);
    } else {
      onShowSnackBar('Unsupported NFC tag type.', Colors.red);
    }
    } catch (e) {
      onError('Error processing NFC tag: $e');
    }
  }

  bool _isSupportedTag(NfcTag tag) {
    return tag.data.containsKey('nfca') && tag.data['nfca']['identifier'] != null;
  }

  void stopSession() {
    NfcManager.instance.stopSession();
  }
}