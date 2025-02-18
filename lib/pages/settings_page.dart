import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

class SettingsPage extends StatefulWidget {
  final String initialIp;
  final LocationAccuracy initialAccuracy;
  final bool initialUseHttps;
  final Function(String, LocationAccuracy, bool) onSettingsChanged;

  const SettingsPage({
    super.key,
    required this.initialIp,
    required this.initialAccuracy,
    required this.initialUseHttps,
    required this.onSettingsChanged,
  });

  @override
  SettingsPageState createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  late TextEditingController _ipController;
  late LocationAccuracy _selectedAccuracy = widget.initialAccuracy;
  bool _useHttps = false;

  final List<LocationAccuracy> _accuracyOptions = [
    LocationAccuracy.lowest,
    LocationAccuracy.low,
    LocationAccuracy.medium,
    LocationAccuracy.high,
    LocationAccuracy.best,
    LocationAccuracy.bestForNavigation,
  ];

  @override
  void initState() {
    super.initState();
    _ipController = TextEditingController(text: widget.initialIp);
    _useHttps = widget.initialUseHttps;
    _loadSavedAccuracy();
  }

  Future<void> _loadSavedAccuracy() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int savedAccuracyIndex = prefs.getInt('selectedAccuracy') ?? widget.initialAccuracy.index;
    setState(() {
      _selectedAccuracy = LocationAccuracy.values[savedAccuracyIndex];
    });
  }

  Future<void> _saveSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('apiIpAddress', _ipController.text);
    await prefs.setInt('selectedAccuracy', _selectedAccuracy.index);
    await prefs.setBool('useHttps', _useHttps);
    widget.onSettingsChanged(_ipController.text, _selectedAccuracy, _useHttps);
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _ipController,
              decoration: const InputDecoration(
                labelText: 'API IP Address',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            DropdownButton<LocationAccuracy>(
              value: _selectedAccuracy,
              items: _accuracyOptions.map((LocationAccuracy accuracy) {
                return DropdownMenuItem<LocationAccuracy>(
                  value: accuracy,
                  child: Text(accuracy.toString().split('.').last),
                );
              }).toList(),
              onChanged: (LocationAccuracy? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedAccuracy = newValue;
                  });
                }
              },
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Checkbox(
                  value: _useHttps,
                  onChanged: (bool? value) {
                    setState(() {
                      _useHttps = value ?? false;
                    });
                  },
                ),
                const Text('Use HTTPS')
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _saveSettings();
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}