// services/api_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:async';
import '../pages/home_page.dart';


class ApiService {
  Future<String?> fetchData(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return response.body;
      } else {
        debugPrint('Failed to fetch data. Status code: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching data: $e');
      return null;
    }
  }
Future<Map<String, dynamic>> getDeviceNames(String apiIpAddress, {bool useHttps = false}) async {
  try {
    final protocol = useHttps ? 'https' : 'http';
    final url = '$protocol://$apiIpAddress/USOP_RFID/Get_Device_Names.php';
    
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
    );

    debugPrint('Device Names Response: ${response.body}'); // Add debug print

    if (response.statusCode == 200 && response.body.isNotEmpty) {
      final List<dynamic> jsonResponse = jsonDecode(response.body);
      
      // Add debug prints
      debugPrint('Parsed JSON: $jsonResponse');
      
      final scanTypes = Map.fromEntries(
        jsonResponse
          .where((item) => item['Name_'] != null && item['Scan_Type'] != null)
          .map((item) {
            debugPrint('Mapping item: $item'); // Debug each item
            return MapEntry(item['Name_'].toString(), item['Scan_Type'].toString());
          })
      );
      
      debugPrint('Scan Types Map: $scanTypes'); // Debug final map

      return {
        'names': jsonResponse
          .where((item) => item['Name_'] != null)
          .map((item) => item['Name_'].toString())
          .toList(),
        'scan_types': scanTypes,
      };
    }
    return {'names': [], 'scan_types': {}};
  } catch (e) {
    debugPrint('Error in getDeviceNames: $e');
    return {'names': [], 'scan_types': {}};
  }
}

Future<Map<String, dynamic>> fetchMemberData(
  String apiIpAddress,
  String tagId, 
  String deviceName,
  // ignore: non_constant_identifier_names
  String Scan_type,
  {bool useHttps = false}
 ) async {
  final protocol = useHttps ? 'https' : 'http';
  debugPrint('URL tagID: $tagId');
  debugPrint('URL DeviceName: $deviceName');
  debugPrint('URL Scan Type: ${GlobalState.scanType}');
  final url = '$protocol://$apiIpAddress/USOP_RFID/Process_Scan.php?RFID_Tag=$tagId&Device_Name=$deviceName&scan_type=${GlobalState.scanType}';
  
  debugPrint('Making API request to: $url');

  final response = await http.post(
    Uri.parse(url),
    headers: {'Content-Type': 'application/json'},
  ).timeout(
    const Duration(seconds: 10),
    onTimeout: () {
      throw TimeoutException('Request timed out');
    },
  );

  debugPrint('Response status code: ${response.statusCode}');
  debugPrint('Response body: ${response.body}');

  if (response.statusCode == 200) {
    final decodedResponse = jsonDecode(response.body);
    return decodedResponse;
  } else {
    debugPrint('Error status code: ${response.statusCode}');
    throw Exception('Server returned ${response.statusCode}');
  }
}


  Future<bool> insertMemberScan(String apiIpAddress, String tagId, String geoLocation, String deviceName, bool active, String playlevel, {bool useHttps = false}) async {
    final protocol = useHttps ? 'https' : 'http';
    int isActiveInt = active ? -1 : 0;
    final url = '$protocol://$apiIpAddress/NPC_RFID/insert_Member_Scan.php?Tag_ID=$tagId&Geo=$geoLocation&Device=$deviceName&Active=$isActiveInt&Play_Level=$playlevel';

try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        debugPrint('Scan record inserted successfully');
        return true;  // Indicate success
      } else {
        debugPrint('Failed to insert scan record: ${response.reasonPhrase}');
        return false; // Indicate failure
      }
    } catch (e) {
      debugPrint('Error inserting scan record: $e');
      return false; // Indicate failure on exception
    }
  }

  Future<String?> getPasswordFromDb(String apiIpAddress, {bool useHttps = false}) async {
    final protocol = useHttps ? 'https' : 'http';
    final url = '$protocol://$apiIpAddress/USOP_RFID/Get_scanner_PW.php';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        debugPrint('Password API Response: $jsonResponse');
        return jsonResponse['config_Value'];
      } else {
        debugPrint('Failed to retrieve password. Status code: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error retrieving password: $e');
      return null;
    }
  }
}
