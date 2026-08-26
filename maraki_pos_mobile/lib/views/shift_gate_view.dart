import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/pos_provider.dart';
import '../services/supabase_service.dart';
import '../services/update_service.dart';
import '../theme/app_theme.dart';
import '../widgets/cloud_sync_dialog.dart';
import '../widgets/pin_pad_dialog.dart';

enum GateShowcaseItem {
  kitchen,
  dayShift,
  nightShift,
}

class ShiftGateView extends StatefulWidget {
  const ShiftGateView({super.key});

  @override
  State<ShiftGateView> createState() => _ShiftGateViewState();
}

class _ShiftGateViewState extends State<ShiftGateView> {
  AppUpdateInfo? _updateInfo;
  bool _isDownloading = false;
  int _downloadProgress = 0;
  int _downloadedBytes = 0;
  GateShowcaseItem _activeItem = GateShowcaseItem.dayShift;

  @override
  void initState() {
    super.initState();
    _checkForUpdatesSilently();
  }

  Future<void> _checkForUpdatesSilently() async {
    if (kIsWeb) return;
    try {
      final info = await UpdateService.checkForUpdate();
      if (mounted && info.hasUpdate) {
        setState(() {
          _updateInfo = info;
        });
      }
    } catch (_) {
      // Retain silent offline operation
    }
  }

  Future<void> _executeOtaDownload(String apkUrl) async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0;
      _downloadedBytes = 0;
    });

    // Show immediate snackbar so user knows something is happening
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⏳ ማውረድ እየተጀመረ ነው…'),
          backgroundColor: Color(0xFF1B5E20),
          duration: Duration(seconds: 3),
        ),
      );
    }

    final success = await UpdateService.downloadAndInstallApk(
      apkUrl,
      onProgress: (progress) {
        if (mounted) {
          setState(() {
            _downloadProgress = progress;
          });
        }
      },
      onBytesReceived: (received) {
        if (mounted) {
          setState(() {
            _downloadedBytes = received;
          });
        }
      },
      onError: (errMsg) {
        if (mounted) {
          setState(() {
            _isDownloading = false;
            _downloadProgress = 0;
            _downloadedBytes = 0;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ የማዘመን ስህተት፡ $errMsg'),
              backgroundColor: Colors.red.shade800,
              duration: const Duration(seconds: 6),
            ),
          );
        }
      },
    );

    if (!success && mounted) {
      setState(() {
        _isDownloading = false;
        _downloadProgress = 0;
        _downloadedBytes = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pos = context.watch<POSProvider>();
    final isDayActive = pos.isDayShiftActive;
    final isNightActive = pos.isNightShiftActive;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6), // Soft pale mint/cream backdrop
      body: Stack(
        children: [
          // Background organic curves
          Positioned(
            top: -120,
            right: -80,
            child: Container(
              width: 460,
              height: 460,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryLight.withValues(alpha: 0.4),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -100,
            child: Container(
              width: 360,
              height: 360,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primarySoft.withValues(alpha: 0.5),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 880),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 32,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Top Row: Empty Left spacer, Center Maraki Logo + Title, Top-Right Online Status
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Top-Right Online Status Pill (Interactive)
                          Align(
                            alignment: Alignment.topRight,
                            child: ValueListenableBuilder<SupabaseSyncStatus>(
                              valueListenable: SupabaseService.instance.statusNotifier,
                              builder: (ctx, status, _) {
                                final isOnline = status == SupabaseSyncStatus.online;
                                final isSyncing = status == SupabaseSyncStatus.syncing;

                                return InkWell(
                                  onTap: () => CloudSyncDialog.show(context),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Tooltip(
                                    message: 'ክላውድ ማመሳሰያ ቅንብር እና ሁኔታን ይመልከቱ (Cloud Sync Info)',
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: isOnline ? Colors.green.shade50 : Colors.amber.shade50,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isOnline ? Colors.green.shade300 : Colors.amber.shade300,
                                          width: 1.2,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 7,
                                            height: 7,
                                            decoration: BoxDecoration(
                                              color: isOnline ? Colors.green.shade600 : Colors.amber.shade700,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            isSyncing
                                                ? 'Syncing...'
                                                : isOnline
                                                    ? 'Online'
                                                    : 'Offline',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: isOnline ? Colors.green.shade800 : Colors.amber.shade900,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                          // Top-Center: Large Logo & Maraki Title
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 62,
                                height: 62,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.primary, width: 2.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.25),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: Padding(
                                    padding: const EdgeInsets.all(3),
                                    child: Image.asset(
                                      'assets/logo.png',
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, _, _) => const Icon(Icons.restaurant, color: AppColors.primary, size: 28),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'ማራኪ ካፌ እና ሬስቶራንት',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.obsidian,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const Text(
                                'MARAKI CAFE & RESTAURANT POS • ቦሌ ቅርንጫፍ',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppColors.primarySoft,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.calendar_today_rounded, size: 13, color: AppColors.primary),
                                    const SizedBox(width: 6),
                                    Text(
                                      DateHelper.todayFormatted(),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.obsidian,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // In-App OTA Update Banner
                      if (_updateInfo != null && _updateInfo!.hasUpdate) ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: _isDownloading ? const Color(0xFF1B5E20) : AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _isDownloading
                                  ? Colors.green.shade400
                                  : AppColors.primary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    _isDownloading
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          )
                                        : const Icon(Icons.system_update_alt_rounded, color: AppColors.primary, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _isDownloading
                                          ? Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  _downloadProgress > 0
                                                      ? 'እየተወረደ ነው… $_downloadProgress%'
                                                      : _downloadedBytes > 0
                                                          ? 'እየተወረደ ነው… ${(_downloadedBytes / 1024 / 1024).toStringAsFixed(1)} MB'
                                                          : 'ማዝሙር ማስጀመሪያ ደርሷል ⏳',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            )
                                          : Text(
                                              'አዲስ ስሪት ተገኝቷል (v${_updateInfo!.latestVersion})',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.obsidian,
                                              ),
                                            ),
                                    ),
                                    if (!_isDownloading)
                                      ElevatedButton(
                                        onPressed: () => _executeOtaDownload(_updateInfo!.apkUrl),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        child: const Text('አዘምን', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                      ),
                                  ],
                                ),
                              ),
                              if (_isDownloading) ...[
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                                  child: _downloadProgress > 0
                                      ? LinearProgressIndicator(
                                          value: _downloadProgress / 100,
                                          minHeight: 5,
                                          backgroundColor: Colors.green.shade900,
                                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                                        )
                                      : const LinearProgressIndicator(
                                          minHeight: 5,
                                          backgroundColor: Color(0xFF1B5E20),
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                                        ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],

                      // Hero Subtitle
                      const Text(
                        'The happiest hour of the day',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: AppColors.obsidian,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ትኩስ ጁሶች፣ ምግቦች እና ፈጣን የሽያጭ ስርዓት። የስራ ቦታዎን ይምረጡ።',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Interactive 3-Card Showcase
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 680;
                          return _buildInteractiveShowcase(pos, isDayActive, isNightActive, isNarrow);
                        },
                      ),

                      const SizedBox(height: 24),
                      const Divider(height: 1, color: Color(0xFFE2E8F0)),
                      const SizedBox(height: 14),

                      // Bottom Row: Admin Button on Bottom-Left, Motto on Bottom-Right
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 12,
                        runSpacing: 10,
                        children: [
                          // Bottom-Left Admin Button
                          InkWell(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => PinPadDialog(
                                  title: 'የአድሚን ዳሽቦርድ መግቢያ',
                                  subtitle: 'የአድሚን PIN ያስገቡ (ነባሪ PIN: ${pos.adminPin})',
                                  requiredPin: pos.adminPin,
                                  onConfirm: (pin) => pos.setMode(AppMode.admin),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.admin_panel_settings_rounded, size: 16, color: AppColors.primary),
                                  SizedBox(width: 6),
                                  Text(
                                    'አድሚን ዳሽቦርድ (PIN)',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.obsidian),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Bottom-Right Brand Motto
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: AppColors.primarySoft,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.stars_rounded, size: 14, color: AppColors.primary),
                                SizedBox(width: 6),
                                Text(
                                  '✨ ጥራት ያለው መስተንግዶ • ፈጣን አገልግሎት (v2.7.0)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.obsidian,
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
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Interactive 3-Card Carousel Builder
  Widget _buildInteractiveShowcase(POSProvider pos, bool isDayActive, bool isNightActive, bool isNarrow) {
    // Dynamic order: whichever card is active will be placed in the center!
    final List<GateShowcaseItem> orderedItems = [
      GateShowcaseItem.kitchen,
      GateShowcaseItem.dayShift,
      GateShowcaseItem.nightShift,
    ];

    // Rearrange so the active item is in the middle on wide screens
    if (!isNarrow) {
      orderedItems.remove(_activeItem);
      orderedItems.insert(1, _activeItem); // Place active in middle index 1
    }

    if (isNarrow) {
      return Column(
        children: orderedItems.map((item) {
          final isHighlighted = item == _activeItem;
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _buildShowcaseCard(
              item: item,
              isHighlighted: isHighlighted,
              pos: pos,
              isDayActive: isDayActive,
              isNightActive: isNightActive,
            ),
          );
        }).toList(),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: orderedItems[0] == _activeItem ? 4 : 3,
          child: _buildShowcaseCard(
            item: orderedItems[0],
            isHighlighted: orderedItems[0] == _activeItem,
            pos: pos,
            isDayActive: isDayActive,
            isNightActive: isNightActive,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          flex: orderedItems[1] == _activeItem ? 4 : 3,
          child: _buildShowcaseCard(
            item: orderedItems[1],
            isHighlighted: orderedItems[1] == _activeItem,
            pos: pos,
            isDayActive: isDayActive,
            isNightActive: isNightActive,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          flex: orderedItems[2] == _activeItem ? 4 : 3,
          child: _buildShowcaseCard(
            item: orderedItems[2],
            isHighlighted: orderedItems[2] == _activeItem,
            pos: pos,
            isDayActive: isDayActive,
            isNightActive: isNightActive,
          ),
        ),
      ],
    );
  }

  // Universal Card Component (Highlighted in Amber or Side Surface)
  Widget _buildShowcaseCard({
    required GateShowcaseItem item,
    required bool isHighlighted,
    required POSProvider pos,
    required bool isDayActive,
    required bool isNightActive,
  }) {
    String title;
    String subtitle;
    IconData icon;
    String hours;
    String status;
    String buttonText;
    VoidCallback onAction;

    switch (item) {
      case GateShowcaseItem.kitchen:
        title = 'የወጥ ቤት ማሳያ';
        subtitle = 'Kitchen Workspace';
        icon = Icons.restaurant_menu_rounded;
        hours = 'ቀጥታ ትዕዛዞች';
        status = '🟢 ዝግጁ (Ready)';
        buttonText = 'ወደ ኩሽና ግባ (ENTER)';
        onAction = () => pos.setMode(AppMode.kitchen);
        break;
      case GateShowcaseItem.dayShift:
        title = 'የቀን ሺፍት';
        subtitle = 'Day Shift Session';
        icon = Icons.wb_sunny_rounded;
        hours = DateHelper.dayShiftHours;
        status = isDayActive ? '🟢 ንቁ (Active)' : 'ዝግጁ (Ready)';
        buttonText = isDayActive ? 'ሺፍቱን ቀጥል (RESUME)' : 'ሺፍት ጀምር (START)';
        onAction = () => pos.selectShift(ShiftType.day);
        break;
      case GateShowcaseItem.nightShift:
        title = 'የማታ ሺፍት';
        subtitle = 'Night Shift Session';
        icon = Icons.nightlight_round;
        hours = DateHelper.nightShiftHours;
        status = isNightActive ? '🟢 ንቁ (Active)' : 'ዝግጁ (Ready)';
        buttonText = isNightActive ? 'ሺፍቱን ቀጥል (RESUME)' : 'ሺፍት ጀምር (START)';
        onAction = () => pos.selectShift(ShiftType.night);
        break;
    }

    if (isHighlighted) {
      // Golden Sunset Amber Dominant Hero Card
      return AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // Floating Visual Top
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, size: 36, color: AppColors.primary),
            ),
            const SizedBox(height: 14),

            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 14),

            // Meta Spec Box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  _buildSpecRow('ሰዓት/ሁኔታ', hours),
                  const Divider(color: Colors.white24, height: 10),
                  _buildSpecRow('ቦታ', 'ቦሌ (Bole)'),
                  const Divider(color: Colors.white24, height: 10),
                  _buildSpecRow('ስታተስ', status),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Big Action Button
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.obsidian,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      buttonText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.white),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Side Surface Card
    return InkWell(
      onTap: () => setState(() => _activeItem = item),
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 26, color: AppColors.obsidian),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: AppColors.obsidian,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 36,
              child: OutlinedButton(
                onPressed: () => setState(() => _activeItem = item),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: AppColors.border, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'ምረጥ (SELECT)',
                  style: TextStyle(
                    color: AppColors.obsidian,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecRow(String label, String val) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            val,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
