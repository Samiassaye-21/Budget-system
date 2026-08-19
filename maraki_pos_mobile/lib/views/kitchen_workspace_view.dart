import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../providers/pos_provider.dart';

class KitchenWorkspaceView extends StatefulWidget {
  const KitchenWorkspaceView({super.key});

  @override
  State<KitchenWorkspaceView> createState() => _KitchenWorkspaceViewState();
}

class _KitchenWorkspaceViewState extends State<KitchenWorkspaceView> {
  String _selectedRoute = 'Day shift'; // 'Day shift' | 'Night shift' | 'Bue delivery'
  String _searchQuery = '';
  final List<OrderItem> _selectedItems = [];
  bool _ticketSent = false;
  String _lastTicketId = '';
  final Uuid _uuid = const Uuid();

  void _handleAddItem(Product product) {
    setState(() {
      final existingIndex = _selectedItems.indexWhere((i) => i.productId == product.id || i.name == product.name);
      if (existingIndex >= 0) {
        final current = _selectedItems[existingIndex];
        _selectedItems[existingIndex] = OrderItem(
          productId: current.productId,
          name: current.name,
          price: current.price,
          quantity: current.quantity + 1,
        );
      } else {
        _selectedItems.add(
          OrderItem(
            productId: product.id,
            name: product.name,
            price: product.price,
            quantity: 1,
          ),
        );
      }
    });
  }

  void _handleChangeQuantity(String name, int delta) {
    setState(() {
      final idx = _selectedItems.indexWhere((i) => i.name == name);
      if (idx >= 0) {
        final newQty = _selectedItems[idx].quantity + delta;
        if (newQty <= 0) {
          _selectedItems.removeAt(idx);
        } else {
          _selectedItems[idx] = OrderItem(
            productId: _selectedItems[idx].productId,
            name: _selectedItems[idx].name,
            price: _selectedItems[idx].price,
            quantity: newQty,
          );
        }
      }
    });
  }

  int get _totalQuantity => _selectedItems.fold(0, (sum, i) => sum + i.quantity);

  void _handleSendTicket(POSProvider pos) {
    if (_selectedItems.isEmpty) return;

    final ticketId = 'k-ticket-${_uuid.v4().substring(0, 6)}';
    final ticket = KitchenTicket(
      id: ticketId,
      route: _selectedRoute,
      items: List.from(_selectedItems),
      totalQuantity: _totalQuantity,
      createdAt: DateTime.now(),
    );

    pos.addKitchenTicket(ticket);

    setState(() {
      _lastTicketId = ticketId.replaceAll('k-ticket-', '').toUpperCase();
      _ticketSent = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pos = context.watch<POSProvider>();

    if (_ticketSent) {
      return _buildSuccessScreen(context, pos);
    }

    final foodProducts = pos.products
        .where((p) =>
            p.category == 'Food' &&
            (p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                p.amharicName.toLowerCase().contains(_searchQuery.toLowerCase())))
        .toList();

    final isTablet = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        titleSpacing: 16,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A202C)),
          onPressed: () => pos.setMode(AppMode.gate),
          tooltip: 'ወደ የስራ ቦታ መረጣ',
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: const Text('🍲', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(width: 8),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ማራኪ POS',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1A202C)),
                ),
                Text(
                  'የኩሽና ማዘዣዎች (KITCHEN TICKETS)',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                const Text('ኩሽና ማሳወቂያ ጣቢያ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
              ],
            ),
          ),
        ],
      ),
      body: isTablet ? _buildTabletContent(context, pos, foodProducts) : _buildMobileContent(context, pos, foodProducts),
    );
  }

  Widget _buildTabletContent(BuildContext context, POSProvider pos, List<Product> foodProducts) {
    return Row(
      children: [
        // Left Column: Route Picker & Food Catalog
        Expanded(
          flex: 6,
          child: Column(
            children: [
              _buildRoutePicker(),
              _buildSearchBar(),
              Expanded(child: _buildFoodGrid(foodProducts)),
            ],
          ),
        ),

        // Right Column: Ticket Builder Panel
        Container(
          width: 380,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(left: BorderSide(color: Colors.grey.shade200, width: 1.5)),
          ),
          child: _buildTicketPanel(context, pos),
        ),
      ],
    );
  }

  Widget _buildMobileContent(BuildContext context, POSProvider pos, List<Product> foodProducts) {
    return Column(
      children: [
        _buildRoutePicker(),
        _buildSearchBar(),
        Expanded(child: _buildFoodGrid(foodProducts)),
        if (_selectedItems.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$_totalQuantity ምግቦች ተመርጠዋል', style: const TextStyle(fontWeight: FontWeight.bold)),
                ElevatedButton(
                  onPressed: () => _showMobileTicketSheet(context, pos),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC05621)),
                  child: const Text('ቲኬት ጨርስ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildRoutePicker() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ተቀባዩ ማን ነው? (Choose Recipient Route)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildRouteButton('Day shift', '☀ የቀን ሺፍት', Icons.wb_sunny_rounded, const Color(0xFFC05621), Colors.amber.shade50),
              const SizedBox(width: 8),
              _buildRouteButton('Night shift', '☾ የማታ ሺፍት', Icons.nightlight_round, const Color(0xFF6B46C1), Colors.purple.shade50),
              const SizedBox(width: 8),
              _buildRouteButton('Bue delivery', '🚚 ቡኤ ዴሊቨሪ', Icons.delivery_dining, const Color(0xFF2B6CB0), Colors.blue.shade50),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRouteButton(String routeKey, String label, IconData icon, Color color, Color activeBg) {
    final isSelected = _selectedRoute == routeKey;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedRoute = routeKey),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? activeBg : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? color : Colors.grey.shade600),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: isSelected ? color : const Color(0xFF2D3748),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: TextField(
        onChanged: (val) => setState(() => _searchQuery = val),
        decoration: InputDecoration(
          hintText: 'የምግብ ዝርዝር ይፈልጉ...',
          prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        ),
      ),
    );
  }

  Widget _buildFoodGrid(List<Product> foodProducts) {
    if (foodProducts.isEmpty) {
      return const Center(child: Text('ምንም የተገኘ ምግብ የለም', style: TextStyle(color: Colors.grey)));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.82,
      ),
      itemCount: foodProducts.length,
      itemBuilder: (context, index) {
        final product = foodProducts[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    color: Colors.grey.shade100,
                    image: DecorationImage(image: NetworkImage(product.imageUrl), fit: BoxFit.cover),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
                    Text('${product.price.toStringAsFixed(0)} ETB', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFC05621))),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      height: 32,
                      child: ElevatedButton.icon(
                        onPressed: () => _handleAddItem(product),
                        icon: const Icon(Icons.add, size: 14, color: Colors.white),
                        label: const Text('ጨምር', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC05621),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTicketPanel(BuildContext context, POSProvider pos) {
    String routeAmharic = _selectedRoute == 'Day shift'
        ? 'የቀን ሺፍት'
        : _selectedRoute == 'Night shift'
            ? 'የማታ ሺፍት'
            : 'ቡኤ ዴሊቨሪ';

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('አዲስ የኩሽና ቲኬት', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                  Text(routeAmharic, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1A202C))),
                ],
              ),
              if (_selectedItems.isNotEmpty)
                TextButton(
                  onPressed: () => setState(() => _selectedItems.clear()),
                  child: const Text('አጽዳ', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ),
        Expanded(
          child: _selectedItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.restaurant_menu, size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 8),
                      const Text('ምንም የተመረጠ ምግብ የለም', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      const Text('ከምግብ ዝርዝሩ ላይ ጨምር የሚለውን ይጫኑ', style: TextStyle(color: Colors.grey, fontSize: 11)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _selectedItems.length,
                  separatorBuilder: (_, __) => const Divider(height: 16),
                  itemBuilder: (context, index) {
                    final item = _selectedItems[index];
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              Text('${item.price.toStringAsFixed(0)} ETB እያንዳንዱ', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => _handleChangeQuantity(item.name, -1),
                              icon: const Icon(Icons.remove_circle_outline, size: 20),
                              color: Colors.grey,
                            ),
                            Text('${item.quantity}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
                            IconButton(
                              onPressed: () => _handleChangeQuantity(item.name, 1),
                              icon: const Icon(Icons.add_circle_outline, size: 20),
                              color: const Color(0xFFC05621),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('ጠቅላላ ብዛት (Total Dishes):', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  Text('$_totalQuantity ምግቦች', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFFC05621))),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _selectedItems.isEmpty ? null : () => _handleSendTicket(pos),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC05621),
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.send_rounded, color: Colors.white),
                  label: const Text('የኩሽና ቲኬት ላክ (Send Ticket)', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showMobileTicketSheet(BuildContext context, POSProvider pos) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: _buildTicketPanel(context, pos),
      ),
    );
  }

  Widget _buildSuccessScreen(BuildContext context, POSProvider pos) {
    String routeAmharic = _selectedRoute == 'Day shift'
        ? 'የቀን ሺፍት'
        : _selectedRoute == 'Night shift'
            ? 'የማታ ሺፍት'
            : 'ቡኤ ዴሊቨሪ';

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          padding: const EdgeInsets.all(32),
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 6)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                child: const Icon(Icons.check_circle, size: 36, color: Colors.green),
              ),
              const SizedBox(height: 16),
              const Text('ቲኬት ተልኳል (TICKET SENT)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 4),
              const Text('የኩሽና ቲኬት ዝግጁ ነው', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1A202C))),
              const SizedBox(height: 8),
              Text(
                'የምግብ ማዘዣ ቲኬትዎ ለ $routeAmharic በተሳካ ሁኔታ ተልኳል።',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Text('KITCHEN #$_lastTicketId', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF7B341E))),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedItems.clear();
                      _ticketSent = false;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC05621),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text('ሌላ የኩሽና ቲኬት ፍጠር', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => pos.setMode(AppMode.gate),
                child: const Text('ወደ የስራ ቦታ መረጣ ተመለስ', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
