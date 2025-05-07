class BOQItem {
  final String refNo;
  final String description;
  final String unit;
  final String quantity;
  final String remarks;

  BOQItem({
    required this.refNo,
    required this.description,
    required this.unit,
    required this.quantity,
    required this.remarks,
  });

  Map<String, dynamic> toMap() {
    return {
      'refNo': refNo,
      'description': description,
      'unit': unit,
      'quantity': quantity,
      'remarks': remarks,
    };
  }

  factory BOQItem.fromMap(Map<String, dynamic> map) {
    return BOQItem(
      refNo: map['refNo'] ?? '',
      description: map['description'] ?? '',
      unit: map['unit'] ?? '',
      quantity: map['quantity'] ?? '',
      remarks: map['remarks'] ?? '',
    );
  }
}

class IRData {
  final String projectName;
  final String contractNo;
  final String irNo;
  final List<BOQItem> boqItems;
  final String masStatus;
  final String dtsStatus;
  final String dispatchStatus;
  final String supplierDeliveryNote;
  final String manufacturer;
  final String countryOfOrigin;
  final String engineerComments;
  final bool isSatisfactory;
  final DateTime dateOfInspection;

  IRData({
    required this.projectName,
    required this.contractNo,
    this.irNo = '',
    this.boqItems = const [],
    this.masStatus = '',
    this.dtsStatus = '',
    this.dispatchStatus = '',
    this.supplierDeliveryNote = '',
    this.manufacturer = '',
    this.countryOfOrigin = '',
    this.engineerComments = '',
    this.isSatisfactory = true,
    DateTime? dateOfInspection,
  }) : dateOfInspection = dateOfInspection ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'projectName': projectName,
      'contractNo': contractNo,
      'irNo': irNo,
      'boqItems': boqItems.map((item) => item.toMap()).toList(),
      'masStatus': masStatus,
      'dtsStatus': dtsStatus,
      'dispatchStatus': dispatchStatus,
      'supplierDeliveryNote': supplierDeliveryNote,
      'manufacturer': manufacturer,
      'countryOfOrigin': countryOfOrigin,
      'engineerComments': engineerComments,
      'isSatisfactory': isSatisfactory,
      'dateOfInspection': dateOfInspection.toIso8601String(),
    };
  }

  factory IRData.fromMap(Map<String, dynamic> map) {
    return IRData(
      projectName: map['projectName'] ?? '',
      contractNo: map['contractNo'] ?? '',
      irNo: map['irNo'] ?? '',
      boqItems: (map['boqItems'] as List<dynamic>?)
          ?.map((item) => BOQItem.fromMap(item as Map<String, dynamic>))
          .toList() ??
          [],
      masStatus: map['masStatus'] ?? '',
      dtsStatus: map['dtsStatus'] ?? '',
      dispatchStatus: map['dispatchStatus'] ?? '',
      supplierDeliveryNote: map['supplierDeliveryNote'] ?? '',
      manufacturer: map['manufacturer'] ?? '',
      countryOfOrigin: map['countryOfOrigin'] ?? '',
      engineerComments: map['engineerComments'] ?? '',
      isSatisfactory: map['isSatisfactory'] ?? true,
      dateOfInspection: map['dateOfInspection'] != null
          ? DateTime.parse(map['dateOfInspection'])
          : null,
    );
  }
} 