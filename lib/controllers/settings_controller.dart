import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../utils/ui_helpers.dart';
import '../pages/settings_page.dart';
import '../pages/home_page.dart';  // For GlobalState

class SettingsController {
  final ApiService apiService;
  final BuildContext context;
  final Function(String, String, bool) onSettingsChanged;
  late SharedPreferences _prefs;

  SettingsController({
    required this.apiService,
    required this.context,
    required this.onSettingsChanged,
  });

  Future<void> loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    String apiIpAddress = _prefs.getString('apiIpAddress') ?? 'not defined';
    String deviceName = _prefs.getString('deviceName') ?? 'Not Defined';
    bool useHttps = _prefs.getBool('useHttps') ?? false;
    
    // Load scan type and set to GlobalState
    String scanType = _prefs.getString('scanType') ?? '';
    GlobalState.scanType = scanType;
    
    debugPrint('🔍 DEBUG: loadSettings - Loaded scanType from storage: "$scanType"');
    debugPrint('🔍 DEBUG: loadSettings - GlobalState.scanType set to: "${GlobalState.scanType}"');
    
    onSettingsChanged(apiIpAddress, deviceName, useHttps);
  }

  Future<void> saveSettings(String apiIpAddress, LocationAccuracy accuracy, bool useHttps) async {
    _prefs = await SharedPreferences.getInstance();
    await _prefs.setString('apiIpAddress', apiIpAddress);
    await _prefs.setBool('useHttps', useHttps);

    String deviceName = _prefs.getString('deviceName') ?? 'Not Defined';
    onSettingsChanged(apiIpAddress, deviceName, useHttps);
  }

  Future<void> updateDeviceName(String newDeviceName) async {
    _prefs = await SharedPreferences.getInstance();
    await _prefs.setString('deviceName', newDeviceName);
    
    String apiIpAddress = _prefs.getString('apiIpAddress') ?? 'not defined';
    bool useHttps = _prefs.getBool('useHttps') ?? false;
    onSettingsChanged(apiIpAddress, newDeviceName, useHttps);
  }

  Future<void> updateScanType(String newScanType) async {
    // Ensure _prefs is initialized
    _prefs = await SharedPreferences.getInstance();
    
    debugPrint('🔍 DEBUG: updateScanType - Saving scanType to storage: "$newScanType"');
    await _prefs.setString('scanType', newScanType);
    GlobalState.scanType = newScanType;
    debugPrint('🔍 DEBUG: updateScanType - GlobalState.scanType set to: "${GlobalState.scanType}"');
    debugPrint('🔍 DEBUG: updateScanType - Verifying save: Storage now has: "${_prefs.getString('scanType')}"');
  }

  Future<String?> getScanType() async {
    _prefs = await SharedPreferences.getInstance();
    String? scanType = _prefs.getString('scanType');
    debugPrint('🔍 DEBUG: getScanType - Retrieved from storage: "$scanType"');
    return scanType;
  }

  Future<void> showPasswordDialog({bool bypassPassword = false}) async {
    if (bypassPassword) {
      _navigateToSettings();
      return;
    }

    _prefs = await SharedPreferences.getInstance();
    await UIHelpers.showPasswordDialog(
      context: context,
      getPassword: () => apiService.getPasswordFromDb(
        _prefs.getString('apiIpAddress') ?? '',
        useHttps: _prefs.getBool('useHttps') ?? false,
      ),
      onSuccess: _navigateToSettings,
    );
  }

  void _navigateToSettings() async {
    _prefs = await SharedPreferences.getInstance();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsPage(
          initialIp: _prefs.getString('apiIpAddress') ?? '',
          initialAccuracy: LocationAccuracy.high,
          initialUseHttps: _prefs.getBool('useHttps') ?? false,
          onSettingsChanged: (newIp, newAccuracy, newUseHttps) {
            saveSettings(newIp, newAccuracy, newUseHttps);
          },
        ),
      ),
    );
  }
}