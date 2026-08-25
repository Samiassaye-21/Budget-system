import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../providers/pos_provider.dart';
import '../services/supabase_service.dart';
import '../services/update_service.dart';
import '../theme/app_theme.dart';

class AdminDashboardView extends StatefulWidget {
  const AdminDashboardView({super.key});

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Uuid _uuid = const Uuid();

  // Menu Tab State
  final TextEditingController _menuSearchController = TextEditingController();
  String _selectedMenuCategory = 'All';
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amharicNameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  String _productCategory = 'Juice';
  bool _showAddForm = false;

  // Analytics Tab State
  String _analyticsShiftFilter = 'All'; // 'All' | 'Day' | 'Night'
  String _analyticsDateFilter = 'Today'; // 'Today' | 'Week' | 'Month' | 'Year' | 'All'

  // Debts Tab State
  final TextEditingController _debtSearchController = TextEditingController();
  String _debtStatusFilter = 'All'; // 'All' | 'Unpaid' | 'Recovered'
  String _debtDateFilter = 'All'; // 'Today' | 'Week' | 'Month' | 'Year' | 'All'

  // Kitchen Tab State
  String _kitchenRouteFilter = 'All'; // 'All' | 'Day shift' | 'Night shift' | 'BeU delivery'
  String _kitchenDateFilter = 'Today'; // 'Today' | 'Week' | 'Month' | 'Year' | 'All'

  // Shift History Tab State
  String _shiftHistoryDateFilter = 'All'; // 'Today' | 'Week' | 'Month' | 'Year' | 'All'

  // Expenses Tab State
  String _expenseCategoryFilter = 'All';
  String _expenseDateFilter = 'Today'; // 'Today' | 'Week' | 'Month' | 'Year' | 'All'

  // In-App Update State
  bool _isCheckingUpdate = false;
  AppUpdateInfo? _updateInfo;
  bool _isDownloadingUpdate = false;
  int _downloadProgress = 0;
  String _updateStatusMessage = '';

  // Cloud Sync State
  bool _isSyncingCloud = false;
  bool? _isSupabaseOnline;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _checkCloudStatus();
  }

  Future<void> _checkCloudStatus() async {
    final status = await SupabaseService.instance.checkConnection();
    if (mounted) {
      setState(() => _isSupabaseOnline = status);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _menuSearchController.dispose();
    _nameController.dispose();
    _amharicNameController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    _descController.dispose();
    _debtSearchController.dispose();
    super.dispose();
  }

  bool _matchesDateFilter(DateTime dt, String filter) {
    if (filter == 'All') return true;
    final now = DateTime.now();
    final local = dt.toLocal();
    if (filter == 'Today') {
      return local.year == now.year && local.month == now.month && local.day == now.day;
    }
    if (filter == 'Week') {
      final diff = now.difference(local).inDays;
      return diff >= 0 && diff <= 7;
    }
    if (filter == 'Month') {
      return local.year == now.year && local.month == now.month;
    }
    if (filter == 'Year') {
      return local.year == now.year;
    }
    return true;
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
        backgroundColor: AppColors.obsidian,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // -------------------------------------------------------------
  // DIALOG ACTIONS
  // -------------------------------------------------------------
  void _handleAddProduct(POSProvider pos) {
    final name = _nameController.text.trim();
    final amharic = _amharicNameController.text.trim();
    final price = double.tryParse(_priceController.text.trim());
    final img = _imageUrlController.text.trim();
    final desc = _descController.text.trim();

    if (name.isEmpty || price == null || price <= 0) {
      _showSnackBar('እባክዎ ስም እና ትክክለኛ ዋጋ ያስገቡ');
      return;
    }

    final newProduct = Product(
      id: 'prod-${_uuid.v4().substring(0, 6)}',
      name: name,
      amharicName: amharic.isEmpty ? name : amharic,
      category: _productCategory,
      price: price,
      description: desc.isNotEmpty ? desc : (amharic.isNotEmpty ? amharic : name),
      imageUrl: img.isEmpty
          ? (_productCategory == 'Juice'
              ? 'assets/products/special.jpg'
              : 'assets/products/fritsalad.jpg')
          : img,
      isAvailable: true,
    );

    pos.saveProduct(newProduct);

    _nameController.clear();
    _amharicNameController.clear();
    _priceController.clear();
    _imageUrlController.clear();
    _descController.clear();

    setState(() => _showAddForm = false);
    _showSnackBar('አዲስ እቃ በተሳካ ሁኔታ ተጨምሯል');
  }

  void _showEditProductDialog(BuildContext context, Product product, POSProvider pos) {
    final nameCtrl = TextEditingController(text: product.name);
    final amharicCtrl = TextEditingController(text: product.amharicName);
    final priceCtrl = TextEditingController(text: product.price.toStringAsFixed(0));
    final imgCtrl = TextEditingController(text: product.imageUrl);
    final descCtrl = TextEditingController(text: product.description);
    String cat = product.category;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('እቃውን አስተካክል (Edit)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'የእንግሊዘኛ ስም (Name)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: amharicCtrl,
                  decoration: const InputDecoration(labelText: 'የአማርኛ ስም (Amharic)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: priceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'ዋጋ (ETB)', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: cat,
                        decoration: const InputDecoration(labelText: 'ምድብ', border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: 'Juice', child: Text('🍹 ጁስ')),
                          DropdownMenuItem(value: 'Food', child: Text('🥗 ምግብ')),
                        ],
                        onChanged: (v) => setDlgState(() => cat = v ?? 'Juice'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: imgCtrl,
                  decoration: const InputDecoration(labelText: 'የምስል ሊንክ (Image URL)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'መግለጫ (Description)', border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('ሰርዝ', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () {
                final newPrice = double.tryParse(priceCtrl.text.trim());
                if (nameCtrl.text.trim().isEmpty || newPrice == null || newPrice <= 0) return;
                final updated = product.copyWith(
                  name: nameCtrl.text.trim(),
                  amharicName: amharicCtrl.text.trim(),
                  price: newPrice,
                  category: cat,
                  imageUrl: imgCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                );
                pos.saveProduct(updated);
                Navigator.pop(ctx);
                _showSnackBar('እቃው ተሻሽሏል');
              },
              child: const Text('አስቀምጥ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDebtDialog(BuildContext context, POSProvider pos) {
    final nameCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final cupsCtrl = TextEditingController(text: '1');
    final priceCtrl = TextEditingController(text: '170');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) {
          final cups = int.tryParse(cupsCtrl.text.trim()) ?? 0;
          final price = double.tryParse(priceCtrl.text.trim()) ?? 170.0;
          final totalAmt = cups * price;

          return AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('አዲስ አዳሪ መዝግብ (New Debt)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'የደንበኛ ስም (Customer Name)*', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: noteCtrl,
                    decoration: const InputDecoration(labelText: 'ማስታወሻ / ስልክ ቁጥር (Note/Phone)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: cupsCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'የብርጭቆ ብዛት*', border: OutlineInputBorder()),
                          onChanged: (_) => setDlgState(() {}),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: priceCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'የአንዱ ዋጋ (ETB)', border: OutlineInputBorder()),
                          onChanged: (_) => setDlgState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.primaryLight),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('ጠቅላላ ዕዳ:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                        Text('${totalAmt.toStringAsFixed(0)} ETB', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.primaryDark)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('ሰርዝ', style: TextStyle(color: AppColors.textSecondary)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: () {
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty || cups <= 0) return;
                  final debt = CustomerDebt(
                    id: 'deb-${_uuid.v4().substring(0, 6)}',
                    customerName: name,
                    note: noteCtrl.text.trim().isNotEmpty ? noteCtrl.text.trim() : 'የአድሚን ቀጥታ አዳሪ መዝገብ',
                    cupCount: cups,
                    pricePerCup: price,
                    amount: totalAmt,
                    isRecovered: false,
                    shiftIdCreated: 'admin-manual',
                    createdAt: DateTime.now(),
                  );
                  pos.addDebt(debt);
                  Navigator.pop(ctx);
                  _showSnackBar('አዳሪ ተመዝግቧል');
                },
                child: const Text('መዝግብ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddExpenseDialog(BuildContext context, POSProvider pos) {
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String category = 'የኩሽና ግብዓት';

    final categories = [
      'የኩሽና ግብዓት',
      'የፍራፍሬ ግዢ',
      'የሰራተኛ ምግብ',
      'መብራት/ውሃ/ኪራይ',
      'ጥገና እና ዕቃዎች',
      'ሌላ ልዩ ልዩ',
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('አዲስ ወጪ መዝግብ (Expense)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'የወጪ መጠን (Amount ETB)*', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(labelText: 'የወጪ ዓይነት (Category)*', border: OutlineInputBorder()),
                  items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 12)))).toList(),
                  onChanged: (v) => setDlgState(() => category = v ?? category),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'ዝርዝር ማብራሪያ (Description)*', border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('ሰርዝ', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () {
                final amt = double.tryParse(amountCtrl.text.trim());
                final desc = descCtrl.text.trim();
                if (amt == null || amt <= 0 || desc.isEmpty) return;

                final exp = ShiftExpense(
                  id: 'exp-${_uuid.v4().substring(0, 6)}',
                  shiftId: 'admin-manual',
                  category: category,
                  description: desc,
                  amount: amt,
                  loggedAt: DateTime.now(),
                );
                pos.addExpense(exp);
                Navigator.pop(ctx);
                _showSnackBar('ወጪው ተመዝግቧል');
              },
              child: const Text('መዝግብ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePinDialog(BuildContext context, POSProvider pos, String pinType) {
    final pinCtrl = TextEditingController();
    String title = '';
    String current = '';

    if (pinType == 'day') {
      title = 'የቀን ሺፍት PIN (Day Shift)';
      current = pos.dayShiftPin;
    } else if (pinType == 'night') {
      title = 'የማታ ሺፍት PIN (Night Shift)';
      current = pos.nightShiftPin;
    } else {
      title = 'የአድሚን ማስተር PIN (Admin Master)';
      current = pos.adminPin;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('የአሁኑ PIN: $current', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            const SizedBox(height: 12),
            TextField(
              controller: pinCtrl,
              keyboardType: TextInputType.number,
              maxLength: 6,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'አዲስ 4-6 ዲጂት PIN', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ሰርዝ', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              final newPin = pinCtrl.text.trim();
              if (newPin.length < 4) {
                _showSnackBar('PIN ቢያንስ 4 ዲጂት መሆን አለበት');
                return;
              }
              if (pinType == 'day') {
                pos.updatePins(dayPin: newPin);
              } else if (pinType == 'night') {
                pos.updatePins(nightPin: newPin);
              } else {
                pos.updatePins(adminPin: newPin);
              }
              Navigator.pop(ctx);
              _showSnackBar('PIN ተቀይሯል');
            },
            child: const Text('ቀይር', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showOrderDetailsDialog(BuildContext context, Order order, POSProvider pos) {
    final juiceCups = order.items.where(pos.isJuiceItem).fold(0, (sum, i) => sum + i.quantity);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('የትዕዛዝ ደረሰኝ #${order.id.length > 6 ? order.id.substring(order.id.length - 6).toUpperCase() : order.id}', style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                Text('${order.shiftType == ShiftType.day ? "☀ ቀን ሺፍት" : "☾ ማታ ሺፍት"} • ${order.createdAt.toLocal().toString().substring(11, 16)}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryLight),
              ),
              child: Text(order.paymentMethod, style: const TextStyle(color: AppColors.primaryDark, fontSize: 10.5, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Divider(height: 1),
              const SizedBox(height: 8),
              ...order.items.map((it) {
                final isJuice = pos.isJuiceItem(it);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text('${it.quantity}x ${it.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AppColors.textPrimary)),
                          if (isJuice) ...[
                            const SizedBox(width: 4),
                            Text('(${it.quantity} 🥤)', style: const TextStyle(fontSize: 11, color: AppColors.primaryDark, fontWeight: FontWeight.bold)),
                          ],
                        ],
                      ),
                      Text('${(it.price * it.quantity).toStringAsFixed(0)} ETB', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5, color: AppColors.primaryDark)),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 8),
              const Divider(height: 1),
              if (order.notes.isNotEmpty) ...[
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('ማስታወሻ: ${order.notes}', style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ጠቅላላ ሂሳብ:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppColors.textPrimary)),
                      if (juiceCups > 0)
                        Text('$juiceCups የጁስ ብርጭቆዎች 🥤', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                    ],
                  ),
                  Text('${order.total.toStringAsFixed(0)} ETB', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.primaryDark)),
                ],
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              pos.deleteOrder(order.id);
              Navigator.pop(ctx);
              _showSnackBar('ትዕዛዙ ተሰርዟል');
            },
            icon: const Icon(Icons.delete_outline, color: AppColors.textSecondary, size: 20),
            tooltip: 'ትዕዛዙን ሰርዝ',
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ዝጋ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showReconciliationDetailsDialog(BuildContext context, ShiftReconciliation recon) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('የተዘጋ ሺፍት ሪፖርት #${recon.shiftId.length > 6 ? recon.shiftId.substring(recon.shiftId.length - 6) : recon.shiftId}', style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                Text('${recon.shiftType == ShiftType.day ? "☀ ቀን ሺፍት" : "☾ ማታ ሺፍት"} • ካሸር: ${recon.cashierName}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.primaryLight)),
              child: const Text('CLOSED', style: TextStyle(color: AppColors.primaryDark, fontSize: 9.5, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildReportSectionTitle('1. የሽያጭ ዝርዝር (Sales)'),
                _buildReportRow('ጠቅላላ ሽያጭ:', '${recon.grossRevenue.toStringAsFixed(0)} ETB'),
                _buildReportRow('ጥሬ ገንዘብ (Cash):', '${recon.cashSales.toStringAsFixed(0)} ETB'),
                _buildReportRow('ባንክ/ቴሌብር (Transfer):', '${recon.transferSales.toStringAsFixed(0)} ETB'),
                _buildReportRow('አዳሪ (Credit):', '${recon.creditSales.toStringAsFixed(0)} ETB'),
                _buildReportRow('ቡኤ ዴሊቨሪ (Delivery):', '${recon.deliverySales.toStringAsFixed(0)} ETB'),
                _buildReportRow('ጠቅላላ ትዕዛዞች:', '${recon.totalOrdersCount}'),
                const Divider(),

                _buildReportSectionTitle('2. የብርጭቆ ቆጠራ (Cups)'),
                _buildReportRow('መነሻ ብርጭቆ:', '${recon.openingCups}'),
                _buildReportRow('የተጨመረ:', '+${recon.addedCups}'),
                _buildReportRow('ቀሪ ቆጠራ:', '${recon.leftoverCups}'),
                _buildReportRow('የተሸጠ በቆጠራ:', '${recon.calculatedCupsSold} 🥤'),
                _buildReportRow('የተሸጠ በሲስተም:', '${recon.tabletCupsSold} 🥤'),
                _buildReportRow(
                  'የብርጭቆ ልዩነት:',
                  recon.cupsVariance == 0 ? 'ትክክል (0)' : '${recon.cupsVariance > 0 ? "+${recon.cupsVariance}" : recon.cupsVariance}',
                  color: recon.cupsVariance == 0 ? AppColors.primaryDark : AppColors.textPrimary,
                ),
                const Divider(),

                _buildReportSectionTitle('3. ወጪዎች እና አዳሪ ስብስብ'),
                _buildReportRow('የሺፍት ወጪዎች:', '-${recon.totalExpenses.toStringAsFixed(0)} ETB'),
                _buildReportRow('የተሰበሰበ አዳሪ:', '+${recon.totalRecoveredDebts.toStringAsFixed(0)} ETB (${recon.totalRecoveredCups} ብርጭቆ)', color: AppColors.primaryDark),
                const Divider(),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primaryLight),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('ለባለቤቱ የተጣራ ጥሬ ገንዘብ:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AppColors.textPrimary)),
                      Text('${recon.netCashToOwner.toStringAsFixed(0)} ETB', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.primaryDark)),
                    ],
                  ),
                ),
                if (recon.shiftNotes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('ማስታወሻ: ${recon.shiftNotes}', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textSecondary)),
                ],
              ],
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('እሺ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildReportSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 3),
      child: Text(title, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
    );
  }

  Widget _buildReportRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
          Text(value, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: color ?? AppColors.textPrimary)),
        ],
      ),
    );
  }

  Future<void> _checkSystemUpdate() async {
    setState(() {
      _isCheckingUpdate = true;
      _updateStatusMessage = 'አዳዲስ ማሻሻያዎችን በመፈለግ ላይ...';
    });

    final info = await UpdateService.checkForUpdate();

    setState(() {
      _isCheckingUpdate = false;
      _updateInfo = info;
      _updateStatusMessage = info.hasUpdate
          ? 'አዲስ ስሪት ${info.latestVersion} ተገኝቷል!'
          : 'ሲስተምዎ በቅርቡ የተሻሻለው አዲስ ስሪት ላይ ነው (v${info.currentVersion})';
    });
  }

  Future<void> _executeOtaDownload(String apkUrl) async {
    if (apkUrl.isEmpty) {
      _showSnackBar('የማሻሻያ ሊንክ አልተገኘም');
      return;
    }

    setState(() {
      _isDownloadingUpdate = true;
      _downloadProgress = 0;
      _updateStatusMessage = 'የአዲሱን ስሪት ፋይል በማውረድ ላይ...';
    });

    await UpdateService.downloadAndInstallApk(
      apkUrl,
      onProgress: (progress) {
        if (mounted) {
          setState(() {
            _downloadProgress = progress;
            _updateStatusMessage = 'በማውረድ ላይ: $progress%';
          });
        }
      },
      onError: (err) {
        if (mounted) {
          setState(() {
            _isDownloadingUpdate = false;
            _updateStatusMessage = err;
          });
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              backgroundColor: AppColors.surface,
              title: const Text('የማዘመን ስህተት', style: TextStyle(color: AppColors.textPrimary)),
              content: Text(err, style: const TextStyle(color: AppColors.textSecondary)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('እሺ', style: TextStyle(color: AppColors.primary)),
                ),
              ],
            ),
          );
        }
      },
    );

    if (mounted) {
      setState(() => _isDownloadingUpdate = false);
    }
  }

  Future<void> _triggerCloudSync(POSProvider pos) async {
    setState(() => _isSyncingCloud = true);
    await pos.syncAllFromCloud();
    await _checkCloudStatus();
    if (mounted) {
      setState(() => _isSyncingCloud = false);
      _showSnackBar('የክላውድ መረጃ ታድሷል');
    }
  }

  @override
  Widget build(BuildContext context) {
    final pos = context.watch<POSProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        titleSpacing: 12,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.obsidian, size: 18),
          onPressed: () => pos.setMode(AppMode.gate),
          tooltip: 'ወደ በር ተመለስ',
        ),
        title: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 1.5),
              ),
              child: ClipOval(
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Image.asset(
                    'assets/logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(Icons.admin_panel_settings, color: AppColors.primary, size: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ማራኪ አድሚን ዳሽቦርድ',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${DateHelper.todayFormatted()} • ቦሌ ቅርንጫፍ',
                    style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: _isSyncingCloud
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                : const Icon(Icons.sync, color: AppColors.primary, size: 20),
            onPressed: _isSyncingCloud ? null : () => _triggerCloudSync(pos),
            tooltip: 'ክላውድ አድስ',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.slate,
          indicatorColor: AppColors.primary,
          indicatorWeight: 2.5,
          tabAlignment: TabAlignment.start,
          labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
          tabs: const [
            Tab(text: 'ምግብ እና ጁስ'),
            Tab(text: 'የሽያጭ ሪፖርት'),
            Tab(text: 'የአዳሪ መዝገብ'),
            Tab(text: 'የኩሽና ምርት'),
            Tab(text: 'የተዘጉ ሺፍቶች'),
            Tab(text: 'የወጪዎች መዝገብ'),
            Tab(text: 'ሲስተም እና PIN'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMenuTab(pos),
          _buildAnalyticsTab(pos),
          _buildDebtsTab(pos),
          _buildKitchenTab(pos),
          _buildShiftHistoryTab(pos),
          _buildExpensesTab(pos),
          _buildSettingsTab(pos),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 1: MENU CATALOG MANAGEMENT
  // -------------------------------------------------------------
  Widget _buildMenuTab(POSProvider pos) {
    final query = _menuSearchController.text.toLowerCase().trim();
    final filtered = pos.products.where((p) {
      final matchesCat = _selectedMenuCategory == 'All' || p.category == _selectedMenuCategory;
      final matchesQuery = query.isEmpty ||
          p.name.toLowerCase().contains(query) ||
          p.amharicName.toLowerCase().contains(query);
      return matchesCat && matchesQuery;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Add Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('የምርቶች ዝርዝር (${filtered.length})', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
              ElevatedButton.icon(
                onPressed: () => setState(() => _showAddForm = !_showAddForm),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: Icon(_showAddForm ? Icons.close : Icons.add, size: 14, color: Colors.white),
                label: Text(_showAddForm ? 'ዝጋ' : 'አዲስ እቃ', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 11.5)),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Search & Category Dropdown
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    controller: _menuSearchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'በስም ፈልግ...',
                      prefixIcon: const Icon(Icons.search, size: 16, color: AppColors.slate),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildThemeDropdown<String>(
                value: _selectedMenuCategory,
                items: const [
                  DropdownMenuItem(value: 'All', child: Text('ሁሉም ምድቦች')),
                  DropdownMenuItem(value: 'Juice', child: Text('🍹 ጁስ')),
                  DropdownMenuItem(value: 'Food', child: Text('🥗 ምግብ')),
                ],
                onChanged: (v) => setState(() => _selectedMenuCategory = v ?? 'All'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Add Product Form
          if (_showAddForm) ...[
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primaryLight, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('አዲስ እቃ መመዝገቢያ (Add Menu Item)', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(labelText: 'የእንግሊዘኛ ስም*', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _amharicNameController,
                          decoration: const InputDecoration(labelText: 'የአማርኛ ስም*', border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'ዋጋ (ETB)*', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _productCategory,
                          decoration: const InputDecoration(labelText: 'ምድብ', border: OutlineInputBorder()),
                          items: const [
                            DropdownMenuItem(value: 'Juice', child: Text('🍹 ጁስ')),
                            DropdownMenuItem(value: 'Food', child: Text('🥗 ምግብ')),
                          ],
                          onChanged: (val) => setState(() => _productCategory = val ?? 'Juice'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _imageUrlController,
                    decoration: const InputDecoration(labelText: 'የምስል ሊንክ (አማራጭ)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 38,
                    child: ElevatedButton(
                      onPressed: () => _handleAddProduct(pos),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      child: const Text('እቃውን መዝግብ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12.5)),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Products List
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.borderLight),
              itemBuilder: (context, index) {
                final p = filtered[index];
                return ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  leading: _buildProductImage(
                    p.imageUrl,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  title: Text(p.amharicName.isNotEmpty ? p.amharicName : p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                  subtitle: Text('${p.name} • ${p.category}', style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${p.price.toStringAsFixed(0)} ETB', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppColors.primaryDark)),
                      const SizedBox(width: 6),
                      Switch(
                        value: p.isAvailable,
                        activeThumbColor: AppColors.primary,
                        activeTrackColor: AppColors.primaryLight,
                        onChanged: (_) => pos.toggleProductAvailability(p.id),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 17, color: AppColors.slate),
                        onPressed: () => _showEditProductDialog(context, p, pos),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 17, color: AppColors.textSecondary),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: AppColors.surface,
                              title: const Text('እቃውን ሰርዝ', style: TextStyle(color: AppColors.textPrimary)),
                              content: Text('እርግጠኛ ነዎት "${p.amharicName}" ይሰረዝ?', style: const TextStyle(color: AppColors.textSecondary)),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('ተመለስ', style: TextStyle(color: AppColors.textSecondary)),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.obsidian),
                                  onPressed: () {
                                    pos.deleteProduct(p.id);
                                    Navigator.pop(ctx);
                                    _showSnackBar('እቃው ተሰርዟል');
                                  },
                                  child: const Text('ሰርዝ', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          );
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 2: ANALYTICS & ORDERS (DROPDOWN SELECTS)
  // -------------------------------------------------------------
  Widget _buildAnalyticsTab(POSProvider pos) {
    final allOrders = pos.orders;
    final filteredOrders = allOrders.where((o) {
      final matchesShift = _analyticsShiftFilter == 'All' ||
          (_analyticsShiftFilter == 'Day' && o.shiftType == ShiftType.day) ||
          (_analyticsShiftFilter == 'Night' && o.shiftType == ShiftType.night);
      final matchesDate = _matchesDateFilter(o.createdAt, _analyticsDateFilter);
      return matchesShift && matchesDate;
    }).toList();

    final double totalGross = filteredOrders.fold(0.0, (sum, o) => sum + o.total);
    final double cashSales = filteredOrders.where((o) => o.paymentMethod == 'Cash').fold(0.0, (sum, o) => sum + o.total);
    final double transferSales = filteredOrders.where((o) => o.paymentMethod == 'Transfer').fold(0.0, (sum, o) => sum + o.total);
    final double creditSales = filteredOrders.where((o) => o.paymentMethod == 'Credit' || o.paymentMethod == 'Pay later').fold(0.0, (sum, o) => sum + o.total);
    final double deliverySales = filteredOrders.where((o) => o.paymentMethod == 'Delivery').fold(0.0, (sum, o) => sum + o.total);

    final int totalJuiceCups = filteredOrders.fold(0, (sum, o) => sum + o.items.where(pos.isJuiceItem).fold(0, (isum, i) => isum + i.quantity));
    final double avgOrder = filteredOrders.isNotEmpty ? totalGross / filteredOrders.length : 0.0;

    final cards = [
      _buildThemeAnalyticsCard('ጠቅላላ ገቢ', '${totalGross.toStringAsFixed(0)} ETB', '${filteredOrders.length} ትዕዛዞች', Icons.payments_outlined),
      _buildThemeAnalyticsCard('ጥሬ ገንዘብ', '${cashSales.toStringAsFixed(0)} ETB', 'በካሽ የተከፈለ', Icons.account_balance_wallet_outlined),
      _buildThemeAnalyticsCard('ባንክ / ቴሌብር', '${transferSales.toStringAsFixed(0)} ETB', 'በዝውውር የገባ', Icons.smartphone_outlined),
      _buildThemeAnalyticsCard('አዳሪ', '${creditSales.toStringAsFixed(0)} ETB', 'ያልተሰበሰበ', Icons.receipt_long_outlined),
      _buildThemeAnalyticsCard('ቡኤ ዴሊቨሪ', '${deliverySales.toStringAsFixed(0)} ETB', 'የዴሊቨሪ ሽያጭ', Icons.delivery_dining_outlined),
      _buildThemeAnalyticsCard('የተሸጡ ብርጭቆዎች', '$totalJuiceCups 🥤', 'ጠቅላላ ጁስ', Icons.local_drink_outlined),
      _buildThemeAnalyticsCard('ጠቅላላ ትዕዛዞች', '${filteredOrders.length}', 'የተመዘገቡ', Icons.shopping_bag_outlined),
      _buildThemeAnalyticsCard('አማካይ የትዕዛዝ ዋጋ', '${avgOrder.toStringAsFixed(0)} ETB', 'ለአንድ ደንበኛ', Icons.analytics_outlined),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Dropdown Selects
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('የሽያጭ ሪፖርት', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
              Row(
                children: [
                  _buildDateDropdown(
                    value: _analyticsDateFilter,
                    onChanged: (v) => setState(() => _analyticsDateFilter = v ?? 'Today'),
                  ),
                  const SizedBox(width: 6),
                  _buildThemeDropdown<String>(
                    value: _analyticsShiftFilter,
                    items: const [
                      DropdownMenuItem(value: 'All', child: Text('ሁሉም ሺፍት')),
                      DropdownMenuItem(value: 'Day', child: Text('☀ ቀን')),
                      DropdownMenuItem(value: 'Night', child: Text('☾ ማታ')),
                    ],
                    onChanged: (v) => setState(() => _analyticsShiftFilter = v ?? 'All'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Cards Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.55,
            children: cards,
          ),
          const SizedBox(height: 20),

          // Recent Orders Log
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('የቅርብ ጊዜ ትዕዛዞች (${filteredOrders.length})', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
              Row(
                children: [
                  if (totalJuiceCups > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(6)),
                      child: Text('$totalJuiceCups 🥤', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.primaryDark)),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text('${totalGross.toStringAsFixed(0)} ETB', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: AppColors.primaryDark)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (filteredOrders.isEmpty)
            _buildEmptyState('በተመረጠው ቀን ምንም የተመዘገበ ትዕዛዝ የለም', Icons.shopping_bag_outlined)
          else
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredOrders.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.borderLight),
                itemBuilder: (context, index) {
                  final ord = filteredOrders[index];
                  final ordJuiceCups = ord.items.where(pos.isJuiceItem).fold(0, (sum, i) => sum + i.quantity);

                  return ListTile(
                    dense: true,
                    onTap: () => _showOrderDetailsDialog(context, ord, pos),
                    leading: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.receipt_outlined, color: AppColors.primary, size: 18),
                    ),
                    title: Row(
                      children: [
                        Text('#${ord.id.length > 6 ? ord.id.substring(ord.id.length - 6).toUpperCase() : ord.id}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AppColors.textPrimary)),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(10)),
                          child: Text(ord.paymentMethod, style: const TextStyle(color: AppColors.primaryDark, fontSize: 9.5, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      '${ord.items.map((i) => "${i.quantity}x ${i.name}").join(", ")} • ${ord.createdAt.toLocal().toString().substring(11, 16)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${ord.total.toStringAsFixed(0)} ETB',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppColors.primaryDark),
                        ),
                        if (ordJuiceCups > 0)
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.primarySoft,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.primaryLight),
                            ),
                            child: Text(
                              '$ordJuiceCups 🥤 ብርጭቆ',
                              style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: AppColors.primaryDark),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildThemeAnalyticsCard(String title, String value, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(6)),
                child: Icon(icon, size: 14, color: AppColors.primary),
              ),
              Text(subtitle, style: const TextStyle(fontSize: 9.5, color: AppColors.textMuted)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
              Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 3: CUSTOMER DEBTS (DROPDOWN SELECTS)
  // -------------------------------------------------------------
  Widget _buildDebtsTab(POSProvider pos) {
    final query = _debtSearchController.text.toLowerCase().trim();
    final filtered = pos.debts.where((d) {
      final matchesStatus = _debtStatusFilter == 'All' ||
          (_debtStatusFilter == 'Unpaid' && !d.isRecovered) ||
          (_debtStatusFilter == 'Recovered' && d.isRecovered);
      final matchesDate = _matchesDateFilter(d.createdAt, _debtDateFilter);
      final matchesQuery = query.isEmpty ||
          d.customerName.toLowerCase().contains(query) ||
          d.note.toLowerCase().contains(query);
      return matchesStatus && matchesDate && matchesQuery;
    }).toList();

    final unrecovered = filtered.where((d) => !d.isRecovered).toList();
    final totalDebts = unrecovered.fold(0.0, (sum, d) => sum + d.amount);
    final totalCups = unrecovered.fold(0, (sum, d) => sum + d.cupCount);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Add
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('የአዳሪ መዝገብ (${filtered.length})', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
              ElevatedButton.icon(
                onPressed: () => _showAddDebtDialog(context, pos),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.add, size: 14, color: Colors.white),
                label: const Text('አዲስ አዳሪ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 11.5)),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Total Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.obsidianCard,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ያልተሰበሰበ ጠቅላላ አዳሪ', style: TextStyle(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('${totalDebts.toStringAsFixed(0)} ETB', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: Column(
                    children: [
                      const Text('ብርጭቆ', style: TextStyle(color: Colors.white70, fontSize: 9.5)),
                      Text('$totalCups 🥤', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Search & Dropdown Filters
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    controller: _debtSearchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'በደንበኛ ስም ፈልግ...',
                      prefixIcon: const Icon(Icons.search, size: 16, color: AppColors.slate),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              _buildDateDropdown(
                value: _debtDateFilter,
                onChanged: (v) => setState(() => _debtDateFilter = v ?? 'All'),
              ),
              const SizedBox(width: 6),
              _buildThemeDropdown<String>(
                value: _debtStatusFilter,
                items: const [
                  DropdownMenuItem(value: 'All', child: Text('ሁሉንም')),
                  DropdownMenuItem(value: 'Unpaid', child: Text('ያልተሰበሰበ')),
                  DropdownMenuItem(value: 'Recovered', child: Text('የተሰበሰበ')),
                ],
                onChanged: (v) => setState(() => _debtStatusFilter = v ?? 'All'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Debt List
          if (filtered.isEmpty)
            _buildEmptyState('ምንም የተመዘገበ አዳሪ የለም', Icons.receipt_long_outlined)
          else
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.borderLight),
                itemBuilder: (context, index) {
                  final d = filtered[index];
                  return ListTile(
                    dense: true,
                    leading: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: d.isRecovered ? AppColors.primarySoft : AppColors.borderLight,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(d.isRecovered ? Icons.check : Icons.person_outline, color: d.isRecovered ? AppColors.primaryDark : AppColors.textSecondary, size: 18),
                    ),
                    title: Text(d.customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AppColors.textPrimary)),
                    subtitle: Text('${d.cupCount} 🥤 ብርጭቆ (${d.amount.toStringAsFixed(0)} ETB) • ${d.note}', style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${d.amount.toStringAsFixed(0)} ETB',
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: d.isRecovered ? AppColors.textSecondary : AppColors.primaryDark),
                            ),
                            Text('${d.cupCount} 🥤', style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                          ],
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          icon: Icon(d.isRecovered ? Icons.undo : Icons.check_circle_outline, color: d.isRecovered ? AppColors.slate : AppColors.primary, size: 18),
                          onPressed: () => pos.toggleDebtRecovered(d.id),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: d.isRecovered ? 'መልስ' : 'የተሰበሰበ አድርግ',
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppColors.textSecondary, size: 17),
                          onPressed: () => pos.deleteDebt(d.id),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: 'ሰርዝ',
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 4: KITCHEN TICKETS HUB (DROPDOWN SELECTS & REVERSED FOOD TOP)
  // -------------------------------------------------------------
  Widget _buildKitchenTab(POSProvider pos) {
    final tickets = pos.kitchenTickets;
    final dateFilteredTickets = tickets.where((t) => _matchesDateFilter(t.createdAt, _kitchenDateFilter)).toList();

    final dayCount = dateFilteredTickets.where((t) => t.route == 'Day shift').fold(0, (sum, t) => sum + t.totalQuantity);
    final nightCount = dateFilteredTickets.where((t) => t.route == 'Night shift').fold(0, (sum, t) => sum + t.totalQuantity);
    final bueCount = dateFilteredTickets.where((t) => t.route == 'BeU delivery' || t.route == 'Bue delivery' || t.route == 'BeU').fold(0, (sum, t) => sum + t.totalQuantity);

    final filteredTickets = _kitchenRouteFilter == 'All'
        ? dateFilteredTickets
        : dateFilteredTickets.where((t) => t.route == _kitchenRouteFilter).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Dropdowns
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('የኩሽና ምርት (${filteredTickets.length})', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
              Row(
                children: [
                  _buildDateDropdown(
                    value: _kitchenDateFilter,
                    onChanged: (v) => setState(() => _kitchenDateFilter = v ?? 'Today'),
                  ),
                  const SizedBox(width: 6),
                  _buildThemeDropdown<String>(
                    value: _kitchenRouteFilter,
                    items: const [
                      DropdownMenuItem(value: 'All', child: Text('ሁሉም መዳረሻ')),
                      DropdownMenuItem(value: 'Day shift', child: Text('☀ ቀን ሺፍት')),
                      DropdownMenuItem(value: 'Night shift', child: Text('☾ ማታ ሺፍት')),
                      DropdownMenuItem(value: 'BeU delivery', child: Text('🛵 BeU')),
                    ],
                    onChanged: (v) => setState(() => _kitchenRouteFilter = v ?? 'All'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Route Cards
          Row(
            children: [
              Expanded(child: _buildThemeAnalyticsCard('☀ የቀን ሺፍት', '$dayCount', 'ለቀን የወጣ', Icons.wb_sunny_outlined)),
              const SizedBox(width: 8),
              Expanded(child: _buildThemeAnalyticsCard('☾ የማታ ሺፍት', '$nightCount', 'ለማታ የወጣ', Icons.nightlight_outlined)),
              const SizedBox(width: 8),
              Expanded(child: _buildThemeAnalyticsCard('🛵 BeU ዴሊቨሪ', '$bueCount', 'ለ BeU የወጣ', Icons.delivery_dining_outlined)),
            ],
          ),
          const SizedBox(height: 12),

          // Clear All Action Row
          if (tickets.isNotEmpty)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: AppColors.surface,
                      title: const Text('ቲኬቶችን አጽዳ', style: TextStyle(color: AppColors.textPrimary)),
                      content: const Text('ሁሉንም የኩሽና ቲኬቶች ማጽዳት ይፈልጋሉ?', style: TextStyle(color: AppColors.textSecondary)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('ተመለስ', style: TextStyle(color: AppColors.textSecondary)),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.obsidian),
                          onPressed: () {
                            pos.clearKitchenTickets();
                            Navigator.pop(ctx);
                            _showSnackBar('ቲኬቶች ተጠርገዋል');
                          },
                          child: const Text('አጽዳ', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.delete_sweep_outlined, size: 16, color: AppColors.textSecondary),
                label: const Text('ሁሉንም አጽዳ', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ),
          const SizedBox(height: 4),

          // Tickets List (FOOD NAME ON TOP WITH BOLD, TICKET # BELOW)
          if (filteredTickets.isEmpty)
            _buildEmptyState('በተመረጠው ቀን ምንም የተላከ የኩሽና ቲኬት የለም', Icons.soup_kitchen_outlined)
          else
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredTickets.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.borderLight),
                itemBuilder: (context, index) {
                  final t = filteredTickets[index];
                  final itemsText = t.items.map((i) => "${i.quantity}x ${i.name}").join(", ");

                  return ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    leading: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.restaurant_outlined, color: AppColors.primary, size: 18),
                    ),
                    // Food name on TOP in BOLD
                    title: Text(
                      itemsText.isNotEmpty ? itemsText : 'የታዘዘ ምግብ',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5, color: AppColors.textPrimary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Ticket info BELOW
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Text(
                            'ቲኬት #${t.id.replaceAll("k-ticket-", "").toUpperCase()}',
                            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(8)),
                            child: Text(t.route, style: const TextStyle(color: AppColors.primaryDark, fontSize: 9.5, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 6),
                          Text('• ${t.createdAt.toLocal().toString().substring(11, 16)}', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(8)),
                          child: Text('${t.totalQuantity} ምግቦች', style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primaryDark, fontSize: 11.5)),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 17, color: AppColors.textSecondary),
                          onPressed: () => pos.deleteKitchenTicket(t.id),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 5: SHIFT RECONCILIATIONS HISTORY (DROPDOWN SELECTS)
  // -------------------------------------------------------------
  Widget _buildShiftHistoryTab(POSProvider pos) {
    final reconciliations = pos.reconciliations;
    final filtered = reconciliations.where((r) => _matchesDateFilter(r.closedAt, _shiftHistoryDateFilter)).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('የተዘጉ ሺፍቶች (${filtered.length})', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
              _buildDateDropdown(
                value: _shiftHistoryDateFilter,
                onChanged: (v) => setState(() => _shiftHistoryDateFilter = v ?? 'All'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (filtered.isEmpty)
            _buildEmptyState('በተመረጠው ቀን ምንም የተዘጋ ሺፍት የለም', Icons.history_toggle_off_outlined)
          else
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.borderLight),
                itemBuilder: (context, index) {
                  final r = filtered[index];
                  return ListTile(
                    dense: true,
                    onTap: () => _showReconciliationDetailsDialog(context, r),
                    leading: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.verified_outlined, color: AppColors.primary, size: 18),
                    ),
                    title: Row(
                      children: [
                        Text(r.shiftType == ShiftType.day ? '☀ የቀን ሺፍት' : '☾ የማታ ሺፍት', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AppColors.textPrimary)),
                        const SizedBox(width: 6),
                        Text('(${r.cashierName})', style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
                      ],
                    ),
                    subtitle: Text(
                      'ሽያጭ: ${r.grossRevenue.toStringAsFixed(0)} ETB • ጁስ: ${r.calculatedCupsSold} 🥤 • ${r.closedAt.toLocal().toString().substring(0, 16)}',
                      style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${r.netCashToOwner.toStringAsFixed(0)} ETB', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppColors.primaryDark)),
                        const Text('ተጣራ ገንዘብ', style: TextStyle(fontSize: 9, color: AppColors.textMuted)),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 6: OPERATIONAL EXPENSES (DROPDOWN SELECTS)
  // -------------------------------------------------------------
  Widget _buildExpensesTab(POSProvider pos) {
    final expenses = pos.expenses;
    final dateFiltered = expenses.where((e) => _matchesDateFilter(e.loggedAt, _expenseDateFilter)).toList();

    final filtered = _expenseCategoryFilter == 'All'
        ? dateFiltered
        : dateFiltered.where((e) => e.category.contains(_expenseCategoryFilter)).toList();

    final totalExpenses = filtered.fold(0.0, (sum, e) => sum + e.amount);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('የወጪዎች መዝገብ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
              ElevatedButton.icon(
                onPressed: () => _showAddExpenseDialog(context, pos),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.add, size: 14, color: Colors.white),
                label: const Text('አዲስ ወጪ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 11.5)),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Total Expense Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.obsidianCard,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ጠቅላላ የተመዘገቡ ወጪዎች', style: TextStyle(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('${totalExpenses.toStringAsFixed(0)} ETB', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('${filtered.length} ወጪዎች', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Date & Category Dropdowns
          Row(
            children: [
              Expanded(
                child: _buildDateDropdown(
                  value: _expenseDateFilter,
                  onChanged: (v) => setState(() => _expenseDateFilter = v ?? 'Today'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildThemeDropdown<String>(
                  value: _expenseCategoryFilter,
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('ሁሉም ምድቦች')),
                    DropdownMenuItem(value: 'የኩሽና ግብዓት', child: Text('የኩሽና ግብዓት')),
                    DropdownMenuItem(value: 'የፍራፍሬ ግዢ', child: Text('የፍራፍሬ ግዢ')),
                    DropdownMenuItem(value: 'የሰራተኛ ምግብ', child: Text('የሰራተኛ ምግብ')),
                    DropdownMenuItem(value: 'መብራት/ውሃ/ኪራይ', child: Text('መብራት/ውሃ/ኪራይ')),
                    DropdownMenuItem(value: 'ጥገና እና ዕቃዎች', child: Text('ጥገና እና ዕቃዎች')),
                  ],
                  onChanged: (v) => setState(() => _expenseCategoryFilter = v ?? 'All'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (filtered.isEmpty)
            _buildEmptyState('በተመረጠው ቀን ምንም የተመዘገበ ወጪ የለም', Icons.receipt_outlined)
          else
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.borderLight),
                itemBuilder: (context, index) {
                  final exp = filtered[index];
                  return ListTile(
                    dense: true,
                    leading: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.remove_circle_outline, color: AppColors.primary, size: 18),
                    ),
                    title: Text(exp.description, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AppColors.textPrimary)),
                    subtitle: Text('${exp.category} • ${exp.loggedAt.toLocal().toString().substring(0, 16)}', style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('-${exp.amount.toStringAsFixed(0)} ETB', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppColors.textPrimary)),
                        const SizedBox(width: 6),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 17, color: AppColors.textSecondary),
                          onPressed: () => pos.deleteExpense(exp.id),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 7: SETTINGS, PIN & SYSTEM
  // -------------------------------------------------------------
  Widget _buildSettingsTab(POSProvider pos) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. PIN SECURITY CARD
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.lock_person_outlined, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('የደህንነት PIN ኮዶች (PIN Security)', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                        Text('የሺፍት መዝጊያ እና የአድሚን PIN ኮዶች', style: TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                _buildThemePinRow(
                  title: 'የቀን ሺፍት መዝጊያ PIN (Day Shift)',
                  pin: pos.dayShiftPin,
                  icon: Icons.wb_sunny_outlined,
                  onEdit: () => _showChangePinDialog(context, pos, 'day'),
                ),
                const SizedBox(height: 8),

                _buildThemePinRow(
                  title: 'የማታ ሺፍት መዝጊያ PIN (Night Shift)',
                  pin: pos.nightShiftPin,
                  icon: Icons.nightlight_outlined,
                  onEdit: () => _showChangePinDialog(context, pos, 'night'),
                ),
                const SizedBox(height: 8),

                _buildThemePinRow(
                  title: 'የአድሚን ማስተር PIN (Admin Master)',
                  pin: pos.adminPin,
                  icon: Icons.security_outlined,
                  onEdit: () => _showChangePinDialog(context, pos, 'admin'),
                ),
              ],
            ),
          ),

          // 2. MASTER CUP & INVENTORY CARD
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.local_drink_outlined, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('የብርጭቆ ቁጥጥር (Cup Inventory)', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                        Text('የመነሻ ቀሪ ብርጭቆዎችን ሚዛን ማስተካከል', style: TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('የመጨረሻ ቀሪ ብርጭቆ:', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        Text('${pos.masterLeftoverCups} 🥤 ብርጭቆ', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.primaryDark)),
                      ],
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () {
                        final ctrl = TextEditingController(text: pos.masterLeftoverCups.toString());
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: AppColors.surface,
                            title: const Text('ቀሪ ብርጭቆ አስተካክል', style: TextStyle(color: AppColors.textPrimary)),
                            content: TextField(
                              controller: ctrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'የብርጭቆ ብዛት', border: OutlineInputBorder()),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('ሰርዝ', style: TextStyle(color: AppColors.textSecondary)),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                                onPressed: () {
                                  final num = int.tryParse(ctrl.text.trim());
                                  if (num != null && num >= 0) {
                                    pos.updateMasterLeftoverCups(num);
                                    Navigator.pop(ctx);
                                  }
                                },
                                child: const Text('አስቀምጥ', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        );
                      },
                      child: const Text('አስተካክል', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11.5)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 3. CLOUD SYNC & SUPABASE BAAS CARD
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
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
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.cloud_sync_outlined, color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ክላውድ ዳታቤዝ (Supabase)', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                            Text('የእውነተኛ ጊዜ ማመሳሰል', style: TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _isSupabaseOnline == true ? AppColors.primarySoft : AppColors.borderLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _isSupabaseOnline == true ? AppColors.primaryLight : AppColors.border),
                      ),
                      child: Text(
                        _isSupabaseOnline == true ? 'Online' : 'Local Mode',
                        style: TextStyle(color: _isSupabaseOnline == true ? AppColors.primaryDark : AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 38,
                  child: OutlinedButton.icon(
                    onPressed: _isSyncingCloud ? null : () => _triggerCloudSync(pos),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.primary)),
                    icon: _isSyncingCloud
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                        : const Icon(Icons.sync, color: AppColors.primary, size: 16),
                    label: const Text('አሁን አመሳስል (Sync Now)', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),

          // 4. IN-APP OTA UPDATER CARD
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.system_update_alt_outlined, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('የሲስተም ማሻሻያ (OTA Updater)', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                        Text('Maraki POS v${UpdateService.currentAppVersion}', style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (_updateStatusMessage.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(_updateStatusMessage, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                  ),

                if (_isDownloadingUpdate) ...[
                  LinearProgressIndicator(value: _downloadProgress / 100.0, backgroundColor: AppColors.borderLight, color: AppColors.primary),
                  const SizedBox(height: 10),
                ],

                if (_updateInfo?.hasUpdate == true && !_isDownloadingUpdate)
                  SizedBox(
                    width: double.infinity,
                    height: 38,
                    child: ElevatedButton.icon(
                      onPressed: () => _executeOtaDownload(_updateInfo!.apkUrl),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      icon: const Icon(Icons.download, color: Colors.white, size: 16),
                      label: const Text('አሁን አዘምን (Update Now)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  )
                else if (!_isDownloadingUpdate)
                  SizedBox(
                    width: double.infinity,
                    height: 38,
                    child: ElevatedButton.icon(
                      onPressed: _isCheckingUpdate ? null : _checkSystemUpdate,
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      icon: _isCheckingUpdate
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.refresh, color: Colors.white, size: 16),
                      label: Text(_isCheckingUpdate ? 'በመፈተሽ ላይ...' : 'ማሻሻያ ፈትሽ', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
              ],
            ),
          ),

          // 5. FACTORY RESET
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ዳታ አጽዳ (Reset Data)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    Text('ትዕዛዞችንና ታሪክን ያጸዳል', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                  ],
                ),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.obsidian),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: AppColors.surface,
                        title: const Text('ዳታ አጽዳ', style: TextStyle(color: AppColors.textPrimary)),
                        content: const Text('እርግጠኛ ነዎት ሁሉንም ትዕዛዞች እና የሺፍት ታሪክ ማጽዳት ይፈልጋሉ?', style: TextStyle(color: AppColors.textSecondary)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('ተመለስ', style: TextStyle(color: AppColors.textSecondary)),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.obsidian),
                            onPressed: () {
                              pos.resetToDefaultData();
                              Navigator.pop(ctx);
                              _showSnackBar('ሲስተም ጸድቷል');
                            },
                            child: const Text('አዎ አጽዳ', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text('አጽዳ', style: TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // REUSABLE THEME DROPDOWN SELECT COMPONENTS
  // -------------------------------------------------------------
  Widget _buildDateDropdown({
    required String value,
    required ValueChanged<String?> onChanged,
  }) {
    return _buildThemeDropdown<String>(
      value: value,
      items: const [
        DropdownMenuItem(value: 'Today', child: Text('📅 ዛሬ (Today)')),
        DropdownMenuItem(value: 'Week', child: Text('📅 ይህ ሳምንት (Week)')),
        DropdownMenuItem(value: 'Month', child: Text('📅 ይህ ወር (Month)')),
        DropdownMenuItem(value: 'Year', child: Text('📅 ይህ ዓመት (Year)')),
        DropdownMenuItem(value: 'All', child: Text('📅 ሁሉንም (All Time)')),
      ],
      onChanged: onChanged,
    );
  }

  Widget _buildThemeDropdown<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isDense: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.slate),
          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          dropdownColor: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildThemePinRow({
    required String title,
    required String pin,
    required IconData icon,
    required VoidCallback onEdit,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.borderLight)),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(title, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.border)),
            child: const Text('••••', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 2, color: AppColors.textPrimary)),
          ),
          const SizedBox(width: 6),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.primary),
            onPressed: onEdit,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'ቀይር',
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 36, color: AppColors.textMuted),
          const SizedBox(height: 6),
          Text(message, style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
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
          child: const Icon(Icons.restaurant, color: AppColors.primary, size: 18),
        ),
      );
    } else if (imageUrl.startsWith('http')) {
      img = Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => Container(
          width: width,
          height: height,
          color: AppColors.primarySoft,
          child: const Icon(Icons.restaurant, color: AppColors.primary, size: 18),
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
