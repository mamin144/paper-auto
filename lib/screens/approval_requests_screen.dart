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
      stream:
          FirebaseFirestore.instance
              .collection('approval_requests')
              .where('status', isEqualTo: status)
              .orderBy('createdAt', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A237E)),
            ),
          );
        }

        final requests = snapshot.data?.docs ?? [];

        final filteredRequests =
            requests.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final email =
                  _showSentRequests
                      ? data['senderEmail']
                      : data['recipientEmail'];
              return email == currentUser?.email;
            }).toList();

        if (filteredRequests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  status == 'pending'
                      ? Icons.pending_actions
                      : status == 'approved'
                      ? Icons.check_circle
                      : Icons.cancel,
                  size: 64,
                  color: const Color(0xFF1A237E).withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No ${status.toLowerCase()} requests',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredRequests.length,
          itemBuilder: (context, index) {
            final requestData = filteredRequests[index].data();
            if (requestData == null || requestData is! Map<String, dynamic>) {
              return const Card(
                child: ListTile(
                  title: Text('Error: Invalid request data'),
                  leading: Icon(Icons.error, color: Colors.red),
                ),
              );
            }
            final request = requestData as Map<String, dynamic>;
            final requestId = filteredRequests[index].id;

            final projectName =
                request['reportType']?.toString() ?? 'Unknown Project';
            final reportType = request['reportType']?.toString() ?? 'N/A';
            final recipientEmail =
                request['recipientEmail']?.toString() ?? 'N/A';
            final senderEmail = request['senderEmail']?.toString() ?? 'N/A';
            final pdfId = request['pdfId']?.toString() ?? '';

            final timestamp = request['createdAt'] as Timestamp?;
            final dateString =
                timestamp?.toDate().toString().split('.')[0] ?? 'No Date';

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
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
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () async {
                    try {
                      final pdfPath = await _reportService.getPdfPath(pdfId);
                      if (context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => ApprovalDetailScreen(
                                  pdfPath: pdfPath,
                                  requestId: requestId,
                                  projectName: projectName,
                                  isReadOnly:
                                      _showSentRequests || status != 'pending',
                                ),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error loading PDF: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A237E).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.description,
                                color: const Color(0xFF1A237E),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                projectName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A237E),
                                ),
                              ),
                            ),
                            if (status != 'pending')
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      status == 'approved'
                                          ? Colors.green.withOpacity(0.1)
                                          : Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  status[0].toUpperCase() + status.substring(1),
                                  style: TextStyle(
                                    color:
                                        status == 'approved'
                                            ? Colors.green
                                            : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow('Type', reportType, Icons.assignment),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          _showSentRequests ? 'To' : 'From',
                          _showSentRequests ? recipientEmail : senderEmail,
                          Icons.person,
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow('Date', dateString, Icons.calendar_today),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
        Text(
          value,
          style: const TextStyle(color: Colors.black87, fontSize: 14),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF1A237E),
          title: const Text(
            'Approval Requests',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment<bool>(
                    value: false,
                    icon: Icon(Icons.download, size: 20),
                    label: Text('Received'),
                  ),
                  ButtonSegment<bool>(
                    value: true,
                    icon: Icon(Icons.upload, size: 20),
                    label: Text('Sent'),
                  ),
                ],
                selected: {_showSentRequests},
                onSelectionChanged: (Set<bool> newSelection) {
                  setState(() {
                    _showSentRequests = newSelection.first;
                  });
                },
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.resolveWith<Color>((
                    Set<MaterialState> states,
                  ) {
                    if (states.contains(MaterialState.selected)) {
                      return Colors.white.withOpacity(0.2);
                    }
                    return Colors.transparent;
                  }),
                  foregroundColor: MaterialStateProperty.all(Colors.white),
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ],
          bottom: TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            tabs: [
              Tab(
                icon: const Icon(Icons.pending),
                child: Text(
                  'Pending',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ),
              Tab(
                icon: const Icon(Icons.check_circle),
                child: Text(
                  'Approved',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ),
              Tab(
                icon: const Icon(Icons.cancel),
                child: Text(
                  'Rejected',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
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
          child: TabBarView(
            children: [
              _buildRequestsList(context, 'pending'),
              _buildRequestsList(context, 'approved'),
              _buildRequestsList(context, 'rejected'),
            ],
          ),
        ),
      ),
    );
  }
}
