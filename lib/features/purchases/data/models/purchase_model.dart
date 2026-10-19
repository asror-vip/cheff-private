class SupplierModel {
  final String id;
  final String name;
  final String contactPerson;
  final String phone;

  SupplierModel({
    required this.id,
    required this.name,
    required this.contactPerson,
    required this.phone,
  });

  factory SupplierModel.fromJson(Map<String, dynamic> json) {
    return SupplierModel(
      id: json['id'],
      name: json['name'],
      contactPerson: json['contact_person'] ?? '',
      phone: json['phone'] ?? '',
    );
  }
}

class PurchaseItemModel {
  final String id;
  final String purchaseId;
  final String productId;
  final double quantity;
  final double price;
  final String unit;
  
  final String productName;

  PurchaseItemModel({
    required this.id,
    required this.purchaseId,
    required this.productId,
    required this.quantity,
    required this.price,
    required this.unit,
    this.productName = '',
  });

  factory PurchaseItemModel.fromJson(Map<String, dynamic> json) {
    String pName = '';
    if (json['products'] != null) {
      pName = json['products']['name'] ?? '';
    }
    return PurchaseItemModel(
      id: json['id'],
      purchaseId: json['purchase_id'],
      productId: json['product_id'],
      quantity: (json['quantity'] ?? 0).toDouble(),
      price: (json['price'] ?? 0).toDouble(),
      unit: json['unit'] ?? 'шт',
      productName: pName,
    );
  }
}

class PurchaseModel {
  final String id;
  final String restaurantId;
  final String? supplierId;
  final String invoiceNumber;
  final String status;
  final double totalAmount;
  final DateTime date;
  
  final SupplierModel? supplier;
  final List<PurchaseItemModel> items;

  PurchaseModel({
    required this.id,
    required this.restaurantId,
    this.supplierId,
    required this.invoiceNumber,
    required this.status,
    required this.totalAmount,
    required this.date,
    this.supplier,
    this.items = const [],
  });

  factory PurchaseModel.fromJson(Map<String, dynamic> json) {
    SupplierModel? sModel;
    if (json['suppliers'] != null) {
      sModel = SupplierModel.fromJson(json['suppliers']);
    }

    var itemsList = <PurchaseItemModel>[];
    if (json['purchase_items'] != null) {
      itemsList = (json['purchase_items'] as List)
          .map((i) => PurchaseItemModel.fromJson(i))
          .toList();
    }

    return PurchaseModel(
      id: json['id'],
      restaurantId: json['restaurant_id'],
      supplierId: json['supplier_id'],
      invoiceNumber: json['invoice_number'] ?? '',
      status: json['status'] ?? 'pending',
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      date: DateTime.parse(json['date']),
      supplier: sModel,
      items: itemsList,
    );
  }
}
