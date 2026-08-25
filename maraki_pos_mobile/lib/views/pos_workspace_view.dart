import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/pos_provider.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/cloud_sync_dialog.dart';
import 'pay_later_modal.dart';
import 'shift_reconciliation_view.dart';

class POSWorkspaceView extends StatefulWidget {
  const POSWorkspaceView({super.key});

  @override
  State<POSWorkspaceView> createState() => _POSWorkspaceViewState();
}

class _POSWorkspaceViewState extends State<POSWorkspaceView> {
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  bool _showSuccessToast = false;
  Timer? _toastTimer;

  @override
  void dispose() {
    _notesController.dispose();
    _searchController.dispose();
    _toastTimer?.cancel();
    super.dispose();
  }

  void _triggerSuccessToast() {
    _toastTimer?.cancel();
    setState(() => _showSuccessToast = true);
    _toastTimer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _showSuccessToast = false);
    });
  }

  void _handleOpenReconciliation(BuildContext context, POSProvider pos) {
    if (pos.pendingPayLaterOrders.isNotEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => PayLaterModal(
          onAllResolved: () {
            showDialog(
              context: context,
              builder: (ctx) => const ShiftReconciliationView(),
            );
          },
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => const ShiftReconciliationView(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pos = context.watch<POSProvider>();
    final isTablet = MediaQuery.of(context).size.width > 700;

    final double totalShiftRevenue = pos.orders.fold(0.0, (sum, o) => sum + o.total);
    final int openingCups = pos.shiftSession?.openingCups ?? 120;
    final int cupsUsed = pos.shiftJuiceCupsSold;
    final int cupsRemaining = (openingCups - cupsUsed).clamp(0, 99999);

    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFFF7FAFC),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 1,
            titleSpacing: isTablet ? 16 : 8,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Real Brand Logo
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                    border: Border.all(color: Colors.amber.shade300, width: 1.5),
                  ),
                  child: ClipOval(
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Image.asset(
                        'assets/logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(Icons.point_of_sale, size: 16, color: AppColors.primary),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'ማራኪ POS',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.obsidian),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        pos.shiftSession?.shiftType == ShiftType.day ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                        size: 11,
                        color: AppColors.primaryDark,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        pos.shiftSession?.shiftType == ShiftType.day ? 'ቀን' : 'ማታ',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                // Supabase Real-Time Live Status Pill
                ValueListenableBuilder<SupabaseSyncStatus>(
                  valueListenable: SupabaseService.instance.statusNotifier,
                  builder: (_, status, __) {
                    final isOnline = status == SupabaseSyncStatus.online;
                    final isSyncing = status == SupabaseSyncStatus.syncing;
                    return InkWell(
                      onTap: () => CloudSyncDialog.show(context),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: isOnline ? Colors.green.shade50 : Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isOnline ? Colors.green.shade300 : Colors.amber.shade300,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: isOnline ? Colors.green.shade700 : Colors.amber.shade800,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isSyncing ? 'Syncing...' : (isOnline ? 'Online' : 'Offline'),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: isOnline ? Colors.green.shade800 : Colors.amber.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            actions: [
              // Pay Later Alert Badge in Top Bar
              if (pos.pendingPayLaterOrders.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                  child: IconButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => PayLaterModal(
                          onAllResolved: () {},
                        ),
                      );
                    },
                    icon: Badge(
                      label: Text('${pos.pendingPayLaterOrders.length}', style: const TextStyle(fontSize: 9)),
                      child: const Icon(Icons.schedule, size: 20, color: AppColors.primary),
                    ),
                    tooltip: 'Pay Later (${pos.pendingPayLaterOrders.length})',
                  ),
                ),

              // Shift Reconciliation Button
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: isTablet
                    ? ElevatedButton.icon(
                        onPressed: () => _handleOpenReconciliation(context, pos),
                        icon: const Icon(Icons.lock_clock, size: 16, color: Colors.white),
                        label: const Text(
                          'የሺፍት ማጠቃለያ',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      )
                    : IconButton.filled(
                        onPressed: () => _handleOpenReconciliation(context, pos),
                        icon: const Icon(Icons.lock_clock, size: 18, color: Colors.white),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        tooltip: 'የሺፍት ማጠቃለያ',
                      ),
              ),
              IconButton(
                onPressed: () => pos.setMode(AppMode.gate),
                icon: const Icon(Icons.exit_to_app, color: Colors.grey, size: 20),
                tooltip: 'ወደ በር ተመለስ',
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: isTablet
                    ? _buildTabletLayout(context, pos)
                    : _buildMobileLayout(context, pos),
              ),
              _buildBottomStatusBar(pos, cupsUsed, cupsRemaining, totalShiftRevenue, context),
            ],
          ),
        ),

        // Order Success Overlay Toast
        if (_showSuccessToast)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.3),
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.symmetric(horizontal: 32),
                constraints: const BoxConstraints(maxWidth: 320),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 8)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                      child: const Icon(Icons.check, color: Colors.green, size: 36),
                    ),
                    const SizedBox(height: 12),
                    const Text('ትዕዛዝ ተልኳል!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1A202C))),
                    const SizedBox(height: 4),
                    const Text('ሌላ ትዕዛዝ ለመጨመር ዝግጁ ነው።', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTabletLayout(BuildContext context, POSProvider pos) {
    return Row(
      children: [
        // Left Column: Catalog (Categories, Search, Product Grid)
        Expanded(
          flex: 6,
          child: Column(
            children: [
              _buildCategoryTabsAndSearch(pos),
              Expanded(child: _buildProductGrid(pos)),
            ],
          ),
        ),

        // Right Column: Active Cart / Order Sheet
        Container(
          width: 380,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(left: BorderSide(color: Colors.grey.shade200, width: 1.5)),
          ),
          child: _buildCartPanel(context, pos, isSheet: false),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context, POSProvider pos) {
    return Column(
      children: [
        _buildCategoryTabsAndSearch(pos),
        Expanded(child: _buildProductGrid(pos)),
        // Bottom Cart Summary Bar
        if (pos.currentCart.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, -4)),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${pos.cartJuiceCupsCount} እቃዎች', style: const TextStyle(fontSize: 12, color: AppColors.slate)),
                    Text('${pos.cartTotal.toStringAsFixed(0)} ETB', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primary)),
                  ],
                ),
                ElevatedButton(
                  onPressed: () => _showMobileCartSheet(context, pos),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('ትዕዛዝ ጨርስ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCategoryTabsAndSearch(POSProvider pos) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.surface,
      child: Column(
        children: [
          Row(
            children: [
              _buildCategoryPill('🍹 ትኩስ ጁሶች (Fresh Juices)', 'Juice', pos),
              const SizedBox(width: 8),
              _buildCategoryPill('🥗 የምግብ አቅራቦት (Food)', 'Food', pos),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _searchController,
            onChanged: (val) => pos.setSearchQuery(val),
            decoration: InputDecoration(
              hintText: 'ምግብ እና ጁስ ይፈልጉ (Search menu)...',
              prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.slate),
              filled: true,
              fillColor: AppColors.background,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPill(String title, String category, POSProvider pos) {
    final isSelected = pos.selectedCategory == category;
    return Expanded(
      child: InkWell(
        onTap: () => pos.selectCategory(category),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.background,
            border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIncomingKitchenTicketsBanner(BuildContext context, POSProvider pos) {
    final tickets = pos.pendingShiftKitchenTickets;
    final totalPendingItems = tickets.fold(0, (sum, t) => sum + t.totalQuantity);

    if (tickets.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.amber.shade400,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.restaurant_menu_rounded,
              color: Colors.amber.shade900,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      '🍳 ከኩሽና የተላከ አዲስ ትዕዛዝ ($totalPendingItems ምግቦች)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${tickets.length} አዳዲስ የኩሽና ቲኬቶች አሉ። ወደ ሽያጭ ካስገቡ በኋላ በራሳቸው ይጠፋሉ!',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => _showIncomingKitchenTicketsModal(context, pos),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 1,
            ),
            icon: const Icon(Icons.receipt_long, size: 14, color: Colors.white),
            label: const Text(
              'ተቀበልና መዝግብ',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showIncomingKitchenTicketsModal(BuildContext context, POSProvider pos) {
    final tickets = pos.pendingShiftKitchenTickets;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.restaurant_menu, color: AppColors.primary, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'ከኩሽና የተላኩ ትዕዛዞች (Incoming Orders)',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.obsidian),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (tickets.length > 1)
                        ElevatedButton(
                          onPressed: () {
                            for (final t in List.from(tickets)) {
                              pos.importKitchenTicketToOrder(t);
                            }
                            Navigator.of(ctx).pop();
                            _triggerSuccessToast();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('ሁሉም የኩሽና ቲኬቶች ወደ ሽያጭ ገብተዋል!'),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('ሁሉንም አስገባ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      IconButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: const Icon(Icons.close, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Tickets List
            Expanded(
              child: tickets.isEmpty
                  ? const Center(child: Text('ምንም አዲስ ያልተመዘገበ የኩሽና ቲኬት የለም', style: TextStyle(color: Colors.grey)))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: tickets.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final t = tickets[index];
                        final timeStr = '${t.createdAt.hour.toString().padLeft(2, '0')}:${t.createdAt.minute.toString().padLeft(2, '0')}';
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppColors.primarySoft,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '#${t.id.replaceAll("k-ticket-", "").toUpperCase()}',
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.primaryDark),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: t.orderType.contains('የታሸገ') ? const Color(0xFFEFF6FF) : const Color(0xFFF0FDF4),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: t.orderType.contains('የታሸገ') ? const Color(0xFFBFDBFE) : const Color(0xFFBBF7D0),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              t.orderType.contains('የታሸገ') ? Icons.shopping_bag_outlined : Icons.table_restaurant_rounded,
                                              size: 11,
                                              color: t.orderType.contains('የታሸገ') ? const Color(0xFF1D4ED8) : const Color(0xFF15803D),
                                            ),
                                            const SizedBox(width: 3),
                                            Text(
                                              t.orderType,
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w800,
                                                color: t.orderType.contains('የታሸገ') ? const Color(0xFF1D4ED8) : const Color(0xFF15803D),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    'ሰዓት፡ $timeStr',
                                    style: const TextStyle(fontSize: 11, color: AppColors.slate, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ...t.items.map(
                                (item) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '• ${item.quantity}x ${item.name}',
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.obsidian),
                                      ),
                                      Text(
                                        '${(item.price * item.quantity).toStringAsFixed(0)} ETB',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        pos.addItemsToCart(t.items);
                                        pos.markKitchenTicketAccepted(t.id);
                                        Navigator.of(ctx).pop();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('የኩሽና እቃዎች ወደ ካርት ገብተዋል!'),
                                            backgroundColor: AppColors.primary,
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      },
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(color: AppColors.primary),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      icon: const Icon(Icons.add_shopping_cart, size: 14, color: AppColors.primary),
                                      label: const Text('ወደ ካርት ጨምር', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        pos.importKitchenTicketToOrder(t);
                                        Navigator.of(ctx).pop();
                                        _triggerSuccessToast();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('የኩሽና ቲኬት #${t.id.replaceAll("k-ticket-", "").toUpperCase()} ወደ ሽያጭ ተመዝግቧል!'),
                                            backgroundColor: Colors.green.shade700,
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      icon: const Icon(Icons.check, size: 14, color: Colors.white),
                                      label: const Text('ወደ ሽያጭ መዝግብ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProductItemDialog(BuildContext context, Product product, POSProvider pos) {
    int qty = 1;
    String orderType = 'ቤት (Dine-in)';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        _buildProductImage(
                          product.imageUrl,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.amharicName.isNotEmpty ? product.amharicName : product.name,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.obsidian),
                              ),
                              Text(
                                product.name,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${product.price.toStringAsFixed(0)} ETB',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.primary),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close, color: AppColors.slate),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Divider(height: 1),
                    const SizedBox(height: 14),

                    // STEP 1: Quantity
                    const Row(
                      children: [
                        Icon(Icons.format_list_numbered, size: 16, color: AppColors.primary),
                        SizedBox(width: 6),
                        Text(
                          'ደረጃ 1፡ ብዛት ይምረጡ (Quantity)',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.obsidian),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        InkWell(
                          onTap: () {
                            if (qty > 1) {
                              setDialogState(() => qty--);
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Icon(Icons.remove, size: 18, color: AppColors.obsidian),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              '$qty',
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.obsidian),
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () => setDialogState(() => qty++),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.add, size: 18, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [1, 2, 3, 4, 5, 10].map((n) {
                        final isSel = qty == n;
                        return InkWell(
                          onTap: () => setDialogState(() => qty = n),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isSel ? AppColors.primary : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isSel ? AppColors.primary : AppColors.border),
                            ),
                            child: Text(
                              '+$n',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: isSel ? Colors.white : AppColors.obsidian,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // STEP 2: Order Type (ቤት vs የታሸገ / Takeaway)
                    const Row(
                      children: [
                        Icon(Icons.restaurant_rounded, size: 16, color: AppColors.primary),
                        SizedBox(width: 6),
                        Text(
                          'ደረጃ 2፡ የማዘዣ አይነት (Order Type)',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.obsidian),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildOrderTypePill(
                            'ቤት (በቦታው)',
                            'ቤት (Dine-in)',
                            Icons.table_restaurant_rounded,
                            orderType == 'ቤት (Dine-in)',
                            () => setDialogState(() => orderType = 'ቤት (Dine-in)'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildOrderTypePill(
                            'የታሸገ (Takeaway)',
                            'የታሸገ (Takeaway)',
                            Icons.shopping_bag_outlined,
                            orderType == 'የታሸገ (Takeaway)',
                            () => setDialogState(() => orderType = 'የታሸገ (Takeaway)'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Total and Add Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('ጠቅላላ ዋጋ፡', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.slate)),
                        Text(
                          '${(product.price * qty).toStringAsFixed(0)} ETB',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          pos.addToCart(product, quantity: qty, notes: orderType);
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                        icon: const Icon(Icons.shopping_cart, size: 16, color: Colors.white),
                        label: const Text(
                          'ወደ ካርት ጨምር (Add to Cart)',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderTypePill(String shortTitle, String fullTitle, IconData icon, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primarySoft : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? AppColors.primaryDark : AppColors.slate,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                shortTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: isSelected ? AppColors.primaryDark : AppColors.obsidian,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductGrid(POSProvider pos) {
    final filtered = pos.products.where((p) {
      final matchesCat = p.category == pos.selectedCategory;
      final matchesSearch = pos.searchQuery.isEmpty ||
          p.name.toLowerCase().contains(pos.searchQuery.toLowerCase()) ||
          p.amharicName.toLowerCase().contains(pos.searchQuery.toLowerCase());
      return matchesCat && matchesSearch;
    }).toList();

    return Column(
      children: [
        _buildIncomingKitchenTicketsBanner(context, pos),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('ምንም የተገኘ እቃ የለም', style: TextStyle(color: Colors.grey)))
              : GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: MediaQuery.of(context).size.width < 400 ? 180 : 220,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: MediaQuery.of(context).size.width < 380 ? 0.68 : (MediaQuery.of(context).size.width < 600 ? 0.72 : 0.82),
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final product = filtered[index];
                    return _buildProductCard(product, pos);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildProductCard(Product product, POSProvider pos) {
    final inCartQty = pos.currentCart.where((i) => i.productId == product.id).fold(0, (sum, i) => sum + i.quantity);
    final isInCart = inCartQty > 0;

    return InkWell(
      onTap: product.isAvailable ? () => _showProductItemDialog(context, product, pos) : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isInCart ? AppColors.primary : Colors.grey.shade200,
            width: isInCart ? 2 : 1,
          ),
          boxShadow: isInCart
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image / Thumbnail with Availability Overlay & In-Cart Badge
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: _buildProductImage(
                      product.imageUrl,
                      fit: BoxFit.cover,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                    ),
                  ),
                  if (!product.isAvailable)
                    Container(
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'አልቋል (Sold Out)',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  // In-Cart Badge
                  if (isInCart)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.shopping_cart, size: 10, color: Colors.white),
                            const SizedBox(width: 3),
                            Text(
                              '$inCartQty በካርት',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Quick Stock Toggle in top right
                  Positioned(
                    top: 4,
                    right: 4,
                    child: InkWell(
                      onTap: () => pos.toggleProductAvailability(product.id),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: product.isAvailable ? Colors.green.shade600 : Colors.red.shade600,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          product.isAvailable ? 'አለ' : 'የለም',
                          style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    product.amharicName.isNotEmpty ? product.amharicName : product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF1A202C)),
                  ),
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          '${product.price.toStringAsFixed(0)} ETB',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.primary),
                        ),
                      ),
                      InkWell(
                        onTap: product.isAvailable ? () => _showProductItemDialog(context, product, pos) : null,
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isInCart ? AppColors.primary : AppColors.obsidian,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isInCart ? '$inCartQty ጨምር' : 'ምረጥ',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleFireOrder(BuildContext context, POSProvider pos, {bool isSheet = false}) {
    if (pos.currentCart.isEmpty) return;
    final success = pos.fireOrder();
    if (success) {
      _notesController.clear();
      final messenger = ScaffoldMessenger.of(context);
      final nav = Navigator.of(context);

      if (isSheet && nav.canPop()) {
        nav.pop();
      }
      _triggerSuccessToast();
      messenger.showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text('ትዕዛዝ በተሳካ ሁኔታ ተላልፏል! (Order Sent Successfully)')),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildCartPanel(BuildContext context, POSProvider pos, {bool isSheet = false}) {
    return Column(
      children: [
        // Cart Header with Top Submit Action
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.receipt, color: Color(0xFF1A202C), size: 20),
                  const SizedBox(width: 8),
                  const Text('የአሁኑ ትዕዛዝ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                    child: Text('${pos.cartJuiceCupsCount} እቃዎች', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              Row(
                children: [
                  if (pos.currentCart.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        pos.clearCart();
                        _notesController.clear();
                      },
                      child: const Text('አጽዳ', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  // Prominent Top Fire Order Button (for instant tap on phones)
                  if (pos.currentCart.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    ElevatedButton.icon(
                      onPressed: () => _handleFireOrder(context, pos, isSheet: isSheet),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.local_fire_department, color: Colors.white, size: 16),
                      label: const Text(
                        'አስተላልፍ',
                        style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),

        // Cart Items List
        Expanded(
          child: pos.currentCart.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_bag_outlined, size: 48, color: AppColors.border),
                      const SizedBox(height: 8),
                      const Text('ምንም የተመረጠ ማዘዣ የለም', style: TextStyle(color: AppColors.slate, fontSize: 13)),
                      const Text('ከካታሎጉ ላይ የመረጡትን ይጫኑ', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: pos.currentCart.length,
                  separatorBuilder: (_, __) => const Divider(height: 16),
                  itemBuilder: (context, index) {
                    final item = pos.currentCart[index];
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.obsidian)),
                              Text('${(item.price * item.quantity).toStringAsFixed(0)} ETB', style: const TextStyle(fontSize: 11, color: AppColors.slate)),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => pos.updateCartQuantity(item.productId, -1),
                              icon: const Icon(Icons.remove_circle_outline, size: 20),
                              color: AppColors.slate,
                            ),
                            Text('${item.quantity}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.obsidian)),
                            IconButton(
                              onPressed: () => pos.updateCartQuantity(item.productId, 1),
                              icon: const Icon(Icons.add_circle_outline, size: 20),
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
        ),

        // Order Notes & Payment Methods & Bottom Fire Order Button
        SafeArea(
          top: false,
          bottom: true,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            decoration: const BoxDecoration(
              color: AppColors.background,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Order Notes Field
                TextField(
                  controller: _notesController,
                  onChanged: (val) => pos.setOrderNotes(val),
                  decoration: const InputDecoration(
                    hintText: 'ልዩ ማስታወሻ ይጻፉ (Order notes)...',
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide(color: AppColors.border)),
                  ),
                ),
                const SizedBox(height: 8),

                const Text('የክፍያ መንገድ (Payment Method)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.slate)),
                const SizedBox(height: 6),
                _buildFastPaymentGrid(pos),
                const SizedBox(height: 10),

                // Total & Fire Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('ጠቅላላ ክፍያ (Net Total):', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.obsidian)),
                    Text('${pos.cartTotal.toStringAsFixed(0)} ETB', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.primary)),
                  ],
                ),
                const SizedBox(height: 8),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: pos.currentCart.isEmpty
                        ? null
                        : () => _handleFireOrder(context, pos, isSheet: isSheet),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor: AppColors.border,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.local_fire_department, color: Colors.white),
                    label: const Text('ትዕዛዝ አስተላልፍ (Fire Order)', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFastPaymentGrid(POSProvider pos) {
    final methods = [
      {'label': 'ጥሬ ገንዘብ', 'method': 'Cash', 'icon': Icons.payments_outlined},
      {'label': 'ቴሌብር', 'method': 'Telebirr', 'icon': Icons.phone_android_rounded},
      {'label': 'CBE/ባንክ', 'method': 'Transfer', 'icon': Icons.account_balance_outlined},
      {'label': 'በኋላ (Later)', 'method': 'Pay later', 'icon': Icons.hourglass_top_rounded},
      {'label': 'አዳሪ (Adari)', 'method': 'Credit', 'icon': Icons.credit_card_rounded},
      {'label': 'ዴሊቨሪ', 'method': 'Delivery', 'icon': Icons.delivery_dining_rounded},
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 6,
      mainAxisSpacing: 6,
      childAspectRatio: 2.4,
      children: methods.map((m) {
        final label = m['label'] as String;
        final method = m['method'] as String;
        final icon = m['icon'] as IconData;
        final isSelected = pos.selectedPaymentMethod == method;

        return Material(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: () => pos.setPaymentMethod(method),
            borderRadius: BorderRadius.circular(10),
            splashColor: AppColors.primary.withValues(alpha: 0.2),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 13,
                    color: isSelected ? Colors.white : AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomStatusBar(POSProvider pos, int cupsUsed, int cupsRemaining, double revenue, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today, size: 12, color: AppColors.obsidian),
                    const SizedBox(width: 4),
                    Text(
                      '${DateHelper.todayFormatted()} • ⏰ ${pos.shiftSession?.shiftType == ShiftType.day ? DateHelper.dayShiftHours : DateHelper.nightShiftHours}',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.obsidian),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(8)),
                child: Text('$cupsUsed ጥቅም ላይ ውሏል / $cupsRemaining ይቀራል', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
              ),
              const SizedBox(width: 8),
              if (pos.pendingPayLaterOrders.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
                  child: Text('${pos.pendingPayLaterOrders.length} ያልተከፈሉ', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                ),
                const SizedBox(width: 8),
              ],
              InkWell(
                onTap: () => _handleOpenReconciliation(context, pos),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.receipt_long, size: 14, color: AppColors.obsidian),
                      const SizedBox(width: 4),
                      const Text('የሺፍት ገቢ፡ ', style: TextStyle(fontSize: 11, color: AppColors.slate)),
                      Text('${revenue.toStringAsFixed(0)} ETB', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.primary)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMobileCartSheet(BuildContext context, POSProvider pos) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Consumer<POSProvider>(
        builder: (modalCtx, livePos, _) => SizedBox(
          height: MediaQuery.of(modalCtx).size.height * 0.90,
          child: _buildCartPanel(modalCtx, livePos, isSheet: true),
        ),
      ),
    );
  }

  Widget _buildProductImage(
    String imageUrl, {
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
    BorderRadius? borderRadius,
  }) {
    Widget img;
    if (imageUrl.startsWith('assets/')) {
      img = Image.asset(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => Container(
          width: width,
          height: height,
          color: AppColors.primarySoft,
          child: const Icon(Icons.restaurant, color: AppColors.primary),
        ),
      );
    } else if (imageUrl.startsWith('http')) {
      final uri = Uri.tryParse(imageUrl);
      final filename = uri?.pathSegments.isNotEmpty == true ? uri!.pathSegments.last : '';
      if (filename.isNotEmpty) {
        img = Image.asset(
          'assets/products/$filename',
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => Image.network(
            imageUrl,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (_, __, ___) => Container(
              width: width,
              height: height,
              color: AppColors.primarySoft,
              child: const Icon(Icons.restaurant, color: AppColors.primary),
            ),
          ),
        );
      } else {
        img = Image.network(
          imageUrl,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => Container(
            width: width,
            height: height,
            color: AppColors.primarySoft,
            child: const Icon(Icons.restaurant, color: AppColors.primary),
          ),
        );
      }
    } else if (imageUrl.startsWith('/products/')) {
      img = Image.asset(
        'assets$imageUrl',
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => Container(
          width: width,
          height: height,
          color: AppColors.primarySoft,
          child: const Icon(Icons.restaurant, color: AppColors.primary),
        ),
      );
    } else {
      img = Image.asset(
        'assets/logo.png',
        width: width,
        height: height,
        fit: BoxFit.contain,
      );
    }

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius, child: img);
    }
    return img;
  }
}
