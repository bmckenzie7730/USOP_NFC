import 'package:flutter/material.dart';
import 'user_info_card.dart';
import 'loading_overlay.dart';
import 'dart:typed_data';

class UserInterface extends StatelessWidget {
  final bool hasScanned;
  final bool? isActive;
  final bool isLoading;
  final TextEditingController geoLocationController;
  final TextEditingController fullNameController;
  final TextEditingController foodController;
  final TextEditingController drinkController;
  final TextEditingController nfcDataController;
  final Uint8List? pictureData;
  final VoidCallback onSettingsPressed;
  final VoidCallback onDeviceNamePressed;
  final VoidCallback onExitPressed;
  final VoidCallback onTitleDoubleTap;
  final String deviceName;

  const UserInterface({
    super.key,
    required this.hasScanned,
    required this.isActive,
    required this.isLoading,
    required this.geoLocationController,
    required this.fullNameController,
    required this.foodController,
    required this.drinkController,
    required this.nfcDataController,
    required this.pictureData,
    required this.onSettingsPressed,
    required this.onDeviceNamePressed,
    required this.onExitPressed,
    required this.onTitleDoubleTap,
    required this.deviceName,
  });
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onDoubleTap: onTitleDoubleTap,
          child: Text('USOP Guest Access - $deviceName', // Display device name here
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        centerTitle: true,
        //leading: Image.asset('assets/pickleball.png', height: 60, width: 60),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'Settings') onSettingsPressed();
              if (value == 'DeviceName') onDeviceNamePressed();
              if (value == 'Exit') onExitPressed();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Settings', child: Text('Settings')),
              const PopupMenuItem(value: 'DeviceName', child: Text('Device Name')),
              const PopupMenuItem(value: 'Exit', child: Text('Exit')),
            ],
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: hasScanned
                ? (isActive == true ? Colors.green : Colors.red)
                : Colors.transparent,
            width: 30.0,
          ),
        ),
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildLogo(),
                  const SizedBox(height: 10),
                  _buildUserInfoCard(),
                ],
              ),
            ),
            if (isLoading) const LoadingOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Center(
      child: Image.asset(
        'assets/USOP Logo.png',
        height: 120,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Logo load error: $error');
          return const Text(
            'Logo could not be loaded',
            style: TextStyle(fontSize: 16, color: Colors.red),
          );
        },
      ),
    );
  }

Widget _buildUserInfoCard() {
  return UserInfoCard(
    geoLocationController: geoLocationController,
    fullNameController: fullNameController,
    foodController: foodController,
    drinkController: drinkController,
    nfcDataController: nfcDataController,
    pictureData: pictureData,
    imageSize: 330.0,
    fullNameLabelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: Colors.black),
    geoLocationLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: Colors.black),
    nfcDataLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: Colors.black),
    fullNameTextStyle: const TextStyle(fontSize: 30, fontWeight: FontWeight.normal, color: Colors.black),
    geoLocationTextStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: Colors.black),
    nfcDataTextStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: Colors.black),
  );
}
}
