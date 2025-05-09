import 'package:flutter/material.dart';

class InputDecorations {
  static InputDecoration inputDecoration({
    required String hintext,
    required String labelText,
    required Icon icon,
  }) {
    return InputDecoration(
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Color.fromARGB(255, 7, 31, 66)),
      ),
      focusedBorder: const UnderlineInputBorder(
          borderSide:
              BorderSide(color: Color.fromARGB(255, 7, 31, 66), width: 2)),
      hintText: hintext,
      labelText: labelText,
      prefixIcon: icon,
    );
  }
}
