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
      final doc = await FirebaseFirestore.instance
          .collection('mir_data')
          .doc(requestId)
          .get();

      if (doc.exists) {
        return MIRData.fromMap(doc.data()!);
      }

      // If no data exists, create initial data
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
        backgroundColor: const Color(0xFF3949AB),
        title: Text(projectName),
      ),
      body: Column(
        children: [
          Expanded(
            child: PDFView(
              filePath: pdfPath,
              enableSwipe: true,
              swipeHorizontal: true,
              autoSpacing: false,
              pageFling: false,
            ),
          ),
          if (!isReadOnly)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        await _updateApprovalStatus('rejected');
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
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
                  ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        await _updateApprovalStatus('approved');
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
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
                ],
              ),
            ),
        ],
      ),
      floatingActionButton: !isReadOnly
          ? FloatingActionButton.extended(
              onPressed: () async {
                final mirData = await _getMIRData();
                if (mirData != null && context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MIREditScreen(
                        requestId: requestId,
                        initialData: mirData,
                      ),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.edit_document),
              label: const Text('Edit MIR'),
              backgroundColor: const Color(0xFF3949AB),
            )
          : null,
    );
  }
} 