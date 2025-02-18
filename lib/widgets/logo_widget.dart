// widgets/logo_widget.dart
import 'package:flutter/material.dart';

class LogoWidget extends StatelessWidget {
  const LogoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset(
        'assets/USOP Logo.jfif',
        height: 120,
        errorBuilder: (context, error, stackTrace) {
          return const Text(
            'Logo could not be loaded',
            style: TextStyle(fontSize: 16, color: Colors.red),
          );
        },
      ),
    );
  }
}
