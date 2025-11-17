import 'package:flutter_test/flutter_test.dart';
import 'package:scp_mobile_shared/services/order_service.dart';
import 'package:scp_mobile_shared/services/http_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';

class MockHttpService extends Mock implements HttpService {}

void main() {
  group('OrderService', () {
    late OrderService orderService;
    late MockHttpService mockHttpService;

    setUp(() {
      mockHttpService = MockHttpService();
      orderService = OrderService(httpService: mockHttpService);
    });

    test('getOrderHistory handles paginated response format', () async {
      when(() => mockHttpService.get(
        '/consumer/orders',
        queryParameters: any(named: 'queryParameters'),
      )).thenAnswer(
        (_) async => Response(
          data: {
            'results': [
              {
                'id': 'order1',
                'order_number': 'ORD-001',
                'supplier_id': 'supplier1',
                'supplier_name': 'Test Supplier',
                'items': [],
                'subtotal': 100.0,
                'tax': 10.0,
                'shipping_fee': 5.0,
                'total': 115.0,
                'status': 'pending',
                'order_date': DateTime.now().toIso8601String(),
                'created_at': DateTime.now().toIso8601String(),
              },
            ],
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/consumer/orders'),
        ),
      );

      final orders = await orderService.getOrderHistory();
      expect(orders.length, 1);
      expect(orders.first.id, 'order1');
    });

    test('getOrderHistory handles wrapped data format', () async {
      when(() => mockHttpService.get(
        '/consumer/orders',
        queryParameters: any(named: 'queryParameters'),
      )).thenAnswer(
        (_) async => Response(
          data: {
            'data': [
              {
                'id': 'order1',
                'order_number': 'ORD-001',
                'supplier_id': 'supplier1',
                'supplier_name': 'Test Supplier',
                'items': [],
                'subtotal': 100.0,
                'tax': 10.0,
                'shipping_fee': 5.0,
                'total': 115.0,
                'status': 'pending',
                'order_date': DateTime.now().toIso8601String(),
                'created_at': DateTime.now().toIso8601String(),
              },
            ],
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/consumer/orders'),
        ),
      );

      final orders = await orderService.getOrderHistory();
      expect(orders.length, 1);
      expect(orders.first.id, 'order1');
    });

    test('getCurrentOrders handles paginated response format', () async {
      when(() => mockHttpService.get('/consumer/orders/current')).thenAnswer(
        (_) async => Response(
          data: {
            'results': [
              {
                'id': 'order1',
                'order_number': 'ORD-001',
                'supplier_id': 'supplier1',
                'supplier_name': 'Test Supplier',
                'items': [],
                'subtotal': 100.0,
                'tax': 10.0,
                'shipping_fee': 5.0,
                'total': 115.0,
                'status': 'pending',
                'order_date': DateTime.now().toIso8601String(),
                'created_at': DateTime.now().toIso8601String(),
              },
            ],
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/consumer/orders/current'),
        ),
      );

      final orders = await orderService.getCurrentOrders();
      expect(orders.length, 1);
      expect(orders.first.id, 'order1');
    });

    test('getOrderDetails handles wrapped response format', () async {
      when(() => mockHttpService.get('/consumer/orders/order1')).thenAnswer(
        (_) async => Response(
          data: {
            'data': {
              'id': 'order1',
              'order_number': 'ORD-001',
              'supplier_id': 'supplier1',
              'supplier_name': 'Test Supplier',
              'items': [],
              'subtotal': 100.0,
              'tax': 10.0,
              'shipping_fee': 5.0,
              'total': 115.0,
              'status': 'pending',
              'order_date': DateTime.now().toIso8601String(),
              'created_at': DateTime.now().toIso8601String(),
            },
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/consumer/orders/order1'),
        ),
      );

      final order = await orderService.getOrderDetails('order1');
      expect(order.id, 'order1');
    });

    test('getOrderHistory handles errors correctly', () async {
      when(() => mockHttpService.get(
        '/consumer/orders',
        queryParameters: any(named: 'queryParameters'),
      )).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/consumer/orders'),
          response: Response(
            statusCode: 500,
            requestOptions: RequestOptions(path: '/consumer/orders'),
          ),
        ),
      );

      expect(
        () => orderService.getOrderHistory(),
        throwsA(isA<Exception>()),
      );
    });
  });
}

