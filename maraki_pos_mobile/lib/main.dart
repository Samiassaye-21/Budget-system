import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/models.dart';
import 'providers/pos_provider.dart';
import 'views/shift_gate_view.dart';
import 'views/cup_setup_view.dart';
import 'views/pos_workspace_view.dart';
import 'views/kitchen_workspace_view.dart';
import 'views/admin_dashboard_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => POSProvider()),
      ],
      child: const MarakiPOSApp(),
    ),
  );
}

class MarakiPOSApp extends StatelessWidget {
  const MarakiPOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Maraki POS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE53E3E),
          primary: const Color(0xFFE53E3E),
          secondary: const Color(0xFFC05621),
        ),
        scaffoldBackgroundColor: const Color(0xFFF7FAFC),
      ),
      home: const MainRouter(),
    );
  }
}

class MainRouter extends StatelessWidget {
  const MainRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final pos = context.watch<POSProvider>();

    switch (pos.mode) {
      case AppMode.gate:
        return const ShiftGateView();
      case AppMode.cups:
        return const CupSetupView();
      case AppMode.pos:
        return const POSWorkspaceView();
      case AppMode.kitchen:
        return const KitchenWorkspaceView();
      case AppMode.admin:
        return const AdminDashboardView();
    }
  }
}
