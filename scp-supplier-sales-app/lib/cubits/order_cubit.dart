import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:scp_mobile_shared/models/order_model.dart';
import '../services/supplier_order_service.dart';

/// Order State
class OrderState extends Equatable {
  const OrderState({
    this.orders = const [],
    this.currentOrders = const [],
    this.selectedOrder,
    this.isLoading = false,
    this.error,
  });

  final List<OrderModel> orders;
  final List<OrderModel> currentOrders;
  final OrderModel? selectedOrder;
  final bool isLoading;
  final String? error;

  OrderState copyWith({
    List<OrderModel>? orders,
    List<OrderModel>? currentOrders,
    OrderModel? selectedOrder,
    bool? isLoading,
    String? error,
  }) {
    return OrderState(
      orders: orders ?? this.orders,
      currentOrders: currentOrders ?? this.currentOrders,
      selectedOrder: selectedOrder,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
        orders,
        currentOrders,
        selectedOrder,
        isLoading,
        error,
      ];
}

/// Order Cubit
class OrderCubit extends Cubit<OrderState> {
  final SupplierOrderServiceInterface _orderService;

  OrderCubit({SupplierOrderServiceInterface? orderService})
      : _orderService = orderService ?? SupplierOrderService(),
        super(const OrderState());

  /// Load order history
  Future<void> loadOrderHistory() async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      final orders = await _orderService.getOrders();
      emit(state.copyWith(
        orders: orders,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  /// Load current orders
  Future<void> loadCurrentOrders() async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      final allOrders = await _orderService.getOrders();
      final currentOrders = allOrders.where((o) =>
        o.status == OrderStatus.pending ||
        o.status == OrderStatus.confirmed ||
        o.status == OrderStatus.processing
      ).toList();
      emit(state.copyWith(
        currentOrders: currentOrders,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  /// Load order details
  Future<void> loadOrderDetails(String orderId) async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      final order = await _orderService.getOrderDetails(orderId);
      emit(state.copyWith(
        selectedOrder: order,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  /// Place order
  Future<bool> placeOrder({
    required String supplierId,
    required List<Map<String, dynamic>> items,
    ShippingAddress? shippingAddress,
    String? notes,
  }) async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      final order = await _orderService.placeOrder(
        supplierId: supplierId,
        items: items,
        shippingAddress: shippingAddress,
        notes: notes,
      );
      emit(state.copyWith(
        selectedOrder: order,
        isLoading: false,
      ));
      // Reload current orders
      await loadCurrentOrders();
      return true;
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
      return false;
    }
  }

  /// Cancel order
  Future<void> cancelOrder(String orderId) async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      await _orderService.cancelOrder(orderId);
      emit(state.copyWith(isLoading: false));
      // Reload orders
      await loadOrderHistory();
      await loadCurrentOrders();
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  /// Track order
  Future<void> trackOrder(String orderId) async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      final order = await _orderService.trackOrder(orderId);
      emit(state.copyWith(
        selectedOrder: order,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  /// Clear selected order
  void clearSelectedOrder() {
    emit(state.copyWith(selectedOrder: null));
  }
}

