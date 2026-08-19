import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

final List<Product> initialProducts = [
  // FOOD MENU (16 ITEMS)
  Product(
    id: 'f-1',
    name: 'Maraki Combo Salad',
    amharicName: 'ማራኪ ኮመቦ ሳላድ',
    category: 'Food',
    price: 430.0,
    description: 'Maraki combo salad',
    imageUrl: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=500&auto=format&fit=crop&q=60',
    isAvailable: true,
  ),
  Product(
    id: 'f-2',
    name: 'Salad',
    amharicName: 'ሳላድ',
    category: 'Food',
    price: 320.0,
    description: 'Fresh garden salad',
    imageUrl: 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=500&auto=format&fit=crop&q=60',
    isAvailable: true,
  ),
  Product(
    id: 'f-3',
    name: 'Pasta with Salad',
    amharicName: 'ፓስታ በሳላድ',
    category: 'Food',
    price: 320.0,
    description: 'Pasta served with salad',
    imageUrl: 'https://images.unsplash.com/photo-1621996346565-e3def616403c?w=500&auto=format&fit=crop&q=60',
    isAvailable: true,
  ),
  Product(
    id: 'f-4',
    name: 'Rice with Salad',
    amharicName: 'ሩዝ በሳላድ',
    category: 'Food',
    price: 320.0,
    description: 'Rice served with salad',
    imageUrl: 'https://images.unsplash.com/photo-1512058564366-18510be2db19?w=500&auto=format&fit=crop&q=60',
    isAvailable: true,
  ),
  Product(
    id: 'f-5',
    name: 'Pasta with Vegetables',
    amharicName: 'ፓስታ በአትክልት',
    category: 'Food',
    price: 320.0,
    description: 'Pasta with vegetables',
    imageUrl: 'https://images.unsplash.com/photo-1621996346565-e3def616403c?w=500&auto=format&fit=crop&q=60',
    isAvailable: true,
  ),
  Product(
    id: 'f-6',
    name: 'Rice with Vegetables',
    amharicName: 'ሩዝ በአትክልት',
    category: 'Food',
    price: 320.0,
    description: 'Rice with vegetables',
    imageUrl: 'https://images.unsplash.com/photo-1512058564366-18510be2db19?w=500&auto=format&fit=crop&q=60',
    isAvailable: true,
  ),
  Product(
    id: 'f-7',
    name: 'Pasta with Egg',
    amharicName: 'ፓስታ በአንቁላል',
    category: 'Food',
    price: 320.0,
    description: 'Pasta with egg',
    imageUrl: 'https://images.unsplash.com/photo-1525351484163-7529414344d8?w=500&auto=format&fit=crop&q=60',
    isAvailable: true,
  ),
  Product(
    id: 'f-8',
    name: 'Rice with Egg',
    amharicName: 'ሩዝ በእንቁላል',
    category: 'Food',
    price: 320.0,
    description: 'Rice with egg',
    imageUrl: 'https://images.unsplash.com/photo-1525351484163-7529414344d8?w=500&auto=format&fit=crop&q=60',
    isAvailable: true,
  ),
  Product(
    id: 'f-9',
    name: 'Egg Firfir',
    amharicName: 'እንቁላል ፍርፍር',
    category: 'Food',
    price: 230.0,
    description: 'Egg firfir',
    imageUrl: 'https://images.unsplash.com/photo-1525351484163-7529414344d8?w=500&auto=format&fit=crop&q=60',
    isAvailable: true,
  ),
  Product(
    id: 'f-10',
    name: 'Egg Sils',
    amharicName: 'እንቁላል ስልስ',
    category: 'Food',
    price: 230.0,
    description: 'Egg sils sauce',
    imageUrl: 'https://images.unsplash.com/photo-1525351484163-7529414344d8?w=500&auto=format&fit=crop&q=60',
    isAvailable: true,
  ),
  Product(
    id: 'f-11',
    name: 'Egg Sandwich',
    amharicName: 'እንቁላል ሳንድዊች',
    category: 'Food',
    price: 120.0,
    description: 'Egg sandwich',
    imageUrl: 'https://images.unsplash.com/photo-1528735602780-2552fd46c7af?w=500&auto=format&fit=crop&q=60',
    isAvailable: true,
  ),
  Product(
    id: 'f-12',
    name: 'Vegetable Sandwich',
    amharicName: 'አትክልት ሳንድዊች',
    category: 'Food',
    price: 100.0,
    description: 'Vegetable sandwich',
    imageUrl: 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=500&auto=format&fit=crop&q=60',
    isAvailable: true,
  ),
  Product(
    id: 'f-13',
    name: 'Fruit Punch',
    amharicName: 'ፍሩት ፓንች',
    category: 'Food',
    price: 320.0,
    description: 'Fresh fruit punch bowl',
    imageUrl: 'https://images.unsplash.com/photo-1490474418585-ba9bad8fd0ea?w=500&auto=format&fit=crop&q=60',
    isAvailable: true,
  ),
  Product(
    id: 'f-14',
    name: 'Firfir',
    amharicName: 'ፍርፍር',
    category: 'Food',
    price: 200.0,
    description: 'Traditional firfir',
    imageUrl: 'https://images.unsplash.com/photo-1546833999-b9f581a1996d?w=500&auto=format&fit=crop&q=60',
    isAvailable: true,
  ),
  Product(
    id: 'f-15',
    name: 'Pasta with Sauce',
    amharicName: 'ፓስታ በስጎ',
    category: 'Food',
    price: 200.0,
    description: 'Pasta with sauce',
    imageUrl: 'https://images.unsplash.com/photo-1621996346565-e3def616403c?w=500&auto=format&fit=crop&q=60',
    isAvailable: true,
  ),
  Product(
    id: 'f-16',
    name: 'Tasty Soya',
    amharicName: 'ቴስቲሶያ',
    category: 'Food',
    price: 200.0,
    description: 'Tasty soya',
    imageUrl: 'https://images.unsplash.com/photo-1546833999-b9f581a1996d?w=500&auto=format&fit=crop&q=60',
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
    imageUrl: 'https://images.unsplash.com/photo-1623065422902-30a2d299bbe4?w=500&auto=format&fit=crop&q=60',
    isAvailable: true,
  ),
  Product(
    id: 'j-2',
    name: 'Avocado with Mango',
    amharicName: 'አቮካዶ ከማንጎ ጋር',
    category: 'Juice',
    price: 170.0,
    description: 'Layered avocado & mango juice',
    imageUrl: 'https://images.unsplash.com/photo-1553530666-ba11a7da3888?w=500&auto=format&fit=crop&q=60',
    isAvailable: true,
  ),
  Product(
    id: 'j-3',
    name: 'Special Spris',
    amharicName: 'ስፕሪስ ጁስ',
    category: 'Juice',
    price: 170.0,
    description: 'Signature mixed layered sprize juice',
    imageUrl: 'https://images.unsplash.com/photo-1553530666-ba11a7da3888?w=500&auto=format&fit=crop&q=60',
    isAvailable: true,
  ),
  Product(
    id: 'j-4',
    name: 'Milk Shake',
    amharicName: 'ሚልክ ሼክ',
    category: 'Juice',
    price: 170.0,
    description: 'Creamy cold milk shake smoothie',
    imageUrl: 'https://images.unsplash.com/photo-1572490122747-3968b75cc699?w=500&auto=format&fit=crop&q=60',
    isAvailable: true,
  ),
  Product(
    id: 'j-5',
    name: 'Mango Juice',
    amharicName: 'ማንጎ ጁስ',
    category: 'Juice',
    price: 170.0,
    description: 'Sweet tropical mango blend',
    imageUrl: 'https://images.unsplash.com/photo-1546173159-315724a31696?w=500&auto=format&fit=crop&q=60',
    isAvailable: true,
  ),
  Product(
    id: 'j-6',
    name: 'Papaya Juice',
    amharicName: 'ፓፓያ ጁስ',
    category: 'Juice',
    price: 170.0,
    description: 'Pure sun-ripened papaya nectar',
    imageUrl: 'https://images.unsplash.com/photo-1517456793572-1d8efd6dc135?w=500&auto=format&fit=crop&q=60',
    isAvailable: true,
  ),
  Product(
    id: 'j-7',
    name: 'Strawberry Juice',
    amharicName: 'ስትሮውቤሪ ጁስ',
    category: 'Juice',
    price: 170.0,
    description: 'Fresh strawberry blend',
    imageUrl: 'https://images.unsplash.com/photo-1553530666-ba11a7da3888?w=500&auto=format&fit=crop&q=60',
    isAvailable: true,
  ),
  Product(
    id: 'j-8',
    name: 'Pineapple Juice',
    amharicName: 'ፓይናፕል ጁስ',
    category: 'Juice',
    price: 170.0,
    description: 'Fresh pressed pineapple juice',
    imageUrl: 'https://images.unsplash.com/photo-1550258987-190a2d41a8ba?w=500&auto=format&fit=crop&q=60',
    isAvailable: true,
  ),
  Product(
    id: 'j-9',
    name: 'Watermelon Juice',
    amharicName: 'ሐብሐብ ጁስ',
    category: 'Juice',
    price: 170.0,
    description: 'Cold fresh watermelon juice',
    imageUrl: 'https://images.unsplash.com/photo-1589733955941-5eeaf752f6dd?w=500&auto=format&fit=crop&q=60',
    isAvailable: true,
  ),
];

final List<CustomerDebt> initialDebts = [
  CustomerDebt(
    id: 'deb-1',
    customerName: 'አበበ ቢቂላ (Abebe Bikila)',
    note: 'የትላንትና የቢሮ ጁስ ብድር',
    cupCount: 5,
    pricePerCup: 170,
    amount: 850,
    isRecovered: false,
    shiftIdCreated: 'prev-shift-1',
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
  ),
  CustomerDebt(
    id: 'deb-2',
    customerName: 'ትዕግስት ኃይሌ (Tigist Haile)',
    note: 'የምሳ ጁስ ማዘዣ ብድር',
    cupCount: 3,
    pricePerCup: 170,
    amount: 510,
    isRecovered: false,
    shiftIdCreated: 'prev-shift-2',
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
  ),
  CustomerDebt(
    id: 'deb-3',
    customerName: 'ከበደ ታሰሰ (Kebede Tassew)',
    note: 'የካፌ ዴሊቨሪ ጁስ ብድር',
    cupCount: 8,
    pricePerCup: 170,
    amount: 1360,
    isRecovered: false,
    shiftIdCreated: 'prev-shift-3',
    createdAt: DateTime.now().subtract(const Duration(days: 3)),
  ),
];

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
        final fetched = list.map((item) => Product.fromMap(item as Map<String, dynamic>)).toList();
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
  }

  List<Order> getOrders() => List.unmodifiable(_orders);

  void addOrder(Order order) {
    _orders.insert(0, order);
  }

  void updateOrders(List<Order> updatedList) {
    for (final updated in updatedList) {
      final idx = _orders.indexWhere((o) => o.id == updated.id);
      if (idx >= 0) {
        _orders[idx] = updated;
      } else {
        _orders.insert(0, updated);
      }
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
  }

  void clearSessionOrders() {
    _orders.clear();
  }
}
