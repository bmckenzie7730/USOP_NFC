// widgets/custom_text_field.dart
import 'package:flutter/material.dart';

Widget buildTextField(String label, TextEditingController controller) {
  return TextField(
    decoration: InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    ),
    controller: controller,
    readOnly: true,
  );
}
