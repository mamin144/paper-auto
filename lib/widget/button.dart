import 'package:flutter/material.dart';

class WidgetButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed; // Added onPressed parameter

  const WidgetButton({
    Key? key,
    this.text = 'Button',
    required this.onPressed, // Make onPressed required
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160, // Set button width
      height: 50, // Set button height
      child: ElevatedButton(
        onPressed: onPressed, // Use onPressed here
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 17, 2, 98), // Modern look
          foregroundColor: const Color.fromARGB(
            255,
            255,
            255,
            255,
          ), // Text color
          shadowColor: Colors.black12, // Soft shadow
          elevation: 5, // Raised effect
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
