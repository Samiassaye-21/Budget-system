import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ota_update/ota_update.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../providers/pos_provider.dart';
import '../services/update_service.dart';

class AdminDashboardView extends StatefulWidget {
  const AdminDashboardView({super.key});

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Uuid _uuid = const Uuid();

  // Add Product Form State
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amharicNameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  String _productCategory = 'Juice';
  bool _showAddForm = false;

  // In-App Update State
  bool _isCheckingUpdate = false;
  AppUpdateInfo? _updateInfo;
  bool _isDownloadingUpdate = false;
  int _downloadProgress = 0;
  String _updateStatusMessage = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _amharicNameController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  void _handleAddProduct(POSProvider pos) {
    final name = _nameController.text.trim();
    final amharic = _amharicNameController.text.trim();
    final price = double.tryParse(_priceController.text.trim());
    final img = _imageUrlController.text.trim();

    if (name.isEmpty || price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('እባክዎ ስም እና ትክክለኛ ዋጋ ያስገቡ'), backgroundColor: Colors.red),
      );
      return;
    }

    final newProduct = Product(
      id: 'prod-${_uuid.v4().substring(0, 6)}',
      name: name,
      amharicName: amharic.isEmpty ? name : amharic,
      category: _productCategory,
      price: price,
      description: name,
      imageUrl: img.isEmpty
          ? (_productCategory == 'Juice'
              ? 'https://images.unsplash.com/photo-1623065422902-30a2d299bbe4?w=500&auto=format&fit=crop&q=60'
              : 'https://images.unsplash.com/photo-1525351484163-7529414344d8?w=500&auto=format&fit=crop&q=60')
          : img,
      isAvailable: true,
    );

    pos.saveProduct(newProduct);

    _nameController.clear();
    _amharicNameController.clear();
    _priceController.clear();
    _imageUrlController.clear();

    setState(() => _showAddForm = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('አዲስ እቃ በተሳካ ሁኔታ ተጨምሯል!'), backgroundColor: Colors.green),
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

  void _executeOtaDownload(String apkUrl) {
    if (apkUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('የማሻሻያ ሊንክ አልተገኘም'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() {
      _isDownloadingUpdate = true;
      _downloadProgress = 0;
      _updateStatusMessage = 'የአዲሱን ስሪት ፋይል በማውረድ ላይ...';
    });

    try {
      UpdateService.executeUpdate(apkUrl).listen(
        (OtaEvent event) {
          setState(() {
            if (event.status == OtaStatus.DOWNLOADING) {
              _downloadProgress = int.tryParse(event.value ?? '0') ?? 0;
              _updateStatusMessage = 'በማውረድ ላይ: $_downloadProgress%';
            } else if (event.status == OtaStatus.INSTALLING) {
              _isDownloadingUpdate = false;
              _updateStatusMessage = 'መጫኛውን በመክፈት ላይ...';
            } else if (event.status == OtaStatus.ALREADY_RUNNING_ERROR) {
              _isDownloadingUpdate = false;
              _updateStatusMessage = 'ማውረዱ አስቀድሞ እየሰራ ነው';
            } else if (event.status == OtaStatus.PERMISSION_NOT_GRANTED_ERROR) {
              _isDownloadingUpdate = false;
              _updateStatusMessage = 'የመጫን ፈቃድ አልተሰጠም (Enable install unknown apps)';
            }
          });
        },
        onError: (err) {
          setState(() {
            _isDownloadingUpdate = false;
            _updateStatusMessage = 'የማውረድ ችግር ተፈጥሯል: $err';
          });
        },
      );
    } catch (e) {
      setState(() {
        _isDownloadingUpdate = false;
        _updateStatusMessage = 'ችግር ተፈጥሯል: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pos = context.watch<POSProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        titleSpacing: 16,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A202C)),
          onPressed: () => pos.setMode(AppMode.gate),
          tooltip: 'ወደ በር ተመለስ',
        ),
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings, color: Color(0xFFC05621)),
            SizedBox(width: 8),
            Text(
              'የአድሚን ዳሽቦርድ እና ሪፖርት (Admin Hub)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1A202C)),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: const Color(0xFFE53E3E),
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: const Color(0xFFE53E3E),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.restaurant_menu, size: 18), text: 'ምግብ እና ጁስ (Menu)'),
            Tab(icon: Icon(Icons.bar_chart, size: 18), text: 'የሽያጭ ሪፖርት (Analytics)'),
            Tab(icon: Icon(Icons.credit_card, size: 18), text: 'የብድር መዝገብ (Debts)'),
            Tab(icon: Icon(Icons.soup_kitchen, size: 18), text: 'የኩሽና ምርት (Kitchen Tickets)'),
            Tab(icon: Icon(Icons.system_update, size: 18), text: 'ሲስተም ማሻሻያ (Updates)'),
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
          _buildUpdatesTab(),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 1: MENU MANAGEMENT
  // -------------------------------------------------------------
  Widget _buildMenuTab(POSProvider pos) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('የምርቶች ዝርዝር (${pos.products.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              ElevatedButton.icon(
                onPressed: () => setState(() => _showAddForm = !_showAddForm),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE53E3E)),
                icon: Icon(_showAddForm ? Icons.close : Icons.add, size: 16, color: Colors.white),
                label: Text(_showAddForm ? 'ቅጹን ዝጋ' : 'አዲስ እቃ ጨምር', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_showAddForm) ...[
            Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber.shade300, width: 1.5),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('አዲስ እቃ መመዝገቢያ (Add Menu Item)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(labelText: 'የእንግሊዘኛ ስም (Name)', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _amharicNameController,
                          decoration: const InputDecoration(labelText: 'የአማርኛ ስም (Amharic Name)', border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'ዋጋ (ETB)', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _productCategory,
                          decoration: const InputDecoration(labelText: 'ምድብ (Category)', border: OutlineInputBorder()),
                          items: const [
                            DropdownMenuItem(value: 'Juice', child: Text('🍹 ትኩስ ጁስ (Juice)')),
                            DropdownMenuItem(value: 'Food', child: Text('🥗 ምግብ (Food)')),
                          ],
                          onChanged: (val) => setState(() => _productCategory = val ?? 'Juice'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _imageUrlController,
                    decoration: const InputDecoration(labelText: 'የምስል ሊንክ (Image URL - Optional)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: () => _handleAddProduct(pos),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700),
                      icon: const Icon(Icons.check, color: Colors.white),
                      label: const Text('እቃውን መዝግብ (Save Product)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ],

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: pos.products.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final p = pos.products[index];
                return ListTile(
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      image: DecorationImage(image: NetworkImage(p.imageUrl), fit: BoxFit.cover),
                    ),
                  ),
                  title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text('${p.amharicName} • ${p.category}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${p.price.toStringAsFixed(0)} ETB', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFFE53E3E))),
                      const SizedBox(width: 12),
                      Switch(
                        value: p.isAvailable,
                        activeColor: Colors.green,
                        onChanged: (_) => pos.toggleProductAvailability(p.id),
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
  // TAB 2: ANALYTICS & REVENUE
  // -------------------------------------------------------------
  Widget _buildAnalyticsTab(POSProvider pos) {
    final orders = pos.orders;
    final double totalGross = orders.fold(0.0, (sum, o) => sum + o.total);
    final double cashSales = orders.where((o) => o.paymentMethod == 'Cash').fold(0.0, (sum, o) => sum + o.total);
    final double transferSales = orders.where((o) => o.paymentMethod == 'Transfer').fold(0.0, (sum, o) => sum + o.total);
    final double creditSales = orders.where((o) => o.paymentMethod == 'Credit' || o.paymentMethod == 'Pay later').fold(0.0, (sum, o) => sum + o.total);
    final double deliverySales = orders.where((o) => o.paymentMethod == 'Delivery').fold(0.0, (sum, o) => sum + o.total);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('የዛሬ የሽያጭ አጠቃላይ ሪፖርት (Sales Analytics)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 16),

          Row(
            children: [
              _buildAnalyticsCard('ጠቅላላ ገቢ (Gross Revenue)', '${totalGross.toStringAsFixed(0)} ETB', '${orders.length} ትዕዛዞች', Colors.blue, Icons.payments),
              const SizedBox(width: 12),
              _buildAnalyticsCard('ጥሬ ገንዘብ (Cash)', '${cashSales.toStringAsFixed(0)} ETB', 'በካሽ የተከፈለ', Colors.green, Icons.wallet),
              const SizedBox(width: 12),
              _buildAnalyticsCard('ባንክ/ቴሌብር (Transfer)', '${transferSales.toStringAsFixed(0)} ETB', 'በሞባይል የገባ', Colors.purple, Icons.smartphone),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildAnalyticsCard('ብድር/በኋላ (Credit & Pay Later)', '${creditSales.toStringAsFixed(0)} ETB', 'ያልተሰበሰበ', Colors.orange, Icons.receipt_long),
              const SizedBox(width: 12),
              _buildAnalyticsCard('ቡኤ ዴሊቨሪ (Delivery)', '${deliverySales.toStringAsFixed(0)} ETB', 'የዴሊቨሪ ሽያጭ', Colors.teal, Icons.delivery_dining),
              const SizedBox(width: 12),
              _buildAnalyticsCard('የተሸጡ ብርጭቆዎች', '${pos.shiftJuiceCupsSold} ብርጭቆ', 'ጠቅላላ ጁስ', Colors.amber, Icons.local_drink),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(String title, String value, String subtitle, MaterialColor color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.shade50, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 20, color: color.shade700),
            ),
            const SizedBox(height: 10),
            Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color.shade900)),
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 3: CUSTOMER DEBTS
  // -------------------------------------------------------------
  Widget _buildDebtsTab(POSProvider pos) {
    final debts = pos.debts;
    final totalDebts = debts.where((d) => !d.isRecovered).fold(0.0, (sum, d) => sum + d.amount);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('ያልተሰበሰቡ የደንበኞች ብድሮች (${debts.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.shade200)),
                child: Text('ጠቅላላ ብድር: ${totalDebts.toStringAsFixed(0)} ETB', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.red.shade900)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (debts.isEmpty)
            const Center(child: Text('ምንም የተመዘገበ ብድር የለም', style: TextStyle(color: Colors.grey)))
          else
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: debts.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final debt = debts[index];
                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: debt.isRecovered ? Colors.green.shade50 : Colors.red.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(debt.isRecovered ? Icons.check : Icons.account_circle, color: debt.isRecovered ? Colors.green : Colors.red),
                    ),
                    title: Text(debt.customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text('${debt.cupCount} ብርጭቆዎች • ${debt.note}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                    trailing: Text(
                      '${debt.amount.toStringAsFixed(0)} ETB',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: debt.isRecovered ? Colors.green : const Color(0xFFE53E3E),
                      ),
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
  // TAB 4: KITCHEN TICKETS AUDIT
  // -------------------------------------------------------------
  Widget _buildKitchenTab(POSProvider pos) {
    final tickets = pos.kitchenTickets;
    final dayCount = tickets.where((t) => t.route == 'Day shift').fold(0, (sum, t) => sum + t.totalQuantity);
    final nightCount = tickets.where((t) => t.route == 'Night shift').fold(0, (sum, t) => sum + t.totalQuantity);
    final bueCount = tickets.where((t) => t.route == 'Bue delivery').fold(0, (sum, t) => sum + t.totalQuantity);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('የኩሽና ምግብ ምርት እና ቲኬቶች (Kitchen Production Hub)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 16),

          Row(
            children: [
              _buildAnalyticsCard('☀ የቀን ሺፍት ምርት', '$dayCount ምግቦች', 'ለቀን ሺፍት የወጣ', Colors.amber, Icons.wb_sunny),
              const SizedBox(width: 12),
              _buildAnalyticsCard('☾ የማታ ሺፍት ምርት', '$nightCount ምግቦች', 'ለማታ ሺፍት የወጣ', Colors.purple, Icons.nightlight),
              const SizedBox(width: 12),
              _buildAnalyticsCard('🚚 ቡኤ ዴሊቨሪ ምርት', '$bueCount ምግቦች', 'ለዴሊቨሪ የተዘጋጀ', Colors.blue, Icons.delivery_dining),
            ],
          ),
          const SizedBox(height: 24),

          Text('የተላኩ ቲኬቶች ታሪክ (${tickets.length})', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),

          if (tickets.isEmpty)
            const Center(child: Text('ምንም የተላከ የኩሽና ቲኬት የለም', style: TextStyle(color: Colors.grey)))
          else
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tickets.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final ticket = tickets[index];
                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.receipt, color: Color(0xFFC05621)),
                    ),
                    title: Text('ቲኬት #${ticket.id.replaceAll('k-ticket-', '').toUpperCase()} • ${ticket.route}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: Text(
                      ticket.items.map((i) => '${i.name} (×${i.quantity})').join(', '),
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                    trailing: Text(
                      '${ticket.totalQuantity} ምግቦች',
                      style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFC05621)),
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
  // TAB 5: IN-APP 1-TAP SYSTEM UPDATER
  // -------------------------------------------------------------
  Widget _buildUpdatesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 580),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.system_update_alt, color: Colors.blue, size: 28),
                  ),
                  const SizedBox(width: 14),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('የሲስተም ማሻሻያ (1-Tap In-App Update)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                      Text('ያለድጋሚ ጭነት በቀጥታ ከታብሌቱ ማዘመን', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('የአሁኑ ስሪት (Current App Version):', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        Text('Maraki POS v${UpdateService.currentAppVersion}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1A202C))),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.green.shade200)),
                      child: const Text('Active Build', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              if (_updateStatusMessage.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: _updateInfo?.hasUpdate == true ? Colors.amber.shade50 : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _updateInfo?.hasUpdate == true ? Colors.amber.shade300 : Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(_updateInfo?.hasUpdate == true ? Icons.new_releases : Icons.info, color: _updateInfo?.hasUpdate == true ? Colors.amber.shade800 : Colors.blue),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _updateStatusMessage,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _updateInfo?.hasUpdate == true ? Colors.amber.shade900 : Colors.blue.shade900),
                        ),
                      ),
                    ],
                  ),
                ),

              if (_isDownloadingUpdate) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('ማውረድ በሂደት ላይ...', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        Text('$_downloadProgress%', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFFE53E3E))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: _downloadProgress / 100.0,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE53E3E)),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ],

              if (_updateInfo?.hasUpdate == true && !_isDownloadingUpdate) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('አዲስ ስሪት ዝግጁ ነው (Version ${_updateInfo!.latestVersion})', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.green.shade900)),
                      const SizedBox(height: 6),
                      Text(_updateInfo!.releaseNotes, style: TextStyle(fontSize: 12, color: Colors.green.shade800)),
                    ],
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () => _executeOtaDownload(_updateInfo!.apkUrl),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    icon: const Icon(Icons.download, color: Colors.white),
                    label: const Text('አሁን አዘምን (1-Tap Update Now)', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
                  ),
                ),
              ] else if (!_isDownloadingUpdate) ...[
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _isCheckingUpdate ? null : _checkSystemUpdate,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE53E3E), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    icon: _isCheckingUpdate
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.refresh, color: Colors.white),
                    label: Text(_isCheckingUpdate ? 'በመፈተሽ ላይ...' : 'አዲስ ማሻሻያ ፈትሽ (Check for Updates)', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
