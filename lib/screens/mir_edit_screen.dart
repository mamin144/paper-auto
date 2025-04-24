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

  // Keep track of BOQ item controllers
  final List<List<TextEditingController>> _boqControllers = [];

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
    } else {
      // Initialize controllers for existing items
      for (var item in _boqItems) {
        _addControllersForItem(item);
      }
    }
  }

  void _addControllersForItem(BOQItem item) {
    _boqControllers.add([
      TextEditingController(text: item.refNo),
      TextEditingController(text: item.description),
      TextEditingController(text: item.unit),
      TextEditingController(text: item.quantity),
      TextEditingController(text: item.remarks),
    ]);
  }

  void _addNewBOQItem() {
    setState(() {
      final newItem = BOQItem(
        refNo: '',
        description: '',
        unit: '',
        quantity: '',
        remarks: '',
      );
      _boqItems.add(newItem);
      _addControllersForItem(newItem);
    });
  }

  void _removeBOQItem(int index) {
    setState(() {
      _boqItems.removeAt(index);
      // Dispose and remove controllers
      for (var controller in _boqControllers[index]) {
        controller.dispose();
      }
      _boqControllers.removeAt(index);
    });
  }

  // Update _boqItems from controllers before generating PDF or saving
  void _updateBOQItemsFromControllers() {
    for (int i = 0; i < _boqItems.length; i++) {
      _boqItems[i] = BOQItem(
        refNo: _boqControllers[i][0].text,
        description: _boqControllers[i][1].text,
        unit: _boqControllers[i][2].text,
        quantity: _boqControllers[i][3].text,
        remarks: _boqControllers[i][4].text,
      );
    }
  }

  Future<void> _generatePDFPreview() async {
    setState(() => _isLoading = true);
    _updateBOQItemsFromControllers(); // Update data model

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
    setState(() => _isLoading = true);
    _updateBOQItemsFromControllers(); // Update data model

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

      final requestDoc =
          await FirebaseFirestore.instance
              .collection('approval_requests')
              .doc(widget.requestId)
              .get();

      if (!requestDoc.exists) {
        throw Exception('Original approval request not found');
      }

      final requestData = requestDoc.data()!;

      await FirebaseFirestore.instance
          .collection('mir_data')
          .doc(widget.requestId)
          .set(updatedData.toMap());

      final pdfPath = await _reportService.generatePDFFromMIR(updatedData);
      final pdfId = await _reportService.uploadPDF(pdfPath, 'mir');

      await FirebaseFirestore.instance
          .collection('approval_requests')
          .doc(widget.requestId)
          .update({
            'lastUpdated': FieldValue.serverTimestamp(),
            'mirData': updatedData.toMap(),
            'status': approved ? 'approved' : 'rejected',
            'pdfId': pdfId,
            'reviewerComments': _commentsController.text,
            'senderId': requestData['senderId'],
            'senderEmail': requestData['senderEmail'],
            'recipientEmail': requestData['recipientEmail'],
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              approved
                  ? 'MIR approved and sent back to sender'
                  : 'MIR rejected and sent back to sender',
            ),
            backgroundColor: approved ? Colors.green : Colors.red,
          ),
        );
        Navigator.of(context)
          ..pop()
          ..pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving MIR: $e'),
            backgroundColor: Colors.red,
          ),
        );
        // Do not rethrow, allow user to stay on screen
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _updateMIRData({
    // Update local data only, not controllers directly
    bool? isSatisfactory,
    String? masStatus,
    String? dtsStatus,
    String? dispatchStatus,
  }) {
    setState(() {
      _mirData = MIRData(
        projectName: _mirData.projectName,
        contractNo: _mirData.contractNo,
        boqItems: _boqItems, // BOQ items updated separately from controllers
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inputDecoration = InputDecoration(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.primaryColor, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
    final denseInputDecoration = inputDecoration.copyWith(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.primaryColor,
        elevation: 0,
        title: Text(
          _isPDFVisible ? 'Preview MIR' : 'Edit MIR',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                ),
              ),
            )
          else if (!_isPDFVisible)
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.preview_outlined, color: Colors.white),
              ),
              onPressed: _generatePDFPreview,
              tooltip: 'Preview PDF',
            ),
        ],
      ),
      body: Container(
        // Add gradient background
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.primaryColor.withOpacity(0.1),
              theme.colorScheme.primary.withOpacity(0.05),
            ],
          ),
        ),
        child:
            _isPDFVisible && _pdfPath != null
                ? _buildPDFView(theme)
                : _buildEditForm(theme, inputDecoration, denseInputDecoration),
      ),
    );
  }

  // --- Build Helper Methods ---

  Widget _buildPDFView(ThemeData theme) {
    return Column(
      children: [
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
                filePath: _pdfPath!,
                enableSwipe: true,
                swipeHorizontal: false,
                autoSpacing: false,
                pageFling: false,
                pageSnap: true,
                fitPolicy: FitPolicy.BOTH,
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(
            16,
            16,
            16,
            24,
          ), // Add bottom padding for safe area
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false, // Only apply bottom safe area
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  label: 'Approve',
                  icon: Icons.check_circle_outline,
                  color: Colors.green,
                  onPressed: () => _saveMIR(true),
                  isLoading: _isLoading,
                ),
                _buildActionButton(
                  label: 'Reject',
                  icon: Icons.cancel_outlined,
                  color: Colors.red,
                  onPressed: () => _saveMIR(false),
                  isLoading: _isLoading,
                ),
                TextButton.icon(
                  onPressed:
                      _isLoading
                          ? null
                          : () => setState(() => _isPDFVisible = false),
                  icon: Icon(Icons.edit_outlined, color: theme.primaryColor),
                  label: Text(
                    'Edit',
                    style: TextStyle(color: theme.primaryColor),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required bool isLoading,
  }) {
    return ElevatedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon:
          isLoading
              ? Container(
                width: 18,
                height: 18,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
              : Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildEditForm(
    ThemeData theme,
    InputDecoration inputDecoration,
    InputDecoration denseInputDecoration,
  ) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionCard(
              theme: theme,
              title: 'Project Information',
              icon: Icons.business_center_outlined,
              children: [
                Text(
                  'Project: ${_mirData.projectName}',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Contract No: ${_mirData.contractNo}',
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
            _buildSectionCard(
              theme: theme,
              title: 'BOQ Items',
              icon: Icons.list_alt_outlined,
              actions: [
                ElevatedButton.icon(
                  onPressed: _addNewBOQItem,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    textStyle: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.swipe_left_outlined,
                      color: Colors.grey[600],
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Swipe table horizontally to see all columns',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildBOQTable(theme, denseInputDecoration),
              ],
            ),
            _buildSectionCard(
              theme: theme,
              title: 'Additional Details',
              icon: Icons.more_horiz_outlined,
              children: [
                TextFormField(
                  controller: _supplierController,
                  decoration: inputDecoration.copyWith(
                    labelText: 'Supplier Delivery Note/Date',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _manufacturerController,
                  decoration: inputDecoration.copyWith(
                    labelText: 'Manufacturer',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _countryController,
                  decoration: inputDecoration.copyWith(
                    labelText: 'Country of Origin',
                  ),
                ),
              ],
            ),
            _buildSectionCard(
              theme: theme,
              title: 'MAS/FAT Report Status',
              icon: Icons.fact_check_outlined,
              children: [
                _buildDropdownField(
                  theme: theme,
                  label: 'MAS Status',
                  value: _mirData.masStatus,
                  items: ['approved', 'pending', 'rejected'],
                  onChanged: (value) => _updateMIRData(masStatus: value),
                ),
                const SizedBox(height: 16),
                _buildDropdownField(
                  theme: theme,
                  label: 'DTS Status',
                  value: _mirData.dtsStatus,
                  items: ['approved', 'pending', 'rejected'],
                  onChanged: (value) => _updateMIRData(dtsStatus: value),
                ),
                const SizedBox(height: 16),
                _buildDropdownField(
                  theme: theme,
                  label: 'Dispatch Clearance Status',
                  value: _mirData.dispatchStatus,
                  items: ['approved', 'pending', 'rejected'],
                  onChanged: (value) => _updateMIRData(dispatchStatus: value),
                ),
              ],
            ),
            _buildSectionCard(
              theme: theme,
              title: 'Engineer\'s Comments & Decision',
              icon: Icons.comment_outlined,
              children: [
                TextFormField(
                  controller: _commentsController,
                  maxLines: 4,
                  decoration: inputDecoration.copyWith(
                    hintText: 'Enter comments here...',
                    labelText: 'Comments',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      'Inspection Result:',
                      style: theme.textTheme.titleMedium,
                    ),
                    const Spacer(),
                    ChoiceChip(
                      label: const Text('Satisfactory'),
                      selected: _mirData.isSatisfactory,
                      onSelected:
                          (selected) => _updateMIRData(isSatisfactory: true),
                      selectedColor: Colors.green.withOpacity(0.2),
                      checkmarkColor: Colors.green,
                      labelStyle: TextStyle(
                        color:
                            _mirData.isSatisfactory
                                ? Colors.green[800]
                                : Colors.black87,
                        fontWeight:
                            _mirData.isSatisfactory
                                ? FontWeight.bold
                                : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Unsatisfactory'),
                      selected: !_mirData.isSatisfactory,
                      onSelected:
                          (selected) => _updateMIRData(isSatisfactory: false),
                      selectedColor: Colors.red.withOpacity(0.2),
                      checkmarkColor: Colors.red,
                      labelStyle: TextStyle(
                        color:
                            !_mirData.isSatisfactory
                                ? Colors.red[800]
                                : Colors.black87,
                        fontWeight:
                            !_mirData.isSatisfactory
                                ? FontWeight.bold
                                : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required ThemeData theme,
    required String title,
    required IconData icon,
    required List<Widget> children,
    List<Widget>? actions,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade300, width: 0.5),
      ),
      color: Colors.white.withOpacity(0.98),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.primaryColor, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                ),
                if (actions != null) ...actions,
              ],
            ),
            const Divider(height: 24, thickness: 0.5),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildBOQTable(ThemeData theme, InputDecoration denseInputDecoration) {
    return Scrollbar(
      thumbVisibility: true, // Make scrollbar always visible
      thickness: 6,
      radius: const Radius.circular(3),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DataTable(
            columnSpacing: 16,
            horizontalMargin: 12,
            headingRowHeight: 40,
            dataRowMinHeight: 52, // Ensure consistent row height
            dataRowMaxHeight: 52,
            headingRowColor: MaterialStateProperty.all(
              theme.primaryColor.withOpacity(0.1),
            ),
            columns: [
              _buildDataColumn('Ref No.', theme),
              _buildDataColumn('Description', theme),
              _buildDataColumn('Unit', theme),
              _buildDataColumn('Quantity', theme),
              _buildDataColumn('Remarks', theme),
              _buildDataColumn('Actions', theme),
            ],
            rows: List<DataRow>.generate(_boqItems.length, (index) {
              return DataRow(
                color: MaterialStateProperty.resolveWith<Color?>((
                  Set<MaterialState> states,
                ) {
                  return index.isEven ? Colors.grey.shade50 : null;
                }),
                cells: [
                  DataCell(
                    _buildBOQTextField(
                      _boqControllers[index][0],
                      100,
                      denseInputDecoration,
                    ),
                  ),
                  DataCell(
                    _buildBOQTextField(
                      _boqControllers[index][1],
                      200,
                      denseInputDecoration,
                    ),
                  ),
                  DataCell(
                    _buildBOQTextField(
                      _boqControllers[index][2],
                      80,
                      denseInputDecoration,
                    ),
                  ),
                  DataCell(
                    _buildBOQTextField(
                      _boqControllers[index][3],
                      100,
                      denseInputDecoration,
                    ),
                  ),
                  DataCell(
                    _buildBOQTextField(
                      _boqControllers[index][4],
                      150,
                      denseInputDecoration,
                    ),
                  ),
                  DataCell(
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      color: Colors.red,
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Remove Item',
                      onPressed: () => _removeBOQItem(index),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  DataColumn _buildDataColumn(String label, ThemeData theme) {
    return DataColumn(
      label: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: theme.primaryColorDark,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildBOQTextField(
    TextEditingController controller,
    double width,
    InputDecoration decoration,
  ) {
    return SizedBox(
      width: width,
      child: TextFormField(
        controller: controller,
        decoration: decoration,
        style: const TextStyle(fontSize: 14),
      ),
    );
  }

  Widget _buildDropdownField({
    required ThemeData theme,
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value.isEmpty ? null : value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.primaryColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      items:
          items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(
                item[0].toUpperCase() + item.substring(1),
              ), // Capitalize
            );
          }).toList(),
      onChanged: onChanged,
    );
  }

  @override
  void dispose() {
    _supplierController.dispose();
    _manufacturerController.dispose();
    _countryController.dispose();
    _commentsController.dispose();
    // Dispose all BOQ controllers
    for (var controllerList in _boqControllers) {
      for (var controller in controllerList) {
        controller.dispose();
      }
    }
    super.dispose();
  }
}
