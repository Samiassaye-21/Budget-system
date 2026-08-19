import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../services/data_service.dart';

class POSProvider extends ChangeNotifier {
  final DataService _dataService = DataService();
  final Uuid _uuid = const Uuid();

  AppMode _mode = AppMode.gate;
  ShiftType? _shiftType;
  ShiftSession? _shiftSession;

  List<Product> _products = [];
  List<CustomerDebt> _debts = [];
  List<Order> _orders = [];
  List<ShiftReconciliation> _reconciliations = [];

  // Active Cart / Order in POS
  List<OrderItem> _currentCart = [];
  String _selectedPaymentMethod = 'Cash';
  String _orderNotes = '';
  String _selectedCategory = 'Juice';
  String _searchQuery = '';

  List<KitchenTicket> _kitchenTickets = [];

  AppMode get mode => _mode;
  ShiftType? get shiftType => _shiftType;
  ShiftSession? get shiftSession => _shiftSession;
  List<Product> get products => _products;
  List<CustomerDebt> get debts => _debts;
  List<Order> get orders => _orders;
  List<ShiftReconciliation> get reconciliations => _reconciliations;
  List<KitchenTicket> get kitchenTickets => _kitchenTickets;

  List<OrderItem> get currentCart => _currentCart;
  String get selectedPaymentMethod => _selectedPaymentMethod;
  String get orderNotes => _orderNotes;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;

  double get cartTotal => _currentCart.fold(0.0, (sum, i) => sum + (i.price * i.quantity));
  int get cartJuiceCupsCount => _currentCart.fold(0, (sum, i) => sum + i.quantity);

  // Unresolved Pay Later orders
  List<Order> get pendingPayLaterOrders =>
      _orders.where((o) => o.paymentMethod == 'Pay later').toList();

  int get shiftJuiceCupsSold => _orders.fold(
        0,
        (sum, o) => sum + o.items.where((i) => i.price == 170).fold(0, (iSum, item) => iSum + item.quantity),
      );

  int get shiftFoodSold => _orders.fold(
        0,
        (sum, o) => sum + o.items.where((i) => i.price != 170).fold(0, (iSum, item) => iSum + item.quantity),
      );

  List<KitchenTicket> get shiftKitchenTickets {
    final routeName = _shiftSession?.shiftType == ShiftType.night ? 'Night shift' : 'Day shift';
    return _kitchenTickets.where((t) => t.route == routeName).toList();
  }

  int get kitchenFoodCookedForShift =>
      shiftKitchenTickets.fold(0, (sum, t) => sum + t.totalQuantity);

  int get foodDiscrepancy => shiftFoodSold - kitchenFoodCookedForShift;

  POSProvider() {
    _init();
  }

  Future<void> _init() async {
    await _dataService.init();
    _products = _dataService.getProducts();
    _debts = _dataService.getCustomerDebts();
    _orders = _dataService.getOrders();
    _kitchenTickets = _dataService.getKitchenTickets();
    notifyListeners();
  }

  void addKitchenTicket(KitchenTicket ticket) {
    _kitchenTickets.insert(0, ticket);
    _dataService.addKitchenTicket(ticket);
    notifyListeners();
  }

  void setMode(AppMode newMode) {
    _mode = newMode;
    notifyListeners();
  }

  void selectCategory(String cat) {
    _selectedCategory = cat;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setPaymentMethod(String method) {
    _selectedPaymentMethod = method;
    notifyListeners();
  }

  void setOrderNotes(String notes) {
    _orderNotes = notes;
    notifyListeners();
  }

  void selectShift(ShiftType chosenShift) {
    _shiftType = chosenShift;
    if (_shiftSession != null &&
        _shiftSession!.shiftType == chosenShift &&
        _shiftSession!.status == 'active') {
      _mode = AppMode.pos;
    } else {
      _mode = AppMode.cups;
    }
    notifyListeners();
  }

  void startShiftSession(int openingCups) {
    if (_shiftType == null) return;
    _shiftSession = ShiftSession(
      id: 'shift-${DateTime.now().millisecondsSinceEpoch}',
      shiftType: _shiftType!,
      cashierName: 'ሳራ መኮንን (Sara M.)',
      openingCups: openingCups,
      status: 'active',
      startedAt: DateTime.now(),
    );
    _orders = [];
    _dataService.clearSessionOrders();
    _currentCart = [];
    _mode = AppMode.pos;
    notifyListeners();
  }

  void addToCart(Product product) {
    if (!product.isAvailable) return;
    final idx = _currentCart.indexWhere((item) => item.productId == product.id);
    if (idx >= 0) {
      final existing = _currentCart[idx];
      _currentCart[idx] = OrderItem(
        productId: existing.productId,
        name: existing.name,
        price: existing.price,
        quantity: existing.quantity + 1,
      );
    } else {
      _currentCart.add(
        OrderItem(
          productId: product.id,
          name: product.name,
          price: product.price,
          quantity: 1,
        ),
      );
    }
    notifyListeners();
  }

  void updateCartQuantity(String productId, int delta) {
    final idx = _currentCart.indexWhere((item) => item.productId == productId);
    if (idx < 0) return;
    final newQty = _currentCart[idx].quantity + delta;
    if (newQty <= 0) {
      _currentCart.removeAt(idx);
    } else {
      _currentCart[idx] = OrderItem(
        productId: _currentCart[idx].productId,
        name: _currentCart[idx].name,
        price: _currentCart[idx].price,
        quantity: newQty,
      );
    }
    notifyListeners();
  }

  void clearCart() {
    _currentCart.clear();
    _orderNotes = '';
    notifyListeners();
  }

  bool fireOrder() {
    if (_currentCart.isEmpty || _shiftSession == null) return false;

    final order = Order(
      id: 'ord-${_uuid.v4().substring(0, 6)}',
      items: List.from(_currentCart),
      total: cartTotal,
      paymentMethod: _selectedPaymentMethod,
      notes: _orderNotes,
      createdAt: DateTime.now(),
      shiftType: _shiftSession!.shiftType,
      status: 'pending',
    );

    _orders.insert(0, order);
    _dataService.addOrder(order);
    _currentCart.clear();
    _orderNotes = '';
    notifyListeners();
    return true;
  }

  void confirmPayLaterResolutions(List<Order> updatedList, List<CustomerDebt> newDebts) {
    for (final updated in updatedList) {
      final idx = _orders.indexWhere((o) => o.id == updated.id);
      if (idx >= 0) {
        _orders[idx] = updated;
      }
    }
    _dataService.updateOrders(updatedList);

    if (newDebts.isNotEmpty) {
      _debts.insertAll(0, newDebts);
      _dataService.addDebts(newDebts);
    }
    notifyListeners();
  }

  Future<void> completeReconciliation(ShiftReconciliation recon) async {
    _reconciliations.insert(0, recon);
    await _dataService.setLastLeftoverCups(recon.leftoverCups);
    _shiftSession = null;
    _orders = [];
    _currentCart = [];
    _mode = AppMode.gate;
    notifyListeners();
  }

  void toggleProductAvailability(String productId) {
    _dataService.toggleProductAvailability(productId);
    _products = _dataService.getProducts();
    notifyListeners();
  }

  void saveProduct(Product product) {
    _dataService.saveProduct(product);
    _products = _dataService.getProducts();
    notifyListeners();
  }

  void updateOrderStatus(String orderId, String newStatus) {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx >= 0) {
      _orders[idx] = _orders[idx].copyWith(status: newStatus);
      notifyListeners();
    }
  }
}
