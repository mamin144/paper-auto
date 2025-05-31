import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/mir_data.dart';
import '../models/ir_data.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart';

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

      // Get recipient user ID
      final recipientQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: recipientEmail)
          .get();

      if (recipientQuery.docs.isEmpty) {
        throw Exception('Recipient not found');
      }

      await _firestore.collection('approval_requests').add({
        'pdfId': pdfId,
        'reportType': reportType.toLowerCase(),
        'projectName': projectName,
        'senderId': currentUser.uid,
        'senderEmail': currentUser.email,
        'recipientId': recipientQuery.docs.first.id,
        'recipientEmail': recipientEmail,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error creating approval request: $e');
    }
  }

  Future<String> getPdfPath(String pdfId, String documentType) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/$pdfId.pdf';
      final file = File(path);

      if (await file.exists()) {
        return path;
      }

      // Try to get PDF from Firestore first
      final pdfDoc = await _firestore.collection('pdfs').doc(pdfId).get();
      if (pdfDoc.exists) {
        final pdfData = pdfDoc.data()?['pdfData'] as String?;
        if (pdfData != null) {
          final bytes = base64Decode(pdfData);
          await file.writeAsBytes(bytes);
          return path;
        }
      }

      // If not in Firestore, try Firebase Storage
      final ref = FirebaseStorage.instance.ref().child('$documentType/$pdfId.pdf');
      await ref.writeToFile(file);
      return path;
    } catch (e) {
      throw Exception('Error getting PDF: $e');
    }
  }

  Future<String> generateMIR(Map<String, dynamic> project) async {
    final personalInfo = project['personalInfo'] as Map<String, dynamic>;
    final projectDetails = project['projectDetails'] as Map<String, dynamic>;
    final projectDescription = project['projectDescription'] as Map<String, dynamic>;

    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // Header with logos
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Container(
                    width: 100,
                    height: 50,
                    child: pw.Center(child: pw.Text('Logo 1')),
                    decoration: pw.BoxDecoration(border: pw.Border.all()),
                  ),
                  pw.Container(
                    width: 100,
                    height: 50,
                    child: pw.Center(child: pw.Text('AECOM')),
                    decoration: pw.BoxDecoration(border: pw.Border.all()),
                  ),
                  pw.Container(
                    width: 100,
                    height: 50,
                    child: pw.Center(child: pw.Text('Logo 3')),
                    decoration: pw.BoxDecoration(border: pw.Border.all()),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              // Title
              pw.Center(
                child: pw.Text(
                  'MATERIAL INSPECTION REQUEST',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              // Project details table
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: pw.FlexColumnWidth(1),
                  1: pw.FlexColumnWidth(3),
                },
                children: [
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Text('Project Name'),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Text(projectDetails['projectName']),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Text('Contract No.'),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Text('A-17080'),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Text('MIR No.'),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Text(projectDetails['mirNo'] ?? ''),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              // Description table
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: pw.FlexColumnWidth(2),
                  1: pw.FlexColumnWidth(4),
                  2: pw.FlexColumnWidth(1),
                  3: pw.FlexColumnWidth(1),
                  4: pw.FlexColumnWidth(2),
                },
                children: [
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Text('B.O.Q Ref. no.'),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Text('Description'),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Text('Unit'),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Text('BOQ Qty'),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Text('Remarks'),
                      ),
                    ],
                  ),
                  // Empty row for data
                  pw.TableRow(
                    children: List.generate(5, (index) => pw.Padding(
                      padding: pw.EdgeInsets.all(5),
                      child: pw.Text(''),
                    )),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              // MAS/FAT Report section
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Text('MAS/FAT Report/Dispatch Clearance - Approvals'),
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Padding(
                            padding: pw.EdgeInsets.all(5),
                            child: pw.Text('MAS'),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.all(5),
                            child: pw.Text('DTS'),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.all(5),
                            child: pw.Text('Dispatch Clearance'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              // Additional details
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Text('Supplier Delivery Note/Date'),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Text(''),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Text('Manufacturer'),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Text(''),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Text('Country of Origin'),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Text(''),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              // Engineer's Comments
              pw.Container(
                decoration: pw.BoxDecoration(border: pw.Border.all()),
                padding: pw.EdgeInsets.all(10),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("Engineer's Comments:"),
                    pw.SizedBox(height: 10),
                    pw.Text('The above materials have been inspected on site/store and found at time of inspection to be:'),
                    pw.Row(
                      children: [
                        pw.Text('Satisfactory '),
                        pw.Container(
                          width: 20,
                          height: 20,
                          decoration: pw.BoxDecoration(border: pw.Border.all()),
                        ),
                        pw.Text('     Unsatisfactory '),
                        pw.Container(
                          width: 20,
                          height: 20,
                          decoration: pw.BoxDecoration(border: pw.Border.all()),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.Spacer(),
              // Footer signatures
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: pw.FlexColumnWidth(1),
                  1: pw.FlexColumnWidth(1),
                  2: pw.FlexColumnWidth(1),
                },
                children: [
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Center(child: pw.Text('Contractor')),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Center(child: pw.Text('Consultant')),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Center(child: pw.Text('Client')),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(20),
                        child: pw.Center(child: pw.Text('ENVICON')),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(20),
                        child: pw.Center(child: pw.Text('AECOM')),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(20),
                        child: pw.Center(child: pw.Text('AADC')),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
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

  Future<String> generatePDFFromMIR(MIRData mirData, {String? signaturePath}) async {
    final pdf = pw.Document();
    pw.MemoryImage? signatureImage;
    if (signaturePath != null && await File(signaturePath).exists()) {
      final bytes = await File(signaturePath).readAsBytes();
      signatureImage = pw.MemoryImage(bytes);
    }
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // Header with logos
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Container(
                    width: 100,
                    height: 50,
                    child: pw.Center(child: pw.Text('Logo 1')),
                    decoration: pw.BoxDecoration(border: pw.Border.all()),
                  ),
                  pw.Container(
                    width: 100,
                    height: 50,
                    child: pw.Center(child: pw.Text('AECOM')),
                    decoration: pw.BoxDecoration(border: pw.Border.all()),
                  ),
                  pw.Container(
                    width: 100,
                    height: 50,
                    child: pw.Center(child: pw.Text('Logo 3')),
                    decoration: pw.BoxDecoration(border: pw.Border.all()),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              // Title
              pw.Center(
                child: pw.Text(
                  'MATERIAL INSPECTION REQUEST',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              // Project details table
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: pw.FlexColumnWidth(1),
                  1: pw.FlexColumnWidth(3),
                },
                children: [
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Text('Project Name'),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Text(mirData.projectName),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Text('Contract No.'),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Text(mirData.contractNo),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Text('MIR No.'),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Text(mirData.mirNo),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              // Description table
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: pw.FlexColumnWidth(2),
                  1: pw.FlexColumnWidth(4),
                  2: pw.FlexColumnWidth(1),
                  3: pw.FlexColumnWidth(1),
                  4: pw.FlexColumnWidth(2),
                },
                children: [
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Text('B.O.Q Ref. no.'),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Text('Description'),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Text('Unit'),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Text('BOQ Qty'),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Text('Remarks'),
                      ),
                    ],
                  ),
                  ...mirData.boqItems.map((item) => pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Text(item.refNo),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Text(item.description),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Text(item.unit),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Text(item.quantity),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Text(item.remarks),
                      ),
                    ],
                  )).toList(),
                ],
              ),
              pw.SizedBox(height: 20),
              // MAS/FAT Report section
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Text('MAS/FAT Report/Dispatch Clearance - Approvals'),
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Padding(
                            padding: pw.EdgeInsets.all(5),
                            child: pw.Text('MAS: ${mirData.masStatus}'),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.all(5),
                            child: pw.Text('DTS: ${mirData.dtsStatus}'),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.all(5),
                            child: pw.Text('Dispatch Clearance: ${mirData.dispatchStatus}'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              // Additional details
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Text('Supplier Delivery Note/Date'),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Text(mirData.supplierDeliveryNote),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Text('Manufacturer'),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Text(mirData.manufacturer),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Text('Country of Origin'),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Text(mirData.countryOfOrigin),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              // Engineer's Comments
              pw.Container(
                decoration: pw.BoxDecoration(border: pw.Border.all()),
                padding: pw.EdgeInsets.all(10),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("Engineer's Comments:"),
                    pw.SizedBox(height: 10),
                    pw.Text(mirData.engineerComments),
                    pw.SizedBox(height: 10),
                    pw.Text('The above materials have been inspected on site/store and found at time of inspection to be:'),
                    pw.Row(
                      children: [
                        pw.Text('Satisfactory '),
                        pw.Container(
                          width: 20,
                          height: 20,
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(),
                            color: mirData.isSatisfactory ? PdfColors.grey300 : null,
                          ),
                        ),
                        pw.Text('     Unsatisfactory '),
                        pw.Container(
                          width: 20,
                          height: 20,
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(),
                            color: !mirData.isSatisfactory ? PdfColors.grey300 : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.Spacer(),
              // Footer signatures
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: pw.FlexColumnWidth(1),
                  1: pw.FlexColumnWidth(1),
                  2: pw.FlexColumnWidth(1),
                },
                children: [
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Center(child: pw.Text('Contractor')),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Center(child: pw.Text('Consultant')),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Center(child: pw.Text('Client')),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Container(
                          height: 50,
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(),
                          ),
                          child: signatureImage != null
                            ? pw.Image(signatureImage, fit: pw.BoxFit.contain)
                            : pw.Center(child: pw.Text('Signature', style: pw.TextStyle(fontSize: 12))),
                        ),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(20),
                        child: pw.Center(child: pw.Text('AECOM')),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(20),
                        child: pw.Center(child: pw.Text('AADC')),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
    final directory = await getTemporaryDirectory();
    final outputPath = '${directory.path}/MIR_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File(outputPath);
    await file.writeAsBytes(await pdf.save());
    return outputPath;
  }

  Future<String> generatePDFFromIR(IRData irData, {String? signaturePath}) async {
    final pdf = pw.Document();
    pw.MemoryImage? signatureImage;
    if (signaturePath != null && await File(signaturePath).exists()) {
      final bytes = await File(signaturePath).readAsBytes();
      signatureImage = pw.MemoryImage(bytes);
    }
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // Header with logos
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Container(
                    width: 100,
                    height: 50,
                    child: pw.Center(child: pw.Text('Logo 1')),
                    decoration: pw.BoxDecoration(border: pw.Border.all()),
                  ),
                  pw.Container(
                    width: 100,
                    height: 50,
                    child: pw.Center(child: pw.Text('AECOM')),
                    decoration: pw.BoxDecoration(border: pw.Border.all()),
                  ),
                  pw.Container(
                    width: 100,
                    height: 50,
                    child: pw.Center(child: pw.Text('Logo 3')),
                    decoration: pw.BoxDecoration(border: pw.Border.all()),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              // Title
              pw.Center(
                child: pw.Text(
                  'INSPECTION REPORT',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              // Project details table
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: pw.FlexColumnWidth(1),
                  1: pw.FlexColumnWidth(3),
                },
                children: [
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Text('Project Name'),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Text(irData.projectName),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Text('Contract No.'),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Text(irData.contractNo),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Text('IR No.'),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Text(irData.irNo),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              // Description table
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: pw.FlexColumnWidth(2),
                  1: pw.FlexColumnWidth(4),
                  2: pw.FlexColumnWidth(1),
                  3: pw.FlexColumnWidth(1),
                  4: pw.FlexColumnWidth(2),
                },
                children: [
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Text('B.O.Q Ref. no.'),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Text('Description'),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Text('Unit'),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Text('BOQ Qty'),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Text('Remarks'),
                      ),
                    ],
                  ),
                  ...irData.boqItems.map((item) => pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Text(item.refNo),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Text(item.description),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Text(item.unit),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Text(item.quantity),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Text(item.remarks),
                      ),
                    ],
                  )).toList(),
                ],
              ),
              pw.SizedBox(height: 20),
              // MAS/FAT Report section
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Text('MAS/FAT Report/Dispatch Clearance - Approvals'),
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Padding(
                            padding: pw.EdgeInsets.all(5),
                            child: pw.Text('MAS: ${irData.masStatus}'),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.all(5),
                            child: pw.Text('DTS: ${irData.dtsStatus}'),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.all(5),
                            child: pw.Text('Dispatch Clearance: ${irData.dispatchStatus}'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              // Additional details
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Text('Supplier Delivery Note/Date'),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Text(irData.supplierDeliveryNote),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Text('Manufacturer'),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Text(irData.manufacturer),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Text('Country of Origin'),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Text(irData.countryOfOrigin),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              // Engineer's Comments
              pw.Container(
                decoration: pw.BoxDecoration(border: pw.Border.all()),
                padding: pw.EdgeInsets.all(10),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("Engineer's Comments:"),
                    pw.SizedBox(height: 10),
                    pw.Text(irData.engineerComments),
                    pw.SizedBox(height: 10),
                    pw.Text('The above materials have been inspected on site/store and found at time of inspection to be:'),
                    pw.Row(
                      children: [
                        pw.Text('Satisfactory '),
                        pw.Container(
                          width: 20,
                          height: 20,
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(),
                            color: irData.isSatisfactory ? PdfColors.grey300 : null,
                          ),
                        ),
                        pw.Text('     Unsatisfactory '),
                        pw.Container(
                          width: 20,
                          height: 20,
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(),
                            color: !irData.isSatisfactory ? PdfColors.grey300 : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.Spacer(),
              // Footer signatures
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: pw.FlexColumnWidth(1),
                  1: pw.FlexColumnWidth(1),
                  2: pw.FlexColumnWidth(1),
                },
                children: [
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Center(child: pw.Text('Contractor')),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Center(child: pw.Text('Consultant')),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Center(child: pw.Text('Client')),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Container(
                          height: 50,
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(),
                          ),
                          child: signatureImage != null
                            ? pw.Image(signatureImage, fit: pw.BoxFit.contain)
                            : pw.Center(child: pw.Text('Signature', style: pw.TextStyle(fontSize: 12))),
                        ),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(20),
                        child: pw.Center(child: pw.Text('AECOM')),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(20),
                        child: pw.Center(child: pw.Text('AADC')),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
    final directory = await getTemporaryDirectory();
    final outputPath = '${directory.path}/IR_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File(outputPath);
    await file.writeAsBytes(await pdf.save());
    return outputPath;
  }
}   