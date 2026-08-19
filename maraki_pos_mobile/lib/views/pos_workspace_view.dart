import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/pos_provider.dart';
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
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: const Text('🍊', style: TextStyle(fontSize: 14)),
                ),
                const SizedBox(width: 6),
                const Text(
                  'ማራኪ POS',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF1A202C)),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: pos.shiftSession?.shiftType == ShiftType.day ? Colors.amber.shade50 : Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: pos.shiftSession?.shiftType == ShiftType.day ? Colors.amber.shade300 : Colors.purple.shade300,
                    ),
                  ),
                  child: Text(
                    pos.shiftSession?.shiftType == ShiftType.day ? '☀ ቀን' : '☾ ማታ',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: pos.shiftSession?.shiftType == ShiftType.day ? const Color(0xFFC05621) : const Color(0xFF6B46C1),
                    ),
                  ),
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
                      child: const Icon(Icons.schedule, size: 20, color: Color(0xFFC05621)),
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
                          backgroundColor: const Color(0xFFE53E3E),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      )
                    : IconButton.filled(
                        onPressed: () => _handleOpenReconciliation(context, pos),
                        icon: const Icon(Icons.lock_clock, size: 18, color: Colors.white),
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFFE53E3E),
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
                    Text('${pos.cartJuiceCupsCount} እቃዎች', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    Text('${pos.cartTotal.toStringAsFixed(0)} ETB', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFFE53E3E))),
                  ],
                ),
                ElevatedButton(
                  onPressed: () => _showMobileCartSheet(context, pos),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53E3E),
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
      color: Colors.white,
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
              prefixIcon: const Icon(Icons.search, size: 18, color: Colors.grey),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
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
            color: isSelected ? const Color(0xFFE53E3E) : Colors.grey.shade100,
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
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ),
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

    if (filtered.isEmpty) {
      return const Center(child: Text('ምንም የተገኘ እቃ የለም', style: TextStyle(color: Colors.grey)));
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final double childAspect = screenWidth < 380 ? 0.68 : (screenWidth < 600 ? 0.72 : 0.82);
    final double maxExtent = screenWidth < 400 ? 180 : 220;

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: maxExtent,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: childAspect,
      ),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final product = filtered[index];
        return _buildProductCard(product, pos);
      },
    );
  }

  Widget _buildProductCard(Product product, POSProvider pos) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image / Thumbnail with Availability Overlay
          Expanded(
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    color: Colors.grey.shade100,
                    image: DecorationImage(
                      image: NetworkImage(product.imageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                if (!product.isAvailable)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'አልቋል (Sold Out)',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
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
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF1A202C)),
                ),
                Text(
                  product.amharicName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        '${product.price.toStringAsFixed(0)} ETB',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFFE53E3E)),
                      ),
                    ),
                    InkWell(
                      onTap: product.isAvailable ? () => pos.addToCart(product) : null,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: product.isAvailable ? const Color(0xFFE53E3E) : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.add, size: 14, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleFireOrder(BuildContext context, POSProvider pos, {bool isSheet = false}) {
    if (pos.currentCart.isEmpty) return;
    final success = pos.fireOrder();
    if (success) {
      _notesController.clear();
      if (isSheet && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      _triggerSuccessToast();
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
                        backgroundColor: const Color(0xFFE53E3E),
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
                      Icon(Icons.shopping_bag_outlined, size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 8),
                      Text('ምንም የተመረጠ ማዘዣ የለም', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                      const Text('ከካታሎጉ ላይ የመረጡትን ይጫኑ', style: TextStyle(color: Colors.grey, fontSize: 11)),
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
                              Text(item.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              Text('${(item.price * item.quantity).toStringAsFixed(0)} ETB', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => pos.updateCartQuantity(item.productId, -1),
                              icon: const Icon(Icons.remove_circle_outline, size: 20),
                              color: Colors.grey,
                            ),
                            Text('${item.quantity}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
                            IconButton(
                              onPressed: () => pos.updateCartQuantity(item.productId, 1),
                              icon: const Icon(Icons.add_circle_outline, size: 20),
                              color: const Color(0xFFE53E3E),
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
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Order Notes Field
                TextField(
                  controller: _notesController,
                  onChanged: (val) => pos.setOrderNotes(val),
                  decoration: InputDecoration(
                    hintText: 'ልዩ ማስታወሻ ይጻፉ (Order notes)...',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                  ),
                ),
                const SizedBox(height: 8),

                const Text('የክፍያ መንገድ (Payment Method)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildPaymentChip('ጥሬ ገንዘብ', 'Cash', pos),
                    _buildPaymentChip('ባንክ/ቴሌብር', 'Transfer', pos),
                    _buildPaymentChip('በኋላ (Pay later)', 'Pay later', pos),
                    _buildPaymentChip('በብድር', 'Credit', pos),
                    _buildPaymentChip('ዴሊቨሪ', 'Delivery', pos),
                  ],
                ),
                const SizedBox(height: 10),

                // Total & Fire Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('ጠቅላላ ክፍያ (Net Total):', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    Text('${pos.cartTotal.toStringAsFixed(0)} ETB', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFFE53E3E))),
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
                      backgroundColor: const Color(0xFFE53E3E),
                      disabledBackgroundColor: Colors.grey.shade300,
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

  Widget _buildPaymentChip(String label, String method, POSProvider pos) {
    final isSelected = pos.selectedPaymentMethod == method;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black87)),
      selected: isSelected,
      selectedColor: const Color(0xFFE53E3E),
      backgroundColor: Colors.white,
      onSelected: (_) => pos.setPaymentMethod(method),
    );
  }

  Widget _buildBottomStatusBar(POSProvider pos, int cupsUsed, int cupsRemaining, double revenue, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
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
                decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(8)),
                child: Text('$cupsUsed ጥቅም ላይ ውሏል / $cupsRemaining ይቀራል', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber.shade900)),
              ),
              const SizedBox(width: 8),
              if (pos.pendingPayLaterOrders.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(8)),
                  child: Text('${pos.pendingPayLaterOrders.length} ያልተከፈሉ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange.shade900)),
                ),
                const SizedBox(width: 8),
              ],
              InkWell(
                onTap: () => _handleOpenReconciliation(context, pos),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('የዛሬ ሽያጭ: ', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      Text('${revenue.toStringAsFixed(0)} ETB', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFFE53E3E))),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_ios, size: 10, color: Colors.grey),
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
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.90,
        child: _buildCartPanel(context, pos, isSheet: true),
      ),
    );
  }
}
