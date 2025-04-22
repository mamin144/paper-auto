import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:paperauto/services/report_service.dart';
import 'package:paperauto/screens/approval_detail_screen.dart';

class ApprovalRequestsScreen extends StatefulWidget {
  const ApprovalRequestsScreen({super.key});

  @override
  State<ApprovalRequestsScreen> createState() => _ApprovalRequestsScreenState();
}

class _ApprovalRequestsScreenState extends State<ApprovalRequestsScreen> {
  final ReportService _reportService = ReportService();
  bool _showSentRequests = false;

  Widget _buildRequestsList(BuildContext context, String status) {
    final currentUser = FirebaseAuth.instance.currentUser;
    
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('approval_requests')
          .where('status', isEqualTo: status)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final requests = snapshot.data?.docs ?? [];
        
        // Filter the requests client-side based on email
        final filteredRequests = requests.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final email = _showSentRequests ? data['senderEmail'] : data['recipientEmail'];
          return email == currentUser?.email;
        }).toList();

        if (filteredRequests.isEmpty) {
          return Center(
            child: Text('No ${status.toLowerCase()} requests'),
          );
        }

        return ListView.builder(
          itemCount: filteredRequests.length,
          itemBuilder: (context, index) {
            final request = filteredRequests[index].data() as Map<String, dynamic>;
            final requestId = filteredRequests[index].id;
            final timestamp = request['createdAt'] as Timestamp;
            final date = timestamp.toDate();

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text('Project: ${request['projectName']}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Type: ${request['reportType']}'),
                    Text(_showSentRequests 
                      ? 'To: ${request['recipientEmail']}'
                      : 'From: ${request['senderEmail']}'),
                    Text('Date: ${date.toString().split('.')[0]}'),
                    if (status != 'pending')
                      Text(
                        'Status: ${status[0].toUpperCase() + status.substring(1)}',
                        style: TextStyle(
                          color: status == 'approved' ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.visibility),
                      onPressed: () async {
                        try {
                          final pdfPath = await _reportService.getPdfPath(request['pdfId'], request['reportType'] ?? 'mir');
                          if (context.mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ApprovalDetailScreen(
                                  pdfPath: pdfPath,
                                  requestId: requestId,
                                  projectName: request['projectName'],
                                  isReadOnly: _showSentRequests || status != 'pending',
                                  isCreator: request['senderEmail'] == FirebaseAuth.instance.currentUser?.email,
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error loading PDF: $e')),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF3949AB),
          title: const Text('Approval Requests'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment<bool>(
                    value: false,
                    icon: Icon(Icons.download, size: 20),
                  ),
                  ButtonSegment<bool>(
                    value: true,
                    icon: Icon(Icons.upload, size: 20),
                  ),
                ],
                selected: {_showSentRequests},
                onSelectionChanged: (Set<bool> newSelection) {
                  setState(() {
                    _showSentRequests = newSelection.first;
                  });
                },
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.resolveWith<Color>(
                    (Set<MaterialState> states) {
                      if (states.contains(MaterialState.selected)) {
                        return Colors.white.withOpacity(0.2);
                      }
                      return Colors.transparent;
                    },
                  ),
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(
                icon: Icon(Icons.pending),
                text: 'Pending',
              ),
              Tab(
                icon: Icon(Icons.check_circle),
                text: 'Approved',
              ),
              Tab(
                icon: Icon(Icons.cancel),
                text: 'Rejected',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildRequestsList(context, 'pending'),
            _buildRequestsList(context, 'approved'),
            _buildRequestsList(context, 'rejected'),
          ],
        ),
      ),
    );
  }
} 