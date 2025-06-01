import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'dart:typed_data'; // Required for Uint8List
import 'package:signature/signature.dart'; // Import the signature package if needed here
import '../widgets/signature_pad.dart'; // Import your SignaturePad widget
import 'package:firebase_auth/firebase_auth.dart'; // Import for user ID

class SignatureScreen extends StatefulWidget {
  const SignatureScreen({Key? key}) : super(key: key);

  @override
  _SignatureScreenState createState() => _SignatureScreenState();
}

class _SignatureScreenState extends State<SignatureScreen> {
  File? _signatureImage;
  final ImagePicker _picker = ImagePicker();
  String? _currentUserId; // To store the current user's ID

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (_currentUserId == null) {
      // Handle the case where the user is not logged in, maybe show an error or navigate away
      print('User not logged in!');
      if (mounted) {
        ScaffoldMessenger.of(this.context).showSnackBar(
          const SnackBar(
            content: Text(
              'User not logged in. Please log in to manage signatures.',
            ),
          ),
        );
        Navigator.of(this.context).pop(); // Or navigate to login screen
      }
      return;
    }
    _loadSignatureImage(); // Load the image when the screen initializes
  }

  Future<void> _loadSignatureImage() async {
    try {
      if (_currentUserId == null) return; // Prevent loading if no user
      final directory = await getApplicationDocumentsDirectory();
      final imagePath = join(directory.path, 'signature_${_currentUserId}.png');
      final file = File(imagePath);
      if (await file.exists()) {
        setState(() {
          _signatureImage = file;
        });
      }
    } catch (e) {
      print('Error loading signature image: $e');
    }
  }

  Future<void> _pickSignatureImage() async {
    // This function will now only handle picking from gallery
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final File imageFile = File(pickedFile.path);
      await _saveSignature(imageFile); // Use the unified save function
    }
  }

  Future<void> _deleteSignatureImage() async {
    if (!mounted) return; // Check if the widget is still mounted
    if (_currentUserId == null) return; // Prevent deleting if no user
    final scaffoldMessenger = ScaffoldMessenger.of(this.context);
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagePath = join(directory.path, 'signature_${_currentUserId}.png');
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
        setState(() {
          _signatureImage = null;
        });
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Signature deleted successfully!')),
        );
      }
    } catch (e) {
      print('Error deleting signature image: $e');
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Failed to delete signature.')),
      );
    }
  }

  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Signature')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _signatureImage == null
                ? const Text('No signature image found.')
                : Image.file(_signatureImage!, height: 200),
            SizedBox(height: 20),
            if (_signatureImage == null) ...[
              ElevatedButton.icon(
                onPressed: _drawSignature,
                icon: const Icon(Icons.brush),
                label: const Text('Draw Signature'),
              ),
              SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _pickSignatureImage,
                icon: const Icon(Icons.image),
                label: const Text('Upload Signature Image'),
              ),
            ] else ...[
              ElevatedButton.icon(
                onPressed: _pickSignatureImage,
                icon: const Icon(Icons.image),
                label: const Text('Change Signature Image'),
              ),
              SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _drawSignature,
                icon: const Icon(Icons.brush),
                label: const Text('Redraw Signature'),
              ),
              SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _deleteSignatureImage,
                icon: const Icon(Icons.delete),
                label: const Text('Delete Signature'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ), // Highlight delete button
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Function to handle drawing signature
  Future<void> _drawSignature() async {
    final signatureBytes = await Navigator.push<Uint8List?>(
      this.context,
      MaterialPageRoute(
        builder:
            (context) => SignaturePad(
              onSignatureComplete: (bytes) {
                if (bytes != null) {
                  _saveSignature(bytes);
                }
              },
            ),
      ),
    );
  }

  // Unified function to save signature, either from bytes (drawn) or file (uploaded)
  Future<void> _saveSignature(dynamic data) async {
    if (!mounted) return; // Check if the widget is still mounted
    if (_currentUserId == null) return; // Prevent saving if no user
    final scaffoldMessenger = ScaffoldMessenger.of(this.context);
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagePath = join(directory.path, 'signature_${_currentUserId}.png');
      final file = File(imagePath);

      if (data is Uint8List) {
        await file.writeAsBytes(data);
      } else if (data is File) {
        await data.copy(imagePath);
      } else {
        throw Exception('Invalid data type for signature saving');
      }

      setState(() {
        _signatureImage = file; // Update the displayed image
      });
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Signature saved successfully!')),
      );
    } catch (e) {
      print('Error saving signature: $e');
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Failed to save signature: $e')),
      );
    }
  }
}
