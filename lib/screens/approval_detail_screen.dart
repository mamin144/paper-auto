import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/mir_data.dart';
import 'mir_edit_screen.dart';

class ApprovalDetailScreen extends StatelessWidget {
  final String pdfPath;
  final String requestId;
  final String projectName;
  final bool isReadOnly;

  const ApprovalDetailScreen({
    super.key,
    required this.pdfPath,
    required this.requestId,
    required this.projectName,
    required this.isReadOnly,
  });

  Future<void> _updateApprovalStatus(String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('approval_requests')
          .doc(requestId)
          .update({
            'status': status,
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      debugPrint('Error updating approval status: $e');
      rethrow;
    }
  }

  Future<MIRData?> _getMIRData() async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('mir_data')
              .doc(requestId)
              .get();

      if (doc.exists) {
        return MIRData.fromMap(doc.data()!);
      }

      final initialData = MIRData(
        projectName: projectName,
        contractNo: 'A-17080',
      );

      await FirebaseFirestore.instance
          .collection('mir_data')
          .doc(requestId)
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
        backgroundColor: const Color(0xFF1A237E),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.description, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                projectName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.info_outline, color: Colors.white),
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A237E).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.info_outline,
                              color: Color(0xFF1A237E),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text('Document Information'),
                        ],
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow('Project', projectName),
                          const SizedBox(height: 12),
                          _buildInfoRow('Request ID', requestId),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            'Status',
                            isReadOnly ? 'Read Only' : 'Pending',
                            isReadOnly ? Colors.grey : Colors.orange,
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
              );
            },
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
        child: Column(
          children: [
            if (!isReadOnly)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                color: Colors.orange.withOpacity(0.1),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Pending Approval',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: PDFView(
                    filePath: pdfPath,
                    enableSwipe: true,
                    swipeHorizontal: true,
                    autoSpacing: false,
                    pageFling: false,
                    onError: (error) {
                      debugPrint('PDF Error: $error');
                    },
                    onPageError: (page, error) {
                      debugPrint('Page Error: $page - $error');
                    },
                  ),
                ),
              ),
            ),
            if (!isReadOnly)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      icon: Icons.close,
                      label: 'Reject',
                      color: Colors.red,
                      onPressed: () async {
                        try {
                          await _updateApprovalStatus('rejected');
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                    ),
                    _buildActionButton(
                      icon: Icons.check,
                      label: 'Approve',
                      color: Colors.green,
                      onPressed: () async {
                        try {
                          await _updateApprovalStatus('approved');
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      floatingActionButton:
          !isReadOnly
              ? FloatingActionButton.extended(
                onPressed: () async {
                  final mirData = await _getMIRData();
                  if (mirData != null && context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => MIREditScreen(
                              requestId: requestId,
                              initialData: mirData,
                            ),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.edit_document),
                label: const Text('Edit MIR'),
                backgroundColor: const Color(0xFF1A237E),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              )
              : null,
    );
  }

  Widget _buildInfoRow(String label, String value, [Color? valueColor]) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      ),
    );
  }
}
