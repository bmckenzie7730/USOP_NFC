// lib/pages/home_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import '../controllers/member_data_controller.dart';
import '../controllers/settings_controller.dart';
import '../controllers/home_page_controller.dart';
import '../managers/location_manager.dart';
import '../managers/nfc_manager.dart';
import '../widgets/user_interface.dart';
import '../services/api_service.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class GlobalState {
  static String scanType = '';
}

class HomePageState extends State<HomePage> with WidgetsBindingObserver {
  // Controllers and managers - initialized in initState
  late final HomePageController homePageController;
  late final MemberDataController memberDataController;
  late final SettingsController settingsController;
  late final LocationManager locationManager;
  late final NFCManager nfcManager;
  
  // State
  bool isLoading = false;
  bool hasScanned = false;
  String apiIpAddress = '';
  String deviceName = '';
  bool useHttps = false;
  bool? isActive;
  Uint8List? pictureData;
  List<String> deviceNames = [];

  // Controllers for UI
  final TextEditingController geoLocationController = TextEditingController();
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController foodController = TextEditingController();
  final TextEditingController drinkController = TextEditingController();
  final TextEditingController nfcDataController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeControllers();
  }

  Future<Uint8List?> _loadDefaultImage() async {
    try {
      final ByteData data = await rootBundle.load('assets/transferguy.png');
      return data.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error loading default image: $e');
      return null;
    }
  }

  void _showIpAddressWarning() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Configuration Required'),
          content: const Text('Please set the API IP Address before using the application.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                settingsController.showPasswordDialog();
              },
              child: const Text('Configure Now'),
            ),
          ],
        );
      },
    );
  }

  void _initializeControllers() {
    debugPrint('🔍 DEBUG: _initializeControllers started');
    final apiService = ApiService();
    
    homePageController = HomePageController(apiService: apiService);

    memberDataController = MemberDataController(
      apiService: apiService,
      onShowSnackBar: _showSnackBar,
      onMemberDataUpdated: _updateMemberData,
      onError: _handleError,
      onLoadingStateChanged: _setLoadingState,
    );

    settingsController = SettingsController(
      apiService: apiService,
      context: context,
      onSettingsChanged: (String newIp, String newDeviceName, bool newUseHttps) async {
        setState(() {
          apiIpAddress = newIp;
          useHttps = newUseHttps;
        });
        await _loadDeviceNames();
        // Remove automatic device name selection
        if (deviceNames.contains(newDeviceName)) {
          setState(() {
            deviceName = newDeviceName;
          });
        } else {
          _showDeviceNameSelectionDialog();
        }
      },
    );

    locationManager = LocationManager(
      context: context,
      onLocationUpdated: _handleLocationUpdate,
      onShowSnackBar: _showSnackBar,
    );

    nfcManager = NFCManager(
      controller: homePageController,
      onTagRead: _handleTagRead,
      onShowSnackBar: _showSnackBar,
      onError: _handleError,
    );

    _initializeServices();
  }

  Future<void> _initializeServices() async {
    debugPrint('🔍 DEBUG: Starting _initializeServices');
    
    await locationManager.initialize();
    locationManager.startLocationUpdates();
    
    nfcManager.startNFCSession();

    debugPrint('🔍 DEBUG: Loading settings...');
    await settingsController.loadSettings();
    
    debugPrint('🔍 DEBUG: Current API IP Address: "$apiIpAddress"');
    
    Future.delayed(const Duration(milliseconds: 500), () {
      debugPrint('🔍 DEBUG: Checking IP Address after delay: "$apiIpAddress"');
      if (apiIpAddress == '' || 
          apiIpAddress.isEmpty || 
          apiIpAddress == 'API IP Address' || 
          apiIpAddress == 'not defined') {
        debugPrint('🔍 DEBUG: Showing IP Address warning');
        _showIpAddressWarning();
      } else {
        // Only load device names if IP is set
        _loadDeviceNames().then((_) {
          // Check if device name needs to be selected
          if (deviceName.isEmpty || !deviceNames.contains(deviceName)) {
            _showDeviceNameSelectionDialog();
          }
        });
      }
    });
  }

  Future<void> _loadDeviceNames() async {
    debugPrint('Starting _loadDeviceNames');
    debugPrint('Current API address: $apiIpAddress');
    debugPrint('HTTPS enabled: $useHttps');
    
    try {
      final response = await settingsController.apiService.getDeviceNames(
        apiIpAddress,
        useHttps: useHttps,
      );
      
      debugPrint('Received response from API: $response');
      
      setState(() {
        deviceNames = (response['names'] as List<String>)..sort();
        debugPrint('Updated deviceNames state: $deviceNames');
        
        // Remove auto-selection of first device
        if (!deviceNames.contains(deviceName)) {
          deviceName = '';
          GlobalState.scanType = '';
        }
      });
    } catch (e) {
      debugPrint('Error loading device names: $e');
      setState(() {
        deviceNames = [];
        deviceName = '';
        GlobalState.scanType = '';
      });
    }
  }

  void _handleLocationUpdate(Position? position) {
    if (position != null) {
      setState(() {
        geoLocationController.text = '${position.latitude}, ${position.longitude}';
      });
    }
  }

  void _handleTagRead(String tagId) {
    if (deviceName.isEmpty) {
      _showSnackBar('Please select a device name first', Colors.red);
      _showDeviceNameSelectionDialog();
      return;
    }
    
    setState(() {
      nfcDataController.text = tagId;
      if (locationManager.currentLocation != null) {
        final position = locationManager.currentLocation!;
        geoLocationController.text = '${position.latitude}, ${position.longitude}';
      }
    });

    memberDataController.fetchAndDisplayMemberData(
      tagId,
      locationManager.currentLocation,
      apiIpAddress: apiIpAddress,
      deviceName: deviceName,
      useHttps: useHttps,
      context: context,
    );
  }

void _updateMemberData(Map<String, dynamic> memberData) async {
    Uint8List? imageData = memberDataController.getImageFromBase64(memberData['picture']);
    
    // Only load default image if we have a valid member (has either first or last name)
    // but they're missing a picture
    bool hasName = (memberData['first_name']?.toString().trim().isNotEmpty == true) || 
                  (memberData['last_name']?.toString().trim().isNotEmpty == true);
    
    if (imageData == null && hasName) {
      imageData = await _loadDefaultImage();
    }
    
    setState(() {
      fullNameController.text = '${memberData['first_name']} ${memberData['last_name']}';
      foodController.text = memberData['food_remaining']?.toString() ?? '0';
      drinkController.text = memberData['drink_remaining']?.toString() ?? '0';
      pictureData = imageData;
      isActive = memberData['status']?.toLowerCase() == 'yes';
      hasScanned = true;
    });
}

void _handleError(String error, {String? tagId}) {
  _clearFields();
  setState(() {
    if (tagId != null) {
      nfcDataController.text = tagId;
    }
    isActive = false;
    hasScanned = true;
    if (error == 'Member not found') {
      pictureData = null;
      isLoading = true;  // Prevent new scans while dialog is showing
    }
  });
  
  if (error == 'Member not found') {
    showDialog(
      context: context,
      barrierDismissible: false,  // Force user to click OK
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Member Not Found'),
          content: Text('No member found with Tag ID: ${tagId ?? "Unknown"}'),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  isLoading = false;  // Re-enable scanning
                });
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  } else {
    _showSnackBar(error, Colors.red);
  }
}

  void _setLoadingState(bool loading) {
    setState(() {
      isLoading = loading;
    });
  }

  void _clearFields() {
    setState(() {
      fullNameController.clear();
      foodController.clear();
      drinkController.clear();
      geoLocationController.clear();
      nfcDataController.clear();
      pictureData = null;
      isActive = null;
    });
  }

  void _showSnackBar(String message, Color color, {Duration? duration}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Center(child: Text(message)),
        backgroundColor: color,
        duration: duration ?? const Duration(seconds: 10),
      ),
    );
  }

  void _showDeviceNameSelectionDialog() {
    debugPrint('🚀 DIALOG: Opening forced device name selection dialog');
    debugPrint('📋 DIALOG: Available device names: $deviceNames');
    
    if (deviceNames.isEmpty) {
      debugPrint('⚠️ DIALOG: Device names list is empty, triggering load');
      _loadDeviceNames().then((_) {
        debugPrint('✅ DIALOG: Finished loading device names: $deviceNames');
        if (deviceNames.isNotEmpty) {
          _showDeviceNameSelectionDialog();
        }
      });
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false, // User must select a device
      builder: (BuildContext context) {
        String? selectedDevice;
        
        return AlertDialog(
          title: const Text('Select Device Name'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Please select a device name to continue'),
                  const SizedBox(height: 16),
                  DropdownButton<String>(
                    value: selectedDevice,
                    hint: const Text('Select a device name'),
                    isExpanded: true,
                    items: deviceNames.map<DropdownMenuItem<String>>((String name) {
                      return DropdownMenuItem<String>(
                        value: name,
                        child: Text(name),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedDevice = newValue;
                      });
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (selectedDevice != null) {
                  final response = await settingsController.apiService.getDeviceNames(
                    apiIpAddress,
                    useHttps: useHttps,
                  );
                  
                  setState(() {
                    deviceName = selectedDevice!;
                    GlobalState.scanType = response['scan_types'][selectedDevice] ?? '';
                  });
                  
                  debugPrint('Selected device: $selectedDevice');
                  debugPrint('Set scan type: ${GlobalState.scanType}');
                  
                  await settingsController.updateDeviceName(selectedDevice!);
                  Navigator.pop(context);
                } else {
                  _showSnackBar('Please select a device name', Colors.red);
                }
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  void _showDeviceNameDialog() {
    if (deviceName.isEmpty) {
      _showDeviceNameSelectionDialog();
      return;
    }
    
    debugPrint('🚀 DIALOG: Opening device name dialog');
    debugPrint('📱 DIALOG: Current device name: $deviceName');
    debugPrint('📋 DIALOG: Available device names: $deviceNames');
    debugPrint('🌐 DIALOG: API Address: $apiIpAddress');
    debugPrint('🔒 DIALOG: HTTPS enabled: $useHttps');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        debugPrint('🏗️ DIALOG: Building dialog widget');
        return AlertDialog(
          title: const Text('Select Device Name'),
          content: SizedBox(
            width: double.maxFinite,
            child: deviceNames.isEmpty 
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('No device names available'),
                    ElevatedButton(
                      onPressed: () {
                        debugPrint('🔄 DIALOG: Retry button pressed');
                        Navigator.pop(context);
                        _loadDeviceNames().then((_) {
                          debugPrint('✅ DIALOG: Retry load finished, device names: $deviceNames');
                          _showDeviceNameDialog();
                        });
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                )
              : DropdownButton<String>(
                  value: deviceName,
                  hint: const Text('Select a device name'),
                  isExpanded: true,
                  items: deviceNames.map<DropdownMenuItem<String>>((String name) {
                    return DropdownMenuItem<String>(
                      value: name,
                      child: Text(name),
                    );
                  }).toList(),
                  onChanged: (String? newValue) async {
                    if (newValue != null) {
                      final response = await settingsController.apiService.getDeviceNames(
                        apiIpAddress,
                        useHttps: useHttps,
                      );
                      
                      setState(() {
                        deviceName = newValue;
                        GlobalState.scanType = response['scan_types'][newValue] ?? '';
                      });
                      
                      debugPrint('Selected device: $newValue');
                      debugPrint('Set scan type: ${GlobalState.scanType}');
                      
                      await settingsController.updateDeviceName(newValue);
                      Navigator.pop(context);
                    }
                  },
                ),
          ),
        );
      },
    );
  }

  Future<void> _exitApp() async {
    locationManager.dispose();
    nfcManager.stopSession();
    if (Platform.isAndroid) {
      SystemNavigator.pop();
    } else if (Platform.isIOS) {
      exit(0);
    }
  }

  @override
  void dispose() {
    locationManager.dispose();
    nfcManager.stopSession();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return UserInterface(
      hasScanned: hasScanned,
      isActive: isActive,
      isLoading: isLoading,
      geoLocationController: geoLocationController,
      fullNameController: fullNameController,
      foodController: foodController,
      drinkController: drinkController,
      nfcDataController: nfcDataController,
      pictureData: pictureData,
      onSettingsPressed: () => settingsController.showPasswordDialog(),
      onDeviceNamePressed: _showDeviceNameDialog,
      onExitPressed: _exitApp,
      onTitleDoubleTap: () => settingsController.showPasswordDialog(bypassPassword: true),
      deviceName: deviceName,
    );
  }
}