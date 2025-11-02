import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'generated/l10n/app_localizations.dart';
import 'package:scp_mobile_shared/scp_mobile_shared.dart';

// Config

// Cubits
import 'cubits/auth_cubit.dart';
import 'cubits/dashboard_cubit.dart';
import 'cubits/chat_sales_cubit.dart';
import 'cubits/order_cubit.dart';

// Screens
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/chat/chat_list_screen.dart';
import 'screens/order/orders_screen.dart';
import 'screens/profile/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize app configuration (environment, etc.)
  AppConfig.initialize();

  // Initialize storage service
  final storageService = StorageService();
  await storageService.init();

  runApp(const SupplierSalesApp());
}

class SupplierSalesApp extends StatelessWidget {
  const SupplierSalesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => AuthCubit(),
        ),
        BlocProvider(
          create: (context) => DashboardCubit(),
        ),
        BlocProvider(
          create: (context) => ChatSalesCubit(),
        ),
        BlocProvider(
          create: (context) => OrderCubit(),
        ),
      ],
      child: MaterialApp(
        title: 'SCP Supplier Sales',
        debugShowCheckedModeBanner: false,
        theme: AppThemeSupplier.lightTheme,
        
        // Localization
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en', ''), // English
          Locale('ru', ''), // Russian
          Locale('kk', ''), // Kazakh
        ],
        
        home: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            if (state.isAuthenticated) {
              return const SupplierMainScreen();
            }
            return const LoginScreen();
          },
        ),
      ),
    );
  }
}

/// Main screen with bottom navigation for Supplier Sales App
class SupplierMainScreen extends StatefulWidget {
  const SupplierMainScreen({super.key});

  @override
  State<SupplierMainScreen> createState() => _SupplierMainScreenState();
}

class _SupplierMainScreenState extends State<SupplierMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    SupplierDashboardScreen(),
    ChatListScreen(),
    OrdersScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Chats',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

