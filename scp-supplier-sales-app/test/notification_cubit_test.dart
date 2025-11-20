import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scp_mobile_shared/models/notification_model.dart';
import 'package:scp_mobile_shared/services/notification_service.dart';
import '../lib/cubits/notification_cubit.dart';

class MockNotificationService extends Mock implements NotificationService {}

void main() {
  group('NotificationCubit', () {
    late NotificationCubit notificationCubit;
    late MockNotificationService mockNotificationService;

    setUp(() {
      mockNotificationService = MockNotificationService();
      notificationCubit = NotificationCubit(
        notificationService: mockNotificationService,
      );
    });

    tearDown(() {
      notificationCubit.close();
    });

    test('initial state is correct', () {
      expect(notificationCubit.state.notifications, isEmpty);
      expect(notificationCubit.state.unreadCount, 0);
      expect(notificationCubit.state.isLoading, false);
      expect(notificationCubit.state.error, isNull);
    });

    blocTest<NotificationCubit, NotificationState>(
      'loadNotifications loads all notifications successfully',
      build: () {
        when(() => mockNotificationService.getNotifications(unreadOnly: false)).thenAnswer(
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
            NotificationModel(
              id: 'notif2',
              title: 'Message',
              body: 'You have a new message',
              type: NotificationType.message,
              targetId: 'conv1',
              data: {},
              isRead: true,
              createdAt: DateTime.now(),
            ),
          ],
        );
        return notificationCubit;
      },
      act: (cubit) => cubit.loadNotifications(unreadOnly: false),
      expect: () => [
        NotificationState(isLoading: true, error: null),
        predicate<NotificationState>((state) =>
          state.isLoading == false &&
          state.notifications.length == 2 &&
          state.unreadCount == 1 &&
          state.error == null),
      ],
    );

    blocTest<NotificationCubit, NotificationState>(
      'loadNotifications loads unread only notifications',
      build: () {
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
        return notificationCubit;
      },
      act: (cubit) => cubit.loadNotifications(unreadOnly: true),
      expect: () => [
        NotificationState(isLoading: true, error: null),
        predicate<NotificationState>((state) =>
          state.isLoading == false &&
          state.notifications.length == 1 &&
          state.unreadCount == 1),
      ],
    );

    blocTest<NotificationCubit, NotificationState>(
      'loadNotifications handles errors correctly',
      build: () {
        when(() => mockNotificationService.getNotifications(unreadOnly: false)).thenThrow(
          Exception('Network error'),
        );
        return notificationCubit;
      },
      act: (cubit) => cubit.loadNotifications(unreadOnly: false),
      expect: () => [
        NotificationState(isLoading: true, error: null),
        predicate<NotificationState>((state) =>
          state.isLoading == false &&
          state.error != null &&
          state.error!.contains('Network error')),
      ],
    );

    blocTest<NotificationCubit, NotificationState>(
      'markAsRead marks notification as read',
      build: () {
        when(() => mockNotificationService.markAsRead('notif1')).thenAnswer(
          (_) async => {},
        );
        when(() => mockNotificationService.getNotifications(unreadOnly: false)).thenAnswer(
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
        return notificationCubit;
      },
      seed: () => NotificationState(
        notifications: [
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
        unreadCount: 1,
      ),
      act: (cubit) => cubit.markAsRead('notif1'),
      expect: () => [
        predicate<NotificationState>((state) =>
          state.notifications.first.isRead == true &&
          state.unreadCount == 0),
      ],
    );

    blocTest<NotificationCubit, NotificationState>(
      'markAllAsRead marks all notifications as read',
      build: () {
        when(() => mockNotificationService.markAllAsRead()).thenAnswer(
          (_) async => {},
        );
        return notificationCubit;
      },
      seed: () => NotificationState(
        notifications: [
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
          NotificationModel(
            id: 'notif2',
            title: 'Message',
            body: 'You have a new message',
            type: NotificationType.message,
            targetId: 'conv1',
            data: {},
            isRead: false,
            createdAt: DateTime.now(),
          ),
        ],
        unreadCount: 2,
      ),
      act: (cubit) => cubit.markAllAsRead(),
      expect: () => [
        predicate<NotificationState>((state) =>
          state.notifications.every((n) => n.isRead == true) &&
          state.unreadCount == 0),
      ],
    );

    blocTest<NotificationCubit, NotificationState>(
      'showLocalNotification calls service',
      build: () {
        when(() => mockNotificationService.showLocalNotification(
          id: any(named: 'id'),
          title: 'Test Title',
          body: 'Test Body',
          payload: null,
        )).thenAnswer((_) async => {});
        return notificationCubit;
      },
      act: (cubit) => cubit.showLocalNotification(
        title: 'Test Title',
        body: 'Test Body',
      ),
      verify: (_) {
        verify(() => mockNotificationService.showLocalNotification(
          id: any(named: 'id'),
          title: 'Test Title',
          body: 'Test Body',
          payload: null,
        )).called(1);
      },
    );
  });
}

