import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../services/data_service.dart';
import '../services/supabase_service.dart';

class POSProvider extends ChangeNotifier {
  final DataService _dataService = DataService();
  final Uuid _uuid = const Uuid();

  AppMode _mode = AppMode.gate;
  ShiftType? _shiftType;
  ShiftSession? _dayShiftSession;
  ShiftSession? _nightShiftSession;

  List<Product> _products = [];
  List<CustomerDebt> _debts = [];
  List<Order> _orders = [];
  List<ShiftReconciliation> _reconciliations = [];
  List<ShiftExpense> _expenses = [];

  // Active Cart / Order in POS
  List<OrderItem> _currentCart = [];
  String _selectedPaymentMethod = 'Cash';
  String _orderNotes = '';
  String _selectedCategory = 'Juice';
  String _searchQuery = '';

  List<KitchenTicket> _kitchenTickets = [];

  AppMode get mode => _mode;
  ShiftType? get shiftType => _shiftType;
  ShiftSession? get dayShiftSession => _dayShiftSession;
  ShiftSession? get nightShiftSession => _nightShiftSession;
  bool get isDayShiftActive =>
      _dayShiftSession != null && _dayShiftSession!.status == 'active';
  bool get isNightShiftActive =>
      _nightShiftSession != null && _nightShiftSession!.status == 'active';

  ShiftSession? get shiftSession =>
      _shiftType == ShiftType.night ? _nightShiftSession : _dayShiftSession;
  List<Product> get products => _products;
  List<CustomerDebt> get debts => _debts;
  List<Order> get orders => _orders;
  List<ShiftReconciliation> get reconciliations => _reconciliations;
  List<ShiftExpense> get expenses => _expenses;
  List<KitchenTicket> get kitchenTickets => _kitchenTickets;

  String _dayShiftPin = '1111';
  String _nightShiftPin = '2222';
  String _adminPin = '9999';

  String get dayShiftPin => _dayShiftPin;
  String get nightShiftPin => _nightShiftPin;
  String get adminPin => _adminPin;

  void updatePins({String? dayPin, String? nightPin, String? adminPin}) {
    if (dayPin != null && dayPin.isNotEmpty) _dayShiftPin = dayPin;
    if (nightPin != null && nightPin.isNotEmpty) _nightShiftPin = nightPin;
    if (adminPin != null && adminPin.isNotEmpty) _adminPin = adminPin;
    notifyListeners();
  }

  int get totalPendingDebtCups =>
      _debts.where((d) => !d.isRecovered).fold(0, (sum, d) => sum + d.cupCount);
  double get totalPendingDebtAmount =>
      _debts.where((d) => !d.isRecovered).fold(0.0, (sum, d) => sum + d.amount);

  List<OrderItem> get currentCart => _currentCart;
  String get selectedPaymentMethod => _selectedPaymentMethod;
  String get orderNotes => _orderNotes;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;

  double get cartTotal =>
      _currentCart.fold(0.0, (sum, i) => sum + (i.price * i.quantity));
  int get cartJuiceCupsCount =>
      _currentCart.fold(0, (sum, i) => sum + i.quantity);

  // Unresolved Pay Later orders
  List<Order> get pendingPayLaterOrders =>
      _orders.where((o) => o.paymentMethod == 'Pay later').toList();

  bool isJuiceItem(OrderItem item) {
    if (item.productId.startsWith('j-') || item.productId.startsWith('j_'))
      return true;
    if (item.productId.startsWith('f-') || item.productId.startsWith('f_'))
      return false;

    final matches = _products.where(
      (p) =>
          p.id == item.productId ||
          p.name.toLowerCase() == item.name.toLowerCase() ||
          p.amharicName == item.name,
    );
    if (matches.isNotEmpty) {
      final cat = matches.first.category.toLowerCase();
      return cat == 'juice' || cat == 'beverage' || cat == 'ትኩስ ጁሶች';
    }

    final n = item.name.toLowerCase();
    return !n.contains('salad') &&
        !n.contains('pasta') &&
        !n.contains('rice') &&
        !n.contains('food') &&
        !n.contains('combo') &&
        !n.contains('sandwich') &&
        !n.contains('burger') &&
        !n.contains('pizza') &&
        !n.contains('ሳላድ') &&
        !n.contains('ፓስታ') &&
        !n.contains('ሩዝ') &&
        !n.contains('ምግብ') &&
        !n.contains('እንቁላል') &&
        !n.contains('ፉል');
  }

  int get shiftJuiceCupsSold {
    if (_shiftType == null || shiftSession == null) return 0;
    return _orders
        .where(
          (o) =>
              o.shiftType == _shiftType &&
              o.createdAt.isAfter(
                shiftSession!.startedAt.subtract(const Duration(seconds: 1)),
              ),
        )
        .fold(
          0,
          (sum, o) =>
              sum +
              o.items
                  .where(isJuiceItem)
                  .fold(0, (iSum, item) => iSum + item.quantity),
        );
  }

  int get shiftFoodSold {
    if (_shiftType == null || shiftSession == null) return 0;
    return _orders
        .where(
          (o) =>
              o.shiftType == _shiftType &&
              o.createdAt.isAfter(
                shiftSession!.startedAt.subtract(const Duration(seconds: 1)),
              ),
        )
        .fold(
          0,
          (sum, o) =>
              sum +
              o.items
                  .where((i) => !isJuiceItem(i))
                  .fold(0, (iSum, item) => iSum + item.quantity),
        );
  }

  List<KitchenTicket> get shiftKitchenTickets {
    if (shiftSession == null) return [];
    final routeName = _shiftType == ShiftType.night
        ? 'Night shift'
        : 'Day shift';
    return _kitchenTickets
        .where(
          (t) =>
              (t.route == routeName ||
                  t.route == 'BeU delivery' ||
                  t.route == 'Bue delivery') &&
              t.createdAt.isAfter(
                shiftSession!.startedAt.subtract(const Duration(seconds: 1)),
              ),
        )
        .toList();
  }

  List<KitchenTicket> get pendingShiftKitchenTickets {
    if (shiftSession == null) return [];
    final routeName = _shiftType == ShiftType.night
        ? 'Night shift'
        : 'Day shift';
    return _kitchenTickets
        .where(
          (t) =>
              (t.route == routeName ||
                  t.route == 'BeU delivery' ||
                  t.route == 'Bue delivery') &&
              t.status == 'pending' &&
              t.createdAt.isAfter(
                shiftSession!.startedAt.subtract(const Duration(seconds: 1)),
              ),
        )
        .toList();
  }

  int get kitchenFoodCookedForShift =>
      shiftKitchenTickets.fold(0, (sum, t) => sum + t.totalQuantity);

  int get foodDiscrepancy => shiftFoodSold - kitchenFoodCookedForShift;

  Timer? _cloudPollingTimer;

  POSProvider() {
    _init();
  }

  Future<void> _init() async {
    _products = List.from(_dataService.getProducts());
    _debts = List.from(_dataService.getCustomerDebts());
    _orders = List.from(_dataService.getOrders());
    _kitchenTickets = List.from(_dataService.getKitchenTickets());
    _expenses = List.from(_dataService.getExpenses());
    _reconciliations = List.from(_dataService.getReconciliations());
    notifyListeners();

    // Initial sync from cloud
    await syncAllFromCloud();

    // Real-time auto sync polling every 5 seconds
    _cloudPollingTimer?.cancel();
    _cloudPollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      syncAllFromCloud();
    });
  }

  final Set<String> _deletedOrAcceptedTicketIds = {};

  Future<void> syncAllFromCloud() async {
    final isOnline = await SupabaseService.instance.checkConnection();
    if (isOnline) {
      bool changed = false;

      // 1. Fetch newest kitchen tickets from cloud
      final cloudTickets = await SupabaseService.instance.fetchKitchenTickets();
      if (cloudTickets.isNotEmpty) {
        final existingMap = {for (var t in _kitchenTickets) t.id: t};
        for (final ct in cloudTickets) {
          if (_deletedOrAcceptedTicketIds.contains(ct.id)) {
            continue;
          }
          if (ct.status != 'pending') {
            continue;
          }
          if (!existingMap.containsKey(ct.id)) {
            _kitchenTickets.insert(0, ct);
            _dataService.addKitchenTicket(ct);
            changed = true;
          }
        }
      }

      // 2. Fetch customer debts from cloud
      final cloudDebts = await SupabaseService.instance.fetchDebts();
      if (cloudDebts.isNotEmpty) {
        final existingDebtIds = {for (var d in _debts) d.id};
        for (final cd in cloudDebts) {
          if (!existingDebtIds.contains(cd.id)) {
            _debts.insert(0, cd);
            changed = true;
          }
        }
      }

      // 3. Silently refresh catalog if changed
      final catalogUpdated = await _dataService.syncCatalogFromCloud();
      if (catalogUpdated) {
        _products = List.from(_dataService.getProducts());
        changed = true;
      }

      if (changed) {
        notifyListeners();
      }
    }
  }

  Future<void> refreshCatalog() async {
    final updated = await _dataService.syncCatalogFromCloud();
    if (updated) {
      _products = List.from(_dataService.getProducts());
      notifyListeners();
    }
  }

  void addKitchenTicket(KitchenTicket ticket) {
    _deletedOrAcceptedTicketIds.remove(ticket.id);
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
    final activeSession = chosenShift == ShiftType.night
        ? _nightShiftSession
        : _dayShiftSession;
    if (activeSession != null && activeSession.status == 'active') {
      _mode = AppMode.pos;
    } else {
      _mode = AppMode.cups;
    }
    notifyListeners();
  }

  void startShiftSession(int openingCups) {
    if (_shiftType == null) return;
    final newSession = ShiftSession(
      id: 'shift-${DateTime.now().millisecondsSinceEpoch}',
      shiftType: _shiftType!,
      cashierName: 'ሳራ መኮንን (Sara M.)',
      openingCups: openingCups,
      status: 'active',
      startedAt: DateTime.now(),
    );
    if (_shiftType == ShiftType.day) {
      _dayShiftSession = newSession;
    } else {
      _nightShiftSession = newSession;
    }
    _currentCart = [];
    _mode = AppMode.pos;
    notifyListeners();
  }

  void addToCart(Product product, {int quantity = 1, String? notes}) {
    final itemName = product.amharicName.isNotEmpty
        ? product.amharicName
        : product.name;
    final idx = _currentCart.indexWhere((item) => item.productId == product.id);
    if (idx >= 0) {
      final existing = _currentCart[idx];
      _currentCart[idx] = OrderItem(
        productId: existing.productId,
        name: itemName,
        price: existing.price,
        quantity: existing.quantity + quantity,
      );
    } else {
      _currentCart.add(
        OrderItem(
          productId: product.id,
          name: itemName,
          price: product.price,
          quantity: quantity,
        ),
      );
    }
    if (notes != null && notes.isNotEmpty) {
      _orderNotes = _orderNotes.isEmpty ? notes : '$_orderNotes, $notes';
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
    final currentSession = shiftSession;
    if (_currentCart.isEmpty || currentSession == null) return false;

    final order = Order(
      id: 'ord-${_uuid.v4().substring(0, 6)}',
      items: List.from(_currentCart),
      total: cartTotal,
      paymentMethod: _selectedPaymentMethod,
      notes: _orderNotes,
      createdAt: DateTime.now(),
      shiftType: currentSession.shiftType,
      status: 'pending',
    );

    _orders.insert(0, order);
    _dataService.addOrder(order);

    if (_selectedPaymentMethod == 'Credit') {
      final juiceCount = _currentCart
          .where(isJuiceItem)
          .fold(0, (sum, i) => sum + i.quantity);
      final debt = CustomerDebt(
        id: 'deb-${_uuid.v4().substring(0, 6)}',
        customerName: _orderNotes.isNotEmpty
            ? _orderNotes
            : 'የአዳሪ ደንበኛ (Adari Customer)',
        note: 'የትዕዛዝ #${order.id.substring(order.id.length - 4)} አዳሪ',
        cupCount: juiceCount > 0
            ? juiceCount
            : _currentCart.fold(0, (sum, i) => sum + i.quantity),
        pricePerCup: 170.0,
        amount: cartTotal,
        isRecovered: false,
        shiftIdCreated: currentSession.id,
        createdAt: DateTime.now(),
      );
      _debts.insert(0, debt);
      _dataService.addDebts([debt]);
    }

    final remaining = (currentSession.openingCups - shiftJuiceCupsSold).clamp(
      0,
      99999,
    );
    _dataService.setLastLeftoverCups(remaining);
    _currentCart.clear();
    _orderNotes = '';
    notifyListeners();
    return true;
  }

  void confirmPayLaterResolutions(
    List<Order> updatedList,
    List<CustomerDebt> newDebts,
  ) {
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

  void markKitchenTicketAccepted(String ticketId) {
    _deletedOrAcceptedTicketIds.add(ticketId);
    final idx = _kitchenTickets.indexWhere((t) => t.id == ticketId);
    if (idx >= 0) {
      _kitchenTickets[idx] = _kitchenTickets[idx].copyWith(status: 'accepted');
      _dataService.updateKitchenTicketStatus(ticketId, 'accepted');
      notifyListeners();
    }
  }

  void importKitchenTicketToOrder(
    KitchenTicket ticket, {
    String paymentMethod = 'Cash',
  }) {
    final order = Order(
      id: 'ord-${_uuid.v4().substring(0, 6)}',
      items: List.from(ticket.items),
      total: ticket.items.fold(0.0, (sum, i) => sum + (i.price * i.quantity)),
      paymentMethod: paymentMethod,
      notes: 'ከኩሽና የተላከ (${ticket.route} • ${ticket.orderType})',
      createdAt: DateTime.now(),
      shiftType: _shiftType ?? ShiftType.day,
      status: 'pending',
    );
    _orders.insert(0, order);
    _dataService.addOrder(order);
    markKitchenTicketAccepted(ticket.id);
    notifyListeners();
  }

  void addItemsToCart(List<OrderItem> items) {
    for (final item in items) {
      final idx = _currentCart.indexWhere(
        (c) => c.productId == item.productId || c.name == item.name,
      );
      if (idx >= 0) {
        final cur = _currentCart[idx];
        _currentCart[idx] = OrderItem(
          productId: cur.productId,
          name: cur.name,
          price: cur.price,
          quantity: cur.quantity + item.quantity,
        );
      } else {
        _currentCart.add(item);
      }
    }
    notifyListeners();
  }

  Future<void> completeReconciliation(ShiftReconciliation recon) async {
    _reconciliations.insert(0, recon);
    await _dataService.setLastLeftoverCups(recon.leftoverCups);

    // Automatically deduct and persist recovered Adari (debts)
    if (recon.totalRecoveredCups > 0) {
      _dataService.recoverDebtCups(recon.totalRecoveredCups);
      _debts = List.from(_dataService.getCustomerDebts());
    }

    // Persist all expenses created during this shift reconciliation
    for (final expense in recon.expenses) {
      _dataService.addExpense(expense);
    }
    _expenses = List.from(_dataService.getExpenses());

    SupabaseService.instance.syncShiftReconciliation(recon);
    if (recon.shiftType == ShiftType.day) {
      _dayShiftSession = null;
    } else {
      _nightShiftSession = null;
    }
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

  void deleteProduct(String productId) {
    _dataService.deleteProduct(productId);
    _products = List.from(_dataService.getProducts());
    notifyListeners();
  }

  void deleteOrder(String orderId) {
    _dataService.deleteOrder(orderId);
    _orders = List.from(_dataService.getOrders());
    notifyListeners();
  }

  void addDebt(CustomerDebt debt) {
    _debts.insert(0, debt);
    _dataService.addDebts([debt]);
    notifyListeners();
  }

  void deleteDebt(String debtId) {
    _dataService.deleteDebt(debtId);
    _debts = List.from(_dataService.getCustomerDebts());
    notifyListeners();
  }

  void toggleDebtRecovered(String debtId) {
    _dataService.toggleDebtRecovered(debtId);
    _debts = List.from(_dataService.getCustomerDebts());
    notifyListeners();
  }

  void deleteKitchenTicket(String ticketId) {
    _deletedOrAcceptedTicketIds.add(ticketId);
    _dataService.deleteKitchenTicket(ticketId);
    _kitchenTickets = List.from(_dataService.getKitchenTickets());
    notifyListeners();
  }

  void clearKitchenTickets() {
    _deletedOrAcceptedTicketIds.addAll(_kitchenTickets.map((t) => t.id));
    _dataService.clearKitchenTickets();
    _kitchenTickets.clear();
    notifyListeners();
  }

  void addExpense(ShiftExpense expense) {
    _expenses.insert(0, expense);
    _dataService.addExpense(expense);
    notifyListeners();
  }

  void deleteExpense(String expenseId) {
    _dataService.deleteExpense(expenseId);
    _expenses = List.from(_dataService.getExpenses());
    notifyListeners();
  }

  void updateMasterLeftoverCups(int cups) {
    _dataService.setLastLeftoverCups(cups);
    notifyListeners();
  }

  int get masterLeftoverCups => _dataService.getLastLeftoverCups();

  void resetToDefaultData() {
    _dataService.resetToDefaultData();
    _products = List.from(_dataService.getProducts());
    _debts = List.from(_dataService.getCustomerDebts());
    _orders = [];
    _kitchenTickets = [];
    _expenses = [];
    _reconciliations = [];
    _currentCart = [];
    _orderNotes = '';
    notifyListeners();
  }

  void updateOrderStatus(String orderId, String newStatus) {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx >= 0) {
      _orders[idx] = _orders[idx].copyWith(status: newStatus);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _cloudPollingTimer?.cancel();
    super.dispose();
  }
}
