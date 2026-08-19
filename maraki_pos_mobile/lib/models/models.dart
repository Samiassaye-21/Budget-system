import 'dart:convert';

enum ShiftType { day, night }

enum AppMode { gate, cups, pos, kitchen, admin }

class Product {
  final String id;
  final String name;
  final String amharicName;
  final String category; // 'Juice' | 'Food'
  final double price;
  final String description;
  final String imageUrl;
  final bool isAvailable;

  Product({
    required this.id,
    required this.name,
    required this.amharicName,
    required this.category,
    required this.price,
    required this.description,
    required this.imageUrl,
    this.isAvailable = true,
  });

  Product copyWith({
    String? id,
    String? name,
    String? amharicName,
    String? category,
    double? price,
    String? description,
    String? imageUrl,
    bool? isAvailable,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      amharicName: amharicName ?? this.amharicName,
      category: category ?? this.category,
      price: price ?? this.price,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amharicName': amharicName,
      'category': category,
      'price': price,
      'description': description,
      'imageUrl': imageUrl,
      'isAvailable': isAvailable,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      amharicName: map['amharicName'] ?? '',
      category: map['category'] ?? 'Juice',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      isAvailable: map['isAvailable'] ?? true,
    );
  }

  String toJson() => json.encode(toMap());
  factory Product.fromJson(String source) => Product.fromMap(json.decode(source));
}

class OrderItem {
  final String productId;
  final String name;
  final double price;
  final int quantity;

  OrderItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'price': price,
      'quantity': quantity,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId'] ?? '',
      name: map['name'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      quantity: map['quantity']?.toInt() ?? 1,
    );
  }
}

class Order {
  final String id;
  final List<OrderItem> items;
  final double total;
  final String paymentMethod; // 'Cash' | 'Transfer' | 'Pay later' | 'Credit' | 'Delivery'
  final String notes;
  final DateTime createdAt;
  final ShiftType shiftType;
  final String status; // 'pending' | 'ready' | 'delivered'

  Order({
    required this.id,
    required this.items,
    required this.total,
    required this.paymentMethod,
    this.notes = '',
    required this.createdAt,
    required this.shiftType,
    this.status = 'pending',
  });

  Order copyWith({
    String? id,
    List<OrderItem>? items,
    double? total,
    String? paymentMethod,
    String? notes,
    DateTime? createdAt,
    ShiftType? shiftType,
    String? status,
  }) {
    return Order(
      id: id ?? this.id,
      items: items ?? this.items,
      total: total ?? this.total,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      shiftType: shiftType ?? this.shiftType,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'items': items.map((x) => x.toMap()).toList(),
      'total': total,
      'paymentMethod': paymentMethod,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'shiftType': shiftType.name,
      'status': status,
    };
  }

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'] ?? '',
      items: List<OrderItem>.from((map['items'] as List? ?? []).map((x) => OrderItem.fromMap(x))),
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: map['paymentMethod'] ?? 'Cash',
      notes: map['notes'] ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      shiftType: map['shiftType'] == 'night' ? ShiftType.night : ShiftType.day,
      status: map['status'] ?? 'pending',
    );
  }
}

class ShiftSession {
  final String id;
  final ShiftType shiftType;
  final String cashierName;
  final int openingCups;
  final String status; // 'active' | 'closed'
  final DateTime startedAt;

  ShiftSession({
    required this.id,
    required this.shiftType,
    required this.cashierName,
    required this.openingCups,
    this.status = 'active',
    required this.startedAt,
  });
}

class CustomerDebt {
  final String id;
  final String customerName;
  final String note;
  final int cupCount;
  final double pricePerCup;
  final double amount;
  final bool isRecovered;
  final String shiftIdCreated;
  final DateTime createdAt;

  CustomerDebt({
    required this.id,
    required this.customerName,
    required this.note,
    required this.cupCount,
    this.pricePerCup = 170.0,
    required this.amount,
    this.isRecovered = false,
    required this.shiftIdCreated,
    required this.createdAt,
  });

  CustomerDebt copyWith({
    String? id,
    String? customerName,
    String? note,
    int? cupCount,
    double? pricePerCup,
    double? amount,
    bool? isRecovered,
    String? shiftIdCreated,
    DateTime? createdAt,
  }) {
    return CustomerDebt(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      note: note ?? this.note,
      cupCount: cupCount ?? this.cupCount,
      pricePerCup: pricePerCup ?? this.pricePerCup,
      amount: amount ?? this.amount,
      isRecovered: isRecovered ?? this.isRecovered,
      shiftIdCreated: shiftIdCreated ?? this.shiftIdCreated,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerName': customerName,
      'note': note,
      'cupCount': cupCount,
      'pricePerCup': pricePerCup,
      'amount': amount,
      'isRecovered': isRecovered,
      'shiftIdCreated': shiftIdCreated,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CustomerDebt.fromMap(Map<String, dynamic> map) {
    return CustomerDebt(
      id: map['id'] ?? '',
      customerName: map['customerName'] ?? '',
      note: map['note'] ?? '',
      cupCount: map['cupCount']?.toInt() ?? 0,
      pricePerCup: (map['pricePerCup'] as num?)?.toDouble() ?? 170.0,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      isRecovered: map['isRecovered'] ?? false,
      shiftIdCreated: map['shiftIdCreated'] ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class ShiftExpense {
  final String id;
  final String shiftId;
  final String category;
  final String description;
  final double amount;
  final DateTime loggedAt;

  ShiftExpense({
    required this.id,
    required this.shiftId,
    required this.category,
    required this.description,
    required this.amount,
    required this.loggedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shiftId': shiftId,
      'category': category,
      'description': description,
      'amount': amount,
      'loggedAt': loggedAt.toIso8601String(),
    };
  }

  factory ShiftExpense.fromMap(Map<String, dynamic> map) {
    return ShiftExpense(
      id: map['id'] ?? '',
      shiftId: map['shiftId'] ?? '',
      category: map['category'] ?? '',
      description: map['description'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      loggedAt: DateTime.tryParse(map['loggedAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class KitchenTicket {
  final String id;
  final String route; // 'Day shift' | 'Night shift' | 'Bue delivery'
  final List<OrderItem> items;
  final int totalQuantity;
  final DateTime createdAt;

  KitchenTicket({
    required this.id,
    required this.route,
    required this.items,
    required this.totalQuantity,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'route': route,
      'items': items.map((x) => x.toMap()).toList(),
      'totalQuantity': totalQuantity,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory KitchenTicket.fromMap(Map<String, dynamic> map) {
    return KitchenTicket(
      id: map['id'] ?? '',
      route: map['route'] ?? 'Day shift',
      items: List<OrderItem>.from((map['items'] as List? ?? []).map((x) => OrderItem.fromMap(x))),
      totalQuantity: map['totalQuantity']?.toInt() ?? 0,
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class ShiftReconciliation {
  final String id;
  final String shiftId;
  final ShiftType shiftType;
  final String cashierName;
  final double grossRevenue;
  final double cashSales;
  final double transferSales;
  final double creditSales;
  final double deliverySales;
  final double tipSales;
  final int totalOrdersCount;
  final int openingCups;
  final int addedCups;
  final int leftoverCups;
  final int calculatedCupsSold;
  final int tabletCupsSold;
  final int cupsVariance;
  final int totalKitchenFoodCooked;
  final int totalWaiterFoodSold;
  final int foodVariance;
  final double totalExpenses;
  final List<ShiftExpense> expenses;
  final int totalRecoveredCups;
  final double totalRecoveredDebts;
  final double netCashToOwner;
  final String shiftNotes;
  final DateTime closedAt;

  ShiftReconciliation({
    required this.id,
    required this.shiftId,
    required this.shiftType,
    required this.cashierName,
    required this.grossRevenue,
    required this.cashSales,
    required this.transferSales,
    required this.creditSales,
    required this.deliverySales,
    this.tipSales = 0.0,
    required this.totalOrdersCount,
    required this.openingCups,
    required this.addedCups,
    required this.leftoverCups,
    required this.calculatedCupsSold,
    required this.tabletCupsSold,
    required this.cupsVariance,
    this.totalKitchenFoodCooked = 0,
    this.totalWaiterFoodSold = 0,
    this.foodVariance = 0,
    required this.totalExpenses,
    required this.expenses,
    required this.totalRecoveredCups,
    required this.totalRecoveredDebts,
    required this.netCashToOwner,
    this.shiftNotes = '',
    required this.closedAt,
  });
}
