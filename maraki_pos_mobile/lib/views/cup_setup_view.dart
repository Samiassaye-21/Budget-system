import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/pos_provider.dart';
import '../services/data_service.dart';
import '../theme/app_theme.dart';
import '../widgets/pin_pad_dialog.dart';

class CupSetupView extends StatefulWidget {
  const CupSetupView({super.key});

  @override
  State<CupSetupView> createState() => _CupSetupViewState();
}

class _CupSetupViewState extends State<CupSetupView> {
  final TextEditingController _controller = TextEditingController();
  int _expectedCups = 120;
  bool _isAdminApproved = false;

  @override
  void initState() {
    super.initState();
    _expectedCups = DataService().getLastLeftoverCups();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pos = context.watch<POSProvider>();
    final shift = pos.shiftType ?? ShiftType.day;

    final text = _controller.text.trim();
    final int? enteredCount = text.isEmpty ? null : int.tryParse(text);
    final bool isEntered = enteredCount != null;
    final int? diff = isEntered ? enteredCount - _expectedCups : null;
    final bool isMatched = isEntered && diff == 0;
    final bool canProceed = (isMatched || _isAdminApproved) && isEntered && enteredCount >= 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back Link & Brand Logo
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          onPressed: () => pos.setMode(AppMode.gate),
                          icon: const Icon(Icons.arrow_back, size: 16, color: Colors.grey),
                          label: const Text('ወደ ሺፍት መረጣ', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          style: TextButton.styleFrom(padding: EdgeInsets.zero, alignment: Alignment.centerLeft),
                        ),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.amber.shade300, width: 1.5),
                          ),
                          child: ClipOval(
                            child: Padding(
                              padding: const EdgeInsets.all(2),
                              child: Image.asset(
                                'assets/logo.png',
                                fit: BoxFit.contain,
                                errorBuilder: (_, _, _) => const Icon(Icons.storefront, size: 16, color: Colors.amber),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Header Icon
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: shift == ShiftType.day ? Colors.amber.shade50 : Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        shift == ShiftType.day ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                        color: shift == ShiftType.day ? const Color(0xFFD69E2E) : const Color(0xFF6B46C1),
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      shift == ShiftType.day ? 'የቀን ሺፍት / ሬጅስተር መክፈቻ' : 'የማታ ሺፍት / ሬጅስተር መክፈቻ',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'ተረካቢ የብርጭቆ ብዛት',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1A202C),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'ከቀደመው ሺፍት የተረፈውን የብርጭቆ ብዛት በአካል ቆጥረው ያስገቡ። ቆጠራው ከቀደመው ሺፍት ርክክብ ጋር ይረጋገጣል።',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.4),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.schedule, size: 14, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${DateHelper.todayFormatted()} • ⏰ ${DateHelper.shiftOperatingHours(shift.name)}',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.obsidian),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Input Field
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'የተረከቡት የብርጭቆ ብዛት *ግዴታ',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
                        ),
                        if (_isAdminApproved)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFA7F3D0)),
                            ),
                            child: const Text(
                              '✓ በአድሚን ጸድቋል',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _controller,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                      decoration: InputDecoration(
                        hintText: 'የቆጠሩትን ብርጭቆ ያስገቡ...',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.primary, width: 2),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.border, width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.primary, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _isAdminApproved = false;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Validation Card States
                    if (!isEntered)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, size: 18, color: Colors.amber.shade800),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'እባክዎ በአካል የቆጠሩትን ተረካቢ የብርጭቆ ብዛት ያስገቡ።',
                                style: TextStyle(fontSize: 12, color: Colors.amber.shade900, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (isMatched)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.green.shade300, width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.check_circle, size: 18, color: Colors.green.shade700),
                                const SizedBox(width: 8),
                                Text(
                                  '✓ ልክ ተጣጥሟል! (0 ልዩነት)',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.green.shade900),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'ከቀደመው ሺፍት የተረፈው $_expectedCups ብርጭቆ በትክክል ተረክበዋል።',
                              style: TextStyle(fontSize: 11, color: Colors.green.shade800, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      )
                    else if (_isAdminApproved)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.verified, size: 18, color: Colors.green.shade700),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'የብርጭቆ ልዩነት በአድሚን PIN ጸድቋል። ሺፍት መጀመር ይችላሉ።',
                                style: TextStyle(fontSize: 12, color: Colors.green.shade900, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Column(
                        children: [
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
                                        Icon(Icons.error_outline, size: 18, color: Colors.red.shade700),
                                        const SizedBox(width: 8),
                                        Text(
                                          'የብርጭቆ ልዩነት ተገኝቷል!',
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.red.shade900),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        diff! > 0 ? '+$diff ብርጭቆ ትርፍ' : '$diff ብርጭቆ ጉድለት',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.red.shade900),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '• ከቀደመው ሺፍት የተረፈው መዝገብ: $_expectedCups ብርጭቆ',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF4A5568)),
                                ),
                                Text(
                                  '• እርስዎ ያስገቡት ቆጠራ: $enteredCount ብርጭቆ',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red.shade800),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => PinPadDialog(
                                  title: 'የአድሚን ፈቃድ ማረጋገጫ (Admin Approval)',
                                  subtitle: 'የብርጭቆ ልዩነትን አጽድቆ ሺፍት ለመጀመር የአድሚን 4-ዲጂት PIN ያስገቡ (ነባሪ: ${pos.adminPin})',
                                  requiredPin: pos.adminPin,
                                  onConfirm: (pin) {
                                    setState(() {
                                      _isAdminApproved = true;
                                    });
                                  },
                                ),
                              );
                            },
                            icon: const Icon(Icons.lock, size: 16, color: AppColors.primary),
                            label: const Text(
                              'ልዩነቱን በአድሚን PIN አጽድቅ (Approve with Admin PIN)',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: AppColors.primarySoft,
                              side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 24),

                    // Start Shift Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: canProceed
                            ? () {
                                pos.startShiftSession(enteredCount);
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          disabledBackgroundColor: AppColors.border,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: canProceed ? 2 : 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              canProceed
                                  ? (shift == ShiftType.day ? 'የቀን ሺፍት ጀምር' : 'የማታ ሺፍት ጀምር')
                                  : (text.isEmpty ? 'ቆጠራውን ያስገቡ' : 'ልዩነቱን ያስተካክሉ (Fix Discrepancy)'),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: canProceed ? Colors.white : Colors.grey.shade600,
                              ),
                            ),
                            if (canProceed) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward, size: 18, color: Colors.white),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
