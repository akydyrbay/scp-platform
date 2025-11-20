import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scp_supplier_sales_app/cubits/order_cubit.dart';
import 'package:scp_supplier_sales_app/screens/order/orders_screen.dart';

void main() {
  group('OrdersScreen Widget Tests', () {
    testWidgets('displays orders screen', (WidgetTester tester) async {
      final orderCubit = OrderCubit();
      
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: orderCubit,
            child: const OrdersScreen(),
          ),
        ),
      );

      expect(find.byType(OrdersScreen), findsOneWidget);
      
      orderCubit.close();
      await tester.pump(const Duration(milliseconds: 100));
    });
  });
}

