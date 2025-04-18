import 'package:flutter/material.dart';
import 'package:paperauto/services/report_service.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

class GenerateReport extends StatefulWidget {
  final Map<String, dynamic> project;

  const GenerateReport({
    super.key,
    required this.project,
  });

  @override
  State<GenerateReport> createState() => _GenerateReportState();
}

class _GenerateReportState extends State<GenerateReport> {
  final ReportService _reportService = ReportService();
  final _recipientController = TextEditingController();
  bool _isGenerating = false;
  bool _isSending = false;
  String? _error;
  String? _lastGeneratedPath;
  String? _lastGeneratedType;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _generateReport(String type) async {
    try {
      setState(() {
        _isGenerating = true;
        _error = null;
      });

      String filePath;
      if (type == 'MIR') {
        filePath = await _reportService.generateMIR(widget.project);
      } else {
        filePath = await _reportService.generateIR(widget.project);
      }

      setState(() {
        _lastGeneratedPath = filePath;
        _lastGeneratedType = type;
      });

      await _reportService.openPDF(filePath);
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  Future<void> _sharePDF() async {
    if (_lastGeneratedPath == null) {
      setState(() {
        _error = 'Please generate a report first';
      });
      return;
    }

    try {
      await Share.shareXFiles(
        [XFile(_lastGeneratedPath!)],
        text: 'Please review and approve this ${widget.project['projectDetails']['projectName']} report',
      );
    } catch (e) {
      setState(() {
        _error = 'Error sharing file: $e';
      });
    }
  }

  Future<void> _sendForApproval() async {
    if (_lastGeneratedPath == null || _lastGeneratedType == null) {
      setState(() {
        _error = 'Please generate a report first';
      });
      return;
    }

    if (_recipientController.text.isEmpty) {
      setState(() {
        _error = 'Please enter recipient email';
      });
      return;
    }

    try {
      setState(() {
        _isSending = true;
        _error = null;
      });

      // Validate file exists
      final file = File(_lastGeneratedPath!);
      if (!await file.exists()) {
        throw Exception('Generated PDF file not found. Please generate the report again.');
      }

      // Upload PDF to Firestore
      final pdfId = await _reportService.uploadPDF(_lastGeneratedPath!, _lastGeneratedType!);

      // Create approval request
      await _reportService.requestApproval(
        pdfId: pdfId,
        reportType: _lastGeneratedType!,
        projectName: widget.project['projectDetails']['projectName'],
        recipientEmail: _recipientController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Approval request sent successfully')),
        );
        // Clear the recipient field
        _recipientController.clear();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF3949AB),
        title: const Text('Generate Report'),
        actions: [
          if (_lastGeneratedPath != null)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _sharePDF,
              tooltip: 'Share for Approval',
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Select Report Type',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isGenerating
                  ? null
                  : () => _generateReport('MIR'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3949AB),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isGenerating
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Generate Monthly Inspection Report (MIR)',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isGenerating
                  ? null
                  : () => _generateReport('IR'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3949AB),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isGenerating
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Generate Inspection Report (IR)',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
            if (_lastGeneratedPath != null) ...[
              const SizedBox(height: 32),
              const Text(
                'Send for Approval',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _recipientController,
                decoration: const InputDecoration(
                  labelText: 'Recipient Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isSending ? null : _sendForApproval,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3949AB),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSending
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Send for Approval',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ],
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  'Error: $_error',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
} 