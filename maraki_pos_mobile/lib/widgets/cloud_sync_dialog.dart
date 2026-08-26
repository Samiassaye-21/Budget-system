import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pos_provider.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';

class CloudSyncDialog extends StatefulWidget {
  const CloudSyncDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => const CloudSyncDialog(),
    );
  }

  @override
  State<CloudSyncDialog> createState() => _CloudSyncDialogState();
}

class _CloudSyncDialogState extends State<CloudSyncDialog> {
  bool _isTesting = false;
  String? _statusMessage;
  bool _showAdvanced = false;

  late TextEditingController _urlController;
  late TextEditingController _keyController;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: SupabaseService.instance.supabaseUrl);
    _keyController = TextEditingController(text: SupabaseService.instance.anonKey);
    _testConnection();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _statusMessage = null;
    });

    final pos = Provider.of<POSProvider>(context, listen: false);
    final isOnline = await SupabaseService.instance.checkConnection();
    if (isOnline) {
      await pos.syncAllFromCloud();
    }

    if (mounted) {
      setState(() {
        _isTesting = false;
        _statusMessage = isOnline
            ? '✓ ከ Supabase ክላውድ ጋር በተሳካ ሁኔታ ተገናኝቷል! (${SupabaseService.instance.lastLatencyMs} ms)'
            : '⚠️ ግንኙነት አልተገኘም። በኦፍላይን ሞድ ይሰራል፤ ዳታው በሎካል ተቀምጧል።';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pos = Provider.of<POSProvider>(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: 480,
        constraints: const BoxConstraints(maxHeight: 650),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: const BoxDecoration(
                color: AppColors.obsidian,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.cloud_sync_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'የክላውድ ሲስተም እና ኦንላይን ሁኔታ',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                        Text(
                          'Supabase Real-Time Sync Status',
                          style: TextStyle(fontSize: 11, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                    splashRadius: 20,
                  ),
                ],
              ),
            ),

            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main Status Card
                    ValueListenableBuilder<SupabaseSyncStatus>(
                      valueListenable: SupabaseService.instance.statusNotifier,
                      builder: (_, status, _) {
                        final isOnline = status == SupabaseSyncStatus.online;
                        final isSyncing = status == SupabaseSyncStatus.syncing || _isTesting;

                        return Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isOnline
                                  ? [const Color(0xFFF0FDF4), const Color(0xFFDCFCE7)]
                                  : [const Color(0xFFFFFBEB), const Color(0xFFFEF3C7)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isOnline ? const Color(0xFF86EFAC) : const Color(0xFFFDE68A),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: isOnline ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: (isOnline ? const Color(0xFF16A34A) : const Color(0xFFD97706))
                                              .withValues(alpha: 0.5),
                                          blurRadius: 8,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    isSyncing
                                        ? 'በማመሳሰል ላይ... (Syncing)'
                                        : isOnline
                                            ? 'ኦንላይን ተገናኝቷል (Online)'
                                            : 'ኦፍላይን ሞድ (Offline Mode)',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: isOnline ? const Color(0xFF14532D) : const Color(0xFF78350F),
                                    ),
                                  ),
                                  const Spacer(),
                                  if (isOnline && SupabaseService.instance.lastLatencyMs > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.8),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '⚡ ${SupabaseService.instance.lastLatencyMs} ms',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF15803D),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                isOnline
                                    ? 'የኩሽና ትዕዛዞች፣ ሽያጮች እና የብድር መረጃዎች ከክላውድ ጋር በቀጥታ ይገናኛሉ።'
                                    : 'ኢንተርኔት በማይኖርበት ጊዜ ሲስተሙ ሙሉ በሙሉ በሎካል ይሰራል፤ ኢንተርኔት ሲመጣ ራሱ ያመሳስላል።',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isOnline ? const Color(0xFF166534) : const Color(0xFF92400E),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    if (_statusMessage != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _statusMessage!,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                        ),
                      ),
                    ],

                    const SizedBox(height: 18),

                    // Metrics Grid
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricTile(
                            title: 'የኩሽና ቲኬቶች',
                            value: '${pos.kitchenTickets.length}',
                            subtitle: 'በሲስተሙ ያሉ',
                            icon: Icons.soup_kitchen_rounded,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildMetricTile(
                            title: 'ጠቅላላ ትዕዛዞች',
                            value: '${pos.orders.length}',
                            subtitle: 'የተመዘገቡ',
                            icon: Icons.receipt_long_rounded,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildMetricTile(
                            title: 'የቀሩ ዳታዎች',
                            value: '${SupabaseService.instance.pendingQueueCount}',
                            subtitle: 'በጥበቃ ላይ',
                            icon: Icons.hourglass_top_rounded,
                            color: SupabaseService.instance.pendingQueueCount > 0 ? Colors.amber.shade800 : Colors.green,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Manual Sync Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _isTesting ? null : _testConnection,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 2,
                        ),
                        icon: _isTesting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.refresh_rounded, color: Colors.white),
                        label: Text(
                          _isTesting ? 'በማመሳሰል ላይ...' : 'አሁን አመሳስል (Sync Now)',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    const Divider(),

                    // Advanced Project Details Toggle
                    InkWell(
                      onTap: () => setState(() => _showAdvanced = !_showAdvanced),
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.settings_ethernet_rounded, size: 16, color: AppColors.slate),
                                SizedBox(width: 8),
                                Text(
                                  'የክላውድ ዳታቤዝ አድራሻ (Cloud Host Info)',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.slate),
                                ),
                              ],
                            ),
                            Icon(
                              _showAdvanced ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                              size: 20,
                              color: AppColors.slate,
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (_showAdvanced) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Supabase Project URL:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.slate)),
                            const SizedBox(height: 4),
                            SelectableText(
                              SupabaseService.instance.supabaseUrl,
                              style: const TextStyle(fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.bold, color: AppColors.obsidian),
                            ),
                            const SizedBox(height: 12),
                            const Text('Anon Public Key:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.slate)),
                            const SizedBox(height: 4),
                            SelectableText(
                              '${SupabaseService.instance.anonKey.substring(0, 30)}... [Active]',
                              style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.obsidian),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 9, color: AppColors.slate),
          ),
        ],
      ),
    );
  }
}
