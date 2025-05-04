import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:paperauto/screens/create_project.dart';
import 'package:paperauto/widget/HomeDrawer.dart';
import 'package:paperauto/widget/button.dart';
import 'package:paperauto/screens/approval_requests_screen.dart';
import 'package:paperauto/screens/mir_edit_screen.dart';
import 'package:paperauto/models/mir_data.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PDFViewerPage extends StatelessWidget {
  const PDFViewerPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Viewer'),
        backgroundColor: Color.fromARGB(255, 17, 2, 98),
      ),
      body: PDFView(
        filePath: 'path_to_your_pdf.pdf', // Replace with your PDF path
      ),
    );
  }
}

class Firstscreen extends StatelessWidget {
  final Map<String, dynamic>? projectData;

  const Firstscreen({
    Key? key, 
    this.projectData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Category"),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 25,
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: Color.fromARGB(255, 17, 2, 98),
        actions: [
          IconButton(
            icon: const Icon(Icons.approval),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ApprovalRequestsScreen()),
              );
            },
            tooltip: 'Approval Requests',
          ),
        ],
      ),
      drawer: HomeDrawer(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            WidgetButton(
              text: 'civil',
              onPressed: () async {
                if (projectData != null) {
                  final projectName = projectData!['projectDetails']?['projectName'] ?? '';
                  final contractNo = projectData!['projectDetails']?['contractNo'] ?? '';
                  final mirNo = '$projectName-$contractNo-MIR-Civil';

                  final initialData = MIRData(
                    projectName: projectName,
                    contractNo: contractNo,
                    mirNo: mirNo,
                    boqItems: [],
                    masStatus: '',
                    dtsStatus: '',
                    dispatchStatus: '',
                    supplierDeliveryNote: '',
                    manufacturer: '',
                    countryOfOrigin: '',
                    engineerComments: '',
                    isSatisfactory: true,
                    dateOfInspection: DateTime.now(),
                  );

                  // Create Firestore document to get requestId
                  final docRef = await FirebaseFirestore.instance.collection('approval_requests').add({
                    'createdAt': FieldValue.serverTimestamp(),
                    'lastUpdated': FieldValue.serverTimestamp(),
                    'status': 'pending',
                    'projectName': projectName,
                    'reportType': 'mir',
                    'senderId': FirebaseAuth.instance.currentUser?.uid,
                    'senderEmail': FirebaseAuth.instance.currentUser?.email,
                    'mirNo': mirNo,
                  });

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MIREditScreen(
                        requestId: docRef.id,
                        initialData: initialData,
                        isCreator: true,
                      ),
                    ),
                  );
                }
              }
            ),
            SizedBox(height: 20),
            WidgetButton(
              text: 'mechanical',
              onPressed: () async {
                if (projectData != null) {
                  final projectName = projectData!['projectDetails']?['projectName'] ?? '';
                  final contractNo = projectData!['projectDetails']?['contractNo'] ?? '';
                  final mirNo = '$projectName-$contractNo-MIR-Mechanical';

                  final initialData = MIRData(
                    projectName: projectName,
                    contractNo: contractNo,
                    mirNo: mirNo,
                    boqItems: [],
                    masStatus: '',
                    dtsStatus: '',
                    dispatchStatus: '',
                    supplierDeliveryNote: '',
                    manufacturer: '',
                    countryOfOrigin: '',
                    engineerComments: '',
                    isSatisfactory: true,
                    dateOfInspection: DateTime.now(),
                  );

                  // Create Firestore document to get requestId
                  final docRef = await FirebaseFirestore.instance.collection('approval_requests').add({
                    'createdAt': FieldValue.serverTimestamp(),
                    'lastUpdated': FieldValue.serverTimestamp(),
                    'status': 'pending',
                    'projectName': projectName,
                    'reportType': 'mir',
                    'senderId': FirebaseAuth.instance.currentUser?.uid,
                    'senderEmail': FirebaseAuth.instance.currentUser?.email,
                    'mirNo': mirNo,
                  });

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MIREditScreen(
                        requestId: docRef.id,
                        initialData: initialData,
                        isCreator: true,
                      ),
                    ),
                  );
                }
              }
            ),
            SizedBox(height: 20),
            WidgetButton(
              text: 'Approval Requests',
              onPressed: () => _navigateTo(context, ApprovalRequestsScreen()),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color.fromARGB(255, 17, 2, 98),
        onPressed: () {
          Navigator.of(context).pop();
        },
        child: const Icon(Icons.arrow_back),
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }
}
