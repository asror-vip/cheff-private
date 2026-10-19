import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'features/dashboard/presentation/pages/main_layout.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/recipes/presentation/providers/recipes_provider.dart';
import 'features/inventory/presentation/providers/inventory_provider.dart';
import 'features/purchases/presentation/providers/purchases_provider.dart';
import 'features/sales/presentation/providers/sales_provider.dart';
import 'features/finance/presentation/providers/finance_provider.dart';
import 'features/staff/presentation/providers/staff_provider.dart';
import 'features/production/presentation/providers/production_provider.dart';
import 'features/pos/presentation/providers/pos_provider.dart';
import 'features/inventory/presentation/providers/reviziya_provider.dart';
import 'features/tables/presentation/providers/tables_provider.dart';

import 'core/session/session_manager.dart';
import 'core/audit/audit_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");
  
  // Initialize Supabase only if keys are available
  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseKey = dotenv.env['SUPABASE_ANON_KEY'] ?? dotenv.env['BOT_TOKEN'] ?? '';
  
  if (supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty) {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabaseKey,
    );
  } else {
    debugPrint('Supabase keys not found in .env, skipping initialization.');
  }

  await EasyLocalization.ensureInitialized();
  await SessionManager().init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SessionManager()),
        ChangeNotifierProvider(create: (_) => AuditService()),
        ChangeNotifierProvider(create: (_) => RecipesProvider()),
        ChangeNotifierProvider(create: (_) => InventoryProvider()),
        ChangeNotifierProvider(create: (_) => PurchasesProvider()),
        ChangeNotifierProvider(create: (_) => SalesProvider()),
        ChangeNotifierProvider(create: (_) => FinanceProvider()),
        ChangeNotifierProvider(create: (_) => StaffProvider()),
        ChangeNotifierProvider(create: (_) => ProductionProvider()),
        ChangeNotifierProvider(create: (_) => PosProvider()),
        ChangeNotifierProvider(create: (_) => TablesProvider()),
        ChangeNotifierProxyProvider<InventoryProvider, ReviziyaProvider>(
          create: (context) => ReviziyaProvider(context.read<InventoryProvider>()),
          update: (context, inventoryProvider, previous) => previous ?? ReviziyaProvider(inventoryProvider),
        ),
      ],
      child: EasyLocalization(
        supportedLocales: const [
          Locale('uz'), 
          Locale('ru'), 
          Locale('en'),
          Locale('uz', 'Cyrl')
        ],
        path: 'assets/translations',
        fallbackLocale: const Locale('uz'),
        startLocale: const Locale('uz'),
        child: const ChefControlApp(),
      ),
    ),
  );
}

class ChefControlApp extends StatelessWidget {
  const ChefControlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChefControl AI',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: AppTheme.darkTheme,
      home: Consumer<SessionManager>(
        builder: (context, session, _) {
          if (session.isLoggedIn) {
            return MainLayout(key: ValueKey('main_${context.locale.toString()}'));
          }
          return const LoginPage();
        },
      ),
    );
  }
}
