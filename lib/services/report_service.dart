import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  ReportService() {
    if (!dotenv.isInitialized) {
      throw Exception('Environment variables not loaded. Call await dotenv.load() before creating ReportService.');
    }
  }

  Future<String> uploadPDF(String filePath, String reportType) async {
    try {
      // Check if user is authenticated
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Check if file exists
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('PDF file not found at $filePath');
      }

      // Read file as bytes and convert to base64
      final bytes = await file.readAsBytes();
      final base64Pdf = base64Encode(bytes);

      // Create a unique document ID
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final docId = '${user.uid}_${reportType}_$timestamp';

      // Store PDF in Firestore
      await _firestore.collection('pdfs').doc(docId).set({
        'pdfData': base64Pdf,
        'userId': user.uid,
        'reportType': reportType,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return docId; // Return document ID instead of URL
    } catch (e) {
      throw Exception('Error uploading PDF: $e');
    }
  }

  Future<void> requestApproval({
    required String pdfId,
    required String reportType,
    required String projectName,
    required String recipientEmail,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('User not logged in');

      // Validate recipient email
      if (!recipientEmail.contains('@')) {
        throw Exception('Invalid recipient email');
      }

      await _firestore.collection('approval_requests').add({
        'pdfId': pdfId,
        'reportType': reportType,
        'projectName': projectName,
        'senderId': currentUser.uid,
        'senderEmail': currentUser.email,
        'recipientEmail': recipientEmail,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error creating approval request: $e');
    }
  }

  Future<String> getPdfPath(String pdfId) async {
    try {
      // Get PDF data from Firestore
      final doc = await _firestore.collection('pdfs').doc(pdfId).get();
      if (!doc.exists) {
        throw Exception('PDF not found');
      }

      final data = doc.data();
      if (data == null || !data.containsKey('pdfData')) {
        throw Exception('Invalid PDF data');
      }

      // Convert base64 back to bytes
      final bytes = base64Decode(data['pdfData'] as String);

      // Save to temporary file
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$pdfId.pdf');
      await file.writeAsBytes(bytes);

      return file.path;
    } catch (e) {
      throw Exception('Error retrieving PDF: $e');
    }
  }

  Future<String> generateMIR(Map<String, dynamic> project) async {
    final personalInfo = project['personalInfo'] as Map<String, dynamic>;
    final projectDetails = project['projectDetails'] as Map<String, dynamic>;
    final projectDescription = project['projectDescription'] as Map<String, dynamic>;

    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Monthly Inspection Report', style: pw.TextStyle(fontSize: 24)),
            pw.SizedBox(height: 20),
            pw.Text('Project Information', style: pw.TextStyle(fontSize: 18)),
            pw.Text('Project Name: ${projectDetails['projectName']}'),
            pw.Text('Project Area: ${projectDetails['projectArea']}'),
            pw.Text('Project Type: ${projectDetails['projectType']}'),
            pw.SizedBox(height: 20),
            pw.Text('Project Details', style: pw.TextStyle(fontSize: 18)),
            pw.Text('Villas: ${projectDescription['village']}'),
            pw.Text('Buildings: ${projectDescription['building']}'),
            pw.Text('Malls: ${projectDescription['malls']}'),
            pw.Text('Parking: ${projectDescription['parking']}'),
            pw.SizedBox(height: 20),
            pw.Text('Contact Information', style: pw.TextStyle(fontSize: 18)),
            pw.Text('Name: ${personalInfo['firstName']} ${personalInfo['lastName']}'),
            pw.Text('Email: ${personalInfo['email']}'),
            pw.Text('Phone: ${personalInfo['phone']}'),
            pw.SizedBox(height: 20),
            pw.Text('Inspection Date: ${DateTime.now().toString().split(' ')[0]}'),
          ],
        ),
      ),
    );

    final directory = await getTemporaryDirectory();
    final outputPath = '${directory.path}/MIR_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File(outputPath);
    await file.writeAsBytes(await pdf.save());
    return outputPath;
  }

  Future<String> generateIR(Map<String, dynamic> project) async {
    final personalInfo = project['personalInfo'] as Map<String, dynamic>;
    final projectDetails = project['projectDetails'] as Map<String, dynamic>;
    final projectDescription = project['projectDescription'] as Map<String, dynamic>;

    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Inspection Report', style: pw.TextStyle(fontSize: 24)),
            pw.SizedBox(height: 20),
            pw.Text('Project Information', style: pw.TextStyle(fontSize: 18)),
            pw.Text('Project Name: ${projectDetails['projectName']}'),
            pw.Text('Project Area: ${projectDetails['projectArea']}'),
            pw.Text('Project Type: ${projectDetails['projectType']}'),
            pw.SizedBox(height: 20),
            pw.Text('Project Details', style: pw.TextStyle(fontSize: 18)),
            pw.Text('Villas: ${projectDescription['village']}'),
            pw.Text('Buildings: ${projectDescription['building']}'),
            pw.Text('Malls: ${projectDescription['malls']}'),
            pw.Text('Parking: ${projectDescription['parking']}'),
            pw.SizedBox(height: 20),
            pw.Text('Contact Information', style: pw.TextStyle(fontSize: 18)),
            pw.Text('Name: ${personalInfo['firstName']} ${personalInfo['lastName']}'),
            pw.Text('Email: ${personalInfo['email']}'),
            pw.Text('Phone: ${personalInfo['phone']}'),
            pw.SizedBox(height: 20),
            pw.Text('Inspection Date: ${DateTime.now().toString().split(' ')[0]}'),
          ],
        ),
      ),
    );

    final directory = await getTemporaryDirectory();
    final outputPath = '${directory.path}/IR_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File(outputPath);
    await file.writeAsBytes(await pdf.save());
    return outputPath;
  }

  Future<void> openPDF(String filePath) async {
    await OpenFile.open(filePath);
  }
} 