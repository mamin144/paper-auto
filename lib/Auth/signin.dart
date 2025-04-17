import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:paperauto/widget/button.dart';
import 'LoginPage.dart';
import 'PreHomeScreen.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class SignIn extends StatefulWidget {
  const SignIn({Key? key}) : super(key: key);

  @override
  _SignInState createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  File? _profileImage;

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadProfileImage(String userId) async {
    if (_profileImage == null) return null;

    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child('$userId.jpg');

      await storageRef.putFile(_profileImage!);
      return await storageRef.getDownloadURL();
    } catch (e) {
      _showSnackBar(context, 'Error uploading profile picture: $e');
      return null;
    }
  }

  void _createAccount(BuildContext context) async {
    try {
      if (!_validateForm(context)) {
        return;
      }

      UserCredential authResult = await _firebaseAuth
          .createUserWithEmailAndPassword(
            email: _emailController.text,
            password: _passwordController.text,
          );

      String? profileImageUrl = await _uploadProfileImage(authResult.user!.uid);

      await _firestore.collection('users').doc(authResult.user!.uid).set({
        'First name': _firstNameController.text,
        'Last name': _lastNameController.text,
        'email': _emailController.text,
        'phone number': _phoneNumberController.text,
        'profileImageUrl': profileImageUrl,
        'uid': authResult.user!.uid,
      });

      _showSnackBar(context, 'Account added successfully!');

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const PreHomeScreen()),
      );
    } catch (error) {
      _showSnackBar(context, 'Error creating account: ${error.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// Background Image
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                  "lib/assets/fas-khan-WJyuzi6EUTs-unsplash.jpg",
                ), // Change the image path
                fit: BoxFit.cover,
              ),
            ),
          ),

          /// Centered Card
          Center(
            child: SingleChildScrollView(
              child: Card(
                elevation: 10,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                margin: EdgeInsets.all(20),
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(height: 10.0),

                        /// Title
                        Text(
                          'Sign Up',
                          style: TextStyle(
                            fontSize: 30.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 20),

                        /// Profile Picture
                        GestureDetector(
                          onTap: _pickImage,
                          child: CircleAvatar(
                            radius: 50,
                            backgroundImage:
                                _profileImage != null
                                    ? FileImage(_profileImage!)
                                    : null,
                            child:
                                _profileImage == null
                                    ? Icon(Icons.camera_alt, size: 50)
                                    : null,
                          ),
                        ),
                        SizedBox(height: 20),

                        /// Name Fields
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                'First Name',
                                _firstNameController,
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: _buildTextField(
                                'Last Name',
                                _lastNameController,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 15),

                        /// Email
                        _buildTextField('Your Email', _emailController),
                        SizedBox(height: 15),

                        /// Phone Number
                        _buildTextField(
                          'Your Phone Number',
                          _phoneNumberController,
                          prefixText: "+20 ",
                        ),
                        SizedBox(height: 15),

                        /// Password
                        _buildTextField(
                          'Your Password',
                          _passwordController,
                          obscureText: true,
                        ),
                        SizedBox(height: 20),

                        /// Sign Up Button
                        SizedBox(
                          width: double.infinity,
                          child: WidgetButton(
                            onPressed: () {
                              if (_validateForm(context)) {
                                _createAccount(context);
                              }
                            },
                            text: 'Sign Up',
                          ),
                        ),
                        SizedBox(height: 10),

                        /// Already have an account? Sign In
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Already have an account?"),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => LoginScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                'Sign In',
                                style: TextStyle(
                                  decoration: TextDecoration.underline,
                                  // border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool obscureText = false,
    String? prefixText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        SizedBox(height: 5),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            labelText: label,
            prefixText: prefixText,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter ${label.toLowerCase()}';
            }
            return null;
          },
        ),
      ],
    );
  }

  bool _validateForm(BuildContext context) {
    if (_passwordController.text.length < 6) {
      _showSnackBar(context, 'Password must be at least 6 characters');
      return false;
    }
    if (!_emailController.text.endsWith('@gmail.com')) {
      _showSnackBar(context, 'Invalid email format (must end with @gmail.com)');
      return false;
    }
    return true;
  }
}
