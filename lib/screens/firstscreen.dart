import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:paperauto/widget/HomeDrawer.dart';
import 'package:paperauto/widget/button.dart';
import 'package:paperauto/screens/approval_requests_screen.dart';
import 'package:paperauto/models/mir_data.dart';
import 'package:paperauto/models/ir_data.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:paperauto/screens/mir_edit_screen.dart';
import 'package:paperauto/screens/ir_edit_screen.dart';

class PDFViewerPage extends StatelessWidget {
  const PDFViewerPage({super.key});

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
  final String? reportType;

  const Firstscreen({
    Key? key, 
    this.projectData,
    this.reportType = 'mir',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Select Category for ${reportType?.toUpperCase() ?? 'MIR'}"),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 25,
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: const Color.fromARGB(255, 17, 2, 98),
        actions: [
          IconButton(
            icon: const Icon(Icons.approval),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ApprovalRequestsScreen()),
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
                  
                  if (reportType == 'mir') {
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MIREditScreen(
                          requestId: '',
                          initialData: initialData,
                          isCreator: true,
                        ),
                      ),
                    );
                  } else {
                    final irNo = ' 24projectName- 24contractNo-IR-Civil';
                    final initialData = IRData(
                      projectName: projectName,
                      contractNo: contractNo,
                      irNo: irNo,
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => IREditScreen(
                          requestId: '',
                          initialData: initialData,
                          isCreator: true,
                        ),
                      ),
                    );
                  }
                }
              }
            ),
            const SizedBox(height: 20),
            WidgetButton(
              text: 'mechanical',
              onPressed: () async {
                if (projectData != null) {
                  final projectName = projectData!['projectDetails']?['projectName'] ?? '';
                  final contractNo = projectData!['projectDetails']?['contractNo'] ?? '';
                  if (reportType == 'mir') {
                    final mirNo = ' 24projectName- 24contractNo-MIR-Mechanical';
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MIREditScreen(
                          requestId: '',
                          initialData: initialData,
                          isCreator: true,
                        ),
                      ),
                    );
                  } else {
                    final irNo = ' 24projectName- 24contractNo-IR-Mechanical';
                    final initialData = IRData(
                      projectName: projectName,
                      contractNo: contractNo,
                      irNo: irNo,
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => IREditScreen(
                          requestId: '',
                          initialData: initialData,
                          isCreator: true,
                        ),
                      ),
                    );
                  }
                }
              }
            ),
            const SizedBox(height: 20),
            WidgetButton(
              text: 'Approval Requests',
              onPressed: () => _navigateTo(context, const ApprovalRequestsScreen()),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color.fromARGB(255, 17, 2, 98),
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
