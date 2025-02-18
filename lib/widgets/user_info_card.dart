// widgets/user_info_card.dart
import 'package:flutter/material.dart';
import 'dart:typed_data';

class UserInfoCard extends StatelessWidget {
  final TextEditingController geoLocationController;
  final TextEditingController fullNameController;
  final TextEditingController foodController;
  final TextEditingController drinkController;
  final TextEditingController nfcDataController;
  final Uint8List? pictureData;
  final double imageSize;
  final TextStyle fullNameLabelStyle;
  final TextStyle geoLocationLabelStyle;
  final TextStyle nfcDataLabelStyle;
  final TextStyle fullNameTextStyle;
  final TextStyle geoLocationTextStyle;
  final TextStyle nfcDataTextStyle;

  const UserInfoCard({
    super.key,
    required this.geoLocationController,
    required this.fullNameController, 
    required this.foodController,
    required this.drinkController,
    required this.nfcDataController,
    this.pictureData,
    required this.imageSize,
    required this.fullNameLabelStyle,
    required this.geoLocationLabelStyle,
    required this.nfcDataLabelStyle,
    required this.fullNameTextStyle,
    required this.geoLocationTextStyle,
    required this.nfcDataTextStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
Center(
  child: pictureData != null
    ? SizedBox(
        width: imageSize,
        height: imageSize,
        child: ClipOval(
          child: Image.memory(
            pictureData!,
            fit: BoxFit.cover,
          ),
        ),
      )
    : SizedBox(  // Replace Container() with SizedBox to maintain layout
        width: imageSize,
        height: imageSize,
      ),
),
        const SizedBox(height: 20),
        Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildTextField(
                  label: 'Name',
                  controller: fullNameController,
                  labelStyle: fullNameLabelStyle,
                  textStyle: fullNameTextStyle,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: buildTextField(
                        label: 'Food Remaining',
                        controller: foodController,
                        labelStyle: fullNameLabelStyle,
                        textStyle: fullNameTextStyle,
                        backgroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: buildTextField(
                        label: 'Drinks Remaining',
                        controller: drinkController,
                        labelStyle: fullNameLabelStyle,
                        textStyle: fullNameTextStyle,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                buildTextField(
                  label: 'Geolocation',
                  controller: geoLocationController,
                  labelStyle: geoLocationLabelStyle,
                  textStyle: geoLocationTextStyle,
                ),
                const SizedBox(height: 12),
                buildTextField(
                  label: 'NFC ID',
                  controller: nfcDataController,
                  labelStyle: nfcDataLabelStyle,
                  textStyle: nfcDataTextStyle,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget buildTextField({
    required String label,
    required TextEditingController controller,
    required TextStyle labelStyle,
    required TextStyle textStyle,
    Color backgroundColor = Colors.white,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: labelStyle),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            controller: controller,
            style: textStyle,
            decoration: InputDecoration(
              filled: true,
              fillColor: backgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
            readOnly: true,
          ),
        ),
      ],
    );
  }
}