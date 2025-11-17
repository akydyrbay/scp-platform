import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:scp_mobile_shared/models/order_model.dart';
import 'package:scp_mobile_shared/services/order_service.dart';
import 'package:mocktail/mocktail.dart';
import '../lib/cubits/order_cubit.dart';

class MockOrderService extends Mock implements OrderService {}

void main() {
  group('OrderCubit', () {
    late OrderCubit orderCubit;
    late MockOrderService mockOrderService;

    setUp(() {
      mockOrderService = MockOrderService();
      orderCubit = OrderCubit(orderService: mockOrderService);
    });

    tearDown(() {
      orderCubit.close();
    });

    test('initial state is correct', () {
      expect(orderCubit.state.orders, isEmpty);
      expect(orderCubit.state.currentOrders, isEmpty);
      expect(orderCubit.state.isLoading, false);
      expect(orderCubit.state.error, isNull);
    });

    blocTest<OrderCubit, OrderState>(
      'loadOrderHistory loads orders successfully',
      build: () {
        when(() => mockOrderService.getOrderHistory()).thenAnswer(
          (_) async => [
            OrderModel(
              id: 'order1',
              orderNumber: 'ORD-001',
              supplierId: 'supplier1',
              supplierName: 'Test Supplier',
              items: [],
              subtotal: 100.0,
              tax: 10.0,
              shippingFee: 5.0,
              total: 115.0,
              status: OrderStatus.pending,
              orderDate: DateTime.now(),
            ),
          ],
        );
        return orderCubit;
      },
      act: (cubit) => cubit.loadOrderHistory(),
      expect: () => [
        OrderState(isLoading: true, error: null),
        predicate<OrderState>((state) =>
          state.isLoading == false &&
          state.orders.length == 1 &&
          state.orders.first.id == 'order1' &&
          state.orders.first.orderNumber == 'ORD-001' &&
          state.orders.first.supplierId == 'supplier1' &&
          state.orders.first.supplierName == 'Test Supplier' &&
          state.orders.first.total == 115.0 &&
          state.orders.first.status == OrderStatus.pending),
      ],
    );

    blocTest<OrderCubit, OrderState>(
      'loadCurrentOrders loads current orders successfully',
      build: () {
        when(() => mockOrderService.getCurrentOrders()).thenAnswer(
          (_) async => [
            OrderModel(
              id: 'order1',
              orderNumber: 'ORD-001',
              supplierId: 'supplier1',
              supplierName: 'Test Supplier',
              items: [],
              subtotal: 100.0,
              tax: 10.0,
              shippingFee: 5.0,
              total: 115.0,
              status: OrderStatus.pending,
              orderDate: DateTime.now(),
            ),
          ],
        );
        return orderCubit;
      },
      act: (cubit) => cubit.loadCurrentOrders(),
      expect: () => [
        OrderState(isLoading: true, error: null),
        predicate<OrderState>((state) =>
          state.isLoading == false &&
          state.currentOrders.length == 1 &&
          state.currentOrders.first.id == 'order1' &&
          state.currentOrders.first.orderNumber == 'ORD-001' &&
          state.currentOrders.first.supplierId == 'supplier1' &&
          state.currentOrders.first.supplierName == 'Test Supplier' &&
          state.currentOrders.first.total == 115.0 &&
          state.currentOrders.first.status == OrderStatus.pending),
      ],
    );

    blocTest<OrderCubit, OrderState>(
      'loadOrderHistory handles errors correctly',
      build: () {
        when(() => mockOrderService.getOrderHistory()).thenThrow(
          Exception('Failed to load orders'),
        );
        return orderCubit;
      },
      act: (cubit) => cubit.loadOrderHistory(),
      expect: () => [
        OrderState(isLoading: true, error: null),
        OrderState(
          isLoading: false,
          error: 'Exception: Failed to load orders',
        ),
      ],
    );

    blocTest<OrderCubit, OrderState>(
      'loadOrderDetails loads order details successfully',
      build: () {
        when(() => mockOrderService.getOrderDetails('order1')).thenAnswer(
          (_) async => OrderModel(
            id: 'order1',
            orderNumber: 'ORD-001',
            supplierId: 'supplier1',
            supplierName: 'Test Supplier',
            items: [],
            subtotal: 100.0,
            tax: 10.0,
            shippingFee: 5.0,
            total: 115.0,
            status: OrderStatus.pending,
            orderDate: DateTime.now(),
          ),
        );
        return orderCubit;
      },
      act: (cubit) => cubit.loadOrderDetails('order1'),
      expect: () => [
        OrderState(isLoading: true, error: null),
        predicate<OrderState>((state) =>
          state.isLoading == false &&
          state.selectedOrder != null &&
          state.selectedOrder!.id == 'order1' &&
          state.selectedOrder!.orderNumber == 'ORD-001' &&
          state.selectedOrder!.supplierId == 'supplier1' &&
          state.selectedOrder!.supplierName == 'Test Supplier' &&
          state.selectedOrder!.total == 115.0 &&
          state.selectedOrder!.status == OrderStatus.pending),
      ],
    );
  });
}

