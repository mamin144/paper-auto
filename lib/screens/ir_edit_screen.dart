import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ir_data.dart';
import '../services/report_service.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class IREditScreen extends StatefulWidget {
  final String requestId;
  final IRData initialData;
  final bool isCreator;

  const IREditScreen({
    super.key,
    required this.requestId,
    required this.initialData,
    required this.isCreator,
  });

  @override
  State<IREditScreen> createState() => _IREditScreenState();
}

class _IREditScreenState extends State<IREditScreen> {
  late IRData _irData;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isPDFVisible = false;
  String? _pdfPath;
  final _reportService = ReportService();
  final _recipientController = TextEditingController();
  final List<String> _recipientEmails = [];
  final FocusNode _recipientFocusNode = FocusNode();
  final _supplierController = TextEditingController();
  final _manufacturerController = TextEditingController();
  final _countryController = TextEditingController();
  final _commentsController = TextEditingController();
  final List<BOQItem> _boqItems = [];

  @override
  void initState() {
    super.initState();
    _irData = widget.initialData;
    _supplierController.text = _irData.supplierDeliveryNote;
    _manufacturerController.text = _irData.manufacturer;
    _countryController.text = _irData.countryOfOrigin;
    _commentsController.text = _irData.engineerComments;
    _boqItems.addAll(_irData.boqItems);
    if (_boqItems.isEmpty) {
      _addNewBOQItem();
    }
    _recipientController.addListener(_handleRecipientInput);
  }

  @override
  void dispose() {
    _recipientController.removeListener(_handleRecipientInput);
    _recipientController.dispose();
    _recipientFocusNode.dispose();
    _supplierController.dispose();
    _manufacturerController.dispose();
    _countryController.dispose();
    _commentsController.dispose();
    super.dispose();
  }

  void _handleRecipientInput() {
    final text = _recipientController.text;
    if (text.endsWith(',') || text.endsWith(';') || text.endsWith(' ')) {
      final email = text.substring(0, text.length - 1).trim();
      if (email.isNotEmpty && _isValidEmail(email)) {
        setState(() {
          _recipientEmails.add(email);
          _recipientController.clear();
        });
      }
    }
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  void _removeRecipient(String email) {
    setState(() {
      _recipientEmails.remove(email);
    });
  }

  void _addRecipient(String email) {
    if (email.isNotEmpty && _isValidEmail(email) && !_recipientEmails.contains(email)) {
      setState(() {
        _recipientEmails.add(email);
        _recipientController.clear();
      });
    }
  }

  void _addNewBOQItem() {
    setState(() {
      _boqItems.add(BOQItem(
        refNo: '',
        description: '',
        unit: '',
        quantity: '',
        remarks: '',
      ));
    });
  }

  Future<void> _generatePDFPreview() async {
    setState(() => _isLoading = true);

    try {
      print('Starting PDF generation...');
      final updatedData = IRData(
        projectName: _irData.projectName,
        contractNo: _irData.contractNo,
        irNo: _irData.irNo,
        boqItems: _boqItems,
        masStatus: _irData.masStatus,
        dtsStatus: _irData.dtsStatus,
        dispatchStatus: _irData.dispatchStatus,
        supplierDeliveryNote: _supplierController.text,
        manufacturer: _manufacturerController.text,
        countryOfOrigin: _countryController.text,
        engineerComments: _commentsController.text,
        isSatisfactory: _irData.isSatisfactory,
        dateOfInspection: _irData.dateOfInspection,
      );
      print('IRData created successfully');

      print('Calling generatePDFFromIR...');
      final pdfPath = await _reportService.generatePDFFromIR(updatedData);
      print('PDF generated successfully at: $pdfPath');
      
      setState(() {
        _pdfPath = pdfPath;
        _isPDFVisible = true;
      });
    } catch (e, stackTrace) {
      print('Error generating PDF preview: $e');
      print('Stack trace: $stackTrace');
      final scaffoldMessenger = ScaffoldMessenger.of(this.context);
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error generating PDF preview: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _updateIRData({
    bool? isSatisfactory,
    String? masStatus,
    String? dtsStatus,
    String? dispatchStatus,
    String? irNo,
  }) {
    setState(() {
      _irData = IRData(
        projectName: _irData.projectName,
        contractNo: _irData.contractNo,
        irNo: irNo ?? _irData.irNo,
        boqItems: _boqItems,
        masStatus: masStatus ?? _irData.masStatus,
        dtsStatus: dtsStatus ?? _irData.dtsStatus,
        dispatchStatus: dispatchStatus ?? _irData.dispatchStatus,
        supplierDeliveryNote: _supplierController.text,
        manufacturer: _manufacturerController.text,
        countryOfOrigin: _countryController.text,
        engineerComments: _commentsController.text,
        isSatisfactory: isSatisfactory ?? _irData.isSatisfactory,
        dateOfInspection: _irData.dateOfInspection,
      );
    });
  }

  void _updateBOQItem(int index, {
    String? refNo,
    String? description,
    String? unit,
    String? quantity,
    String? remarks,
  }) {
    setState(() {
      _boqItems[index] = BOQItem(
        refNo: refNo ?? _boqItems[index].refNo,
        description: description ?? _boqItems[index].description,
        unit: unit ?? _boqItems[index].unit,
        quantity: quantity ?? _boqItems[index].quantity,
        remarks: remarks ?? _boqItems[index].remarks,
      );
    });
  }

  Future<String?> _getSignatureImagePath() async {
    final directory = await getApplicationDocumentsDirectory();
    final imagePath = join(directory.path, 'signature.png');
    final file = File(imagePath);
    if (await file.exists()) {
      return imagePath;
    }
    return null;
  }

  Future<void> _saveIR(bool approved) async {
    setState(() => _isLoading = true);

    try {
      if (widget.isCreator && _recipientEmails.isEmpty) {
        throw Exception('Please add at least one recipient email');
      }

      final updatedData = IRData(
        projectName: _irData.projectName,
        contractNo: _irData.contractNo,
        irNo: _irData.irNo,
        boqItems: _boqItems,
        masStatus: _irData.masStatus,
        dtsStatus: _irData.dtsStatus,
        dispatchStatus: _irData.dispatchStatus,
        supplierDeliveryNote: _supplierController.text,
        manufacturer: _manufacturerController.text,
        countryOfOrigin: _countryController.text,
        engineerComments: _commentsController.text,
        isSatisfactory: _irData.isSatisfactory,
        dateOfInspection: _irData.dateOfInspection,
      );

      // Get the original request to preserve sender information
      final requestDoc = await FirebaseFirestore.instance
          .collection('approval_requests')
          .doc(widget.requestId)
          .get();
      
      if (!requestDoc.exists) {
        throw Exception('Original approval request not found');
      }

      final requestData = requestDoc.data()!;

      // Update the IR data in Firestore first
      await FirebaseFirestore.instance
          .collection('ir_data')
          .doc(widget.requestId)
          .set(updatedData.toMap());

      // Generate and save the PDF
      String? signaturePath;
      if (approved) {
        signaturePath = await _getSignatureImagePath();
      }
      final pdfPath = await _reportService.generatePDFFromIR(updatedData, signaturePath: signaturePath);
      
      // Upload the PDF to storage with correct type
      final pdfId = await _reportService.uploadPDF(pdfPath, 'ir');

      if (widget.isCreator) {
        // Get the recipients' user IDs
        final recipientQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('email', whereIn: _recipientEmails)
            .get();

        if (recipientQuery.docs.isEmpty) {
          throw Exception('No valid recipients found');
        }

        // Create a new approval request for each recipient
        final batch = FirebaseFirestore.instance.batch();
        final newRequestRef = FirebaseFirestore.instance
            .collection('approval_requests')
            .doc();

        batch.set(newRequestRef, {
          'lastUpdated': FieldValue.serverTimestamp(),
          'irData': updatedData.toMap(),
          'status': 'pending',
          'pdfId': pdfId,
          'reviewerComments': '',
          'senderId': FirebaseAuth.instance.currentUser?.uid,
          'senderEmail': FirebaseAuth.instance.currentUser?.email,
          'recipientId': recipientQuery.docs.first.id,
          'recipientEmail': _recipientEmails.first,
          'createdAt': FieldValue.serverTimestamp(),
          'projectName': updatedData.projectName,
          'reportType': 'ir',
        });

        await batch.commit();

        final scaffoldMessenger = ScaffoldMessenger.of(this.context);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('IR sent to ${_recipientEmails.length} recipients'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(this.context).pop();
      } else {
        // If reviewer is editing, update with approval/rejection
        await FirebaseFirestore.instance
            .collection('approval_requests')
            .doc(widget.requestId)
            .update({
          'lastUpdated': FieldValue.serverTimestamp(),
          'irData': updatedData.toMap(),
          'status': approved ? 'approved' : 'rejected',
          'pdfId': pdfId,
          'reviewerComments': _commentsController.text,
          'senderId': requestData['recipientId'],
          'senderEmail': requestData['recipientEmail'],
          'recipientEmail': requestData['senderEmail'],
          'projectName': updatedData.projectName,
          'reportType': 'ir',
        });

        final scaffoldMessenger = ScaffoldMessenger.of(this.context);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(approved 
              ? 'IR approved and sent back to creator' 
              : 'IR rejected and sent back to creator'
            ),
            backgroundColor: approved ? Colors.green : Colors.red,
          ),
        );
        Navigator.of(this.context)
          ..pop() // Pop IREditScreen
          ..pop(); // Pop ApprovalDetailScreen
      }
    } catch (e) {
      final scaffoldMessenger = ScaffoldMessenger.of(this.context);
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error saving IR: $e'),
          backgroundColor: Colors.red,
        ),
      );
      rethrow;
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF3949AB),
        title: Text(widget.isCreator ? 'Edit Inspection Report' : 'Review Inspection Report'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: CircularProgressIndicator(color: Colors.white),
              ),
            )
          else if (!_isPDFVisible)
            IconButton(
              icon: const Icon(Icons.preview),
              onPressed: _generatePDFPreview,
              tooltip: 'Preview PDF',
            ),
        ],
      ),
      body: _isPDFVisible && _pdfPath != null
          ? Column(
              children: [
                Expanded(
                  child: _pdfPath!.isNotEmpty
                      ? PDFView(
                          filePath: _pdfPath!,
                          enableSwipe: true,
                          swipeHorizontal: false,
                          autoSpacing: false,
                          pageFling: false,
                          pageSnap: true,
                          defaultPage: 0,
                          fitPolicy: FitPolicy.BOTH,
                          preventLinkNavigation: false,
                        )
                      : const Center(
                          child: Text(
                            'PDF not available',
                            style: TextStyle(fontSize: 16),
                          ),
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
                          if (widget.isCreator) ...[
                            const Text(
                              'Recipients',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                children: [
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: _recipientEmails.map((email) => Chip(
                                      label: Text(email),
                                      deleteIcon: const Icon(Icons.close, size: 18),
                                      onDeleted: () => _removeRecipient(email),
                                      backgroundColor: const Color(0xFF3949AB).withOpacity(0.1),
                                    )).toList(),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _recipientController,
                                          focusNode: _recipientFocusNode,
                                          decoration: const InputDecoration(
                                            hintText: 'Type email and press Enter or add comma',
                                            border: InputBorder.none,
                                            contentPadding: EdgeInsets.symmetric(horizontal: 8),
                                          ),
                                          keyboardType: TextInputType.emailAddress,
                                          onSubmitted: (value) {
                                            _addRecipient(value);
                                          },
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add_circle_outline),
                                        onPressed: () {
                                          _addRecipient(_recipientController.text);
                                        },
                                        tooltip: 'Add recipient',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Press Enter or add comma to add recipient',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: [
                              if (!_isLoading) ...[
                                if (!widget.isCreator) ...[
                                  SizedBox(
                                    height: 48,
                                    child: ElevatedButton.icon(
                                      onPressed: () async {
                                        setState(() => _isLoading = true);
                                        try {
                                          await _saveIR(true);
                                        } catch (e) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(this.context).showSnackBar(
                                              SnackBar(
                                                content: Text('Error: $e'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        } finally {
                                          if (mounted) {
                                            setState(() => _isLoading = false);
                                          }
                                        }
                                      },
                                      icon: const Icon(Icons.check, color: Colors.white),
                                      label: const Text('Approve Changes'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 24),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: 48,
                                    child: ElevatedButton.icon(
                                      onPressed: () async {
                                        setState(() => _isLoading = true);
                                        try {
                                          await _saveIR(false);
                                        } catch (e) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(this.context).showSnackBar(
                                              SnackBar(
                                                content: Text('Error: $e'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        } finally {
                                          if (mounted) {
                                            setState(() => _isLoading = false);
                                          }
                                        }
                                      },
                                      icon: const Icon(Icons.close, color: Colors.white),
                                      label: const Text('Reject Changes'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 24),
                                      ),
                                    ),
                                  ),
                                ] else ...[
                                  SizedBox(
                                    height: 48,
                                    child: ElevatedButton.icon(
                                      onPressed: () async {
                                        if (_recipientEmails.isEmpty) {
                                          ScaffoldMessenger.of(this.context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Please add at least one recipient'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                          return;
                                        }
                                        setState(() => _isLoading = true);
                                        try {
                                          await _saveIR(true);
                                        } catch (e) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(this.context).showSnackBar(
                                              SnackBar(
                                                content: Text('Error: $e'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        } finally {
                                          if (mounted) {
                                            setState(() => _isLoading = false);
                                          }
                                        }
                                      },
                                      icon: const Icon(Icons.save, color: Colors.white),
                                      label: const Text('Save Changes'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF3949AB),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 24),
                                      ),
                                    ),
                                  ),
                                ],
                                SizedBox(
                                  height: 48,
                                  child: TextButton.icon(
                                    onPressed: !_isLoading 
                                      ? () => setState(() => _isPDFVisible = false)
                                      : null,
                                    icon: const Icon(Icons.edit),
                                    label: const Text('Back to Edit'),
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
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Project Info Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Project Information',
                                style: Theme.of(this.context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Project: ${_irData.projectName}',
                                style: Theme.of(this.context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Contract No: ${_irData.contractNo}',
                                style: Theme.of(this.context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                initialValue: _irData.irNo,
                                decoration: const InputDecoration(
                                  labelText: 'IR No.',
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (value) {
                                  _updateIRData(irNo: value);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // BOQ Items Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'BOQ Items',
                                    style: Theme.of(this.context).textTheme.titleLarge,
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: _addNewBOQItem,
                                    icon: const Icon(Icons.add),
                                    label: const Text('Add Item'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF3949AB),
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Scroll indicator text
                              Row(
                                children: [
                                  Icon(Icons.swipe, color: Colors.grey[600]),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Swipe horizontally to see more',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Horizontal scroll indicator
                              Container(
                                height: 2,
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Theme.of(this.context).primaryColor,
                                      Theme.of(this.context).primaryColor.withOpacity(0.1),
                                    ],
                                  ),
                                ),
                              ),
                              Scrollbar(
                                thickness: 8,
                                radius: const Radius.circular(4),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey[300]!),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: DataTable(
                                      columnSpacing: 16,
                                      horizontalMargin: 8,
                                      headingRowColor: MaterialStateProperty.all(
                                        const Color(0xFF3949AB).withOpacity(0.1),
                                      ),
                                      columns: const [
                                        DataColumn(
                                          label: Text(
                                            'Ref No.',
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        DataColumn(
                                          label: Text(
                                            'Description',
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        DataColumn(
                                          label: Text(
                                            'Unit',
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        DataColumn(
                                          label: Text(
                                            'Quantity',
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        DataColumn(
                                          label: Text(
                                            'Remarks',
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        DataColumn(
                                          label: Text(
                                            'Actions',
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                      rows: _boqItems.asMap().entries.map((entry) {
                                        final index = entry.key;
                                        final item = entry.value;
                                        return DataRow(
                                          cells: [
                                            DataCell(
                                              SizedBox(
                                                width: 100,
                                                child: TextFormField(
                                                  initialValue: item.refNo,
                                                  decoration: const InputDecoration(
                                                    isDense: true,
                                                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                                    border: OutlineInputBorder(),
                                                  ),
                                                  onChanged: (value) => _updateBOQItem(
                                                    index,
                                                    refNo: value,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              SizedBox(
                                                width: 200,
                                                child: TextFormField(
                                                  initialValue: item.description,
                                                  decoration: const InputDecoration(
                                                    isDense: true,
                                                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                                    border: OutlineInputBorder(),
                                                  ),
                                                  onChanged: (value) => _updateBOQItem(
                                                    index,
                                                    description: value,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              SizedBox(
                                                width: 80,
                                                child: TextFormField(
                                                  initialValue: item.unit,
                                                  decoration: const InputDecoration(
                                                    isDense: true,
                                                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                                    border: OutlineInputBorder(),
                                                  ),
                                                  onChanged: (value) => _updateBOQItem(
                                                    index,
                                                    unit: value,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              SizedBox(
                                                width: 100,
                                                child: TextFormField(
                                                  initialValue: item.quantity,
                                                  decoration: const InputDecoration(
                                                    isDense: true,
                                                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                                    border: OutlineInputBorder(),
                                                  ),
                                                  onChanged: (value) => _updateBOQItem(
                                                    index,
                                                    quantity: value,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              SizedBox(
                                                width: 150,
                                                child: TextFormField(
                                                  initialValue: item.remarks,
                                                  decoration: const InputDecoration(
                                                    isDense: true,
                                                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                                    border: OutlineInputBorder(),
                                                  ),
                                                  onChanged: (value) => _updateBOQItem(
                                                    index,
                                                    remarks: value,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(Icons.delete),
                                                    color: Colors.red,
                                                    onPressed: () {
                                                      setState(() {
                                                        _boqItems.removeAt(index);
                                                      });
                                                    },
                                                  ),
                                                  if (index == _boqItems.length - 1)
                                                    Icon(
                                                      Icons.keyboard_arrow_right,
                                                      color: Colors.grey[400],
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Additional Details Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Additional Details',
                                style: Theme.of(this.context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _supplierController,
                                decoration: const InputDecoration(
                                  labelText: 'Supplier Delivery Note/Date',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _manufacturerController,
                                decoration: const InputDecoration(
                                  labelText: 'Manufacturer',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _countryController,
                                decoration: const InputDecoration(
                                  labelText: 'Country of Origin',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // MAS/FAT Report Status Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'MAS/FAT Report Status',
                                style: Theme.of(this.context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                value: _irData.masStatus.isEmpty ? null : _irData.masStatus,
                                decoration: const InputDecoration(
                                  labelText: 'MAS Status',
                                  border: OutlineInputBorder(),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'approved', child: Text('Approved')),
                                  DropdownMenuItem(value: 'pending', child: Text('Pending')),
                                  DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                                ],
                                onChanged: (value) => _updateIRData(masStatus: value),
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                value: _irData.dtsStatus.isEmpty ? null : _irData.dtsStatus,
                                decoration: const InputDecoration(
                                  labelText: 'DTS Status',
                                  border: OutlineInputBorder(),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'approved', child: Text('Approved')),
                                  DropdownMenuItem(value: 'pending', child: Text('Pending')),
                                  DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                                ],
                                onChanged: (value) => _updateIRData(dtsStatus: value),
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                value: _irData.dispatchStatus.isEmpty ? null : _irData.dispatchStatus,
                                decoration: const InputDecoration(
                                  labelText: 'Dispatch Clearance Status',
                                  border: OutlineInputBorder(),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'approved', child: Text('Approved')),
                                  DropdownMenuItem(value: 'pending', child: Text('Pending')),
                                  DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                                ],
                                onChanged: (value) => _updateIRData(dispatchStatus: value),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Engineer's Comments Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Engineer's Comments",
                                style: Theme.of(this.context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _commentsController,
                                maxLines: 3,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  hintText: 'Enter comments here...',
                                ),
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 16,
                                runSpacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  const Text('Inspection Result:', style: TextStyle(fontSize: 16)),
                                  ChoiceChip(
                                    label: const Text('Satisfactory'),
                                    selected: _irData.isSatisfactory,
                                    onSelected: (selected) {
                                      _updateIRData(isSatisfactory: true);
                                    },
                                  ),
                                  ChoiceChip(
                                    label: const Text('Unsatisfactory'),
                                    selected: !_irData.isSatisfactory,
                                    onSelected: (selected) {
                                      _updateIRData(isSatisfactory: false);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
} 