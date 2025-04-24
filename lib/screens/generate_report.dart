import 'package:flutter/material.dart';
import 'package:paperauto/services/report_service.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

class GenerateReport extends StatefulWidget {
  final Map<String, dynamic> project;

  const GenerateReport({super.key, required this.project});

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
  String? _generatingType; // Track which report type is being generated

  @override
  void dispose() {
    _recipientController.dispose();
    super.dispose();
  }

  Future<void> _generateReport(String type) async {
    try {
      setState(() {
        _isGenerating = true;
        _generatingType = type;
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
        _error = 'Error generating $type: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _generatingType = null;
        });
      }
    }
  }

  Future<void> _sharePDF() async {
    if (_lastGeneratedPath == null || _lastGeneratedType == null) {
      setState(() {
        _error = 'Please generate a report first';
      });
      return;
    }

    try {
      final projectName =
          widget.project['projectDetails']?['projectName'] ?? 'report';
      await Share.shareXFiles(
        [XFile(_lastGeneratedPath!)],
        text:
            'Please review and approve this $_lastGeneratedType for $projectName',
      );
    } catch (e) {
      setState(() {
        _error = 'Error sharing file: $e';
      });
    }
  }

  // Modified to show confirmation dialog
  Future<void> _confirmAndSendForApproval() async {
    final recipientEmail = _recipientController.text.trim();
    if (recipientEmail.isEmpty || !recipientEmail.contains('@')) {
      setState(() {
        _error = 'Please enter a valid recipient email';
      });
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Send'),
          content: Text(
            'Send the $_lastGeneratedType report to $recipientEmail for approval?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed:
                  () => Navigator.of(context).pop(false), // Not confirmed
              child: const Text('Cancel'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.green),
              onPressed: () => Navigator.of(context).pop(true), // Confirmed
              child: const Text('Send'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      _sendForApproval(recipientEmail); // Proceed if confirmed
    }
  }

  Future<void> _sendForApproval(String recipientEmail) async {
    if (_lastGeneratedPath == null || _lastGeneratedType == null) {
      setState(() {
        _error = 'Please generate a report first';
      });
      return;
    }

    try {
      setState(() {
        _isSending = true;
        _error = null;
      });

      final file = File(_lastGeneratedPath!);
      if (!await file.exists()) {
        throw Exception(
          'Generated PDF file not found. Please generate the report again.',
        );
      }

      final pdfId = await _reportService.uploadPDF(
        _lastGeneratedPath!,
        _lastGeneratedType!,
      );
      final projectName =
          widget.project['projectDetails']?['projectName'] ?? 'Unknown Project';

      await _reportService.requestApproval(
        pdfId: pdfId,
        reportType: _lastGeneratedType!,
        projectName: projectName,
        recipientEmail: recipientEmail,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Approval request sent successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _recipientController.clear();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error sending request: ${e.toString()}';
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
    final projectName =
        widget.project['projectDetails']?['projectName'] ?? 'Report';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        elevation: 0,
        title: Text(
          'Generate: $projectName',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (_lastGeneratedPath != null)
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.share_outlined, color: Colors.white),
              ),
              onPressed: _sharePDF,
              tooltip: 'Share PDF',
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1A237E).withOpacity(0.1),
              const Color(0xFF3949AB).withOpacity(0.1),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            16,
            20,
            16,
            16,
          ), // Added top padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionCard(
                title: 'Select Report Type',
                icon: Icons.description_outlined,
                children: [
                  _buildGenerateButton(
                    label: 'Monthly Inspection Report (MIR)',
                    type: 'MIR',
                    isLastGenerated: _lastGeneratedType == 'MIR',
                  ),
                  const SizedBox(height: 12),
                  _buildGenerateButton(
                    label: 'Inspection Report (IR)',
                    type: 'IR',
                    isLastGenerated: _lastGeneratedType == 'IR',
                  ),
                ],
              ),
              if (_lastGeneratedPath != null) ...[
                const SizedBox(height: 24),
                _buildSectionCard(
                  title: 'Send for Approval',
                  icon: Icons.send_outlined,
                  children: [
                    Text(
                      'Generated: $_lastGeneratedType Report',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _recipientController,
                      decoration: InputDecoration(
                        labelText: 'Recipient Email',
                        prefixIcon: const Icon(
                          Icons.email_outlined,
                          color: Color(0xFF1A237E),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF1A237E),
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed:
                          _isSending
                              ? null
                              : _confirmAndSendForApproval, // Use confirmation method
                      icon:
                          _isSending
                              ? Container(
                                width: 20,
                                height: 20,
                                padding: const EdgeInsets.all(2.0),
                                child: const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              )
                              : const Icon(Icons.send, size: 18),
                      label: const Text('Send for Approval'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A237E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 24,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.red,
                            size: 18,
                          ),
                          onPressed: () => setState(() => _error = null),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 4), // Reduce bottom margin slightly
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.grey.shade300,
          width: 0.5,
        ), // Add subtle border
      ),
      color: Colors.white.withOpacity(0.95), // Slightly off-white
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 20,
        ), // Adjust padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF1A237E), size: 24),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A237E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildGenerateButton({
    required String label,
    required String type,
    required bool isLastGenerated, // New parameter
  }) {
    final isLoading = _isGenerating && _generatingType == type;
    final isHighlighted = !isLoading && isLastGenerated;

    return ElevatedButton.icon(
      onPressed: _isGenerating ? null : () => _generateReport(type),
      icon:
          isLoading
              ? Container(
                width: 20,
                height: 20,
                padding: const EdgeInsets.all(2.0),
                child: const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
              : Icon(
                isHighlighted
                    ? Icons
                        .check_circle_outline // Indicate generated
                    : Icons.picture_as_pdf_outlined,
                size: 18,
                color: isHighlighted ? Colors.white : null,
              ),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isHighlighted ? Colors.green : const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side:
              isHighlighted
                  ? BorderSide(color: Colors.green.shade700, width: 2)
                  : BorderSide.none,
        ),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
    );
  }
}
