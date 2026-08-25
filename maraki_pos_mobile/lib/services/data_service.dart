import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import 'supabase_service.dart';

final List<Product> initialProducts = [
  // FOOD MENU (16 ITEMS)
  Product(
    id: 'f-1',
    name: 'Maraki Combo Salad',
    amharicName: 'ማራኪ ኮመቦ ሳላድ',
    category: 'Food',
    price: 430.0,
    description: 'ማንጎ ጁስ ከሳላድ ጋር (Mango juice with salad)',
    imageUrl: 'assets/products/maraki_special.png',
    isAvailable: true,
  ),
  Product(
    id: 'f-2',
    name: 'Salad',
    amharicName: 'ሳላድ',
    category: 'Food',
    price: 320.0,
    description: 'Fresh garden salad',
    imageUrl: 'assets/products/fritsalad.jpg',
    isAvailable: true,
  ),
  Product(
    id: 'f-3',
    name: 'Pasta with Salad',
    amharicName: 'ፓስታ በሳላድ',
    category: 'Food',
    price: 320.0,
    description: 'Pasta served with salad',
    imageUrl: 'assets/products/pasta_with_salad.jpg',
    isAvailable: true,
  ),
  Product(
    id: 'f-4',
    name: 'Rice with Salad',
    amharicName: 'ሩዝ በሳላድ',
    category: 'Food',
    price: 320.0,
    description: 'Rice served with salad',
    imageUrl: 'assets/products/rice_salad.jpg',
    isAvailable: true,
  ),
  Product(
    id: 'f-5',
    name: 'Pasta with Vegetables',
    amharicName: 'ፓስታ በአትክልት',
    category: 'Food',
    price: 320.0,
    description: 'Pasta with vegetables',
    imageUrl: 'assets/products/pastawithvegitable.jpg',
    isAvailable: true,
  ),
  Product(
    id: 'f-6',
    name: 'Rice with Vegetables',
    amharicName: 'ሩዝ በአትክልት',
    category: 'Food',
    price: 320.0,
    description: 'Rice with vegetables',
    imageUrl: 'assets/products/ricewithvegitable.jpg',
    isAvailable: true,
  ),
  Product(
    id: 'f-7',
    name: 'Pasta with Egg',
    amharicName: 'ፓስታ በአንቁላል',
    category: 'Food',
    price: 320.0,
    description: 'Pasta with egg',
    imageUrl: 'assets/products/pasta_with_egg.jpg',
    isAvailable: true,
  ),
  Product(
    id: 'f-8',
    name: 'Rice with Egg',
    amharicName: 'ሩዝ በእንቁላል',
    category: 'Food',
    price: 320.0,
    description: 'Rice with egg',
    imageUrl: 'assets/products/ricewithvegitable.jpg',
    isAvailable: true,
  ),
  Product(
    id: 'f-9',
    name: 'Egg Firfir',
    amharicName: 'እንቁላል ፍርፍር',
    category: 'Food',
    price: 230.0,
    description: 'Egg firfir',
    imageUrl: 'assets/products/enkulal_firfir.jpg',
    isAvailable: true,
  ),
  Product(
    id: 'f-10',
    name: 'Egg Sils',
    amharicName: 'እንቁላል ስልስ',
    category: 'Food',
    price: 230.0,
    description: 'Egg sils sauce',
    imageUrl: 'assets/products/pastawithtomatosause.jpg',
    isAvailable: true,
  ),
  Product(
    id: 'f-11',
    name: 'Egg Sandwich',
    amharicName: 'እንቁላል ሳንድዊች',
    category: 'Food',
    price: 120.0,
    description: 'Egg sandwich',
    imageUrl: 'assets/products/enkulal_sandwich.jpg',
    isAvailable: true,
  ),
  Product(
    id: 'f-12',
    name: 'Vegetable Sandwich',
    amharicName: 'አትክልት ሳንድዊች',
    category: 'Food',
    price: 100.0,
    description: 'Vegetable sandwich',
    imageUrl: 'assets/products/fritsalad.jpg',
    isAvailable: true,
  ),
  Product(
    id: 'f-13',
    name: 'Fruit Punch',
    amharicName: 'ፍሩት ፓንች',
    category: 'Food',
    price: 320.0,
    description: 'Fresh fruit punch bowl',
    imageUrl: 'assets/products/fruitpunch.jpg',
    isAvailable: true,
  ),
  Product(
    id: 'f-14',
    name: 'Firfir',
    amharicName: 'ፍርፍር',
    category: 'Food',
    price: 200.0,
    description: 'Traditional firfir',
    imageUrl: 'assets/products/firfir.webp',
    isAvailable: true,
  ),
  Product(
    id: 'f-15',
    name: 'Pasta with Sauce',
    amharicName: 'ፓስታ በስጎ',
    category: 'Food',
    price: 200.0,
    description: 'Pasta with sauce',
    imageUrl: 'assets/products/pastawithtomatosause.jpg',
    isAvailable: true,
  ),
  Product(
    id: 'f-16',
    name: 'Tasty Soya',
    amharicName: 'ቴስቲሶያ',
    category: 'Food',
    price: 200.0,
    description: 'Tasty soya',
    imageUrl: 'assets/products/protin.jpg',
    isAvailable: true,
  ),

  // JUICE MENU (ALL 170 ETB)
  Product(
    id: 'j-1',
    name: 'Avocado',
    amharicName: 'አቮካዶ',
    category: 'Juice',
    price: 170.0,
    description: 'Fresh creamy avocado juice',
    imageUrl: 'assets/products/avocado.jpg',
    isAvailable: true,
  ),
  Product(
    id: 'j-2',
    name: 'Avocado with Mango',
    amharicName: 'አቮካዶ ከማንጎ ጋር',
    category: 'Juice',
    price: 170.0,
    description: 'Layered avocado & mango juice',
    imageUrl: 'assets/products/avocado.png',
    isAvailable: true,
  ),
  Product(
    id: 'j-3',
    name: 'Special Juice',
    amharicName: 'ስፔሻል ጁስ',
    category: 'Juice',
    price: 170.0,
    description: 'Signature mixed layered special juice',
    imageUrl: 'assets/products/special.jpg',
    isAvailable: true,
  ),
  Product(
    id: 'j-4',
    name: 'Milk Shake',
    amharicName: 'ሚልክ ሼክ',
    category: 'Juice',
    price: 170.0,
    description: 'Creamy cold milk shake smoothie',
    imageUrl: 'assets/products/protin.jpg',
    isAvailable: true,
  ),
  Product(
    id: 'j-5',
    name: 'Mango Juice',
    amharicName: 'ማንጎ ጁስ',
    category: 'Juice',
    price: 170.0,
    description: 'Sweet tropical mango blend',
    imageUrl: 'assets/products/mango.jpg',
    isAvailable: true,
  ),
  Product(
    id: 'j-6',
    name: 'Papaya Juice',
    amharicName: 'ፓፓያ ጁስ',
    category: 'Juice',
    price: 170.0,
    description: 'Pure sun-ripened papaya nectar',
    imageUrl: 'assets/products/papaya.jpg',
    isAvailable: true,
  ),
  Product(
    id: 'j-7',
    name: 'Strawberry Juice',
    amharicName: 'ስትሮውቤሪ ጁስ',
    category: 'Juice',
    price: 170.0,
    description: 'Fresh strawberry blend',
    imageUrl: 'assets/products/strawberryjuice.jpg',
    isAvailable: true,
  ),
  Product(
    id: 'j-8',
    name: 'Pineapple Juice',
    amharicName: 'ፓይናፕል ጁስ',
    category: 'Juice',
    price: 170.0,
    description: 'Fresh pressed pineapple juice',
    imageUrl: 'assets/products/pineapplejuice.jpg',
    isAvailable: true,
  ),
  Product(
    id: 'j-9',
    name: 'Watermelon Juice',
    amharicName: 'ሐብሐብ ጁስ',
    category: 'Juice',
    price: 170.0,
    description: 'Cold fresh watermelon juice',
    imageUrl: 'assets/products/watermillonjuice.jpg',
    isAvailable: true,
  ),
];

final List<CustomerDebt> initialDebts = [];

class DataService {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

  List<Product> _products = List.from(initialProducts);
  List<CustomerDebt> _debts = List.from(initialDebts);
  List<Order> _orders = [];
  List<KitchenTicket> _kitchenTickets = [];
  int _lastLeftoverCups = 120;

  Future<void> init() async {
    await syncCatalogFromCloud();
  }

  /// Automatically syncs catalog from cloud without any APK reinstalls
  Future<bool> syncCatalogFromCloud() async {
    try {
      final cacheBuster = DateTime.now().millisecondsSinceEpoch;
      final response = await http
          .get(
            Uri.parse('https://raw.githubusercontent.com/Samiassaye-21/Budget-system/main/public/catalog.json?t=$cacheBuster'),
            headers: {'Cache-Control': 'no-cache', 'Pragma': 'no-cache'},
          )
          .timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final List<dynamic> list = json.decode(utf8.decode(response.bodyBytes));
        final initialMap = {for (var p in initialProducts) p.id: p};
        final fetched = list.map((item) {
          final p = Product.fromMap(item as Map<String, dynamic>);
          final local = initialMap[p.id];
          if (local != null) {
            return p.copyWith(
              amharicName: p.amharicName.isNotEmpty ? p.amharicName : local.amharicName,
              imageUrl: (p.imageUrl.isNotEmpty && !p.imageUrl.startsWith('assets/')) && local.imageUrl.startsWith('assets/')
                  ? local.imageUrl
                  : (p.imageUrl.isNotEmpty ? p.imageUrl : local.imageUrl),
            );
          }
          return p;
        }).toList();
        if (fetched.isNotEmpty) {
          _products = fetched;
          return true;
        }
      }
    } catch (_) {
      // Retain offline cache safely if offline
    }
    return false;
  }

  int getLastLeftoverCups() {
    return _lastLeftoverCups;
  }

  Future<void> setLastLeftoverCups(int cups) async {
    _lastLeftoverCups = cups;
  }

  List<Product> getProducts() => List.unmodifiable(_products);

  void toggleProductAvailability(String productId) {
    _products = _products.map((p) {
      if (p.id == productId) {
        return p.copyWith(isAvailable: !p.isAvailable);
      }
      return p;
    }).toList();
  }

  void saveProduct(Product product) {
    final idx = _products.indexWhere((p) => p.id == product.id);
    if (idx >= 0) {
      _products[idx] = product;
    } else {
      _products.add(product);
    }
  }

  List<CustomerDebt> getCustomerDebts() => List.unmodifiable(_debts);

  void addDebts(List<CustomerDebt> newDebts) {
    _debts.insertAll(0, newDebts);
    for (final debt in newDebts) {
      SupabaseService.instance.syncDebt(debt);
    }
  }

  void recoverDebtCups(int cupsToRecover) {
    if (cupsToRecover <= 0) return;
    int remainingToRecover = cupsToRecover;
    for (int i = 0; i < _debts.length; i++) {
      if (!_debts[i].isRecovered && remainingToRecover > 0) {
        final debt = _debts[i];
        if (debt.cupCount <= remainingToRecover) {
          remainingToRecover -= debt.cupCount;
          _debts[i] = debt.copyWith(isRecovered: true);
          SupabaseService.instance.syncDebt(_debts[i]);
        } else {
          final unrecoveredCount = debt.cupCount - remainingToRecover;
          final recoveredPart = debt.copyWith(
            id: '${debt.id}-rec-${DateTime.now().millisecondsSinceEpoch}',
            cupCount: remainingToRecover,
            amount: remainingToRecover * debt.pricePerCup,
            isRecovered: true,
          );
          _debts[i] = debt.copyWith(
            cupCount: unrecoveredCount,
            amount: unrecoveredCount * debt.pricePerCup,
          );
          remainingToRecover = 0;
          SupabaseService.instance.syncDebt(recoveredPart);
          SupabaseService.instance.syncDebt(_debts[i]);
        }
      }
    }
  }

  List<Order> getOrders() => List.unmodifiable(_orders);

  void addOrder(Order order) {
    _orders.insert(0, order);
    SupabaseService.instance.syncOrder(order);
  }

  void updateOrders(List<Order> updatedList) {
    for (final updated in updatedList) {
      final idx = _orders.indexWhere((o) => o.id == updated.id);
      if (idx >= 0) {
        _orders[idx] = updated;
      } else {
        _orders.insert(0, updated);
      }
      SupabaseService.instance.syncOrder(updated);
    }
  }

  List<KitchenTicket> getKitchenTickets([String? route]) {
    if (route != null) {
      return _kitchenTickets.where((t) => t.route == route).toList();
    }
    return List.unmodifiable(_kitchenTickets);
  }

  void addKitchenTicket(KitchenTicket ticket) {
    _kitchenTickets.insert(0, ticket);
    SupabaseService.instance.syncKitchenTicket(ticket);
  }

  List<ShiftExpense> _expenses = [];
  List<ShiftReconciliation> _reconciliations = [];

  void deleteProduct(String productId) {
    _products.removeWhere((p) => p.id == productId);
  }

  void deleteOrder(String orderId) {
    _orders.removeWhere((o) => o.id == orderId);
  }

  void deleteDebt(String debtId) {
    _debts.removeWhere((d) => d.id == debtId);
  }

  void toggleDebtRecovered(String debtId) {
    final idx = _debts.indexWhere((d) => d.id == debtId);
    if (idx >= 0) {
      final updated = _debts[idx].copyWith(isRecovered: !_debts[idx].isRecovered);
      _debts[idx] = updated;
      SupabaseService.instance.syncDebt(updated);
    }
  }

  void deleteKitchenTicket(String ticketId) {
    _kitchenTickets.removeWhere((t) => t.id == ticketId);
  }

  void clearKitchenTickets() {
    _kitchenTickets.clear();
  }

  List<ShiftExpense> getExpenses() => List.unmodifiable(_expenses);

  void addExpense(ShiftExpense expense) {
    _expenses.insert(0, expense);
  }

  void deleteExpense(String expenseId) {
    _expenses.removeWhere((e) => e.id == expenseId);
  }

  List<ShiftReconciliation> getReconciliations() => List.unmodifiable(_reconciliations);

  void saveReconciliation(ShiftReconciliation recon) {
    final idx = _reconciliations.indexWhere((r) => r.id == recon.id || r.shiftId == recon.shiftId);
    if (idx >= 0) {
      _reconciliations[idx] = recon;
    } else {
      _reconciliations.insert(0, recon);
    }
  }

  void resetToDefaultData() {
    _products = List.from(initialProducts);
    _debts = List.from(initialDebts);
    _orders = [];
    _kitchenTickets = [];
    _expenses = [];
    _reconciliations = [];
    _lastLeftoverCups = 120;
  }

  void clearSessionOrders() {
    _orders.clear();
  }
}
