// utils/ui_helpers.dart
import 'package:flutter/material.dart';

class UIHelpers {
  static Future<void> showPasswordDialog({
    required BuildContext context,
    required Future<String?> Function() getPassword,
    required VoidCallback onSuccess,
  }) async {
    TextEditingController passwordController = TextEditingController();
    String? correctPassword = await getPassword();

    if (correctPassword == null) {
      showSnackBar(context, 'Failed to retrieve password from server.', Colors.red);
      return;
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter Password'),
          content: TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (passwordController.text == correctPassword) {
                  Navigator.of(context).pop(); // Close the dialog
                  onSuccess();
                } else {
                  showSnackBar(context, 'Incorrect password.', Colors.red, durationInSeconds: 3);
                }
              },
              child: const Text('Submit'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  static void showSnackBar(BuildContext context, String message, Color color, {int durationInSeconds = 3}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: Duration(seconds: durationInSeconds),
      ),
    );
  }
}
