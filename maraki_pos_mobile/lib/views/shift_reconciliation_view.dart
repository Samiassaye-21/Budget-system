import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../providers/pos_provider.dart';
import '../widgets/pin_pad_dialog.dart';

class ShiftReconciliationView extends StatefulWidget {
  const ShiftReconciliationView({super.key});

  @override
  State<ShiftReconciliationView> createState() => _ShiftReconciliationViewState();
}

class _ShiftReconciliationViewState extends State<ShiftReconciliationView> {
  int _currentStep = 1;
  final Uuid _uuid = const Uuid();

  // Step 2 Cup Count State
  final TextEditingController _leftoverController = TextEditingController();
  int _addedCups = 0;

  // Step 3 Expenses State
  final List<ShiftExpense> _expenses = [];
  final TextEditingController _expenseDescController = TextEditingController();
  final TextEditingController _expenseAmountController = TextEditingController();

  // Step 4 Debt Recovery State
  int _recoveredCups = 0;
  final double _pricePerCup = 170.0;

  // Step 5 Notes
  final TextEditingController _shiftNotesController = TextEditingController();

  @override
  void dispose() {
    _leftoverController.dispose();
    _expenseDescController.dispose();
    _expenseAmountController.dispose();
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
        .where((o) => o.paymentMethod == 'Delivery')
        .fold(0.0, (sum, o) => sum + o.total);

    final int tabletCupsSold = pos.shiftJuiceCupsSold;
    final int openingCups = session.openingCups;

    final String leftoverText = _leftoverController.text.trim();
    final int? leftoverVal = leftoverText.isEmpty ? null : int.tryParse(leftoverText);
    final int? calculatedCupsSold = leftoverVal != null ? (openingCups + _addedCups) - leftoverVal : null;
    final int? cupsVariance = calculatedCupsSold != null ? calculatedCupsSold - tabletCupsSold : null;
    final int kitchenFoodCooked = pos.kitchenFoodCookedForShift;
    final int waiterFoodSold = pos.shiftFoodSold;
    final int foodVariance = waiterFoodSold - kitchenFoodCooked;
    final bool foodValid = kitchenFoodCooked == 0 || waiterFoodSold >= kitchenFoodCooked;
    final bool step2Valid = leftoverVal != null && cupsVariance == 0 && foodValid;

    final double totalExpenses = _expenses.fold(0.0, (sum, e) => sum + e.amount);
    final double totalRecoveredDebts = _recoveredCups * _pricePerCup;
    final double netCashToOwner = cashSales + totalRecoveredDebts - totalExpenses;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 780),
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
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.amber.shade300),
                            ),
                            child: const Text('🍊', style: TextStyle(fontSize: 18)),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                session.shiftType == ShiftType.day ? 'የቀን ሺፍት ማጠቃለያ' : 'የማታ ሺፍት ማጠቃለያ',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1A202C)),
                              ),
                              const Text(
                                'የሺፍት ማጠቃለያ መዝገብ (Shift Reconciliation)',
                                style: TextStyle(fontSize: 11, color: Colors.grey),
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
                                    ? const Color(0xFFE53E3E)
                                    : (isPassed ? Colors.green : Colors.grey.shade200),
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
                      _buildSummaryRow('ያልተሰበሰበ ብድር (Credit Sales)', creditSales, Colors.purple),
                      const SizedBox(height: 8),
                      _buildSummaryRow('ዴሊቨሪ ሽያጭ (Delivery)', deliverySales, Colors.orange),
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
                              Text('🍲', style: TextStyle(fontSize: 18)),
                              SizedBox(width: 8),
                              Text(
                                'የኩሽና ምግብ ርክክብ (Kitchen Food Cross-Check)',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF1A202C)),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                            child: Text(
                              session.shiftType == ShiftType.day ? 'ቀን ሺፍት' : 'ማታ ሺፍት',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
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
                                color: Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.amber.shade200),
                              ),
                              child: Column(
                                children: [
                                  const Text('👩‍🍳 ኩሽና ያዘጋጀው', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFC05621))),
                                  const SizedBox(height: 4),
                                  Text('$kitchenFoodCooked', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF7B341E))),
                                  const Text('ምግቦች', style: TextStyle(fontSize: 9, color: Colors.grey)),
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
                                  const Text('📱 ዌተር ያስመዘገበው', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF2B6CB0))),
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
                      const SizedBox(height: 12),

                      if (kitchenFoodCooked > 0 && !foodValid)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'ያልተመዘገበ የምግብ ክፍተት አለ! ኩሽና ያዘጋጀው $kitchenFoodCooked ሲሆን ዌተር ያስመዘገበው $waiterFoodSold ነው። እባክዎ የቀሩትን ${foodVariance.abs()} ምግቦች ሳያስመዘግቡ ሺፍቱን ማጠቃለል አይቻልም።',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red.shade900),
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (kitchenFoodCooked > 0 && foodValid)
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
                              const Text('✓ የምግብ ቆጠራው ሙሉ በሙሉ ተጣጥሟል!', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
                            ],
                          ),
                        ),
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
                              backgroundColor: const Color(0xFFE53E3E),
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
                      // STEP 4: Debt Collection
                      const Text('ደረጃ 4 ከ 5', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const Text('የቆየ ብድር ስብስብ (Debt Recovery)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Text('ዛሬ ከቀደሙት ባለዕዳዎች የተሰበሰበውን የብርጭቆ ብዛት ያስገቡ።', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      const SizedBox(height: 16),

                      Wrap(
                        spacing: 8,
                        children: [1, 2, 3, 5, 10].map((c) {
                          return OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _recoveredCups += c;
                              });
                            },
                            child: Text('+$c ብርጭቆ', style: const TextStyle(fontWeight: FontWeight.bold)),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('የተሰበሰበ ብድር ጠቅላላ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue)),
                                Text('$_recoveredCups ብርጭቆ × 170 ETB', style: TextStyle(fontSize: 12, color: Colors.blue.shade900)),
                              ],
                            ),
                            Text(
                              '+${totalRecoveredDebts.toStringAsFixed(0)} ETB',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.blue.shade900),
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
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFF34D399), width: 2),
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
                                      decoration: BoxDecoration(color: const Color(0xFF047857), borderRadius: BorderRadius.circular(8)),
                                      child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 16),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text('የገንዘብ ርክክብ ቀመር (Net Cash Handover)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF064E3B))),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            _buildHandoverRow('የዛሬ የጥሬ ገንዘብ ሽያጭ (Cash Sales):', '+${cashSales.toStringAsFixed(0)} ETB', Colors.green, '+'),
                            const SizedBox(height: 6),
                            _buildHandoverRow('+ የተሰበሰበ የቆየ ብድር (ደረጃ 4):', '+${totalRecoveredDebts.toStringAsFixed(0)} ETB ($_recoveredCups ብርጭቆ)', Colors.blue, '+'),
                            const SizedBox(height: 6),
                            _buildHandoverRow('− የዛሬ የሬጅስተር ወጪዎች (ደረጃ 3):', '−${totalExpenses.toStringAsFixed(0)} ETB', Colors.red, '−'),
                            const SizedBox(height: 12),

                            // Glowing Grand Total
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Color(0xFF065F46), Color(0xFF047857), Color(0xFF134E4A)]),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('ለባለቤቱ የሚረከበው የተጣራ ገንዘብ', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
                                      SizedBox(height: 2),
                                      Text('ተጣራ ገንዘብ = የጥሬ ገንዘብ ሽያጭ + የተሰበሰበ ብድር − ወጪዎች', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  Text(
                                    '${netCashToOwner.toStringAsFixed(0)} ETB',
                                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
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
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
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
                        backgroundColor: const Color(0xFFE53E3E),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.arrow_forward, size: 16, color: Colors.white),
                      label: const Text('ቀጣይ ደረጃ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => PinPadDialog(
                            title: 'ሺፍት መዝጊያ ማረጋገጫ (PIN Lock)',
                            subtitle: 'ሺፍቱን ቆልፈው ለማስረከብ 4-ዲጂት PIN ያስገቡ (ነባሪ: 1234)',
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
                        backgroundColor: const Color(0xFF047857),
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
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
          Text('${amount.toStringAsFixed(0)} ETB', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: color.shade800)),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF1A202C))),
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

  Widget _buildHandoverRow(String label, String value, MaterialColor color, String sign) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(color: color.shade100, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(sign, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: color.shade900)),
              ),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF1A202C))),
            ],
          ),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: color.shade800)),
        ],
      ),
    );
  }
}
