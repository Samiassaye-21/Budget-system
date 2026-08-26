import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/models.dart';

enum SupabaseSyncStatus {
  online,
  offline,
  syncing,
}

class SupabaseService {
  static final SupabaseService instance = SupabaseService._internal();
  SupabaseService._internal() {
    _startHeartbeat();
  }

  // Supabase Configuration (Live Maraki POS Project)
  static const String defaultSupabaseUrl = 'https://lltyymvshmkpziwforcw.supabase.co';
  static const String defaultAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxsdHl5bXZzaG1rcHppd2ZvcmN3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODcxNDU5NTEsImV4cCI6MjEwMjcyMTk1MX0.xJU5qcG7qbwHAzYJLSYqgcoLh-9rhk2r1Kp0keVyHJ0';

  String _supabaseUrl = defaultSupabaseUrl;
  String _anonKey = defaultAnonKey;
  bool _isConfigured = true;

  SupabaseSyncStatus _status = SupabaseSyncStatus.online;
  final ValueNotifier<SupabaseSyncStatus> statusNotifier =
      ValueNotifier<SupabaseSyncStatus>(SupabaseSyncStatus.online);

  DateTime? _lastSyncTime;
  int _lastLatencyMs = 0;

  DateTime? get lastSyncTime => _lastSyncTime;
  int get lastLatencyMs => _lastLatencyMs;
  String get supabaseUrl => _supabaseUrl;
  String get anonKey => _anonKey;
  bool get isConfigured => _isConfigured;

  final List<Map<String, dynamic>> _pendingSyncQueue = [];
  Timer? _heartbeatTimer;

  bool get isOnline => _status == SupabaseSyncStatus.online;
  int get pendingQueueCount => _pendingSyncQueue.length;

  void configure({required String url, required String anonKey}) {
    _supabaseUrl = url.trim();
    _anonKey = anonKey.trim();
    _isConfigured = url.isNotEmpty && anonKey.isNotEmpty && !url.contains('YOUR_SUPABASE');
    checkConnection();
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      checkConnection();
    });
  }

  Future<bool> checkConnection() async {
    final sw = Stopwatch()..start();
    try {
      final res = await http
          .get(
            Uri.parse('$_supabaseUrl/auth/v1/health'),
            headers: {
              'apikey': _anonKey,
              'Authorization': 'Bearer $_anonKey',
            },
          )
          .timeout(const Duration(seconds: 4));

      sw.stop();
      _lastLatencyMs = sw.elapsedMilliseconds;

      final isAvailable = res.statusCode == 200;
      _updateStatus(isAvailable ? SupabaseSyncStatus.online : SupabaseSyncStatus.offline);

      if (isAvailable) {
        _lastSyncTime = DateTime.now();
        if (_pendingSyncQueue.isNotEmpty) {
          _processPendingQueue();
        }
      }
      return isAvailable;
    } catch (_) {
      sw.stop();
      _lastLatencyMs = 0;
      _updateStatus(SupabaseSyncStatus.offline);
      return false;
    }
  }

  void _updateStatus(SupabaseSyncStatus newStatus) {
    if (_status != newStatus) {
      _status = newStatus;
      statusNotifier.value = newStatus;
    }
  }

  /// Syncs an order immediately or queues it for offline sync
  Future<void> syncOrder(Order order) async {
    final payload = {
      'table': 'orders',
      'action': 'insert',
      'data': {
        'id': order.id,
        'shift_type': order.shiftType.name,
        'payment_method': order.paymentMethod,
        'status': order.status,
        'total': order.total,
        'notes': order.notes,
        'created_at': order.createdAt.toIso8601String(),
        'items': order.items.map((i) => {
          'product_id': i.productId,
          'name': i.name,
          'price': i.price,
          'quantity': i.quantity,
        }).toList(),
      },
    };

    if (!_isConfigured || _status == SupabaseSyncStatus.offline) {
      _pendingSyncQueue.add(payload);
      return;
    }

    try {
      final res = await _postToSupabase('orders', payload['data'] as Map<String, dynamic>);
      if (!res) {
        _pendingSyncQueue.add(payload);
      } else {
        _lastSyncTime = DateTime.now();
      }
    } catch (_) {
      _pendingSyncQueue.add(payload);
      _updateStatus(SupabaseSyncStatus.offline);
    }
  }

  /// Syncs a Kitchen Ticket safely with schema compatibility
  Future<void> syncKitchenTicket(KitchenTicket ticket) async {
    // Note: Supabase kitchen_tickets has columns: id, route, items, total_quantity, status, created_at
    final fullRoute = ticket.orderType.isNotEmpty && !ticket.route.contains(ticket.orderType)
        ? '${ticket.route} • ${ticket.orderType}'
        : ticket.route;

    final payload = {
      'table': 'kitchen_tickets',
      'action': 'insert',
      'data': {
        'id': ticket.id,
        'route': fullRoute,
        'total_quantity': ticket.totalQuantity,
        'status': ticket.status,
        'created_at': ticket.createdAt.toIso8601String(),
        'items': ticket.items.map((i) => {
          'product_id': i.productId,
          'name': i.name,
          'price': i.price,
          'quantity': i.quantity,
        }).toList(),
      },
    };

    if (!_isConfigured || _status == SupabaseSyncStatus.offline) {
      _pendingSyncQueue.add(payload);
      return;
    }

    try {
      final res = await _postToSupabase('kitchen_tickets', payload['data'] as Map<String, dynamic>);
      if (!res) {
        _pendingSyncQueue.add(payload);
      } else {
        _lastSyncTime = DateTime.now();
      }
    } catch (_) {
      _pendingSyncQueue.add(payload);
      _updateStatus(SupabaseSyncStatus.offline);
    }
  }

  /// Fetch kitchen tickets from cloud for real-time kitchen-to-POS synchronization
  Future<List<KitchenTicket>> fetchKitchenTickets() async {
    if (!_isConfigured) return [];
    try {
      final res = await http
          .get(
            Uri.parse('$_supabaseUrl/rest/v1/kitchen_tickets?select=*&order=created_at.desc&limit=50'),
            headers: {
              'apikey': _anonKey,
              'Authorization': 'Bearer $_anonKey',
            },
          )
          .timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        _lastSyncTime = DateTime.now();
        final List<dynamic> list = json.decode(utf8.decode(res.bodyBytes));
        return list.map((item) {
          final map = item as Map<String, dynamic>;
          final fullRoute = (map['route'] as String? ?? 'Day shift');
          String route = fullRoute;
          String orderType = 'ቤት (Dine-in)';
          if (fullRoute.contains('•')) {
            final parts = fullRoute.split('•');
            route = parts[0].trim();
            orderType = parts[1].trim();
          }
          final itemsList = (map['items'] as List? ?? []).map<OrderItem>((x) {
            final xMap = x as Map<String, dynamic>;
            return OrderItem(
              productId: xMap['product_id'] ?? xMap['productId'] ?? '',
              name: xMap['name'] ?? '',
              price: (xMap['price'] as num?)?.toDouble() ?? 0.0,
              quantity: (xMap['quantity'] as num?)?.toInt() ?? 1,
            );
          }).toList();

          final int calculatedQty = itemsList.fold<int>(0, (int s, OrderItem i) => s + i.quantity);
          final int totalQty = (map['total_quantity'] as num?)?.toInt() ?? calculatedQty;

          return KitchenTicket(
            id: map['id'] ?? '',
            route: route,
            orderType: orderType,
            items: itemsList,
            totalQuantity: totalQty,
            createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
            status: map['status'] ?? 'pending',
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('Error fetching kitchen tickets: $e');
    }
    return [];
  }

  /// Updates status of kitchen ticket in cloud (e.g. 'accepted' or 'completed')
  Future<void> updateKitchenTicketStatus(String ticketId, String status) async {
    if (!_isConfigured) return;
    try {
      await http.patch(
        Uri.parse('$_supabaseUrl/rest/v1/kitchen_tickets?id=eq.$ticketId'),
        headers: {
          'apikey': _anonKey,
          'Authorization': 'Bearer $_anonKey',
          'Content-Type': 'application/json',
          'Prefer': 'return=minimal',
        },
        body: json.encode({'status': status}),
      ).timeout(const Duration(seconds: 4));
    } catch (e) {
      debugPrint('Error updating kitchen ticket status in cloud: $e');
    }
  }

  /// Deletes a kitchen ticket from Supabase cloud database
  Future<void> deleteKitchenTicket(String ticketId) async {
    if (!_isConfigured) return;
    try {
      await http.delete(
        Uri.parse('$_supabaseUrl/rest/v1/kitchen_tickets?id=eq.$ticketId'),
        headers: {
          'apikey': _anonKey,
          'Authorization': 'Bearer $_anonKey',
        },
      ).timeout(const Duration(seconds: 4));
    } catch (e) {
      debugPrint('Error deleting kitchen ticket from cloud: $e');
    }
  }

  /// Clears all kitchen tickets from Supabase cloud database
  Future<void> clearAllKitchenTickets() async {
    if (!_isConfigured) return;
    try {
      await http.delete(
        Uri.parse('$_supabaseUrl/rest/v1/kitchen_tickets?id=neq.none'),
        headers: {
          'apikey': _anonKey,
          'Authorization': 'Bearer $_anonKey',
        },
      ).timeout(const Duration(seconds: 4));
    } catch (e) {
      debugPrint('Error clearing kitchen tickets from cloud: $e');
    }
  }

  /// Syncs customer debt
  Future<void> syncDebt(CustomerDebt debt) async {
    final payload = {
      'table': 'customer_debts',
      'action': 'insert',
      'data': {
        'id': debt.id,
        'customer_name': debt.customerName,
        'note': debt.note,
        'cup_count': debt.cupCount,
        'price_per_cup': debt.pricePerCup,
        'amount': debt.amount,
        'is_recovered': debt.isRecovered,
        'shift_id_created': debt.shiftIdCreated,
        'created_at': debt.createdAt.toIso8601String(),
      },
    };

    if (!_isConfigured || _status == SupabaseSyncStatus.offline) {
      _pendingSyncQueue.add(payload);
      return;
    }

    try {
      final res = await _postToSupabase('customer_debts', payload['data'] as Map<String, dynamic>);
      if (!res) {
        _pendingSyncQueue.add(payload);
      } else {
        _lastSyncTime = DateTime.now();
      }
    } catch (_) {
      _pendingSyncQueue.add(payload);
    }
  }

  /// Fetch debts from cloud
  Future<List<CustomerDebt>> fetchDebts() async {
    if (!_isConfigured) return [];
    try {
      final res = await http
          .get(
            Uri.parse('$_supabaseUrl/rest/v1/customer_debts?select=*&order=created_at.desc&limit=50'),
            headers: {
              'apikey': _anonKey,
              'Authorization': 'Bearer $_anonKey',
            },
          )
          .timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        _lastSyncTime = DateTime.now();
        final List<dynamic> list = json.decode(utf8.decode(res.bodyBytes));
        return list.map((item) {
          final map = item as Map<String, dynamic>;
          return CustomerDebt(
            id: map['id'] ?? '',
            customerName: map['customer_name'] ?? '',
            note: map['note'] ?? '',
            cupCount: (map['cup_count'] as num?)?.toInt() ?? 0,
            pricePerCup: (map['price_per_cup'] as num?)?.toDouble() ?? 170.0,
            amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
            isRecovered: map['is_recovered'] ?? false,
            shiftIdCreated: map['shift_id_created'] ?? '',
            createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('Error fetching customer debts: $e');
    }
    return [];
  }

  /// Syncs shift reconciliation
  Future<void> syncShiftReconciliation(ShiftReconciliation reconciliation) async {
    final payload = {
      'table': 'shift_reconciliations',
      'action': 'insert',
      'data': {
        'id': reconciliation.id,
        'shift_id': reconciliation.shiftId,
        'shift_type': reconciliation.shiftType.name,
        'cashier_name': reconciliation.cashierName,
        'gross_revenue': reconciliation.grossRevenue,
        'cash_sales': reconciliation.cashSales,
        'transfer_sales': reconciliation.transferSales,
        'credit_sales': reconciliation.creditSales,
        'delivery_sales': reconciliation.deliverySales,
        'opening_cups': reconciliation.openingCups,
        'added_cups': reconciliation.addedCups,
        'leftover_cups': reconciliation.leftoverCups,
        'calculated_cups_sold': reconciliation.calculatedCupsSold,
        'tablet_cups_sold': reconciliation.tabletCupsSold,
        'cups_variance': reconciliation.cupsVariance,
        'total_kitchen_food_cooked': reconciliation.totalKitchenFoodCooked,
        'total_waiter_food_sold': reconciliation.totalWaiterFoodSold,
        'food_variance': reconciliation.foodVariance,
        'total_expenses': reconciliation.totalExpenses,
        'net_cash_to_owner': reconciliation.netCashToOwner,
        'shift_notes': reconciliation.shiftNotes,
        'closed_at': reconciliation.closedAt.toIso8601String(),
        'created_at': reconciliation.closedAt.toIso8601String(),
      },
    };

    if (!_isConfigured || _status == SupabaseSyncStatus.offline) {
      _pendingSyncQueue.add(payload);
      return;
    }

    try {
      final res = await _postToSupabase('shift_reconciliations', payload['data'] as Map<String, dynamic>);
      if (!res) {
        _pendingSyncQueue.add(payload);
      } else {
        _lastSyncTime = DateTime.now();
      }
    } catch (_) {
      _pendingSyncQueue.add(payload);
    }
  }

  Future<bool> _postToSupabase(String table, Map<String, dynamic> data) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_supabaseUrl/rest/v1/$table'),
            headers: {
              'apikey': _anonKey,
              'Authorization': 'Bearer $_anonKey',
              'Content-Type': 'application/json',
              'Prefer': 'resolution=merge-duplicates',
            },
            body: json.encode(data),
          )
          .timeout(const Duration(seconds: 5));

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('Supabase post error ($table): $e');
      return false;
    }
  }

  Future<bool> processPendingQueue() async {
    return _processPendingQueue();
  }

  Future<bool> _processPendingQueue() async {
    if (_pendingSyncQueue.isEmpty) return true;
    _updateStatus(SupabaseSyncStatus.syncing);

    final queueCopy = List<Map<String, dynamic>>.from(_pendingSyncQueue);
    for (final item in queueCopy) {
      final table = item['table'] as String;
      final data = item['data'] as Map<String, dynamic>;
      final success = await _postToSupabase(table, data);
      if (success) {
        _pendingSyncQueue.remove(item);
      } else {
        break;
      }
    }

    final isAllCleared = _pendingSyncQueue.isEmpty;
    _updateStatus(isAllCleared ? SupabaseSyncStatus.online : SupabaseSyncStatus.offline);
    return isAllCleared;
  }

  void dispose() {
    _heartbeatTimer?.cancel();
  }
}
