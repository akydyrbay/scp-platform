import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:scp_mobile_shared/models/order_model.dart';
import 'package:scp_supplier_sales_app/services/supplier_order_service.dart';
import 'package:mocktail/mocktail.dart';
import '../lib/cubits/order_cubit.dart';

class MockSupplierOrderService extends Mock implements SupplierOrderServiceInterface {
  @override
  Future<List<OrderModel>> getOrders({int page = 1, int pageSize = 20}) => super.noSuchMethod(
        Invocation.method(#getOrders, [], {#page: page, #pageSize: pageSize}),
        returnValue: Future.value(<OrderModel>[]),
      ) as Future<List<OrderModel>>;

  @override
  Future<OrderModel> getOrderDetails(String orderId) => super.noSuchMethod(
        Invocation.method(#getOrderDetails, [orderId]),
        returnValue: Future.value(OrderModel(
          id: orderId,
          orderNumber: 'ORD-001',
          supplierId: 'supplier1',
          supplierName: 'Test Supplier',
          items: [],
          subtotal: 0.0,
          tax: 0.0,
          shippingFee: 0.0,
          total: 0.0,
          status: OrderStatus.pending,
          orderDate: DateTime.now(),
        )),
      ) as Future<OrderModel>;

  @override
  Future<OrderModel> trackOrder(String orderId) => super.noSuchMethod(
        Invocation.method(#trackOrder, [orderId]),
        returnValue: Future.value(OrderModel(
          id: orderId,
          orderNumber: 'ORD-001',
          supplierId: 'supplier1',
          supplierName: 'Test Supplier',
          items: [],
          subtotal: 0.0,
          tax: 0.0,
          shippingFee: 0.0,
          total: 0.0,
          status: OrderStatus.pending,
          orderDate: DateTime.now(),
        )),
      ) as Future<OrderModel>;

  @override
  Future<OrderModel> placeOrder({
    required String supplierId,
    required List<Map<String, dynamic>> items,
    ShippingAddress? shippingAddress,
    String? notes,
  }) => super.noSuchMethod(
        Invocation.method(#placeOrder, [], {
          #supplierId: supplierId,
          #items: items,
          #shippingAddress: shippingAddress,
          #notes: notes,
        }),
        returnValue: Future.value(OrderModel(
          id: 'order1',
          orderNumber: 'ORD-001',
          supplierId: supplierId,
          supplierName: 'Test Supplier',
          items: [],
          subtotal: 0.0,
          tax: 0.0,
          shippingFee: 0.0,
          total: 0.0,
          status: OrderStatus.pending,
          orderDate: DateTime.now(),
        )),
      ) as Future<OrderModel>;

  @override
  Future<void> cancelOrder(String orderId) => super.noSuchMethod(
        Invocation.method(#cancelOrder, [orderId]),
        returnValue: Future.value(),
      ) as Future<void>;
}

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
        when(() => mockService.getOrders()).thenAnswer(
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
        when(() => mockService.getOrders()).thenThrow(
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
  });
}

