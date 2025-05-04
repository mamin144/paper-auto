import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/mir_data.dart';
import '../services/report_service.dart';
import 'mir_edit_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ApprovalDetailScreen extends StatefulWidget {
  final String pdfPath;
  final String requestId;
  final String projectName;
  final bool isReadOnly;
  final bool isCreator;

  const ApprovalDetailScreen({
    super.key,
    required this.pdfPath,
    required this.requestId,
    required this.projectName,
    required this.isReadOnly,
    required this.isCreator,
  });

  @override
  State<ApprovalDetailScreen> createState() => _ApprovalDetailScreenState();
}

class _ApprovalDetailScreenState extends State<ApprovalDetailScreen> {
  String? _loadedPdfPath;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    try {
      setState(() => _isLoading = true);
      
      // Get the request details to check the type
      final requestDoc = await FirebaseFirestore.instance
          .collection('approval_requests')
          .doc(widget.requestId)
          .get();

      if (!requestDoc.exists) {
        throw Exception('Request not found');
      }

      final requestData = requestDoc.data()!;
      final String documentType = requestData['type'] ?? 'mir'; // Default to 'mir' if not specified
      
      // Get the PDF from storage with correct type
      final reportService = ReportService();
      final pdfPath = await reportService.getPdfPath(requestData['pdfId'], documentType);

      setState(() {
        _loadedPdfPath = pdfPath;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading PDF: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateApprovalStatus(String status) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance
          .collection('approval_requests')
          .doc(widget.requestId)
          .update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
        'reviewerName': user?.displayName ?? user?.email,
        'reviewerEmail': user?.email,
      });
    } catch (e) {
      debugPrint('Error updating approval status: $e');
      rethrow;
    }
  }

  Future<MIRData?> _getMIRData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('mir_data')
          .doc(widget.requestId)
          .get();

      if (doc.exists) {
        return MIRData.fromMap(doc.data()!);
      }

      // If no data exists, create initial data
      final initialData = MIRData(
        projectName: widget.projectName,
        contractNo: 'A-17080',
      );

      await FirebaseFirestore.instance
          .collection('mir_data')
          .doc(widget.requestId)
          .set(initialData.toMap());

      return initialData;
    } catch (e) {
      debugPrint('Error getting MIR data: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF3949AB),
        title: const Text('Review Document'),
        actions: [
          if (!widget.isReadOnly)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final mirData = await _getMIRData();
                if (mirData != null && mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MIREditScreen(
                        requestId: widget.requestId,
                        initialData: mirData,
                        isCreator: widget.isCreator,
                      ),
                    ),
                  );
                }
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadPdf,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: _loadedPdfPath != null
                          ? PDFView(
                              filePath: _loadedPdfPath!,
                              enableSwipe: true,
                              swipeHorizontal: false,
                              autoSpacing: false,
                              pageFling: false,
                              pageSnap: true,
                              defaultPage: 0,
                              fitPolicy: FitPolicy.BOTH,
                              preventLinkNavigation: false,
                              onError: (error) {
                                setState(() {
                                  _error = error.toString();
                                });
                              },
                            )
                          : const Center(
                              child: Text('PDF not available'),
                            ),
                    ),
                    if (!widget.isReadOnly)
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
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    try {
                                      await _updateApprovalStatus('approved');
                                      if (mounted) {
                                        Navigator.pop(context);
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Error: $e'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  icon: const Icon(Icons.check),
                                  label: const Text('Approve'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    try {
                                      await _updateApprovalStatus('rejected');
                                      if (mounted) {
                                        Navigator.pop(context);
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Error: $e'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  icon: const Icon(Icons.close),
                                  label: const Text('Reject'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }
} 