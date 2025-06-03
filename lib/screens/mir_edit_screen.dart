import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/mir_data.dart';
import '../services/report_service.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import '../widgets/signature_pad.dart';
import 'package:image_picker/image_picker.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';

class MIREditScreen extends StatefulWidget {
  final String requestId;
  final MIRData initialData;
  final bool isCreator;

  const MIREditScreen({
    super.key,
    required this.requestId,
    required this.initialData,
    required this.isCreator,
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
  final _recipientController = TextEditingController();
  final List<String> _recipientEmails = [];
  final FocusNode _recipientFocusNode = FocusNode();
  final _supplierController = TextEditingController();
  final _manufacturerController = TextEditingController();
  final _countryController = TextEditingController();
  final _commentsController = TextEditingController();
  final List<BOQItem> _boqItems = [];
  String? _signatureImagePath;
  String? _sealImagePath;
  String? _currentUserId;
  int _totalPages = 0;
  int _currentPage = 0;
  PDFViewController? _pdfViewController;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (_currentUserId == null) {
      print('User not logged in!');
      if (mounted) {
        ScaffoldMessenger.of(this.context).showSnackBar(
          const SnackBar(
            content: Text(
              'User not logged in. Please log in to manage signatures.',
            ),
          ),
        );
        Navigator.of(this.context).pop();
      }
      return;
    }

    _mirData = widget.initialData;
    _supplierController.text = _mirData.supplierDeliveryNote;
    _manufacturerController.text = _mirData.manufacturer;
    _countryController.text = _mirData.countryOfOrigin;
    _commentsController.text = _mirData.engineerComments;
    _boqItems.addAll(_mirData.boqItems);
    if (_boqItems.isEmpty) {
      _addNewBOQItem();
    }
    _recipientController.addListener(_handleRecipientInput);
    _loadSignatureImage();
    _loadSealImage();
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
    if (email.isNotEmpty &&
        _isValidEmail(email) &&
        !_recipientEmails.contains(email)) {
      setState(() {
        _recipientEmails.add(email);
        _recipientController.clear();
      });
    }
  }

  void _addNewBOQItem() {
    setState(() {
      _boqItems.add(
        BOQItem(
          refNo: '',
          description: '',
          unit: '',
          quantity: '',
          remarks: '',
        ),
      );
    });
  }

  Future<void> _generatePDFPreview() async {
    setState(() => _isLoading = true);

    try {
      final updatedData = MIRData(
        projectName: _mirData.projectName,
        contractNo: _mirData.contractNo,
        mirNo: _mirData.mirNo,
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

      final String? signaturePath = await _getSignatureImagePath();
      final String? sealPath = await _getSealImagePath();
      final pdfPath = await _reportService.generatePDFFromMIR(
        updatedData,
        signaturePath: signaturePath,
        sealPath: sealPath,
      );
      setState(() {
        _pdfPath = pdfPath;
        _isPDFVisible = true;
      });
    } catch (e) {
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

  void _updateMIRData({
    bool? isSatisfactory,
    String? masStatus,
    String? dtsStatus,
    String? dispatchStatus,
    String? mirNo,
  }) {
    setState(() {
      _mirData = MIRData(
        projectName: _mirData.projectName,
        contractNo: _mirData.contractNo,
        mirNo: mirNo ?? _mirData.mirNo,
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

  void _updateBOQItem(
    int index, {
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
    if (_currentUserId == null) return null;
    final directory = await getApplicationDocumentsDirectory();
    final imagePath = join(directory.path, 'signature_${_currentUserId}.png');
    final file = File(imagePath);
    if (await file.exists()) {
      return imagePath;
    }
    return null;
  }

  Future<void> _loadSignatureImage() async {
    final path = await _getSignatureImagePath();
    setState(() {
      _signatureImagePath = path;
    });
  }

  Future<void> _saveSignature(dynamic data) async {
    if (!mounted) return;
    if (_currentUserId == null) return;
    final scaffoldMessenger = ScaffoldMessenger.of(this.context);
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagePath = join(directory.path, 'signature_${_currentUserId}.png');
      final file = File(imagePath);

      if (data is Uint8List) {
        await file.writeAsBytes(data);
      } else if (data is File) {
        await data.copy(imagePath);
      } else {
        throw Exception('Invalid data type for signature saving');
      }

      setState(() {
        _signatureImagePath = imagePath;
      });
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Signature saved successfully!')),
      );
    } catch (e) {
      print('Error saving signature: $e');
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Failed to save signature: $e')),
      );
    }
  }

  Future<String?> _getSealImagePath() async {
    if (_currentUserId == null) return null;
    final directory = await getApplicationDocumentsDirectory();
    final imagePath = join(directory.path, 'seal_${_currentUserId}.png');
    final file = File(imagePath);
    if (await file.exists()) {
      return imagePath;
    }
    return null;
  }

  Future<void> _loadSealImage() async {
    if (_currentUserId == null) return;
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagePath = join(directory.path, 'seal_${_currentUserId}.png');
      final file = File(imagePath);

      if (await file.exists()) {
        setState(() {
          _sealImagePath = imagePath;
        });
      } else {
        setState(() {
          _sealImagePath = null;
        });
      }
    } catch (e) {
      print('Error loading seal image: $e');
      setState(() {
        _sealImagePath = null;
      });
    }
  }

  Future<void> _deleteSealImage() async {
    if (!mounted) return;
    if (_currentUserId == null) return;
    final scaffoldMessenger = ScaffoldMessenger.of(this.context);
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagePath = join(directory.path, 'seal_${_currentUserId}.png');
      final file = File(imagePath);

      // Force clear the state first
      setState(() {
        _sealImagePath = null;
      });

      // Then delete the file
      if (await file.exists()) {
        await file.delete();
      }

      // Verify deletion
      if (await file.exists()) {
        throw Exception('Failed to delete seal file');
      }

      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Seal deleted successfully!')),
      );
    } catch (e) {
      print('Error deleting seal image: $e');
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Failed to delete seal: $e')),
      );
      // Reload the state to ensure consistency
      _loadSealImage();
    }
  }

  Future<void> _pickSealImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      try {
        // Clear the state first
        setState(() {
          _sealImagePath = null;
        });

        // Delete old file if it exists
        if (_currentUserId != null) {
          final directory = await getApplicationDocumentsDirectory();
          final oldPath = join(directory.path, 'seal_${_currentUserId}.png');
          final oldFile = File(oldPath);
          if (await oldFile.exists()) {
            await oldFile.delete();
          }
        }

        // Save new file
        final File imageFile = File(pickedFile.path);
        await _saveSealImage(imageFile);
      } catch (e) {
        print('Error handling seal image: $e');
        // Reload the state to ensure consistency
        _loadSealImage();
      }
    }
  }

  Future<void> _saveSealImage(File imageFile) async {
    if (!mounted) return;
    if (_currentUserId == null) return;
    final scaffoldMessenger = ScaffoldMessenger.of(this.context);
    try {
      final directory = await getApplicationDocumentsDirectory();
      final localPath = join(directory.path, 'seal_${_currentUserId}.png');

      // Delete existing file if it exists
      final existingFile = File(localPath);
      if (await existingFile.exists()) {
        await existingFile.delete();
      }

      // Copy the new file
      final localImage = await imageFile.copy(localPath);

      // Verify the new file exists
      if (!await localImage.exists()) {
        throw Exception('Failed to save seal file');
      }

      // Update state
      setState(() {
        _sealImagePath = localImage.path;
      });

      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Seal saved successfully!')),
      );
    } catch (e) {
      print('Error saving seal image: $e');
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Failed to save seal: $e')),
      );
      // Reload the state to ensure consistency
      _loadSealImage();
    }
  }

  Future<void> _saveMIR(bool approved) async {
    setState(() => _isLoading = true);

    try {
      if (widget.isCreator && _recipientEmails.isEmpty) {
        throw Exception('Please add at least one recipient email');
      }

      final updatedData = MIRData(
        projectName: _mirData.projectName,
        contractNo: _mirData.contractNo,
        mirNo: _mirData.mirNo,
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
      final requestDoc =
          await FirebaseFirestore.instance
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
      String? signaturePath;
      if (approved) {
        signaturePath = await _getSignatureImagePath();
      }
      final String? sealPath = await _getSealImagePath();
      final pdfPath = await _reportService.generatePDFFromMIR(
        updatedData,
        signaturePath: signaturePath,
        sealPath: sealPath,
      );

      // Upload the PDF to storage with correct type
      final pdfId = await _reportService.uploadPDF(pdfPath, 'mir');

      if (widget.isCreator) {
        // Get the recipients' user IDs
        final recipientQuery =
            await FirebaseFirestore.instance
                .collection('users')
                .where('email', whereIn: _recipientEmails)
                .get();

        if (recipientQuery.docs.isEmpty) {
          throw Exception('No valid recipients found');
        }

        // Create a new approval request for each recipient
        final batch = FirebaseFirestore.instance.batch();
        final newRequestRef =
            FirebaseFirestore.instance.collection('approval_requests').doc();

        batch.set(newRequestRef, {
          'lastUpdated': FieldValue.serverTimestamp(),
          'mirData': updatedData.toMap(),
          'status': 'pending',
          'pdfId': pdfId,
          'reviewerComments': '',
          'senderId': FirebaseAuth.instance.currentUser?.uid,
          'senderEmail': FirebaseAuth.instance.currentUser?.email,
          'recipientId': recipientQuery.docs.first.id,
          'recipientEmail': _recipientEmails.first,
          'createdAt': FieldValue.serverTimestamp(),
          'projectName': updatedData.projectName,
          'reportType': 'mir',
        });

        await batch.commit();

        final scaffoldMessenger = ScaffoldMessenger.of(this.context);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('MIR sent to ${_recipientEmails.length} recipients'),
            backgroundColor: Colors.green,
          ),
        );
        // Navigator.of(this.context).pop(); // Comment out or remove this line
      } else {
        // If reviewer is editing, update with approval/rejection
        await FirebaseFirestore.instance
            .collection('approval_requests')
            .doc(widget.requestId)
            .update({
              'lastUpdated': FieldValue.serverTimestamp(),
              'mirData': updatedData.toMap(),
              'status': approved ? 'approved' : 'rejected',
              'pdfId': pdfId,
              'reviewerComments': _commentsController.text,
              'senderId': requestData['recipientId'],
              'senderEmail': requestData['recipientEmail'],
              'recipientEmail': requestData['senderEmail'],
              'projectName': updatedData.projectName,
              'reportType': 'mir',
            });

        final scaffoldMessenger = ScaffoldMessenger.of(this.context);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              approved
                  ? 'MIR approved and sent back to creator'
                  : 'MIR rejected and sent back to creator',
            ),
            backgroundColor: approved ? Colors.green : Colors.red,
          ),
        );
        Navigator.of(this.context)
          ..pop() // Pop MIREditScreen
          ..pop(); // Pop ApprovalDetailScreen
      }
    } catch (e) {
      final scaffoldMessenger = ScaffoldMessenger.of(this.context);
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error saving MIR: $e'),
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
        elevation: 0,
        title: Text(
          widget.isCreator
              ? 'Edit Material Inspection Request'
              : 'Review Material Inspection Request',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: CircularProgressIndicator(color: Colors.white),
              ),
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.preview),
              onPressed: _generatePDFPreview,
              tooltip: 'Preview PDF',
              color: Colors.white,
            ),
            IconButton(
              icon: const Icon(Icons.print),
              onPressed: _printPDF,
              tooltip: 'Print PDF',
              color: Colors.white,
            ),
          ],
        ],
      ),
      body:
          _isPDFVisible && _pdfPath != null
              ? Column(
                children: [
                  // Container(
                  //   padding: const EdgeInsets.symmetric(
                  //     horizontal: 16,
                  //     vertical: 8,
                  //   ),
                  //   decoration: BoxDecoration(
                  //     color: Colors.white,
                  //     boxShadow: [
                  //       BoxShadow(
                  //         color: Colors.black.withOpacity(0.1),
                  //         blurRadius: 4,
                  //         offset: const Offset(0, 2),
                  //       ),
                  //     ],
                  //   ),
                  //   child: Row(
                  //     children: [
                  //       IconButton(
                  //         icon: const Icon(Icons.arrow_back),
                  //         onPressed:
                  //             () => setState(() => _isPDFVisible = false),
                  //         tooltip: 'Back to Edit',
                  //       ),
                  //       const SizedBox(width: 8),
                  //       const Text(
                  //         'PDF Preview',
                  //         style: TextStyle(
                  //           fontSize: 18,
                  //           fontWeight: FontWeight.bold,
                  //           color: Color(0xFF3949AB),
                  //         ),
                  //       ),
                  //       const Spacer(),
                  //       IconButton(
                  //         icon: const Icon(Icons.refresh),
                  //         onPressed: _generatePDFPreview,
                  //         tooltip: 'Refresh Preview',
                  //       ),
                  //       IconButton(
                  //         icon: const Icon(Icons.print),
                  //         onPressed: _printPDF,
                  //         tooltip: 'Print PDF',
                  //       ),
                  //     ],
                  //   ),
                  // ),
                  Expanded(
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child:
                              _pdfPath!.isNotEmpty
                                  ? PDFView(
                                    filePath: _pdfPath!,
                                    enableSwipe: true,
                                    swipeHorizontal: false,
                                    autoSpacing: true,
                                    pageFling: true,
                                    pageSnap: true,
                                    defaultPage: 0,
                                    fitPolicy: FitPolicy.BOTH,
                                    preventLinkNavigation: false,
                                    onRender: (pages) {
                                      setState(() {
                                        _totalPages = pages ?? 0;
                                      });
                                    },
                                    onPageChanged: (page, total) {
                                      setState(() {
                                        _currentPage = page ?? 0;
                                      });
                                    },
                                    onError: (error) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Error loading PDF: $error',
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    },
                                    onPageError: (page, error) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Error loading page $page: $error',
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    },
                                    onViewCreated: (controller) {
                                      setState(() {
                                        _pdfViewController = controller;
                                      });
                                    },
                                  )
                                  : const Center(
                                    child: Text(
                                      'PDF not available',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ),
                        ),
                        if (_isLoading)
                          Container(
                            color: Colors.black.withOpacity(0.3),
                            child: const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Generating PDF...',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Container(
                  //   padding: const EdgeInsets.symmetric(
                  //     horizontal: 16,
                  //     vertical: 8,
                  //   ),
                  //   decoration: BoxDecoration(
                  //     color: Colors.white,
                  //     boxShadow: [
                  //       BoxShadow(
                  //         color: Colors.black.withOpacity(0.1),
                  //         blurRadius: 4,
                  //         offset: const Offset(0, -2),
                  //       ),
                  //     ],
                  //   ),
                  //   // child: Row(
                  //   //   mainAxisAlignment: MainAxisAlignment.center,
                  //   //   children: [
                  //   //     IconButton(
                  //   //       icon: const Icon(Icons.first_page),
                  //   //       onPressed:
                  //   //           _currentPage > 0
                  //   //               ? () => _pdfViewController?.setPage(0)
                  //   //               : null,
                  //   //       tooltip: 'First Page',
                  //   //     ),
                  //   //     IconButton(
                  //   //       icon: const Icon(Icons.chevron_left),
                  //   //       onPressed:
                  //   //           _currentPage > 0
                  //   //               ? () => _pdfViewController?.setPage(
                  //   //                 _currentPage - 1,
                  //   //               )
                  //   //               : null,
                  //   //       tooltip: 'Previous Page',
                  //   //     ),
                  //   //     Container(
                  //   //       padding: const EdgeInsets.symmetric(horizontal: 16),
                  //   //       child: Text(
                  //   //         'Page ${_currentPage + 1} of $_totalPages',
                  //   //         style: const TextStyle(
                  //   //           fontSize: 14,
                  //   //           fontWeight: FontWeight.w500,
                  //   //         ),
                  //   //       ),
                  //   //     ),
                  //   //     IconButton(
                  //   //       icon: const Icon(Icons.chevron_right),
                  //   //       onPressed:
                  //   //           _currentPage < _totalPages - 1
                  //   //               ? () => _pdfViewController?.setPage(
                  //   //                 _currentPage + 1,
                  //   //               )
                  //   //               : null,
                  //   //       tooltip: 'Next Page',
                  //   //     ),
                  //   //     IconButton(
                  //   //       icon: const Icon(Icons.last_page),
                  //   //       onPressed:
                  //   //           _currentPage < _totalPages - 1
                  //   //               ? () => _pdfViewController?.setPage(
                  //   //                 _totalPages - 1,
                  //   //               )
                  //   //               : null,
                  //   //       tooltip: 'Last Page',
                  //   //     ),
                  //   //   ],
                  //   // ),
                  // ),
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
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF3949AB),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.grey[50],
                                ),
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  children: [
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children:
                                          _recipientEmails
                                              .map(
                                                (email) => Chip(
                                                  label: Text(
                                                    email,
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                  deleteIcon: const Icon(
                                                    Icons.close,
                                                    size: 18,
                                                  ),
                                                  backgroundColor: const Color(
                                                    0xFF3949AB,
                                                  ).withOpacity(0.1),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  onDeleted:
                                                      () => _removeRecipient(
                                                        email,
                                                      ),
                                                ),
                                              )
                                              .toList(),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: _recipientController,
                                            focusNode: _recipientFocusNode,
                                            decoration: InputDecoration(
                                              hintText:
                                                  'Type email and press Enter or add comma',
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                borderSide: BorderSide(
                                                  color: Colors.grey[300]!,
                                                ),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                borderSide: BorderSide(
                                                  color: Colors.grey[300]!,
                                                ),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                borderSide: const BorderSide(
                                                  color: Color(0xFF3949AB),
                                                ),
                                              ),
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 8,
                                                  ),
                                              filled: true,
                                              fillColor: Colors.white,
                                            ),
                                            keyboardType:
                                                TextInputType.emailAddress,
                                            onSubmitted: (value) {
                                              _addRecipient(value);
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.add_circle_outline,
                                            color: Color(0xFF3949AB),
                                          ),
                                          onPressed: () {
                                            _addRecipient(
                                              _recipientController.text,
                                            );
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
                              spacing: 12,
                              runSpacing: 12,
                              alignment: WrapAlignment.center,
                              children: [
                                if (!_isLoading) ...[
                                  if (!widget.isCreator) ...[
                                    _buildActionButton(
                                      onPressed: () async {
                                        setState(() => _isLoading = true);
                                        try {
                                          await _saveMIR(true);
                                        } catch (e) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(
                                              this.context,
                                            ).showSnackBar(
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
                                      icon: Icons.check,
                                      label: 'Approve Changes',
                                      backgroundColor: Colors.green,
                                    ),
                                    _buildActionButton(
                                      onPressed: () async {
                                        setState(() => _isLoading = true);
                                        try {
                                          await _saveMIR(false);
                                        } catch (e) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(
                                              this.context,
                                            ).showSnackBar(
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
                                      icon: Icons.close,
                                      label: 'Reject Changes',
                                      backgroundColor: Colors.red,
                                    ),
                                  ] else ...[
                                    _buildActionButton(
                                      onPressed: () async {
                                        if (_recipientEmails.isEmpty) {
                                          ScaffoldMessenger.of(
                                            this.context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Please add at least one recipient',
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                          return;
                                        }
                                        setState(() => _isLoading = true);
                                        try {
                                          await _saveMIR(true);
                                        } catch (e) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(
                                              this.context,
                                            ).showSnackBar(
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
                                      icon: Icons.save,
                                      label: 'Save Changes',
                                      backgroundColor: const Color(0xFF3949AB),
                                    ),
                                  ],
                                  _buildActionButton(
                                    onPressed:
                                        !_isLoading
                                            ? () => setState(
                                              () => _isPDFVisible = false,
                                            )
                                            : null,
                                    icon: Icons.edit,
                                    label: 'Back to Edit',
                                    backgroundColor: Colors.grey[700]!,
                                    isOutlined: true,
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
                            // if (widget.isCreator && !_isLoading) ...[
                            //   const SizedBox(height: 12),
                            //   _buildActionButton(
                            //     onPressed: _printPDF,
                            //     icon: Icons.print,
                            //     label: 'Print PDF',
                            //     backgroundColor: Colors.blueAccent,
                            //   ),
                            // ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              )
              : Form(
                key: _formKey,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF3949AB).withOpacity(0.05),
                        Colors.white,
                      ],
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildModernCard(
                            title: 'Project Information',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Project: ${_mirData.projectName}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF3949AB),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Contract No: ${_mirData.contractNo}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF3949AB),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildArabicTextField(
                                  controller: _manufacturerController,
                                  label: 'Manufacturer',
                                ),
                                const SizedBox(height: 16),
                                _buildArabicTextField(
                                  controller: _countryController,
                                  label: 'Country of Origin',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildModernCard(
                            title: 'BOQ Items',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Items List',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF3949AB),
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: _addNewBOQItem,
                                      icon: const Icon(Icons.add),
                                      label: const Text('Add Item'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF3949AB,
                                        ),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.swipe,
                                      color: Colors.grey[600],
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Swipe horizontally to see more',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  height: 2,
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFF3949AB),
                                        const Color(
                                          0xFF3949AB,
                                        ).withOpacity(0.1),
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
                                        border: Border.all(
                                          color: Colors.grey[300]!,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: DataTable(
                                        columnSpacing: 16,
                                        horizontalMargin: 8,
                                        headingRowColor:
                                            MaterialStateProperty.all(
                                              const Color(
                                                0xFF3949AB,
                                              ).withOpacity(0.1),
                                            ),
                                        columns: const [
                                          DataColumn(
                                            label: Text(
                                              'Ref No.',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              'Description',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              'Unit',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              'Quantity',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              'Remarks',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              'Actions',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                        rows:
                                            _boqItems.asMap().entries.map((
                                              entry,
                                            ) {
                                              final index = entry.key;
                                              final item = entry.value;
                                              return DataRow(
                                                cells: [
                                                  DataCell(
                                                    SizedBox(
                                                      width: 100,
                                                      child: TextFormField(
                                                        initialValue:
                                                            item.refNo,
                                                        decoration: InputDecoration(
                                                          isDense: true,
                                                          contentPadding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 8,
                                                                vertical: 8,
                                                              ),
                                                          border: OutlineInputBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  8,
                                                                ),
                                                          ),
                                                          enabledBorder:
                                                              OutlineInputBorder(
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      8,
                                                                    ),
                                                                borderSide:
                                                                    BorderSide(
                                                                      color:
                                                                          Colors
                                                                              .grey[300]!,
                                                                    ),
                                                              ),
                                                          focusedBorder: OutlineInputBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  8,
                                                                ),
                                                            borderSide:
                                                                const BorderSide(
                                                                  color: Color(
                                                                    0xFF3949AB,
                                                                  ),
                                                                ),
                                                          ),
                                                        ),
                                                        onChanged:
                                                            (value) =>
                                                                _updateBOQItem(
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
                                                        initialValue:
                                                            item.description,
                                                        decoration: InputDecoration(
                                                          isDense: true,
                                                          contentPadding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 8,
                                                                vertical: 8,
                                                              ),
                                                          border: OutlineInputBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  8,
                                                                ),
                                                          ),
                                                          enabledBorder:
                                                              OutlineInputBorder(
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      8,
                                                                    ),
                                                                borderSide:
                                                                    BorderSide(
                                                                      color:
                                                                          Colors
                                                                              .grey[300]!,
                                                                    ),
                                                              ),
                                                          focusedBorder: OutlineInputBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  8,
                                                                ),
                                                            borderSide:
                                                                const BorderSide(
                                                                  color: Color(
                                                                    0xFF3949AB,
                                                                  ),
                                                                ),
                                                          ),
                                                        ),
                                                        onChanged:
                                                            (value) =>
                                                                _updateBOQItem(
                                                                  index,
                                                                  description:
                                                                      value,
                                                                ),
                                                      ),
                                                    ),
                                                  ),
                                                  DataCell(
                                                    SizedBox(
                                                      width: 80,
                                                      child: TextFormField(
                                                        initialValue: item.unit,
                                                        decoration: InputDecoration(
                                                          isDense: true,
                                                          contentPadding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 8,
                                                                vertical: 8,
                                                              ),
                                                          border: OutlineInputBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  8,
                                                                ),
                                                          ),
                                                          enabledBorder:
                                                              OutlineInputBorder(
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      8,
                                                                    ),
                                                                borderSide:
                                                                    BorderSide(
                                                                      color:
                                                                          Colors
                                                                              .grey[300]!,
                                                                    ),
                                                              ),
                                                          focusedBorder: OutlineInputBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  8,
                                                                ),
                                                            borderSide:
                                                                const BorderSide(
                                                                  color: Color(
                                                                    0xFF3949AB,
                                                                  ),
                                                                ),
                                                          ),
                                                        ),
                                                        onChanged:
                                                            (value) =>
                                                                _updateBOQItem(
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
                                                        initialValue:
                                                            item.quantity,
                                                        decoration: InputDecoration(
                                                          isDense: true,
                                                          contentPadding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 8,
                                                                vertical: 8,
                                                              ),
                                                          border: OutlineInputBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  8,
                                                                ),
                                                          ),
                                                          enabledBorder:
                                                              OutlineInputBorder(
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      8,
                                                                    ),
                                                                borderSide:
                                                                    BorderSide(
                                                                      color:
                                                                          Colors
                                                                              .grey[300]!,
                                                                    ),
                                                              ),
                                                          focusedBorder: OutlineInputBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  8,
                                                                ),
                                                            borderSide:
                                                                const BorderSide(
                                                                  color: Color(
                                                                    0xFF3949AB,
                                                                  ),
                                                                ),
                                                          ),
                                                        ),
                                                        onChanged:
                                                            (value) =>
                                                                _updateBOQItem(
                                                                  index,
                                                                  quantity:
                                                                      value,
                                                                ),
                                                      ),
                                                    ),
                                                  ),
                                                  DataCell(
                                                    SizedBox(
                                                      width: 150,
                                                      child: TextFormField(
                                                        initialValue:
                                                            item.remarks,
                                                        decoration: InputDecoration(
                                                          isDense: true,
                                                          contentPadding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 8,
                                                                vertical: 8,
                                                              ),
                                                          border: OutlineInputBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  8,
                                                                ),
                                                          ),
                                                          enabledBorder:
                                                              OutlineInputBorder(
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      8,
                                                                    ),
                                                                borderSide:
                                                                    BorderSide(
                                                                      color:
                                                                          Colors
                                                                              .grey[300]!,
                                                                    ),
                                                              ),
                                                          focusedBorder: OutlineInputBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  8,
                                                                ),
                                                            borderSide:
                                                                const BorderSide(
                                                                  color: Color(
                                                                    0xFF3949AB,
                                                                  ),
                                                                ),
                                                          ),
                                                        ),
                                                        onChanged:
                                                            (value) =>
                                                                _updateBOQItem(
                                                                  index,
                                                                  remarks:
                                                                      value,
                                                                ),
                                                      ),
                                                    ),
                                                  ),
                                                  DataCell(
                                                    Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        IconButton(
                                                          icon: const Icon(
                                                            Icons.delete,
                                                            color: Colors.red,
                                                          ),
                                                          onPressed: () {
                                                            setState(() {
                                                              _boqItems
                                                                  .removeAt(
                                                                    index,
                                                                  );
                                                            });
                                                          },
                                                        ),
                                                        if (index ==
                                                            _boqItems.length -
                                                                1)
                                                          Icon(
                                                            Icons
                                                                .keyboard_arrow_right,
                                                            color:
                                                                Colors
                                                                    .grey[400],
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
                          const SizedBox(height: 16),
                          _buildModernCard(
                            title: 'Additional Details',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextFormField(
                                  controller: _supplierController,
                                  decoration: InputDecoration(
                                    labelText: 'Supplier Delivery Note/Date',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: Colors.grey[300]!,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF3949AB),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildArabicTextField(
                                  controller: _commentsController,
                                  label: '',
                                  hintText: 'Enter comments here...',
                                  maxLines: 3,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildModernCard(
                            title: 'Signature',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Center(
                                  child: ElevatedButton.icon(
                                    onPressed: _showSignatureOptions,
                                    icon: Icon(
                                      _signatureImagePath == null
                                          ? Icons.brush
                                          : Icons.edit,
                                      color: Color(0xFF3949AB),
                                    ),
                                    label: Text(
                                      _signatureImagePath == null
                                          ? 'Add Signature'
                                          : 'Change Signature',
                                      style: const TextStyle(
                                        color: Color(0xFF3949AB),
                                      ),
                                    ),
                                  ),
                                ),
                                if (_signatureImagePath != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 16.0),
                                    child: Center(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.grey[300]!,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        padding: const EdgeInsets.all(8),
                                        child: Image.file(
                                          File(_signatureImagePath!),
                                          height: 100,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildModernCard(
                            title: 'Seal',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Center(
                                  child: ElevatedButton.icon(
                                    onPressed: _pickSealImage,
                                    icon: const Icon(
                                      Icons.image,
                                      color: Color(0xFF3949AB),
                                    ),
                                    label: const Text(
                                      'Add Seal',
                                      style: TextStyle(
                                        color: Color(0xFF3949AB),
                                      ),
                                    ),
                                  ),
                                ),
                                if (_sealImagePath != null) ...[
                                  Padding(
                                    padding: const EdgeInsets.only(top: 16.0),
                                    child: Center(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.grey[300]!,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        padding: const EdgeInsets.all(8),
                                        child: Image.file(
                                          File(_sealImagePath!),
                                          height: 100,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 16.0),
                                    child: Center(
                                      child: ElevatedButton.icon(
                                        onPressed: _deleteSealImage,
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Color(0xFF3949AB),
                                        ),
                                        label: const Text(
                                          'Delete Seal',
                                          style: TextStyle(
                                            color: Color(0xFF3949AB),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
    );
  }

  Widget _buildModernCard({required String title, required Widget child}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, const Color(0xFF3949AB).withOpacity(0.05)],
          ),
        ),
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
                      color: const Color(0xFF3949AB).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getIconForTitle(title),
                      color: const Color(0xFF3949AB),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3949AB),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              child,
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForTitle(String title) {
    switch (title) {
      case 'Project Information':
        return Icons.business;
      case 'BOQ Items':
        return Icons.list_alt;
      case 'Additional Details':
        return Icons.description;
      case 'MAS/FAT Report Status':
        return Icons.assessment;
      case "Engineer's Comments":
        return Icons.comment;
      case 'Signature':
        return Icons.draw;
      case 'Seal':
        return Icons.verified_user;
      default:
        return Icons.info;
    }
  }

  Widget _buildActionButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required Color backgroundColor,
    bool isOutlined = false,
  }) {
    // Define gradient colors based on button type
    List<Color> gradientColors;
    Color textColor;
    Color iconColor;
    Color borderColor;
    Color shadowColor;

    if (isOutlined) {
      gradientColors = [Colors.white, Colors.white];
      textColor = backgroundColor;
      iconColor = backgroundColor;
      borderColor = backgroundColor;
      shadowColor = backgroundColor.withOpacity(0.2);
    } else {
      switch (backgroundColor) {
        case Colors.green:
          gradientColors = [const Color(0xFF4CAF50), const Color(0xFF43A047)];
          textColor = Colors.white;
          iconColor = Colors.white;
          borderColor = const Color(0xFF43A047);
          shadowColor = const Color(0xFF4CAF50).withOpacity(0.3);
          break;
        case Colors.red:
          gradientColors = [const Color(0xFFE53935), const Color(0xFFD32F2F)];
          textColor = Colors.white;
          iconColor = Colors.white;
          borderColor = const Color(0xFFD32F2F);
          shadowColor = const Color(0xFFE53935).withOpacity(0.3);
          break;
        default:
          gradientColors = [const Color(0xFF3949AB), const Color(0xFF303F9F)];
          textColor = Colors.white;
          iconColor = Colors.white;
          borderColor = const Color(0xFF303F9F);
          shadowColor = const Color(0xFF3949AB).withOpacity(0.3);
      }
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: isOutlined ? Border.all(color: borderColor, width: 1.5) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: iconColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;
    Color textColor;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'approved':
        chipColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        icon = Icons.check_circle;
        break;
      case 'pending':
        chipColor = Colors.orange[100]!;
        textColor = Colors.orange[800]!;
        icon = Icons.pending;
        break;
      case 'rejected':
        chipColor = Colors.red[100]!;
        textColor = Colors.red[800]!;
        icon = Icons.cancel;
        break;
      default:
        chipColor = Colors.grey[100]!;
        textColor = Colors.grey[800]!;
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 4),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String label,
    String? hintText,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      prefixIcon: prefixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF3949AB)),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      labelStyle: TextStyle(
        color: Colors.grey[600],
        fontWeight: FontWeight.w500,
        fontFamily: 'Amiri',
      ),
      hintStyle: TextStyle(
        color: Colors.grey[400],
        fontSize: 14,
        fontFamily: 'Amiri',
      ),
    );
  }

  Widget _buildArabicTextField({
    required TextEditingController controller,
    required String label,
    String? hintText,
    int? maxLines,
    Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines ?? 1,
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.right,
      style: const TextStyle(fontFamily: 'Amiri', fontSize: 16),
      decoration: _buildInputDecoration(
        label: label,
        hintText: hintText,
      ).copyWith(alignLabelWithHint: true),
      onChanged: (value) {
        if (onChanged != null) {
          onChanged(value);
        }
        setState(() {
          // Force a rebuild to ensure the text is displayed
          controller.text = value;
        });
      },
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.next,
      enableInteractiveSelection: true,
      cursorColor: const Color(0xFF3949AB),
      cursorWidth: 2.0,
      cursorRadius: const Radius.circular(1.0),
    );
  }

  Future<void> _showSignatureOptions() {
    return showModalBottomSheet(
      context: this.context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.brush),
                title: const Text('Draw Signature'),
                onTap: () {
                  Navigator.pop(context);
                  _drawSignature();
                },
              ),
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text('Upload Signature Image'),
                onTap: () {
                  Navigator.pop(context);
                  _uploadSignatureImage();
                },
              ),
              if (_signatureImagePath != null)
                ListTile(
                  leading: const Icon(Icons.delete),
                  title: const Text('Delete Signature'),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteSignatureImage();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _drawSignature() async {
    final signatureBytes = await Navigator.push<Uint8List?>(
      this.context,
      MaterialPageRoute(
        builder:
            (context) => SignaturePad(
              onSignatureComplete: (bytes) => _saveSignature(bytes),
            ),
      ),
    );
  }

  Future<void> _uploadSignatureImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final File imageFile = File(pickedFile.path);
      await _saveSignature(imageFile);
    }
  }

  Future<void> _deleteSignatureImage() async {
    if (!mounted) return;
    if (_currentUserId == null) return;
    final scaffoldMessenger = ScaffoldMessenger.of(this.context);
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagePath = join(directory.path, 'signature_${_currentUserId}.png');
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
        setState(() {
          _signatureImagePath = null;
        });
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Signature deleted successfully!')),
        );
      }
    } catch (e) {
      print('Error deleting signature image: $e');
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Failed to delete signature.')),
      );
    }
  }

  Future<void> _printPDF() async {
    if (_pdfPath != null) {
      try {
        await Printing.layoutPdf(
          onLayout:
              (PdfPageFormat format) async => File(_pdfPath!).readAsBytes(),
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(this.context).showSnackBar(
            SnackBar(
              content: Text('Error printing PDF: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
