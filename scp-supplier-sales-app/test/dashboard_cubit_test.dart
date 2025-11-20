import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scp_mobile_shared/models/conversation_model.dart';
import 'package:scp_mobile_shared/models/order_model.dart';
import 'package:scp_mobile_shared/models/notification_model.dart';
import 'package:scp_mobile_shared/services/chat_service_sales.dart';
import 'package:scp_mobile_shared/services/notification_service.dart';
import '../lib/cubits/dashboard_cubit.dart';
import '../lib/services/supplier_order_service.dart';

class MockChatServiceSales extends Mock implements ChatServiceSales {}
class MockSupplierOrderService extends Mock implements SupplierOrderService {}
class MockNotificationService extends Mock implements NotificationService {}

void main() {
  group('DashboardCubit', () {
    late DashboardCubit dashboardCubit;
    late MockChatServiceSales mockChatService;
    late MockSupplierOrderService mockOrderService;
    late MockNotificationService mockNotificationService;

    setUp(() {
      mockChatService = MockChatServiceSales();
      mockOrderService = MockSupplierOrderService();
      mockNotificationService = MockNotificationService();
      dashboardCubit = DashboardCubit(
        chatService: mockChatService,
        orderService: mockOrderService,
        notificationService: mockNotificationService,
      );
    });

    tearDown(() {
      dashboardCubit.close();
    });

    test('initial state is correct', () {
      expect(dashboardCubit.state.conversations, isEmpty);
      expect(dashboardCubit.state.recentOrders, isEmpty);
      expect(dashboardCubit.state.notifications, isEmpty);
      expect(dashboardCubit.state.unreadMessagesCount, 0);
      expect(dashboardCubit.state.newOrdersCount, 0);
      expect(dashboardCubit.state.isLoading, false);
      expect(dashboardCubit.state.error, isNull);
    });

    blocTest<DashboardCubit, DashboardState>(
      'loadDashboard loads all data successfully',
      build: () {
        when(() => mockChatService.getConversations()).thenAnswer(
          (_) async => [
            ConversationModelSales(
              id: 'conv1',
              consumerId: 'consumer1',
              consumerName: 'Test Consumer',
              lastMessage: 'Hello',
              lastMessageTime: DateTime.now(),
              unreadCount: 2,
              createdAt: DateTime.now(),
            ),
            ConversationModelSales(
              id: 'conv2',
              consumerId: 'consumer2',
              consumerName: 'Another Consumer',
              lastMessage: 'Hi',
              lastMessageTime: DateTime.now(),
              unreadCount: 3,
              createdAt: DateTime.now(),
            ),
          ],
        );
        when(() => mockOrderService.getOrders(page: 1, pageSize: 5)).thenAnswer(
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
          ],
        );
        when(() => mockNotificationService.getNotifications(unreadOnly: true)).thenAnswer(
          (_) async => [
            NotificationModel(
              id: 'notif1',
              title: 'New Order',
              body: 'You have a new order',
              type: NotificationType.orderUpdate,
              targetId: 'order1',
              data: {},
              isRead: false,
              createdAt: DateTime.now(),
            ),
          ],
        );
        return dashboardCubit;
      },
      act: (cubit) => cubit.loadDashboard(),
      expect: () => [
        DashboardState(isLoading: true, error: null),
        predicate<DashboardState>((state) =>
          state.isLoading == false &&
          state.conversations.length == 2 &&
          state.recentOrders.length == 2 &&
          state.notifications.length == 1 &&
          state.unreadMessagesCount == 5 && // 2 + 3
          state.newOrdersCount == 2 && // pending + confirmed
          state.error == null),
      ],
    );

    blocTest<DashboardCubit, DashboardState>(
      'loadDashboard calculates unread messages count correctly',
      build: () {
        when(() => mockChatService.getConversations()).thenAnswer(
          (_) async => [
            ConversationModelSales(
              id: 'conv1',
              consumerId: 'consumer1',
              consumerName: 'Test Consumer',
              lastMessage: 'Hello',
              lastMessageTime: DateTime.now(),
              unreadCount: 5,
              createdAt: DateTime.now(),
            ),
            ConversationModelSales(
              id: 'conv2',
              consumerId: 'consumer2',
              consumerName: 'Another Consumer',
              lastMessage: 'Hi',
              lastMessageTime: DateTime.now(),
              unreadCount: 0,
              createdAt: DateTime.now(),
            ),
          ],
        );
        when(() => mockOrderService.getOrders(page: 1, pageSize: 5)).thenAnswer(
          (_) async => [],
        );
        when(() => mockNotificationService.getNotifications(unreadOnly: true)).thenAnswer(
          (_) async => [],
        );
        return dashboardCubit;
      },
      act: (cubit) => cubit.loadDashboard(),
      expect: () => [
        DashboardState(isLoading: true, error: null),
        predicate<DashboardState>((state) =>
          state.unreadMessagesCount == 5),
      ],
    );

    blocTest<DashboardCubit, DashboardState>(
      'loadDashboard calculates new orders count correctly',
      build: () {
        when(() => mockChatService.getConversations()).thenAnswer(
          (_) async => [],
        );
        when(() => mockOrderService.getOrders(page: 1, pageSize: 5)).thenAnswer(
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
        when(() => mockNotificationService.getNotifications(unreadOnly: true)).thenAnswer(
          (_) async => [],
        );
        return dashboardCubit;
      },
      act: (cubit) => cubit.loadDashboard(),
      expect: () => [
        DashboardState(isLoading: true, error: null),
        predicate<DashboardState>((state) =>
          state.newOrdersCount == 2), // Only pending and confirmed
      ],
    );

    blocTest<DashboardCubit, DashboardState>(
      'loadDashboard handles errors correctly',
      build: () {
        when(() => mockChatService.getConversations()).thenThrow(
          Exception('Network error'),
        );
        when(() => mockOrderService.getOrders(page: 1, pageSize: 5)).thenAnswer(
          (_) async => [],
        );
        when(() => mockNotificationService.getNotifications(unreadOnly: true)).thenAnswer(
          (_) async => [],
        );
        return dashboardCubit;
      },
      act: (cubit) => cubit.loadDashboard(),
      expect: () => [
        DashboardState(isLoading: true, error: null),
        predicate<DashboardState>((state) =>
          state.isLoading == false &&
          state.error != null &&
          state.error!.contains('Network error')),
      ],
    );

    blocTest<DashboardCubit, DashboardState>(
      'refresh calls loadDashboard',
      build: () {
        when(() => mockChatService.getConversations()).thenAnswer(
          (_) async => [],
        );
        when(() => mockOrderService.getOrders(page: 1, pageSize: 5)).thenAnswer(
          (_) async => [],
        );
        when(() => mockNotificationService.getNotifications(unreadOnly: true)).thenAnswer(
          (_) async => [],
        );
        return dashboardCubit;
      },
      act: (cubit) => cubit.refresh(),
      expect: () => [
        DashboardState(isLoading: true, error: null),
        DashboardState(isLoading: false, error: null),
      ],
      verify: (_) {
        verify(() => mockChatService.getConversations()).called(1);
        verify(() => mockOrderService.getOrders(page: 1, pageSize: 5)).called(1);
        verify(() => mockNotificationService.getNotifications(unreadOnly: true)).called(1);
      },
    );
  });
}

