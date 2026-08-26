import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../providers/pos_provider.dart';
import '../theme/app_theme.dart';

class PayLaterModal extends StatefulWidget {
  final VoidCallback onAllResolved;

  const PayLaterModal({super.key, required this.onAllResolved});

  @override
  State<PayLaterModal> createState() => _PayLaterModalState();
}

class _PayLaterModalState extends State<PayLaterModal> {
  final Map<String, String> _resolutions = {}; // orderId -> 'Cash' | 'Transfer' | 'Credit'
  final Map<String, String> _customerNames = {}; // orderId -> debtor name
  final Uuid _uuid = const Uuid();

  @override
  Widget build(BuildContext context) {
    final pos = context.watch<POSProvider>();
    final pendingOrders = pos.pendingPayLaterOrders;

    final bool allChosen = pendingOrders.isNotEmpty &&
        pendingOrders.every((o) {
          final res = _resolutions[o.id];
          if (res == null) return false;
          if (res == 'Credit') {
            return (_customerNames[o.id] ?? '').trim().isNotEmpty;
          }
          return true;
        });

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 550, maxHeight: 680),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.receipt_long, color: AppColors.primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ያልተጠናቀቁ ክፍያዎች (Pay Later)',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.obsidian),
                        ),
                        Text(
                          'ሺፍቱን ከመዝጋትዎ በፊት ${pendingOrders.length} የ"በኋላ ክፍያ" ትዕዛዞችን ይወስኑ',
                          style: const TextStyle(fontSize: 12, color: AppColors.slate),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            // Scrollable List of Pay Later Orders
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: pendingOrders.length,
                separatorBuilder: (_, _) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final order = pendingOrders[index];
                  final currentMethod = _resolutions[order.id];

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: currentMethod != null ? Colors.green.shade300 : AppColors.primary.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.obsidian.withValues(alpha: 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    order.items.map((i) {
                                      final matches = pos.products.where((p) => p.id == i.productId || p.name.toLowerCase() == i.name.toLowerCase() || p.amharicName == i.name);
                                      final amharicTitle = matches.isNotEmpty && matches.first.amharicName.isNotEmpty
                                          ? matches.first.amharicName
                                          : i.name;
                                      return '$amharicTitle × ${i.quantity}';
                                    }).join(', '),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.obsidian,
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: Text(
                                      'ትዕዛዝ #${order.id.replaceAll('ord-', '')}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${order.total.toStringAsFixed(0)} ETB',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Option Buttons: Cash, Transfer, Credit
                        Row(
                          children: [
                            Expanded(
                              child: _buildChoiceChip(
                                label: 'ጥሬ ገንዘብ (Cash)',
                                icon: Icons.payments_outlined,
                                isSelected: currentMethod == 'Cash',
                                color: Colors.green,
                                onTap: () {
                                  setState(() {
                                    _resolutions[order.id] = 'Cash';
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildChoiceChip(
                                label: 'ባንክ (Transfer)',
                                icon: Icons.phone_android,
                                isSelected: currentMethod == 'Transfer',
                                color: Colors.blue,
                                onTap: () {
                                  setState(() {
                                    _resolutions[order.id] = 'Transfer';
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildChoiceChip(
                                label: 'አዳሪ (Adari)',
                                icon: Icons.credit_card,
                                isSelected: currentMethod == 'Credit',
                                color: Colors.purple,
                                onTap: () {
                                  setState(() {
                                    _resolutions[order.id] = 'Credit';
                                  });
                                },
                              ),
                            ),
                          ],
                        ),

                        // If Credit, show Debtor Name Input
                        if (currentMethod == 'Credit') ...[
                          const SizedBox(height: 12),
                          TextField(
                            decoration: InputDecoration(
                              labelText: 'የአዳሪ ደንበኛ ስም (Customer Name) *ግዴታ',
                              hintText: 'ምሳሌ: አቶ ከበደ / ቢሮ ቁጥር 12',
                              filled: true,
                              fillColor: Colors.purple.shade50,
                              labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.purple),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.purple.shade300),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            onChanged: (val) {
                              setState(() {
                                _customerNames[order.id] = val;
                              });
                            },
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),

            // Footer Confirm Button
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: allChosen
                      ? () {
                          final updatedOrders = <Order>[];
                          final newDebts = <CustomerDebt>[];

                          for (final order in pendingOrders) {
                            final res = _resolutions[order.id]!;
                            updatedOrders.add(order.copyWith(paymentMethod: res));

                            if (res == 'Credit') {
                              final name = _customerNames[order.id]?.trim() ?? 'ያልታወቀ ደንበኛ';
                              final cupCount = order.items.fold(0, (sum, i) => sum + i.quantity);
                              final noteItems = order.items.map((i) {
                                final matches = pos.products.where((p) => p.id == i.productId || p.name.toLowerCase() == i.name.toLowerCase() || p.amharicName == i.name);
                                final amharicTitle = matches.isNotEmpty && matches.first.amharicName.isNotEmpty
                                    ? matches.first.amharicName
                                    : i.name;
                                return '$amharicTitle × ${i.quantity}';
                              }).join(', ');
                              newDebts.add(
                                CustomerDebt(
                                  id: 'deb-${_uuid.v4().substring(0, 6)}',
                                  customerName: name,
                                  note: noteItems,
                                  cupCount: cupCount,
                                  pricePerCup: cupCount > 0 ? (order.total / cupCount) : 170.0,
                                  amount: order.total,
                                  isRecovered: false,
                                  shiftIdCreated: pos.shiftSession?.id ?? 'shift',
                                  createdAt: DateTime.now(),
                                ),
                              );
                            }
                          }

                          pos.confirmPayLaterResolutions(updatedOrders, newDebts);
                          Navigator.of(context).pop();
                          widget.onAllResolved();
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.border,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    allChosen ? 'አረጋግጥ እና ወደ ሺፍት ማጠቃለያ ቀጥል' : 'ሁሉንም ትዕዛዞች ይወስኑ',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: allChosen ? Colors.white : Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required MaterialColor color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.shade50 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color.shade600 : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: isSelected ? color.shade700 : Colors.grey.shade600),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isSelected ? color.shade900 : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
