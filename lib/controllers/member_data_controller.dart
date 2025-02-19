// lib/controllers/member_data_controller.dart

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

class MemberDataController {
  final ApiService apiService;
  final Function(String, Color, {Duration? duration}) onShowSnackBar;
  final Function(Map<String, dynamic>) onMemberDataUpdated;
  final Function(String, {String? tagId}) onError;
  final Function(bool) onLoadingStateChanged;

  MemberDataController({
    required this.apiService,
    required this.onShowSnackBar,
    required this.onMemberDataUpdated,
    required this.onError,
    required this.onLoadingStateChanged,
  });

  Future<void> fetchAndDisplayMemberData(
    String tagId, 
    Position? position, {
      required String apiIpAddress,
      required String deviceName,
      required bool useHttps,
      required BuildContext context,
    }) async {
    onLoadingStateChanged(true);
    debugPrint('Starting fetchAndDisplayMemberData for tagId: $tagId');

    // Check connectivity first
    final connectivity = Connectivity();
    final connectivityResult = await connectivity.checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      onLoadingStateChanged(false);
      await _showNoConnectivityDialog(context);
      return;
    }

    try {
      final memberData = await _fetchMemberData(
        tagId, 
        apiIpAddress, 
        useHttps,
        position,
        deviceName,
        context,
      );

      debugPrint('Processing memberData response: $memberData');

      if (memberData['message'] == 'no_record_found') {
        debugPrint('Handling no record found case');
        // Clear all member data and set border to red
        final clearedData = {
          'first_name': "",
          'last_name': "",
          'picture': null,
          'food_remaining': null,
          'drink_remaining': null,
          'status': 'error',
          'border_color': 'red',  // Add border color information
        };
        onMemberDataUpdated(clearedData);
        await _showNoRecordDialog(context);
      } else if (memberData['status'] == 'error') {
        debugPrint('Handling error case: ${memberData['message']}');
        // Connection error dialog already shown in _fetchMemberData if needed
      } else {
        debugPrint('Handling successful member data case');
        // Add default border color for successful case
        memberData['border_color'] = 'default';
        onMemberDataUpdated(memberData);
      }
    } catch (e) {
      debugPrint('Error caught in fetchAndDisplayMemberData: $e');
      onError('Error fetching member data: $e', tagId: tagId);
    } finally {
      onLoadingStateChanged(false);
    }
  }

  Future<Map<String, dynamic>> _fetchMemberData(
    String tagId,
    String apiIpAddress,
    bool useHttps,
    Position? position,
    String deviceName,
    BuildContext context,
  ) async {
    debugPrint('Fetching member data for tagId: $tagId');
    debugPrint('API IP: $apiIpAddress, useHttps: $useHttps');
    
    try {
      final response = await apiService.fetchMemberData(
        apiIpAddress,
        tagId,
        deviceName,
        deviceName,
        useHttps: useHttps,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Unable to connect to the server.');
        },
      );

      debugPrint('API Response received: ${response.toString()}');
      
      // Handle successful API response
      if (response != null) {
        // Check if both first_name and last_name are null to determine if no record was found
        if ((response['first_name'] == null || response['first_name'].toString().trim().isEmpty) && 
          (response['last_name'] == null || response['last_name'].toString().trim().isEmpty)) {
          debugPrint('No record found (null names)');
          return {
            'status': 'error',
            'message': 'no_record_found'
          };
        } else {
          debugPrint('Member data found');
          return response;
        }
      } else {
        debugPrint('Null response received');
        return {
          'status': 'error',
          'message': 'invalid_response'
        };
      }
        
    } on SocketException catch (e) {
      debugPrint('Socket Exception in _fetchMemberData: $e');
      await _showServerConnectionDialog(context);
      return {
        'status': 'error',
        'message': 'server_connection_error'
      };
    } on TimeoutException catch (e) {
      debugPrint('Timeout in _fetchMemberData: $e');
      await _showServerConnectionDialog(context);
      return {
        'status': 'error',
        'message': 'server_connection_error'
      };
    } catch (e) {
      debugPrint('Unexpected error in _fetchMemberData: $e');
      await _showServerConnectionDialog(context);
      return {
        'status': 'error',
        'message': 'server_connection_error'
      };
    }
  }

  Future<void> _showNoRecordDialog(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('No Record Found'),
          content: const Text('No record was found for this ID.'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showServerConnectionDialog(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Connection Error'),
          content: const Text('Unable to connect to the server.'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showNoConnectivityDialog(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('No Internet Connection'),
          content: const Text(
            'Please enable WiFi or mobile data to continue. The app requires an internet connection to fetch member data.'
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Uint8List? getImageFromBase64(String? base64String) {
    if (base64String == null || base64String.isEmpty) {
      return null;
    }

    try {
      return base64Decode(base64String);
    } catch (e) {
      debugPrint('Error decoding base64 image: $e');
      return null;
    }
  }
}