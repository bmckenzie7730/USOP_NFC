// controllers/home_page_controller.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../services/api_service.dart';

class HomePageController {
  final ApiService apiService;

  HomePageController({required this.apiService});

  Future<void> loadSettings(Function(String, String) updateSettings) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String apiIpAddress = prefs.getString('apiIpAddress') ?? '';
      String deviceName = prefs.getString('deviceName') ?? 'Not Defined';
      updateSettings(apiIpAddress, deviceName);
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }

  Future<Position> fetchGeoLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied.');
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      debugPrint('Current Position: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      debugPrint('Error fetching geolocation: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> fetchMemberData(String apiIpAddress, String rfidTag) async {
    String apiUrl = '$apiIpAddress/USOP_RFID/Process_Scan.php?RFID_Tag=$rfidTag';
    debugPrint('API URL: $apiUrl');

    try {
      final response = await apiService.fetchData(apiUrl);
      if (response != null) {
        debugPrint('Raw API Response: $response');
        final parsedData = json.decode(response);
        debugPrint('Parsed JSON Data: $parsedData');
        return parsedData;
      } else {
        debugPrint('No response from the server or response is null.');
        return null;
      }
    } catch (e) {
      debugPrint('Error during API call or JSON parsing: $e');
      return null;
    }
  }

  String convertIdentifier(List<int> identifierBytes) {
    debugPrint('Converting bytes: $identifierBytes');
    
    // Calculate the Tag ID as an integer using the original bit-shift logic
    int tagIdInt = (identifierBytes[3] << 24) |
                   (identifierBytes[2] << 16) |
                   (identifierBytes[1] << 8) |
                   identifierBytes[0];
                   
    debugPrint('Integer value after bit shifting: $tagIdInt');
    
    // Convert to a decimal string and pad with leading zeros to ensure a length of 10
    String tagIdDecimal = tagIdInt.toString().padLeft(10, '0');
    debugPrint('Final tag ID: $tagIdDecimal');
    
    return tagIdDecimal;
  }
}

  Uint8List? getImageFromBase64(String base64String) {
    try {
      if (base64String.isNotEmpty && base64String != 'File not found') {
        debugPrint('Decoding base64 image string.');
        return base64Decode(base64String);
      } else {
        debugPrint('Empty or invalid image string.');
        return null;
      }
    } catch (e) {
      debugPrint('Error decoding base64 image: $e');
      return null;
    }
  }

