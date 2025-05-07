import 'package:flutter/material.dart';
import 'package:paperauto/services/report_service.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import '../models/mir_data.dart';
import '../screens/mir_edit_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/firstscreen.dart';
import '../models/ir_data.dart';
import '../screens/ir_edit_screen.dart';

class GenerateReport extends StatefulWidget {
  final Map<String, dynamic> project;
  final bool isEditMode;
  final String? requestId;
  final bool isCreator;

  const GenerateReport({
    super.key,
    required this.project,
    this.isEditMode = false,
    this.requestId,
    this.isCreator = false,
  });

  @override
  State<GenerateReport> createState() => _GenerateReportState();
}

class _GenerateReportState extends State<GenerateReport> {
  final ReportService _reportService = ReportService();
  final _recipientController = TextEditingController();
  bool _isGenerating = false;
  bool _isSending = false;
  bool _isPDFVisible = false;
  String? _error;
  String? _lastGeneratedPath;
  String? _lastGeneratedType;
  String? _pdfPath;
  String? _currentRequestId;

  @override
  void initState() {
    super.initState();
    _currentRequestId = widget.requestId;
    if (widget.isEditMode) {
      _loadExistingPDF();
    }
  }

  Future<void> _loadExistingPDF() async {
    try {
      if (_currentRequestId != null) {
        final pdfPath = await _reportService.getPdfPath(_currentRequestId!, _lastGeneratedType ?? 'mir');
        setState(() {
          _pdfPath = pdfPath;
          _isPDFVisible = true;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading PDF: $e';
      });
    }
  }

  Future<void> _generateReport(String type) async {
    try {
      setState(() {
        _isGenerating = true;
        _error = null;
      });

      if (type == 'MIR') {
        // First navigate to Firstscreen for category selection
        if (mounted) {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => Firstscreen(
                projectData: widget.project,
                reportType: 'mir',
              ),
            ),
          );

          // Handle the category selection result
          if (mounted && result != null) {
            final categoryData = result as Map<String, dynamic>;
            final requestId = categoryData['requestId'] as String;
            final initialData = categoryData['initialData'] as MIRData;

            // Update the current request ID
            _currentRequestId = requestId;

            // Update the MIR data in Firestore
            await FirebaseFirestore.instance
                .collection('mir_data')
                .doc(requestId)
                .set(initialData.toMap());

            // Generate and display the PDF
            final filePath = await _reportService.generatePDFFromMIR(initialData);
            
            setState(() {
              _lastGeneratedPath = filePath;
              _lastGeneratedType = type;
              _pdfPath = filePath;
              _isPDFVisible = true;
            });
          }
        }
      } else if (type == 'IR') {
        // First navigate to Firstscreen for category selection
        if (mounted) {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => Firstscreen(
                projectData: widget.project,
                reportType: 'ir',
              ),
            ),
          );

          // Handle the category selection result
          if (mounted && result != null) {
            final categoryData = result as Map<String, dynamic>;
            final requestId = categoryData['requestId'] as String;
            final initialData = categoryData['initialData'] as IRData;

            // Update the current request ID
            _currentRequestId = requestId;

            // Update the IR data in Firestore
            await FirebaseFirestore.instance
                .collection('ir_data')
                .doc(requestId)
                .set(initialData.toMap());

            // Generate and display the PDF
            final filePath = await _reportService.generatePDFFromIR(initialData);
            
            setState(() {
              _lastGeneratedPath = filePath;
              _lastGeneratedType = type;
              _pdfPath = filePath;
              _isPDFVisible = true;
            });
          }
        }
      }
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

  Future<void> _saveChanges() async {
    if (_lastGeneratedPath == null || _lastGeneratedType == null || _currentRequestId == null) return;

    try {
      setState(() => _isSending = true);

      // Upload the updated PDF
      final pdfId = await _reportService.uploadPDF(_lastGeneratedPath!, _lastGeneratedType!);

      if (widget.isEditMode) {
        // Update existing approval request
        await FirebaseFirestore.instance
            .collection('approval_requests')
            .doc(_currentRequestId)
            .update({
          'pdfId': pdfId,
          'status': 'pending',
          'lastUpdated': FieldValue.serverTimestamp(),
          'recipientEmail': _recipientController.text.trim(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Report updated and sent for approval'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        }
      } else {
        // Create new approval request
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
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  Future<void> _navigateToMIREdit() async {
    if (_currentRequestId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No request ID found. Please generate a report first.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      // Get the MIR data from Firestore
      final mirDoc = await FirebaseFirestore.instance
          .collection('mir_data')
          .doc(_currentRequestId)
          .get();

      if (mirDoc.exists) {
        final mirData = MIRData.fromMap(mirDoc.data()!);
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MIREditScreen(
                requestId: _currentRequestId!,
                initialData: mirData,
                isCreator: widget.isCreator,
              ),
            ),
          );
        }
      } else {
        // If no MIR data exists, create initial data
        final initialData = MIRData(
          projectName: widget.project['projectDetails']['projectName'],
          contractNo: widget.project['projectDetails']['contractNo'] ?? 'A-17080',
          mirNo: widget.project['projectDetails']['mirNo'] ?? '',
        );

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MIREditScreen(
                requestId: _currentRequestId!,
                initialData: initialData,
                isCreator: widget.isCreator,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading MIR data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _navigateToIREdit() async {
    if (_currentRequestId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No request ID found. Please generate a report first.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      // Get the IR data from Firestore
      final irDoc = await FirebaseFirestore.instance
          .collection('ir_data')
          .doc(_currentRequestId)
          .get();

      if (irDoc.exists) {
        final irData = IRData.fromMap(irDoc.data()!);
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => IREditScreen(
                requestId: _currentRequestId!,
                initialData: irData,
                isCreator: widget.isCreator,
              ),
            ),
          );
        }
      } else {
        // If no IR data exists, create initial data
        final initialData = IRData(
          projectName: widget.project['projectDetails']['projectName'],
          contractNo: widget.project['projectDetails']['contractNo'] ?? 'A-17080',
          irNo: widget.project['projectDetails']['irNo'] ?? '',
        );

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => IREditScreen(
                requestId: _currentRequestId!,
                initialData: initialData,
                isCreator: widget.isCreator,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading IR data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF3949AB),
        title: Text(widget.isEditMode ? 'Edit Report' : 'Generate Report'),
        actions: [
          if (_isGenerating)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: CircularProgressIndicator(color: Colors.white),
              ),
            )
          else if (!_isPDFVisible)
            IconButton(
              icon: const Icon(Icons.preview),
              onPressed: () => _generateReport('MIR'),
              tooltip: 'Preview PDF',
            ),
        ],
      ),
      body: _isPDFVisible && _pdfPath != null
          ? Column(
              children: [
                Expanded(
                  child: PDFView(
                    filePath: _pdfPath!,
                    enableSwipe: true,
                    swipeHorizontal: false,
                    autoSpacing: false,
                    pageFling: false,
                    pageSnap: true,
                    defaultPage: 0,
                    fitPolicy: FitPolicy.BOTH,
                    preventLinkNavigation: false,
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          if (!widget.isEditMode) ...[
                            TextField(
                              controller: _recipientController,
                              decoration: const InputDecoration(
                                labelText: 'Recipient Email',
                                border: OutlineInputBorder(),
                                hintText: 'Enter email of the person to review',
                              ),
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 16),
                          ],
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: [
                              if (!_isSending) ...[
                                SizedBox(
                                  height: 48,
                                  child: ElevatedButton.icon(
                                    onPressed: _saveChanges,
                                    icon: const Icon(Icons.save, color: Colors.white),
                                    label: const Text('Save Changes'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF3949AB),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 24),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: 48,
                                  child: TextButton.icon(
                                    onPressed: !_isSending 
                                      ? (_lastGeneratedType == 'MIR' ? _navigateToMIREdit : _navigateToIREdit)
                                      : null,
                                    icon: const Icon(Icons.edit),
                                    label: Text('Edit ${_lastGeneratedType ?? "Report"}'),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 24),
                                    ),
                                  ),
                                ),
                              ] else
                                const SizedBox(
                                  height: 48,
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            )
          : Padding(
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
                ],
              ),
            ),
    );
  }
}