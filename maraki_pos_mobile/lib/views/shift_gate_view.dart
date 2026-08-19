import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/pos_provider.dart';
import '../widgets/pin_pad_dialog.dart';

class ShiftGateView extends StatelessWidget {
  const ShiftGateView({super.key});

  @override
  Widget build(BuildContext context) {
    final pos = context.watch<POSProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo & Brand
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: Colors.amber.shade200, width: 2),
                    ),
                    child: const Center(
                      child: Text('🍊', style: TextStyle(fontSize: 36)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'ማራኪ POS',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1A202C),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Text(
                    'አዲስ አበባ • ቦሌ ቅርንጫፍ',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: Colors.amber,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'የሺፍት የስራ ቦታ ምርጫ (Shift Selection Gate)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF718096),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Shift Selection Cards
                  Row(
                    children: [
                      // Day Shift
                      Expanded(
                        child: _buildShiftCard(
                          context,
                          title: 'የቀን ሺፍት (Day Shift)',
                          time: '8:00 AM – 4:00 PM',
                          icon: Icons.wb_sunny_rounded,
                          iconColor: const Color(0xFFD69E2E),
                          bgColor: const Color(0xFFFFFDF5),
                          borderColor: const Color(0xFFECC94B),
                          onTap: () => pos.selectShift(ShiftType.day),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Night Shift
                      Expanded(
                        child: _buildShiftCard(
                          context,
                          title: 'የማታ ሺፍት (Night Shift)',
                          time: '4:00 PM – 11:30 PM',
                          icon: Icons.nightlight_round,
                          iconColor: const Color(0xFF6B46C1),
                          bgColor: const Color(0xFFFAF5FF),
                          borderColor: const Color(0xFFB794F4),
                          onTap: () => pos.selectShift(ShiftType.night),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Workspace Alternate Links (Kitchen & Admin)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => pos.setMode(AppMode.kitchen),
                        icon: const Icon(Icons.restaurant_menu, size: 18, color: Color(0xFF2D3748)),
                        label: const Text('የወጥ ቤት ማሳያ (Kitchen)', style: TextStyle(color: Color(0xFF2D3748), fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      OutlinedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => PinPadDialog(
                              title: 'የአድሚን ዳሽቦርድ መግቢያ',
                              subtitle: 'የአድሚን PIN ያስገቡ (ነባሪ PIN: 1234)',
                              onConfirm: (pin) => pos.setMode(AppMode.admin),
                            ),
                          );
                        },
                        icon: const Icon(Icons.admin_panel_settings, size: 18, color: Color(0xFF2D3748)),
                        label: const Text('አድሚን (Admin)', style: TextStyle(color: Color(0xFF2D3748), fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 36),
                  const Divider(),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          const Text('ሲስተም ዝግጁ ነው • ሎካል & ደመና', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Text('ማራኪ POS v2.6.0', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShiftCard(
    BuildContext context, {
    required String title,
    required String time,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: iconColor.withOpacity(0.15),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Icon(icon, size: 36, color: iconColor),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1A202C),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFE53E3E),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'ሺፍት ክፈት',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward, size: 14, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
