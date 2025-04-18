import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ReportService {
  ReportService() {
    if (!dotenv.isInitialized) {
      throw Exception('Environment variables not loaded. Call await dotenv.load() before creating ReportService.');
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