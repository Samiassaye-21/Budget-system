import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../providers/pos_provider.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/cloud_sync_dialog.dart';

class KitchenWorkspaceView extends StatefulWidget {
  const KitchenWorkspaceView({super.key});

  @override
  State<KitchenWorkspaceView> createState() => _KitchenWorkspaceViewState();
}

class _KitchenWorkspaceViewState extends State<KitchenWorkspaceView> {
  int _currentStep = 1; // 1: Menu, 2: Quantity, 3: Order Type, 4: Recipient, 5: Confirm, 6: Success
  Product? _selectedProduct;
  int _quantity = 1;
  String _orderType = 'ቤት (Dine-in)'; // 'ቤት (Dine-in)' | 'የታሸገ (Takeaway)'
  String _selectedRoute = 'Day shift'; // 'Day shift' | 'Night shift'
  Timer? _autoResetTimer;
  final Uuid _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pos = Provider.of<POSProvider>(context, listen: false);
      final currentShift = pos.shiftSession?.shiftType ?? pos.shiftType ?? ShiftType.day;
      setState(() {
        _selectedRoute = currentShift == ShiftType.night ? 'Night shift' : 'Day shift';
      });
    });
  }

  @override
  void dispose() {
    _autoResetTimer?.cancel();
    super.dispose();
  }

  String _getFoodEmoji(String name, String amharicName) {
    final combined = '$name $amharicName'.toLowerCase();
    if (combined.contains('ኮምቦ') || combined.contains('combo') || combined.contains('ማራኪ') || combined.contains('ፓንች')) {
      return '⭐';
    }
    if (combined.contains('ፓስታ') || combined.contains('pasta')) {
      return '🍝';
    }
    if (combined.contains('ሩዝ') || combined.contains('rice')) {
      return '🍚';
    }
    if (combined.contains('ሳላድ') || combined.contains('salad')) {
      return '🥗';
    }
    if (combined.contains('እንቁላል') || combined.contains('egg')) {
      return '🍳';
    }
    if (combined.contains('ሳንድዊች') || combined.contains('sandwich')) {
      return '🥪';
    }
    if (combined.contains('ፍርፍር') || combined.contains('firfir')) {
      return '🍲';
    }
    return '🍽️';
  }

  void _handleSaveTicket(POSProvider pos) {
    if (_selectedProduct == null) return;

    final ticketId = 'k-ticket-${_uuid.v4().substring(0, 6)}';
    final item = OrderItem(
      productId: _selectedProduct!.id,
      name: _selectedProduct!.amharicName.isNotEmpty ? _selectedProduct!.amharicName : _selectedProduct!.name,
      price: _selectedProduct!.price,
      quantity: _quantity,
    );

    final ticket = KitchenTicket(
      id: ticketId,
      route: _selectedRoute,
      orderType: _orderType,
      items: [item],
      totalQuantity: _quantity,
      createdAt: DateTime.now(),
      status: 'pending',
    );

    pos.addKitchenTicket(ticket);

    setState(() {
      _currentStep = 6;
    });

    _autoResetTimer?.cancel();
    _autoResetTimer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) {
        setState(() {
          _currentStep = 1;
          _selectedProduct = null;
          _quantity = 1;
          _orderType = 'ቤት (Dine-in)';
        });
      }
    });
  }

  void _handleBack(POSProvider pos) {
    if (_currentStep > 1 && _currentStep < 6) {
      setState(() {
        _currentStep--;
      });
    } else if (_currentStep == 1) {
      pos.setMode(AppMode.gate);
    } else if (_currentStep == 6) {
      _autoResetTimer?.cancel();
      setState(() {
        _currentStep = 1;
        _selectedProduct = null;
        _quantity = 1;
        _orderType = 'ቤት (Dine-in)';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pos = context.watch<POSProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation & Shift / Ethiopian Date Bar
            if (_currentStep < 6) _buildTopBar(pos),

            // Main Content Body
            Expanded(
              child: _buildCurrentStepContent(context, pos),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(POSProvider pos) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(bottom: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Circular Back Button
          InkWell(
            onTap: () => _handleBack(pos),
            borderRadius: BorderRadius.circular(22),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
              ),
              child: const Icon(Icons.arrow_back_rounded, color: AppColors.primaryDark, size: 22),
            ),
          ),
          const SizedBox(width: 10),

          // Kitchen Title Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.restaurant_menu_rounded, size: 14, color: AppColors.primary),
                SizedBox(width: 6),
                Text(
                  'የኩሽና የስራ ቦታ',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Live Ethiopian + Gregorian Date Pill
          Flexible(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_month_rounded, size: 14, color: AppColors.primary),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      isTablet ? DateHelper.todayFormatted() : DateHelper.shortDate(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Online / Offline Status (Interactive)
          ValueListenableBuilder<SupabaseSyncStatus>(
            valueListenable: SupabaseService.instance.statusNotifier,
            builder: (_, status, _) {
              final isOnline = status == SupabaseSyncStatus.online;
              final isSyncing = status == SupabaseSyncStatus.syncing;
              return InkWell(
                onTap: () => CloudSyncDialog.show(context),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: isOnline ? const Color(0xFFECFDF5) : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isOnline ? const Color(0xFFA7F3D0) : const Color(0xFFFDE68A),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isOnline ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isSyncing ? 'Syncing...' : (isOnline ? 'Online' : 'Offline'),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isOnline ? const Color(0xFF065F46) : const Color(0xFF92400E),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // 4-Step Progress Indicator (Steps 2 to 5)
          if (_currentStep >= 2 && _currentStep <= 5)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Row(
                children: List.generate(4, (index) {
                  final stepIndex = index + 2; // Steps 2, 3, 4, 5
                  final isCurrent = _currentStep == stepIndex;
                  final isPassed = _currentStep > stepIndex;

                  return Container(
                    margin: const EdgeInsets.only(left: 4),
                    width: isCurrent ? 20 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: (isCurrent || isPassed) ? AppColors.primary : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCurrentStepContent(BuildContext context, POSProvider pos) {
    switch (_currentStep) {
      case 1:
        return _buildStep1MenuGrid(context, pos);
      case 2:
        return _buildStep2Quantity(context);
      case 3:
        return _buildStep3OrderType(context);
      case 4:
        return _buildStep4Recipient(context);
      case 5:
        return _buildStep5Confirm(context, pos);
      case 6:
        return _buildStep6Success(context);
      default:
        return _buildStep1MenuGrid(context, pos);
    }
  }

  // ==========================================
  // SLIDE 1: FOOD CHOICES (MENU)
  // ==========================================
  Widget _buildStep1MenuGrid(BuildContext context, POSProvider pos) {
    final foodProducts = pos.products.where((p) => p.category == 'Food').toList();

    if (foodProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu_rounded, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text(
              'ምንም የተገኘ የምግብ አይነት የለም',
              style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.restaurant_rounded, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'የኩሽና ምግቦች (${foodProducts.length})',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: foodProducts.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isTablet ? 2 : 1,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 14,
                  childAspectRatio: isTablet ? 4.2 : 3.4,
                ),
                itemBuilder: (context, index) {
                  final product = foodProducts[index];
                  final emoji = _getFoodEmoji(product.name, product.amharicName);
                  final displayName = product.amharicName.isNotEmpty ? product.amharicName : product.name;

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedProduct = product;
                        _quantity = 1;
                        _orderType = 'ቤት (Dine-in)';
                        _currentStep = 2;
                      });
                    },
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.border, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: double.infinity,
                            decoration: const BoxDecoration(
                              color: AppColors.primarySoft,
                              borderRadius: BorderRadius.horizontal(left: Radius.circular(16)),
                            ),
                            child: Center(
                              child: Text(
                                emoji,
                                style: const TextStyle(fontSize: 26),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.obsidian,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (product.name.isNotEmpty && product.name != displayName)
                                  Text(
                                    product.name,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.slate,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.primarySoft,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                              ),
                              child: Text(
                                '${product.price.toStringAsFixed(0)} ETB',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primaryDark,
                                ),
                              ),
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
        ),
      ),
    );
  }

  // ==========================================
  // SLIDE 2: QUANTITY (ስንት?)
  // ==========================================
  Widget _buildStep2Quantity(BuildContext context) {
    final displayName = _selectedProduct?.amharicName.isNotEmpty == true
        ? _selectedProduct!.amharicName
        : (_selectedProduct?.name ?? 'ምግብ');

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.obsidian,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'ስንት?',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: AppColors.obsidian,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'How many portions?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.slate,
                ),
              ),
              const SizedBox(height: 32),

              // Minus / Count / Plus Counter Row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Minus Button
                  InkWell(
                    onTap: () {
                      if (_quantity > 1) {
                        setState(() => _quantity--);
                      }
                    },
                    borderRadius: BorderRadius.circular(35),
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.remove, size: 28, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 36),

                  // Large Number
                  Text(
                    '$_quantity',
                    style: const TextStyle(
                      fontSize: 60,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(width: 36),

                  // Plus Button
                  InkWell(
                    onTap: () => setState(() => _quantity++),
                    borderRadius: BorderRadius.circular(35),
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.add, size: 28, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Quick Preset Buttons
              Wrap(
                spacing: 10,
                children: [1, 2, 3, 5, 10].map((n) {
                  final isSelected = _quantity == n;
                  return ChoiceChip(
                    label: Text(
                      '+$n',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : AppColors.obsidian,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
                    ),
                    onSelected: (sel) {
                      if (sel) setState(() => _quantity = n);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 36),

              // Next Button
              SizedBox(
                width: 240,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() => _currentStep = 3);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                    elevation: 2,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'ቀጥይ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
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

  // ==========================================
  // SLIDE 3: ORDER TYPE (የማዘዣ አይነት)
  // ==========================================
  Widget _buildStep3OrderType(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'የማዘዣ አይነት',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: AppColors.obsidian,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Select Dine-in or Takeaway',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.slate,
                ),
              ),
              const SizedBox(height: 24),

              // Option 1: Dine-in (ቤት / በቦታው)
              _buildOrderTypeOptionCard(
                iconData: Icons.table_restaurant_rounded,
                title: 'ቤት (በቦታው)',
                subtitle: 'Dine-in / በቦታው የሚቀርብ',
                typeKey: 'ቤት (Dine-in)',
                isActive: _orderType == 'ቤት (Dine-in)',
              ),
              const SizedBox(height: 16),

              // Option 2: Takeaway (የታሸገ)
              _buildOrderTypeOptionCard(
                iconData: Icons.shopping_bag_outlined,
                title: 'የታሸገ (Takeaway)',
                subtitle: 'Takeaway / ተቋጥሮ የሚወሰድ',
                typeKey: 'የታሸገ (Takeaway)',
                isActive: _orderType == 'የታሸገ (Takeaway)',
              ),

              const SizedBox(height: 32),

              // Next Button
              Center(
                child: SizedBox(
                  width: 240,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() => _currentStep = 4);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                      elevation: 2,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'ቀጥይ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderTypeOptionCard({
    required IconData iconData,
    required String title,
    required String subtitle,
    required String typeKey,
    bool isActive = false,
  }) {
    return InkWell(
      onTap: () {
        setState(() {
          _orderType = typeKey;
          _currentStep = 4;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primarySoft : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.border,
            width: isActive ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : AppColors.primarySoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                iconData,
                size: 26,
                color: isActive ? Colors.white : AppColors.primaryDark,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: isActive ? AppColors.primaryDark : AppColors.obsidian,
                        ),
                      ),
                      if (isActive) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'የተመረጠ',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.slate,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isActive ? AppColors.primary : AppColors.slate,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // SLIDE 4: RECIPIENT (ማን ወሰደ?) - ONLY DAY & NIGHT SHIFTS
  // ==========================================
  Widget _buildStep4Recipient(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ማን ወሰደ?',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: AppColors.obsidian,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Who took the food order?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.slate,
                ),
              ),
              const SizedBox(height: 24),

              // Option 1: Day Shift
              _buildRecipientOptionCard(
                iconEmoji: '☀️',
                title: 'ቀን ሺፍት',
                subtitle: 'Day Shift (${DateHelper.dayShiftHours})',
                routeKey: 'Day shift',
                isActive: _selectedRoute == 'Day shift',
              ),
              const SizedBox(height: 16),

              // Option 2: Night Shift
              _buildRecipientOptionCard(
                iconEmoji: '🌙',
                title: 'የማታ ሺፍት',
                subtitle: 'Night Shift (${DateHelper.nightShiftHours})',
                routeKey: 'Night shift',
                isActive: _selectedRoute == 'Night shift',
              ),
              const SizedBox(height: 16),

              // Option 3: BeU Delivery
              _buildRecipientOptionCard(
                iconEmoji: '🛵',
                title: 'BeU ዴሊቨሪ',
                subtitle: 'BeU Delivery Service',
                routeKey: 'BeU delivery',
                isActive: _selectedRoute == 'BeU delivery',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecipientOptionCard({
    required String iconEmoji,
    required String title,
    required String subtitle,
    required String routeKey,
    bool isActive = false,
  }) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedRoute = routeKey;
          _currentStep = 5;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primarySoft : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.border,
            width: isActive ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(iconEmoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: isActive ? AppColors.primaryDark : AppColors.obsidian,
                        ),
                      ),
                      if (isActive) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'የተመረጠ',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.slate,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isActive ? AppColors.primary : AppColors.slate,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // SLIDE 5: CONFIRMATION (እርግጠኛ ነህ?)
  // ==========================================
  Widget _buildStep5Confirm(BuildContext context, POSProvider pos) {
    final displayName = _selectedProduct?.amharicName.isNotEmpty == true
        ? _selectedProduct!.amharicName
        : (_selectedProduct?.name ?? 'ምግብ');
    final foodEmoji = _getFoodEmoji(_selectedProduct?.name ?? '', _selectedProduct?.amharicName ?? '');

    final isDayRoute = _selectedRoute == 'Day shift';
    final isNightRoute = _selectedRoute == 'Night shift';
    final routeTitle = isDayRoute
        ? 'ቀን ሺፍት'
        : isNightRoute
            ? 'የማታ ሺፍት'
            : 'BeU ዴሊቨሪ';
    final routeSubtitle = isDayRoute
        ? 'Day Shift (${DateHelper.dayShiftHours})'
        : isNightRoute
            ? 'Night Shift (${DateHelper.nightShiftHours})'
            : 'BeU Delivery Service';
    final routeEmoji = isDayRoute
        ? '☀️'
        : isNightRoute
            ? '🌙'
            : '🛵';

    final isDineIn = _orderType.contains('ቤት');

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'እርግጠኛ ነህ?',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: AppColors.obsidian,
                ),
              ),
              const SizedBox(height: 28),

              // Confirmation Summary Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Food Details
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(foodEmoji, style: const TextStyle(fontSize: 28)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.obsidian,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'ብዛት: $_quantity',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(color: AppColors.border, height: 1),
                    ),

                    // Order Type Details
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            isDineIn ? Icons.table_restaurant_rounded : Icons.shopping_bag_outlined,
                            size: 24,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isDineIn ? 'ቤት (በቦታው)' : 'የታሸገ (Takeaway)',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.obsidian,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isDineIn ? 'Dine-in Order' : 'Takeaway Order',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.slate,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(color: AppColors.border, height: 1),
                    ),

                    // Recipient Details
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(routeEmoji, style: const TextStyle(fontSize: 28)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                routeTitle,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.obsidian,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                routeSubtitle,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.slate,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Save Action Button
              SizedBox(
                width: 260,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => _handleSaveTicket(pos),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                    elevation: 3,
                    shadowColor: AppColors.primary.withValues(alpha: 0.4),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_rounded, size: 20, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'አስቀምጥ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
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

  // ==========================================
  // SLIDE 6: SUCCESS (ተቀምጧል!)
  // ==========================================
  Widget _buildStep6Success(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _autoResetTimer?.cancel();
        setState(() {
          _currentStep = 1;
          _selectedProduct = null;
          _quantity = 1;
          _orderType = 'ቤት (Dine-in)';
        });
      },
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E),
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF22C55E).withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(Icons.check_rounded, size: 54, color: Colors.white),
            ),
            const SizedBox(height: 24),

            const Text(
              'ተቀምጧል!',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: AppColors.obsidian,
              ),
            ),
            const SizedBox(height: 6),

            const Text(
              'Order Saved Successfully',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.slate,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
