import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:scp_mobile_shared/models/order_model.dart';
import 'package:mocktail/mocktail.dart';
import '../lib/cubits/order_cubit.dart';
import '../lib/services/supplier_order_service.dart';

class MockSupplierOrderService extends Mock implements SupplierOrderServiceInterface {}

void main() {
  group('OrderCubit (Supplier)', () {
    setUpAll(() {
      registerFallbackValue(MockSupplierOrderService());
    });
    test('initial state is correct', () {
      final orderCubit = OrderCubit();
      expect(orderCubit.state.orders, isEmpty);
      expect(orderCubit.state.currentOrders, isEmpty);
      expect(orderCubit.state.isLoading, false);
      expect(orderCubit.state.error, isNull);
      orderCubit.close();
    });

    blocTest<OrderCubit, OrderState>(
      'loadOrderHistory loads orders successfully',
      build: () {
        final mockService = MockSupplierOrderService();
        when(() => mockService.getOrders(page: any(named: 'page'), pageSize: any(named: 'pageSize'))).thenAnswer(
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
        return OrderCubit(orderService: mockService);
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
      'loadOrderHistory handles errors correctly',
      build: () {
        final mockService = MockSupplierOrderService();
        when(() => mockService.getOrders(page: any(named: 'page'), pageSize: any(named: 'pageSize'))).thenThrow(
          Exception('Failed to load orders'),
        );
        return OrderCubit(orderService: mockService);
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
      'loadCurrentOrders filters pending and confirmed orders',
      build: () {
        final mockService = MockSupplierOrderService();
        when(() => mockService.getOrders(page: any(named: 'page'), pageSize: any(named: 'pageSize'))).thenAnswer(
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
            OrderModel(
              id: 'order2',
              orderNumber: 'ORD-002',
              supplierId: 'supplier1',
              supplierName: 'Test Supplier',
              items: [],
              subtotal: 200.0,
              tax: 20.0,
              shippingFee: 10.0,
              total: 230.0,
              status: OrderStatus.confirmed,
              orderDate: DateTime.now(),
            ),
            OrderModel(
              id: 'order3',
              orderNumber: 'ORD-003',
              supplierId: 'supplier1',
              supplierName: 'Test Supplier',
              items: [],
              subtotal: 300.0,
              tax: 30.0,
              shippingFee: 15.0,
              total: 345.0,
              status: OrderStatus.delivered,
              orderDate: DateTime.now(),
            ),
          ],
        );
        return OrderCubit(orderService: mockService);
      },
      act: (cubit) => cubit.loadCurrentOrders(),
      expect: () => [
        OrderState(isLoading: true, error: null),
        predicate<OrderState>((state) =>
          state.isLoading == false &&
          state.currentOrders.length == 2 &&
          state.currentOrders.every((o) =>
            o.status == OrderStatus.pending ||
            o.status == OrderStatus.confirmed ||
            o.status == OrderStatus.processing)),
      ],
    );

    blocTest<OrderCubit, OrderState>(
      'loadOrderDetails loads order details',
      build: () {
        final mockService = MockSupplierOrderService();
        when(() => mockService.getOrderDetails('order1')).thenAnswer(
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
        return OrderCubit(orderService: mockService);
      },
      act: (cubit) => cubit.loadOrderDetails('order1'),
      expect: () => [
        OrderState(isLoading: true, error: null),
        predicate<OrderState>((state) =>
          state.isLoading == false &&
          state.selectedOrder != null &&
          state.selectedOrder!.id == 'order1'),
      ],
    );

    blocTest<OrderCubit, OrderState>(
      'trackOrder loads order tracking info',
      build: () {
        final mockService = MockSupplierOrderService();
        when(() => mockService.trackOrder('order1')).thenAnswer(
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
            status: OrderStatus.processing,
            orderDate: DateTime.now(),
          ),
        );
        return OrderCubit(orderService: mockService);
      },
      act: (cubit) => cubit.trackOrder('order1'),
      expect: () => [
        OrderState(isLoading: true, error: null),
        predicate<OrderState>((state) =>
          state.isLoading == false &&
          state.selectedOrder != null &&
          state.selectedOrder!.id == 'order1'),
      ],
    );

    blocTest<OrderCubit, OrderState>(
      'clearSelectedOrder clears selected order',
      build: () => OrderCubit(),
      seed: () => OrderState(
        selectedOrder: OrderModel(
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
      ),
      act: (cubit) => cubit.clearSelectedOrder(),
      expect: () => [
        OrderState(selectedOrder: null),
      ],
    );
  });
}

