import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'generated/l10n/app_localizations.dart';
import 'package:scp_mobile_shared/scp_mobile_shared.dart';

// Config

// Cubits
import 'cubits/auth_cubit.dart';
import 'cubits/product_cubit.dart';
import 'cubits/supplier_cubit.dart';
import 'cubits/order_cubit.dart';
import 'cubits/chat_cubit.dart';
import 'cubits/cart_cubit.dart';
import 'cubits/notification_cubit.dart';

// Screens
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/order/orders_screen.dart';
import 'screens/chat/chat_list_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/supplier/supplier_discovery_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enhanced error handling with logging
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    // Always log errors, even in release mode (for debugging)
    print('═══════════════════════════════════════');
    print('❌ FLUTTER ERROR');
    print('═══════════════════════════════════════');
    print('Exception: ${details.exception}');
    print('Library: ${details.library}');
    print('Context: ${details.context}');
    if (details.stack != null) {
      print('Stack: ${details.stack}');
    }
    print('═══════════════════════════════════════');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    print('═══════════════════════════════════════');
    print('❌ PLATFORM ERROR');
    print('═══════════════════════════════════════');
    print('Error: $error');
    print('Stack: $stack');
    print('═══════════════════════════════════════');
    return true;
  };

  // Enhanced startup logging
  print('🚀 [APP] Starting SCP Consumer App...');
  print('📱 [APP] Flutter binding initialized');

  try {
    // Initialize app configuration (environment, etc.) - this is fast
    print('⚙️  [APP] Initializing AppConfig...');
    AppConfig.initialize();
    print('✅ [APP] AppConfig initialized');
    print('🌐 [APP] API Base URL: ${AppConfig.baseUrl}');
    print('🔧 [APP] Environment: ${AppConfig.environment}');

    // Initialize storage service with timeout to prevent blocking
    // If storage init fails, app can still start
    print('💾 [APP] Initializing storage service...');
    try {
    final storageService = StorageService();
      await storageService.init().timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          print('⚠️  [APP] Storage initialization timeout - continuing anyway');
        },
      );
      print('✅ [APP] Storage service initialized');
    } catch (e) {
      print('⚠️  [APP] Storage initialization error (non-fatal): $e');
      // Continue anyway - storage might work later
    }

    // Start app immediately - don't wait for anything else
    // This prevents Android from killing the app (3 second timeout)
    print('🎨 [APP] Starting Flutter app widget tree...');
    runApp(const SCPConsumerApp());
    print('✅ [APP] Flutter app started successfully');
  } catch (e, stackTrace) {
    print('═══════════════════════════════════════');
    print('❌ [APP] FATAL ERROR DURING INITIALIZATION');
    print('═══════════════════════════════════════');
    print('Error: $e');
      print('Stack trace: $stackTrace');
    print('═══════════════════════════════════════');
    // Run app with error widget to show user-friendly message
    runApp(const ErrorApp());
  }
}

class SCPConsumerApp extends StatelessWidget {
  const SCPConsumerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => AuthCubit(),
        ),
        BlocProvider(
          create: (context) => ProductCubit(),
        ),
        BlocProvider(
          create: (context) => SupplierCubit(),
        ),
        BlocProvider(
          create: (context) => OrderCubit(),
        ),
        BlocProvider(
          create: (context) => ChatCubit(),
        ),
        BlocProvider(
          create: (context) => CartCubit(),
        ),
        BlocProvider(
          create: (context) => NotificationCubit(),
        ),
      ],
      child: MaterialApp(
        title: 'SCP Consumer',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        
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
            // Show loading screen while checking auth status
            if (state.isLoading) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }
            
            if (state.isAuthenticated) {
              return const MainScreen();
            }
            return const LoginScreen();
          },
        ),
      ),
    );
  }
}

/// Error widget shown when app fails to initialize
class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SCP Consumer',
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.error_outline, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  'App Initialization Error',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'The app encountered an error during startup. Please try again or contact support.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Main screen with bottom navigation
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    OrdersScreen(),
    ChatListScreen(),
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
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SupplierDiscoveryScreen(),
                  ),
                );
              },
              tooltip: 'Find Suppliers',
              child: const Icon(Icons.search),
            )
          : null,
    );
  }
}
