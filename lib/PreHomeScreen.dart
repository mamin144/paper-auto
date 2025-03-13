// ignore_for_file: file_names, avoid_unnecessary_containers

import 'package:flutter/material.dart';

import 'LoginPage.dart';
import 'signin.dart';

class PreHomeScreen extends StatelessWidget {
  // ignore: use_key_in_widget_constructors
  const PreHomeScreen({Key? key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color.fromARGB(255, 233, 188, 124), Color(0xFFFFFFFF)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'lib/pics/Group_2.png',
                  height: 120.0, // Adjust the height as needed
                  width: 120.0, // Adjust the width as needed
                ),
                const SizedBox(
                    height: 16.0), // Add some space between image and text
                Container(
                  child: const Text(
                    'Agarly',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8.0),
                const Text(
                  'Simplify real estate selling, purchasing, renting, and managing properties',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 32.0),
                RoundedButton(
                  text: 'Login',
                  color: const Color(0xFFF9CF93),
                  width: 304.0,
                  height: 59.0,
                  onPressed: () {
                    // Navigate to SignInPage when the "Login" button is pressed
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginScreen()),
                    );
                  },
                ),
                const SizedBox(height: 16.0),
                RoundedButton(
                  text: 'Sign Up',
                  color: const Color(0xFFD9D9D9),
                  width: 304.0,
                  height: 59.0,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SignInPage()),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RoundedButton extends StatelessWidget {
  final String text;
  final Color color;
  final double width;
  final double height;
  final VoidCallback? onPressed;

  const RoundedButton({
    Key? key,
    required this.text,
    required this.color,
    required this.width,
    required this.height,
    this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20.0),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
