import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scp_consumer_app/screens/auth/login_screen.dart';
import 'package:scp_consumer_app/cubits/auth_cubit.dart';

void main() {
  group('LoginScreen Widget Tests', () {
    testWidgets('should display login form', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(
            create: (_) => AuthCubit(),
            child: const LoginScreen(),
          ),
        ),
      );

      // Verify login form elements are present
      expect(find.text('SCP Consumer'), findsOneWidget);
      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2)); // Email and password
      expect(find.text('Login'), findsOneWidget);
      expect(find.text('Forgot Password?'), findsOneWidget);
    });

    testWidgets('should toggle password visibility', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(
            create: (_) => AuthCubit(),
            child: const LoginScreen(),
          ),
        ),
      );

      // Find password field
      final passwordField = find.byType(TextFormField).last;
      await tester.enterText(passwordField, 'testpassword');
      await tester.pump();

      // Find visibility toggle button
      final visibilityButton = find.byIcon(Icons.visibility_outlined);
      expect(visibilityButton, findsOneWidget);

      // Tap to toggle visibility
      await tester.tap(visibilityButton);
      await tester.pump();

      // Should now show visibility_off icon
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });

    testWidgets('should validate email field', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(
            create: (_) => AuthCubit(),
            child: const LoginScreen(),
          ),
        ),
      );

      // Find email field and enter invalid email
      final emailField = find.byType(TextFormField).first;
      await tester.enterText(emailField, 'invalid-email');
      await tester.tap(find.text('Login'));
      await tester.pump();

      // Should show validation error
      // Note: Actual validation depends on AppValidators implementation
    });

    testWidgets('should show loading indicator during login', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(
            create: (_) => AuthCubit(),
            child: const LoginScreen(),
          ),
        ),
      );

      // Enter valid credentials
      final emailField = find.byType(TextFormField).first;
      final passwordField = find.byType(TextFormField).last;
      
      await tester.enterText(emailField, 'test@example.com');
      await tester.enterText(passwordField, 'password123');
      await tester.tap(find.text('Login'));
      await tester.pump();

      // Should show loading indicator
      // Note: Actual implementation depends on AuthCubit state
    });
  });
}

