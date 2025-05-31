import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

class SignatureScreen extends StatefulWidget {
  const SignatureScreen({Key? key}) : super(key: key);

  @override
  _SignatureScreenState createState() => _SignatureScreenState();
}

class _SignatureScreenState extends State<SignatureScreen> {
  File? _signatureImage;
  final ImagePicker _picker = ImagePicker();
  final String _signatureFileName = 'signature.png'; // Define a fixed filename

  @override
  void initState() {
    super.initState();
    _loadSignatureImage(); // Load the image when the screen initializes
  }

  Future<void> _loadSignatureImage() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagePath = join(directory.path, _signatureFileName);
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
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final File imageFile = File(pickedFile.path);
      await _saveSignatureImage(imageFile); // Save the new image
    }
  }

  Future<void> _saveSignatureImage(File imageFile) async {
    if (!mounted) return; // Check if the widget is still mounted
    final scaffoldMessenger = ScaffoldMessenger.of(this.context);
    try {
      final directory = await getApplicationDocumentsDirectory();
      final localPath = join(directory.path, _signatureFileName);
      final localImage = await imageFile.copy(localPath);
      setState(() {
        _signatureImage = localImage;
      });
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Signature saved successfully!')),
      );
    } catch (e) {
      print('Error saving signature image: $e');
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Failed to save signature.')),
      );
    }
  }

  Future<void> _deleteSignatureImage() async {
    if (!mounted) return; // Check if the widget is still mounted
    final scaffoldMessenger = ScaffoldMessenger.of(this.context);
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagePath = join(directory.path, _signatureFileName);
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
      appBar: AppBar(
        title: const Text('Manage Signature'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _signatureImage == null
                ? const Text('No signature image found.')
                : Image.file(
                    _signatureImage!,
                    height: 200,
                  ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickSignatureImage,
              child: Text(_signatureImage == null ? 'Add Signature' : 'Change Signature'),
            ),
            if (_signatureImage != null)
              SizedBox(height: 10),
            if (_signatureImage != null)
              ElevatedButton(
                onPressed: _deleteSignatureImage,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red), // Highlight delete button
                child: Text('Delete Signature'),
              ),
          ],
        ),
      ),
    );
  }
} 