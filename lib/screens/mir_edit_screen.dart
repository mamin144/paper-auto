import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/mir_data.dart';
import '../services/report_service.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

class MIREditScreen extends StatefulWidget {
  final String requestId;
  final MIRData initialData;

  const MIREditScreen({
    super.key,
    required this.requestId,
    required this.initialData,
  });

  @override
  State<MIREditScreen> createState() => _MIREditScreenState();
}

class _MIREditScreenState extends State<MIREditScreen> {
  late MIRData _mirData;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isPDFVisible = false;
  String? _pdfPath;
  final _reportService = ReportService();

  // Controllers
  final _supplierController = TextEditingController();
  final _manufacturerController = TextEditingController();
  final _countryController = TextEditingController();
  final _commentsController = TextEditingController();
  final List<BOQItem> _boqItems = [];

  @override
  void initState() {
    super.initState();
    _mirData = widget.initialData;
    _supplierController.text = _mirData.supplierDeliveryNote;
    _manufacturerController.text = _mirData.manufacturer;
    _countryController.text = _mirData.countryOfOrigin;
    _commentsController.text = _mirData.engineerComments;
    _boqItems.addAll(_mirData.boqItems);
    if (_boqItems.isEmpty) {
      _addNewBOQItem();
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
      final updatedData = MIRData(
        projectName: _mirData.projectName,
        contractNo: _mirData.contractNo,
        boqItems: _boqItems,
        masStatus: _mirData.masStatus,
        dtsStatus: _mirData.dtsStatus,
        dispatchStatus: _mirData.dispatchStatus,
        supplierDeliveryNote: _supplierController.text,
        manufacturer: _manufacturerController.text,
        countryOfOrigin: _countryController.text,
        engineerComments: _commentsController.text,
        isSatisfactory: _mirData.isSatisfactory,
        dateOfInspection: _mirData.dateOfInspection,
      );

      final pdfPath = await _reportService.generatePDFFromMIR(updatedData);
      setState(() {
        _pdfPath = pdfPath;
        _isPDFVisible = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF preview: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveMIR(bool approved) async {
    // Remove form validation since we're in PDF preview mode
    setState(() => _isLoading = true);

    try {
      // First generate the final PDF with all changes
      final updatedData = MIRData(
        projectName: _mirData.projectName,
        contractNo: _mirData.contractNo,
        boqItems: _boqItems,
        masStatus: _mirData.masStatus,
        dtsStatus: _mirData.dtsStatus,
        dispatchStatus: _mirData.dispatchStatus,
        supplierDeliveryNote: _supplierController.text,
        manufacturer: _manufacturerController.text,
        countryOfOrigin: _countryController.text,
        engineerComments: _commentsController.text,
        isSatisfactory: _mirData.isSatisfactory,
        dateOfInspection: _mirData.dateOfInspection,
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

      // Update the MIR data in Firestore first
      await FirebaseFirestore.instance
          .collection('mir_data')
          .doc(widget.requestId)
          .set(updatedData.toMap());

      // Generate and save the PDF
      final pdfPath = await _reportService.generatePDFFromMIR(updatedData);
      
      // Upload the PDF to storage
      final pdfId = await _reportService.uploadPDF(pdfPath, 'mir');

      // Update the approval request with the latest status and PDF
      await FirebaseFirestore.instance
          .collection('approval_requests')
          .doc(widget.requestId)
          .update({
        'lastUpdated': FieldValue.serverTimestamp(),
        'mirData': updatedData.toMap(),
        'status': approved ? 'approved' : 'rejected',
        'pdfId': pdfId,
        'reviewerComments': _commentsController.text,
        // Preserve original sender and recipient information
        'senderId': requestData['senderId'],
        'senderEmail': requestData['senderEmail'],
        'recipientEmail': requestData['recipientEmail'],
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(approved 
              ? 'MIR approved and sent back to sender' 
              : 'MIR rejected and sent back to sender'
            ),
            backgroundColor: approved ? Colors.green : Colors.red,
          ),
        );
        // Pop twice to go back to the approval requests screen
        Navigator.of(context)
          ..pop() // Pop MIREditScreen
          ..pop(); // Pop ApprovalDetailScreen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving MIR: $e'),
            backgroundColor: Colors.red,
          ),
        );
        rethrow; // Re-throw to be caught by the button's error handler
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _updateMIRData({
    bool? isSatisfactory,
    String? masStatus,
    String? dtsStatus,
    String? dispatchStatus,
  }) {
    setState(() {
      _mirData = MIRData(
        projectName: _mirData.projectName,
        contractNo: _mirData.contractNo,
        boqItems: _boqItems,
        masStatus: masStatus ?? _mirData.masStatus,
        dtsStatus: dtsStatus ?? _mirData.dtsStatus,
        dispatchStatus: dispatchStatus ?? _mirData.dispatchStatus,
        supplierDeliveryNote: _supplierController.text,
        manufacturer: _manufacturerController.text,
        countryOfOrigin: _countryController.text,
        engineerComments: _commentsController.text,
        isSatisfactory: isSatisfactory ?? _mirData.isSatisfactory,
        dateOfInspection: _mirData.dateOfInspection,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF3949AB),
        title: const Text('Edit Material Inspection Request'),
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
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          if (!_isLoading) ...[
                            SizedBox(
                              height: 48,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  setState(() => _isLoading = true);
                                  try {
                                    await _saveMIR(true);
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
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
                                    await _saveMIR(false);
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
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
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Project: ${_mirData.projectName}',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Contract No: ${_mirData.contractNo}',
                                style: Theme.of(context).textTheme.titleMedium,
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
                                    style: Theme.of(context).textTheme.titleLarge,
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
                                      Theme.of(context).primaryColor,
                                      Theme.of(context).primaryColor.withOpacity(0.1),
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
                                style: Theme.of(context).textTheme.titleLarge,
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
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                value: _mirData.masStatus.isEmpty ? null : _mirData.masStatus,
                                decoration: const InputDecoration(
                                  labelText: 'MAS Status',
                                  border: OutlineInputBorder(),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'approved', child: Text('Approved')),
                                  DropdownMenuItem(value: 'pending', child: Text('Pending')),
                                  DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                                ],
                                onChanged: (value) => _updateMIRData(masStatus: value),
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                value: _mirData.dtsStatus.isEmpty ? null : _mirData.dtsStatus,
                                decoration: const InputDecoration(
                                  labelText: 'DTS Status',
                                  border: OutlineInputBorder(),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'approved', child: Text('Approved')),
                                  DropdownMenuItem(value: 'pending', child: Text('Pending')),
                                  DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                                ],
                                onChanged: (value) => _updateMIRData(dtsStatus: value),
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                value: _mirData.dispatchStatus.isEmpty ? null : _mirData.dispatchStatus,
                                decoration: const InputDecoration(
                                  labelText: 'Dispatch Clearance Status',
                                  border: OutlineInputBorder(),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'approved', child: Text('Approved')),
                                  DropdownMenuItem(value: 'pending', child: Text('Pending')),
                                  DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                                ],
                                onChanged: (value) => _updateMIRData(dispatchStatus: value),
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
                                style: Theme.of(context).textTheme.titleLarge,
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
                                    selected: _mirData.isSatisfactory,
                                    onSelected: (selected) {
                                      _updateMIRData(isSatisfactory: true);
                                    },
                                  ),
                                  ChoiceChip(
                                    label: const Text('Unsatisfactory'),
                                    selected: !_mirData.isSatisfactory,
                                    onSelected: (selected) {
                                      _updateMIRData(isSatisfactory: false);
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

  @override
  void dispose() {
    _supplierController.dispose();
    _manufacturerController.dispose();
    _countryController.dispose();
    _commentsController.dispose();
    super.dispose();
  }
} 