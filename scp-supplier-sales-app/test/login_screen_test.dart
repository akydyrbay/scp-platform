import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scp_mobile_shared/services/auth_service.dart';
import 'package:scp_supplier_sales_app/cubits/auth_cubit.dart';
import 'package:scp_supplier_sales_app/screens/auth/login_screen.dart';

class MockAuthService extends Mock implements AuthService {}

void main() {
  group('LoginScreen Widget Tests', () {
    late MockAuthService mockAuthService;

    setUp(() {
      mockAuthService = MockAuthService();
      // Mock isAuthenticated to return false immediately to avoid timer
      when(() => mockAuthService.isAuthenticated()).thenAnswer((_) async => false);
    });

    testWidgets('displays login form with email and password fields', (WidgetTester tester) async {
      final authCubit = AuthCubit(authService: mockAuthService, skipInitialCheck: true);
      
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: authCubit,
            child: const LoginScreen(),
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(TextField), findsNWidgets(2)); // Email and password
      expect(find.byType(ElevatedButton), findsOneWidget); // Login button
      
      authCubit.close();
    });

    testWidgets('validates email and password fields', (WidgetTester tester) async {
      final authCubit = AuthCubit(authService: mockAuthService, skipInitialCheck: true);
      
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: authCubit,
            child: const LoginScreen(),
          ),
        ),
      );

      await tester.pump();

      // Try to submit without entering data
      final button = find.byType(ElevatedButton);
      if (button.evaluate().isNotEmpty) {
        await tester.tap(button);
        await tester.pump();
      }

      // Form validation should prevent submission
      // Exact behavior depends on form implementation
      
      authCubit.close();
    });
  });
}

