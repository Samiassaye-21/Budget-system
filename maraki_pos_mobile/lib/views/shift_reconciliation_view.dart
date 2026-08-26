import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../providers/pos_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/pin_pad_dialog.dart';

class ShiftReconciliationView extends StatefulWidget {
  const ShiftReconciliationView({super.key});

  @override
  State<ShiftReconciliationView> createState() => _ShiftReconciliationViewState();
}

class _ShiftReconciliationViewState extends State<ShiftReconciliationView> {
  int _currentStep = 1;
  final Uuid _uuid = const Uuid();

  // Step 2 Cup Count & Food State
  final TextEditingController _leftoverController = TextEditingController();
  final int _addedCups = 0;
  bool _isFoodApproved = false;

  // Step 3 Expenses State
  final List<ShiftExpense> _expenses = [];
  final TextEditingController _expenseDescController = TextEditingController();
  final TextEditingController _expenseAmountController = TextEditingController();

  // Step 4 Debt Recovery State
  int _recoveredCups = 0;
  final TextEditingController _recoveredCupsController = TextEditingController(text: '0');
  double get _pricePerCup {
    final pos = Provider.of<POSProvider>(context, listen: false);
    final juice = pos.products.where((p) => p.category == 'Juice');
    return juice.isNotEmpty ? juice.first.price : 170.0;
  }

  // Step 5 Notes
  final TextEditingController _shiftNotesController = TextEditingController();

  @override
  void dispose() {
    _leftoverController.dispose();
    _expenseDescController.dispose();
    _expenseAmountController.dispose();
    _recoveredCupsController.dispose();
    _shiftNotesController.dispose();
    super.dispose();
  }

  void _addQuickExpense(String desc, double amount) {
    setState(() {
      _expenses.add(
        ShiftExpense(
          id: 'exp-${_uuid.v4().substring(0, 6)}',
          shiftId: 'shift',
          category: 'Operations',
          description: desc,
          amount: amount,
          loggedAt: DateTime.now(),
        ),
      );
    });
  }

  void _addCustomExpense() {
    final desc = _expenseDescController.text.trim();
    final amt = double.tryParse(_expenseAmountController.text.trim());
    if (desc.isNotEmpty && amt != null && amt > 0) {
      setState(() {
        _expenses.add(
          ShiftExpense(
            id: 'exp-${_uuid.v4().substring(0, 6)}',
            shiftId: 'shift',
            category: 'Operations',
            description: desc,
            amount: amt,
            loggedAt: DateTime.now(),
          ),
        );
        _expenseDescController.clear();
        _expenseAmountController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pos = context.watch<POSProvider>();
    final session = pos.shiftSession;
    final orders = pos.orders;

    if (session == null) {
      return const SizedBox.shrink();
    }

    final double grossRevenue = orders.fold(0.0, (sum, o) => sum + o.total);
    final double cashSales = orders
        .where((o) => o.paymentMethod == 'Cash')
        .fold(0.0, (sum, o) => sum + o.total);
    final double transferSales = orders
        .where((o) => o.paymentMethod == 'Transfer')
        .fold(0.0, (sum, o) => sum + o.total);
    final double creditSales = orders
        .where((o) => o.paymentMethod == 'Credit' || o.paymentMethod == 'Pay later')
        .fold(0.0, (sum, o) => sum + o.total);
    final double deliverySales = orders
        .where((o) => o.paymentMethod == 'Delivery' || o.notes.contains('BeU') || o.notes.contains('Bue'))
        .fold(0.0, (sum, o) => sum + o.total);

    // Order Types breakdown
    final dineInOrders = orders.where((o) => o.notes.contains('ቤት') || (!o.notes.contains('የታሸገ') && !o.notes.contains('BeU') && !o.notes.contains('Bue') && o.paymentMethod != 'Delivery')).toList();
    final takeawayOrders = orders.where((o) => o.notes.contains('የታሸገ')).toList();
    final deliveryOrders = orders.where((o) => o.notes.contains('BeU') || o.notes.contains('Bue') || o.paymentMethod == 'Delivery').toList();

    final double dineInRevenue = dineInOrders.fold(0.0, (sum, o) => sum + o.total);
    final double takeawayRevenue = takeawayOrders.fold(0.0, (sum, o) => sum + o.total);
    final double deliveryRevenue = deliveryOrders.fold(0.0, (sum, o) => sum + o.total);

    // Kitchen tickets breakdown
    final kitchenTickets = pos.shiftKitchenTickets;
    final dineInTicketsCount = kitchenTickets.where((t) => t.orderType.contains('ቤት')).fold(0, (sum, t) => sum + t.totalQuantity);
    final takeawayTicketsCount = kitchenTickets.where((t) => t.orderType.contains('የታሸገ')).fold(0, (sum, t) => sum + t.totalQuantity);
    final beuTicketsCount = kitchenTickets.where((t) => t.route.contains('BeU') || t.route.contains('Bue')).fold(0, (sum, t) => sum + t.totalQuantity);

    final int tabletCupsSold = pos.shiftJuiceCupsSold;
    final int openingCups = session.openingCups;

    final String leftoverText = _leftoverController.text.trim();
    final int? leftoverVal = leftoverText.isEmpty ? null : int.tryParse(leftoverText);
    final int? calculatedCupsSold = leftoverVal != null ? (openingCups + _addedCups) - leftoverVal : null;
    final int? cupsVariance = calculatedCupsSold != null ? calculatedCupsSold - tabletCupsSold : null;
    final int kitchenFoodCooked = pos.kitchenFoodCookedForShift;
    final int waiterFoodSold = pos.shiftFoodSold;
    final int foodVariance = waiterFoodSold - kitchenFoodCooked;
    final bool foodMatch = kitchenFoodCooked == waiterFoodSold;
    final bool foodValid = foodMatch || _isFoodApproved;
    final bool step2Valid = leftoverVal != null && cupsVariance == 0 && foodValid;

    final double totalExpenses = _expenses.fold(0.0, (sum, e) => sum + e.amount);
    final double totalRecoveredDebts = _recoveredCups * _pricePerCup;
    final double netCashToOwner = cashSales + totalRecoveredDebts - totalExpenses;

    final allUnrecoveredDebts = pos.debts.where((d) => !d.isRecovered).toList();
    final previousDebts = allUnrecoveredDebts.where((d) => d.shiftIdCreated != session.id).toList();
    final int previousPendingCups = previousDebts.fold(0, (sum, d) => sum + d.cupCount);
    final todayDebts = allUnrecoveredDebts.where((d) => d.shiftIdCreated == session.id).toList();
    final int todayPendingCups = todayDebts.fold(0, (sum, d) => sum + d.cupCount);
    final int totalPendingPool = previousPendingCups + todayPendingCups;
    final int remainingPendingCups = (totalPendingPool - _recoveredCups).clamp(0, 999999);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 780),
        child: Column(
          children: [
            // Header with Step Indicator
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
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
                                  errorBuilder: (_, _, _) => const Icon(Icons.receipt_long, size: 18, color: AppColors.primary),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                session.shiftType == ShiftType.day ? 'የቀን ሺፍት ማጠቃለያ' : 'የማታ ሺፍት ማጠቃለያ',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1A202C)),
                              ),
                              Text(
                                '${DateHelper.todayFormatted(session.startedAt)} • ⏰ ${DateHelper.shiftOperatingHours(session.shiftType.name)}',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // 5 Progress Steps
                  Row(
                    children: List.generate(5, (index) {
                      final s = index + 1;
                      final isCurrent = s == _currentStep;
                      final isPassed = s < _currentStep;

                      return Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isCurrent
                                    ? AppColors.primary
                                    : (isPassed ? Colors.green : AppColors.border),
                              ),
                              alignment: Alignment.center,
                              child: isPassed
                                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                                  : Text(
                                      '$s',
                                      style: TextStyle(
                                        color: isCurrent ? Colors.white : Colors.grey.shade600,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                            if (s < 5)
                              Expanded(
                                child: Container(
                                  height: 3,
                                  color: isPassed ? Colors.green : Colors.grey.shade200,
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

            // Step Content Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_currentStep == 1) ...[
                      // STEP 1: Sales Summary
                      const Text('ደረጃ 1 ከ 5', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const Text('የሽያጭ ማጠቃለያ (Sales Summary)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 16),

                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A202C),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('ጠቅላላ የሺፍት ገቢ', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                                Text('ጠቅላላ የተመዘገበ ሽያጭ', style: TextStyle(color: Colors.white70, fontSize: 13)),
                              ],
                            ),
                            Text(
                              '${grossRevenue.toStringAsFixed(0)} ETB',
                              style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      _buildSummaryRow('ጥሬ ገንዘብ (Cash Sales)', cashSales, Colors.green),
                      const SizedBox(height: 8),
                      _buildSummaryRow('ባንክ ማስተላለፍ (Transfer Sales)', transferSales, Colors.blue),
                      const SizedBox(height: 8),
                      _buildSummaryRow('ያልተሰበሰበ አዳሪ (Adari)', creditSales, Colors.purple),
                      const SizedBox(height: 8),
                      _buildSummaryRow('ዴሊቨሪ ሽያጭ (Delivery)', deliverySales, Colors.orange),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),

                      // Order Type Breakdown Section
                      const Text(
                        'የማዘዣ አይነት ማጠቃለያ (Order Types Breakdown)',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.obsidian),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _buildOrderTypeSummaryTile(
                              title: 'ቤት (በቦታው)',
                              count: dineInOrders.length,
                              amount: dineInRevenue,
                              icon: Icons.table_restaurant_rounded,
                              color: const Color(0xFF15803D),
                              bgColor: const Color(0xFFF0FDF4),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildOrderTypeSummaryTile(
                              title: 'የታሸገ (Takeaway)',
                              count: takeawayOrders.length,
                              amount: takeawayRevenue,
                              icon: Icons.shopping_bag_outlined,
                              color: const Color(0xFF1D4ED8),
                              bgColor: const Color(0xFFEFF6FF),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildOrderTypeSummaryTile(
                              title: 'BeU ዴሊቨሪ',
                              count: deliveryOrders.length,
                              amount: deliveryRevenue,
                              icon: Icons.delivery_dining_rounded,
                              color: const Color(0xFFB45309),
                              bgColor: const Color(0xFFFFFBEB),
                            ),
                          ),
                        ],
                      ),
                    ] else if (_currentStep == 2) ...[
                      // STEP 2: Cup Count Inventory Verification
                      const Text('ደረጃ 2 ከ 5', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const Text('የብርጭቆ ቆጠራ ማረጋገጫ (Cup Reconciliation)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Text('በሺፍቱ መጨረሻ በአካል የተረፈውን የብርጭቆ ብዛት ያስገቡ።', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      const SizedBox(height: 16),

                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            _buildStatItem('የመጀመሪያ ቆጠራ', '$openingCups ብርጭቆ'),
                            Container(width: 1, height: 36, color: Colors.grey.shade300),
                            _buildStatItem('በታብሌት የተሸጠ', '$tabletCupsSold ብርጭቆ'),
                            Container(width: 1, height: 36, color: Colors.grey.shade300),
                            _buildStatItem('የተጨመረ', '$_addedCups ብርጭቆ'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      const Text('የተረፈ ብርጭቆ ቆጠራ *ግዴታ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _leftoverController,
                        keyboardType: TextInputType.number,
                        autofocus: true,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                        decoration: InputDecoration(
                          hintText: 'የተረፈውን ብርጭቆ ቆጥረው ያስገቡ...',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 16),

                      if (leftoverVal != null) ...[
                        if (cupsVariance == 0)
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.green.shade300),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('✓ ልክ ተጣጥሟል! (0 ልዩነት)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.green.shade900)),
                                      Text('የተሰላ ሽያጭ = ($openingCups + $_addedCups) − $leftoverVal = $calculatedCupsSold ብርጭቆ', style: TextStyle(fontSize: 11, color: Colors.green.shade800)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.red.shade300, width: 1.5),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                                        const SizedBox(width: 8),
                                        Text('የብርጭቆ ልዩነት ተገኝቷል!', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.red.shade900)),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(8)),
                                      child: Text(
                                        cupsVariance! > 0 ? '+$cupsVariance ትርፍ' : '$cupsVariance ጉድለት',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.red.shade900),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text('• በታብሌት የታዘዘው: $tabletCupsSold ብርጭቆ', style: const TextStyle(fontSize: 11, color: Color(0xFF4A5568))),
                                Text('• በተረፈው መሰረት የተሰላው: $calculatedCupsSold ብርጭቆ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red.shade800)),
                                const SizedBox(height: 4),
                                const Text('ልዩነቱ 0 እስኪሆን ድረስ ወደ ሚቀጥለው ደረጃ ማለፍ አይችሉም።', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red)),
                              ],
                            ),
                          ),
                      ],

                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 12),

                      // Part B: Food Cross-Check
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.restaurant_menu, size: 20, color: AppColors.primary),
                              SizedBox(width: 8),
                              Text(
                                'የኩሽና ምግብ ርክክብ (Kitchen Food Cross-Check)',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.obsidian),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
                            child: Text(
                              session.shiftType == ShiftType.day ? 'ቀን ሺፍት' : 'ማታ ሺፍት',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.slate),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primarySoft,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                              ),
                              child: Column(
                                children: [
                                  const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.countertops_outlined, size: 12, color: AppColors.primary),
                                      SizedBox(width: 4),
                                      Text('ኩሽና ያዘጋጀው', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text('$kitchenFoodCooked', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.obsidian)),
                                  const Text('ምግቦች', style: TextStyle(fontSize: 9, color: AppColors.slate)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Column(
                                children: [
                                  const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.point_of_sale, size: 12, color: Color(0xFF2B6CB0)),
                                      SizedBox(width: 4),
                                      Text('ዌተር ያስመዘገበው', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF2B6CB0))),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text('$waiterFoodSold', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF2C5282))),
                                  const Text('የተሸጡ', style: TextStyle(fontSize: 9, color: Colors.grey)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: foodVariance == 0
                                    ? Colors.green.shade50
                                    : foodVariance < 0
                                        ? Colors.red.shade50
                                        : Colors.purple.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: foodVariance == 0
                                      ? Colors.green.shade200
                                      : foodVariance < 0
                                          ? Colors.red.shade200
                                          : Colors.purple.shade200,
                                ),
                              ),
                              child: Column(
                                children: [
                                  const Text('⚖️ ልዩነት', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(
                                    foodVariance > 0 ? '+$foodVariance' : '$foodVariance',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: foodVariance == 0
                                          ? Colors.green.shade800
                                          : foodVariance < 0
                                              ? Colors.red.shade800
                                              : Colors.purple.shade800,
                                    ),
                                  ),
                                  Text(
                                    foodVariance == 0 ? 'ተጣጥሟል' : foodVariance < 0 ? 'ጎድሏል' : 'ትርፍ',
                                    style: const TextStyle(fontSize: 9, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Order Type breakdown pill for cooked food
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Text('🏠 ቤት፡ $dineInTicketsCount ምግቦች', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                            Container(width: 1, height: 14, color: AppColors.primary.withValues(alpha: 0.3)),
                            Text('🛍️ የታሸገ፡ $takeawayTicketsCount ምግቦች', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                            Container(width: 1, height: 14, color: AppColors.primary.withValues(alpha: 0.3)),
                            Text('🛵 BeU፡ $beuTicketsCount ምግቦች', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (!foodValid) ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.red.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      foodVariance < 0
                                          ? 'ያልተመዘገበ የምግብ ክፍተት አለ! ኩሽና ያዘጋጀው $kitchenFoodCooked ሲሆን ዌተር ያስመዘገበው $waiterFoodSold ነው።'
                                          : 'የኩሽና ቲኬት ያልተላከለት ምግብ አለ! ዌተር ያስመዘገበው $waiterFoodSold ሲሆን ኩሽና ያዘጋጀው $kitchenFoodCooked ነው።',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.red.shade900),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                foodVariance < 0
                                    ? '• ከኩሽና የተላኩ ምግቦች: ${pos.shiftKitchenTickets.expand((t) => t.items).map((i) => "${i.quantity}x ${i.name}").join(", ")}'
                                    : '• እባክዎ ኩሽና ትዕዛዙን ወደ ሲስተሙ እንዲልክ ያድርጉ ወይም የተበላሸ ከሆነ በአድሚን PIN (9999) ያጽድቁ።',
                                style: TextStyle(fontSize: 11, color: Colors.red.shade900, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () => Navigator.of(context).pop(),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    icon: const Icon(Icons.point_of_sale, size: 14, color: Colors.white),
                                    label: const Text(
                                      'ወደ POS ተመለስና አስተካክል',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (ctx) => PinPadDialog(
                                          title: 'የአድሚን ልዩነት ማጽደቂያ (Admin PIN)',
                                          subtitle: 'የተበላሸ/የተሰረዘ ምግብ ከሆነ በአድሚን PIN (${pos.adminPin}) ያጽድቁ',
                                          requiredPin: pos.adminPin,
                                          onConfirm: (pin) {
                                            setState(() {
                                              _isFoodApproved = true;
                                            });
                                          },
                                        ),
                                      );
                                    },
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(color: Colors.red.shade400),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    icon: Icon(Icons.lock_open_rounded, size: 14, color: Colors.red.shade800),
                                    label: Text(
                                      'በአድሚን PIN አጽድቅ (9999)',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red.shade900),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ] else if (foodValid && (kitchenFoodCooked > 0 || waiterFoodSold > 0)) ...[
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green.shade700, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                _isFoodApproved ? '✓ የምግብ ልዩነቱ በአድሚን ጸድቋል!' : '✓ የምግብ ቆጠራው ሙሉ በሙሉ ተጣጥሟል ($kitchenFoodCooked ምግቦች)!',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ] else if (_currentStep == 3) ...[
                      // STEP 3: Shift Expenses
                      const Text('ደረጃ 3 ከ 5', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const Text('የዕለቱ የሺፍት ወጪዎች (Shift Expenses)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 16),

                      const Text('ፈጣን መምረጫዎች (Quick Add):', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildQuickExpenseChip('ሎሚ (Lemon)', 150),
                          _buildQuickExpenseChip('በረዶ (Ice)', 200),
                          _buildQuickExpenseChip('ስኳር (Sugar)', 300),
                          _buildQuickExpenseChip('የጽዳት እቃዎች', 100),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: _expenseDescController,
                              decoration: InputDecoration(
                                hintText: 'የወጪው አይነት...',
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _expenseAmountController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: 'ዋጋ (ETB)',
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _addCustomExpense,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('ጨምር', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      if (_expenses.isNotEmpty) ...[
                        const Text('የተመዘገቡ ወጪዎች ዝርዝር:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ...List.generate(_expenses.length, (idx) {
                          final exp = _expenses[idx];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(exp.description, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                Row(
                                  children: [
                                    Text('−${exp.amount.toStringAsFixed(0)} ETB', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red)),
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _expenses.removeAt(idx);
                                        });
                                      },
                                      icon: const Icon(Icons.delete_outline, size: 16, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ] else if (_currentStep == 4) ...[
                      // STEP 4: Debt Collection & Cumulative Adari Tracking
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('ደረጃ 4 ከ 5', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                                const Text('የቆየ አዳሪ ስብስብ (Adari Recovery)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                                const SizedBox(height: 4),
                                Text('ዛሬ ከአዳሪ ደንበኞች የተሰበሰበውን የብርጭቆ ብዛት ያስገቡ።', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.purple.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('ጠቅላላ ቀሪ አዳሪ', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.purple)),
                                if (todayPendingCups > 0)
                                  Text('$previousPendingCups + $todayPendingCups = $totalPendingPool ብርጭቆ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.purple.shade900))
                                else
                                  Text('$totalPendingPool ብርጭቆ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.purple.shade900)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Breakdown of Previous + Today's Pending Adari
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('የቀደመ ያልተከፈለ አዳሪ (Previous Adari):', style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                                Text('$previousPendingCups ብርጭቆ', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            if (todayPendingCups > 0) ...[
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('+ የዛሬ አዲስ አዳሪ (Today\'s Pending):', style: TextStyle(fontSize: 12, color: Colors.purple.shade700, fontWeight: FontWeight.bold)),
                                  Text('+$todayPendingCups ብርጭቆ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.purple.shade900)),
                                ],
                              ),
                            ],
                            const Divider(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('ጠቅላላ የሚሰበሰብ አዳሪ (Total Pool):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
                                Text(
                                  '$totalPendingPool ብርጭቆ (${(totalPendingPool * _pricePerCup).toStringAsFixed(0)} ETB)',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.primary),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Interactive Direct Number Input with Keyboard Support & +/- Controls
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ዛሬ የተሰበሰበውን የብርጭቆ ብዛት ያስገቡ (በኪቦርድ ይፃፉ)፦',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                // Decrement Button
                                Material(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () {
                                      setState(() {
                                        _recoveredCups = (_recoveredCups - 1).clamp(0, totalPendingPool);
                                        _recoveredCupsController.text = '$_recoveredCups';
                                      });
                                    },
                                    child: const SizedBox(
                                      width: 48,
                                      height: 48,
                                      child: Icon(Icons.remove, size: 24, color: Colors.black87),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),

                                // Keyboard Input Field
                                Expanded(
                                  child: TextField(
                                    controller: _recoveredCupsController,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.primary,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: '0',
                                      suffixText: 'ብርጭቆ',
                                      suffixStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                      filled: true,
                                      fillColor: Colors.purple.shade50.withValues(alpha: 0.4),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: Colors.purple.shade200),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                                      ),
                                    ),
                                    onChanged: (val) {
                                      final parsed = int.tryParse(val) ?? 0;
                                      final clamped = parsed.clamp(0, totalPendingPool);
                                      setState(() {
                                        _recoveredCups = clamped;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),

                                // Increment Button
                                Material(
                                  color: AppColors.primarySoft,
                                  borderRadius: BorderRadius.circular(12),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () {
                                      setState(() {
                                        _recoveredCups = (_recoveredCups + 1).clamp(0, totalPendingPool);
                                        _recoveredCupsController.text = '$_recoveredCups';
                                      });
                                    },
                                    child: const SizedBox(
                                      width: 48,
                                      height: 48,
                                      child: Icon(Icons.add, size: 24, color: AppColors.primary),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Quick Add Chips
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ...[1, 2, 3, 5].where((c) => c <= totalPendingPool).map((c) {
                            return OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _recoveredCups = (_recoveredCups + c).clamp(0, totalPendingPool);
                                  _recoveredCupsController.text = '$_recoveredCups';
                                });
                              },
                              child: Text('+$c ብርጭቆ', style: const TextStyle(fontWeight: FontWeight.bold)),
                            );
                          }),
                          if (totalPendingPool > 0)
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _recoveredCups = totalPendingPool;
                                  _recoveredCupsController.text = '$_recoveredCups';
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade600,
                                foregroundColor: Colors.white,
                              ),
                              child: Text('ሁሉንም ($totalPendingPool)', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          if (_recoveredCups > 0)
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _recoveredCups = 0;
                                  _recoveredCupsController.text = '0';
                                });
                              },
                              child: const Text('አፅዳ (0)', style: TextStyle(color: Colors.red)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Live Recovery & Remaining Summary Container
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('ዛሬ የተሰበሰበ አዳሪ (Recovered Today)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue)),
                                    Text('$_recoveredCups ብርጭቆ × ${_pricePerCup.toStringAsFixed(0)} ETB', style: TextStyle(fontSize: 12, color: Colors.blue.shade900)),
                                  ],
                                ),
                                Text(
                                  '+${totalRecoveredDebts.toStringAsFixed(0)} ETB',
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.blue.shade900),
                                ),
                              ],
                            ),
                            const Divider(height: 20, color: Colors.blue),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('ለቀጣይ የሚተላለፍ ቀሪ አዳሪ (Remaining):', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
                                Text(
                                  '$remainingPendingCups ብርጭቆ (${(remainingPendingCups * _pricePerCup).toStringAsFixed(0)} ETB)',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: remainingPendingCups > 0 ? Colors.purple.shade900 : Colors.green.shade800),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ] else if (_currentStep == 5) ...[
                      // STEP 5: Final Net Cash Handover & Security Close
                      const Text('ደረጃ 5 ከ 5', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const Text('የመጨረሻ የገንዘብ ርክክብ እና ቁልፍ (Cash Handover)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 12),

                      // Notice Banner
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info, color: Colors.amber.shade900, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'የካሽ ሬጅስተሩን ከመቆለፍዎ በፊት የገንዘብ ርክክብ ቀመሩን ያረጋግጡ።',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF78350F)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Bold Formula Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 1.5),
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
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(color: AppColors.obsidian, borderRadius: BorderRadius.circular(8)),
                                      child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 16),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text('የገንዘብ ርክክብ ቀመር (Net Cash Handover)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.obsidian)),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            _buildHandoverRow('የዛሬ የጥሬ ገንዘብ ሽያጭ (Cash Sales):', '+${cashSales.toStringAsFixed(0)} ETB', Colors.green, '+'),
                            const SizedBox(height: 6),
                            _buildHandoverRow('+ የተሰበሰበ የቆየ አዳሪ (ደረጃ 4):', '+${totalRecoveredDebts.toStringAsFixed(0)} ETB ($_recoveredCups ብርጭቆ)', Colors.blue, '+'),
                            const SizedBox(height: 6),
                            _buildHandoverRow('− የዛሬ የሬጅስተር ወጪዎች (ደረጃ 3):', '−${totalExpenses.toStringAsFixed(0)} ETB', Colors.red, '−'),
                            const SizedBox(height: 8),

                            // Order Types summary chips
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('🏠 ቤት: ${dineInOrders.length}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF15803D))),
                                  Text('🛍️ የታሸገ: ${takeawayOrders.length}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF1D4ED8))),
                                  Text('🛵 BeU: ${deliveryOrders.length}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFFB45309))),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Obsidian Dark Total Card
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [AppColors.obsidian, AppColors.obsidianCard]),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('ለባለቤቱ የሚረከበው የተጣራ ገንዘብ', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900)),
                                        SizedBox(height: 2),
                                        Text('ተጣራ ገንዘብ = የጥሬ ገንዘብ ሽያጭ + የተሰበሰበ ብድር − ወጪዎች', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${netCashToOwner.toStringAsFixed(0)} ETB',
                                    style: const TextStyle(color: AppColors.primary, fontSize: 20, fontWeight: FontWeight.w900),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextField(
                        controller: _shiftNotesController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'የሺፍት ማስታወሻ (አማራጭ)',
                          hintText: 'ለባለቤቱ ወይም ለሚቀጥለው ሺፍት ማስታወሻ ይጻፉ...',
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Footer Actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      if (_currentStep == 1) {
                        Navigator.of(context).pop();
                      } else {
                        setState(() {
                          _currentStep--;
                        });
                      }
                    },
                    icon: const Icon(Icons.arrow_back, size: 16),
                    label: Text(_currentStep == 1 ? 'ሰርዝ' : 'ወደ ኋላ'),
                  ),

                  if (_currentStep < 5)
                    ElevatedButton.icon(
                      onPressed: (_currentStep == 2 && !step2Valid)
                          ? null
                          : () {
                              setState(() {
                                _currentStep++;
                              });
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.arrow_forward, size: 16, color: Colors.white),
                      label: const Text('ቀጣይ ደረጃ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: () {
                        final isDay = session.shiftType == ShiftType.day;
                        final requiredPin = isDay ? pos.dayShiftPin : pos.nightShiftPin;
                        final shiftName = isDay ? 'የቀን ሺፍት' : 'የማታ ሺፍት';
                        showDialog(
                          context: context,
                          builder: (ctx) => PinPadDialog(
                            title: '$shiftName መዝጊያ ማረጋገጫ (PIN Lock)',
                            subtitle: '$shiftName ቆልፈው ለማስረከብ 4-ዲጂት PIN ያስገቡ (ነባሪ: $requiredPin)',
                            requiredPin: requiredPin,
                            onConfirm: (pin) {
                              final recon = ShiftReconciliation(
                                id: 'recon-${_uuid.v4().substring(0, 6)}',
                                shiftId: session.id,
                                shiftType: session.shiftType,
                                cashierName: session.cashierName,
                                grossRevenue: grossRevenue,
                                cashSales: cashSales,
                                transferSales: transferSales,
                                creditSales: creditSales,
                                deliverySales: deliverySales,
                                totalOrdersCount: orders.length,
                                openingCups: openingCups,
                                addedCups: _addedCups,
                                leftoverCups: leftoverVal ?? 0,
                                calculatedCupsSold: calculatedCupsSold ?? 0,
                                tabletCupsSold: tabletCupsSold,
                                cupsVariance: cupsVariance ?? 0,
                                totalKitchenFoodCooked: kitchenFoodCooked,
                                totalWaiterFoodSold: waiterFoodSold,
                                foodVariance: foodVariance,
                                totalExpenses: totalExpenses,
                                expenses: List.from(_expenses),
                                totalRecoveredCups: _recoveredCups,
                                totalRecoveredDebts: totalRecoveredDebts,
                                netCashToOwner: netCashToOwner,
                                shiftNotes: _shiftNotesController.text.trim(),
                                closedAt: DateTime.now(),
                              );

                              pos.completeReconciliation(recon);
                              Navigator.of(context).pop();
                            },
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.lock, size: 16, color: Colors.white),
                      label: const Text('በ PIN አረጋግጥ እና ሺፍት ዝጋ', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${amount.toStringAsFixed(0)} ETB',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: color.shade800),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF1A202C)), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildQuickExpenseChip(String label, double amount) {
    return ActionChip(
      label: Text('$label (${amount.toStringAsFixed(0)} ETB)', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      onPressed: () => _addQuickExpense(label, amount),
      backgroundColor: Colors.amber.shade50,
      side: BorderSide(color: Colors.amber.shade200),
    );
  }

  Widget _buildOrderTypeSummaryTile({
    required String title,
    required int count,
    required double amount,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$count ትዕዛዞች',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.obsidian),
          ),
          Text(
            '${amount.toStringAsFixed(0)} ETB',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildHandoverRow(String label, String value, MaterialColor color, String sign) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(color: color.shade100, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(sign, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: color.shade900)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.obsidian)),
          ),
          const SizedBox(width: 8),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: color.shade800)),
        ],
      ),
    );
  }
}
