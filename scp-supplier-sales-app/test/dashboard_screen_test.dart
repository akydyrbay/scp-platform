import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scp_supplier_sales_app/cubits/dashboard_cubit.dart';
import 'package:scp_supplier_sales_app/screens/dashboard/dashboard_screen.dart';

void main() {
  group('DashboardScreen Widget Tests', () {
    testWidgets('displays dashboard screen', (WidgetTester tester) async {
      final dashboardCubit = DashboardCubit();
      
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: dashboardCubit,
            child: const SupplierDashboardScreen(),
          ),
        ),
      );

      expect(find.byType(SupplierDashboardScreen), findsOneWidget);
      
      dashboardCubit.close();
      await tester.pump(const Duration(milliseconds: 100));
    });
  });
}

