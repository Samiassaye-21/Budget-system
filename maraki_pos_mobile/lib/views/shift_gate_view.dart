import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/pos_provider.dart';
import '../services/update_service.dart';
import '../widgets/pin_pad_dialog.dart';

class ShiftGateView extends StatefulWidget {
  const ShiftGateView({super.key});

  @override
  State<ShiftGateView> createState() => _ShiftGateViewState();
}

class _ShiftGateViewState extends State<ShiftGateView> {
  AppUpdateInfo? _updateInfo;
  bool _isDownloading = false;
  int _downloadProgress = 0;

  @override
  void initState() {
    super.initState();
    _checkUpdate();
  }

  Future<void> _checkUpdate() async {
    try {
      final info = await UpdateService.checkForUpdate();
      if (mounted && info.hasUpdate) {
        setState(() {
          _updateInfo = info;
        });
      }
    } catch (_) {}
  }

  Future<void> _executeOtaDownload(String apkUrl) async {
    if (apkUrl.isEmpty) return;
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0;
    });

    await UpdateService.downloadAndInstallApk(
      apkUrl,
      onProgress: (progress) {
        if (mounted) {
          setState(() {
            _downloadProgress = progress;
          });
        }
      },
      onError: (err) {
        if (mounted) {
          setState(() {
            _isDownloading = false;
          });
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('የማዘመን ስህተት (Update Error)'),
              content: Text(err),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('እሺ (OK)'),
                ),
              ],
            ),
          );
        }
      },
    );

    if (mounted) {
      setState(() {
        _isDownloading = false;
      });
    }
  }

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
                  // Optional Auto-Update Available Banner
                  if (_updateInfo != null && _updateInfo!.hasUpdate) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.green.shade300, width: 1.5),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(color: Colors.green.shade100, shape: BoxShape.circle),
                                child: const Icon(Icons.system_update, color: Colors.green, size: 20),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'አዲስ ማሻሻያ ተገኝቷል (v${_updateInfo!.latestVersion})',
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.green.shade900),
                                    ),
                                    Text(
                                      _updateInfo!.releaseNotes,
                                      style: TextStyle(fontSize: 11, color: Colors.green.shade800),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_isDownloading) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('በማውረድ ላይ...', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
                                Text('$_downloadProgress%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.green)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            LinearProgressIndicator(
                              value: _downloadProgress / 100.0,
                              backgroundColor: Colors.green.shade100,
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                              minHeight: 6,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ] else
                            SizedBox(
                              width: double.infinity,
                              height: 40,
                              child: ElevatedButton.icon(
                                onPressed: () => _executeOtaDownload(_updateInfo!.apkUrl),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF047857),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: const Icon(Icons.download, size: 16, color: Colors.white),
                                label: const Text('አሁን በ 1-Tap አዘምን (Update)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white)),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],

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
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 450;
                      if (isNarrow) {
                        return Column(
                          children: [
                            _buildShiftCard(
                              context,
                              title: 'የቀን ሺፍት (Day Shift)',
                              time: '8:00 AM – 4:00 PM',
                              icon: Icons.wb_sunny_rounded,
                              iconColor: const Color(0xFFD69E2E),
                              bgColor: const Color(0xFFFFFDF5),
                              borderColor: const Color(0xFFECC94B),
                              onTap: () => pos.selectShift(ShiftType.day),
                            ),
                            const SizedBox(height: 12),
                            _buildShiftCard(
                              context,
                              title: 'የማታ ሺፍት (Night Shift)',
                              time: '4:00 PM – 11:30 PM',
                              icon: Icons.nightlight_round,
                              iconColor: const Color(0xFF6B46C1),
                              bgColor: const Color(0xFFFAF5FF),
                              borderColor: const Color(0xFFB794F4),
                              onTap: () => pos.selectShift(ShiftType.night),
                            ),
                          ],
                        );
                      }

                      return Row(
                        children: [
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
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Workspace Alternate Links (Kitchen & Admin)
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => pos.setMode(AppMode.kitchen),
                        icon: const Icon(Icons.restaurant_menu, size: 18, color: Color(0xFF2D3748)),
                        label: const Text('የወጥ ቤት ማሳያ (Kitchen)', style: TextStyle(color: Color(0xFF2D3748), fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
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
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 10),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          const Text('ሲስተም ዝግጁ ነው • ሎካል & ደመና', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Text('ማራኪ POS v2.6.2', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
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
