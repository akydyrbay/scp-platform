import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:scp_mobile_shared/models/notification_model.dart';
import 'package:scp_mobile_shared/services/notification_service.dart';
import 'package:scp_mobile_shared/services/chat_service_sales.dart';
import 'package:scp_mobile_shared/models/conversation_model.dart';
import '../services/supplier_order_service.dart';
import 'package:scp_mobile_shared/models/order_model.dart';

/// Dashboard State
class DashboardState extends Equatable {
  const DashboardState({
    this.conversations = const [],
    this.recentOrders = const [],
    this.notifications = const [],
    this.unreadMessagesCount = 0,
    this.newOrdersCount = 0,
    this.isLoading = false,
    this.error,
  });

  final List<ConversationModelSales> conversations;
  final List<OrderModel> recentOrders;
  final List<NotificationModel> notifications;
  final int unreadMessagesCount;
  final int newOrdersCount;
  final bool isLoading;
  final String? error;

  DashboardState copyWith({
    List<ConversationModelSales>? conversations,
    List<OrderModel>? recentOrders,
    List<NotificationModel>? notifications,
    int? unreadMessagesCount,
    int? newOrdersCount,
    bool? isLoading,
    String? error,
  }) {
    return DashboardState(
      conversations: conversations ?? this.conversations,
      recentOrders: recentOrders ?? this.recentOrders,
      notifications: notifications ?? this.notifications,
      unreadMessagesCount: unreadMessagesCount ?? this.unreadMessagesCount,
      newOrdersCount: newOrdersCount ?? this.newOrdersCount,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
        conversations,
        recentOrders,
        notifications,
        unreadMessagesCount,
        newOrdersCount,
        isLoading,
        error,
      ];
}

/// Dashboard Cubit
class DashboardCubit extends Cubit<DashboardState> {
  final ChatServiceSales _chatService;
  final SupplierOrderService _orderService;
  final NotificationService _notificationService;

  DashboardCubit({
    ChatServiceSales? chatService,
    SupplierOrderService? orderService,
    NotificationService? notificationService,
  })  : _chatService = chatService ?? ChatServiceSales(),
        _orderService = orderService ?? SupplierOrderService(),
        _notificationService = notificationService ?? NotificationService(),
        super(const DashboardState());

  /// Load dashboard data
  Future<void> loadDashboard() async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      // Load conversations, recent orders, and notifications in parallel
      final conversations = await _chatService.getConversations();
      final recentOrders = await _orderService.getOrders(pageSize: 5);
      final notifications = await _notificationService.getNotifications(unreadOnly: true);

      // Calculate unread counts
      final unreadMessagesCount = conversations.fold(0, (sum, conv) => sum + conv.unreadCount);
      final newOrdersCount = recentOrders.where((order) => 
        order.status == OrderStatus.pending || order.status == OrderStatus.confirmed
      ).length;

      emit(state.copyWith(
        conversations: conversations,
        recentOrders: recentOrders,
        notifications: notifications,
        unreadMessagesCount: unreadMessagesCount,
        newOrdersCount: newOrdersCount,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  /// Refresh dashboard
  Future<void> refresh() async {
    await loadDashboard();
  }
}

