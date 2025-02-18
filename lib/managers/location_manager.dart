// lib/managers/location_manager.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationManager {
  Position? _cachedLocation;
  Timer? _locationUpdateTimer;
  bool _isUpdatingLocation = false;
  final Function(Position?) onLocationUpdated;
  final Function(String, Color) onShowSnackBar;
  final BuildContext context;

  LocationManager({
    required this.context,
    required this.onLocationUpdated,
    required this.onShowSnackBar,
  });

  Position? get currentLocation => _cachedLocation;

  Future<void> initialize() async {
    await _checkLocationPermission();
  }

  Future<void> startLocationUpdates() async {
    if (_locationUpdateTimer != null) return;

    try {
      _cachedLocation = await _getLocation();
      onLocationUpdated(_cachedLocation);
      
      _locationUpdateTimer = Timer.periodic(
        const Duration(seconds: 120),
        (timer) async => _updateLocationIfNotBusy(),
      );
    } catch (e) {
      debugPrint('Location initialization error: $e');
      onShowSnackBar('Unable to get location.', Colors.orange);
    }
  }

  Future<void> _updateLocationIfNotBusy() async {
    if (_isUpdatingLocation) return;
    _isUpdatingLocation = true;
    
    try {
      Position? newLocation = await _getLocation();
      if (newLocation != null) {
        _cachedLocation = newLocation;
        onLocationUpdated(newLocation);
      }
    } finally {
      _isUpdatingLocation = false;
    }
  }

  Future<Position?> _getLocation() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int savedAccuracyIndex = prefs.getInt('selectedAccuracy') ?? LocationAccuracy.high.index;
      LocationAccuracy desiredAccuracy = LocationAccuracy.values[savedAccuracyIndex];

      // First try to get the last known position
      Position? lastKnownPosition = await Geolocator.getLastKnownPosition();
      
      // Start getting current position in background
      Geolocator.getCurrentPosition(
        desiredAccuracy: desiredAccuracy,
      ).then((Position position) {
        _cachedLocation = position;
        onLocationUpdated(position);
      }).catchError((error) {
        debugPrint('Error getting current position: $error');
      });

      // Return last known position if available, otherwise wait for current position
      return lastKnownPosition ?? await Geolocator.getCurrentPosition(
        desiredAccuracy: desiredAccuracy,
      ).timeout(const Duration(seconds: 5));
      
    } catch (e) {
      debugPrint('Error getting location: $e');
      return null;
    }
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showLocationServicesDialog();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showLocationPermissionDeniedDialog();
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showLocationPermissionPermanentlyDeniedDialog();
      return;
    }
  }

  void _showLocationServicesDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Services Disabled'),
          content: const Text(
            'Location services are disabled. Please enable location services in your device settings to continue.'
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Open Settings'),
              onPressed: () async {
                await Geolocator.openLocationSettings();
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showLocationPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Permission Required'),
          content: const Text(
            'This app needs location permission to function properly. Please grant location permission.'
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
                _checkLocationPermission();
              },
            ),
          ],
        );
      },
    );
  }

  void _showLocationPermissionPermanentlyDeniedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Permission Denied'),
          content: const Text(
            'Location permission is permanently denied. Please enable it in app settings.'
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Open Settings'),
              onPressed: () async {
                await Geolocator.openAppSettings();
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void dispose() {
    _locationUpdateTimer?.cancel();
  }
}