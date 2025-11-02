import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/order_cubit.dart';
import 'package:scp_mobile_shared/config/app_theme.dart';
import 'package:scp_mobile_shared/widgets/loading_indicator.dart';
import 'package:scp_mobile_shared/widgets/error_widget.dart';
import 'package:scp_mobile_shared/widgets/empty_state_widget.dart';

/// Orders screen
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    context.read<OrderCubit>().loadCurrentOrders();
    context.read<OrderCubit>().loadOrderHistory();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'delivered':
        return AppTheme.successColor;
      case 'cancelled':
        return AppTheme.errorColor;
      case 'processing':
      case 'shipped':
        return AppTheme.primaryColor;
      default:
        return AppTheme.pendingColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
      ),
      body: Column(
        children: [
          // Tabs
          DefaultTabController(
            length: 2,
            child: TabBar(
              onTap: (index) {
                setState(() {
                  _selectedTabIndex = index;
                });
              },
              tabs: const [
                Tab(text: 'Current Orders'),
                Tab(text: 'Order History'),
              ],
            ),
          ),
          // Orders list
          Expanded(
            child: IndexedStack(
              index: _selectedTabIndex,
              children: [
                // Current orders
                BlocBuilder<OrderCubit, OrderState>(
                  builder: (context, state) {
                    if (state.isLoading && state.currentOrders.isEmpty) {
                      return const LoadingIndicator();
                    }

                    if (state.error != null && state.currentOrders.isEmpty) {
                      return ErrorDisplay(
                        message: state.error!,
                        onRetry: () =>
                            context.read<OrderCubit>().loadCurrentOrders(),
                      );
                    }

                    if (state.currentOrders.isEmpty) {
                      return const EmptyStateWidget(
                        icon: Icons.receipt_long,
                        title: 'No current orders',
                        subtitle: 'Start shopping to place your first order',
                      );
                    }

                    return ListView.builder(
                      itemCount: state.currentOrders.length,
                      itemBuilder: (context, index) {
                        final order = state.currentOrders[index];
                        return _buildOrderCard(context, order);
                      },
                    );
                  },
                ),
                // Order history
                BlocBuilder<OrderCubit, OrderState>(
                  builder: (context, state) {
                    if (state.isLoading && state.orders.isEmpty) {
                      return const LoadingIndicator();
                    }

                    if (state.error != null && state.orders.isEmpty) {
                      return ErrorDisplay(
                        message: state.error!,
                        onRetry: () =>
                            context.read<OrderCubit>().loadOrderHistory(),
                      );
                    }

                    if (state.orders.isEmpty) {
                      return const EmptyStateWidget(
                        icon: Icons.history,
                        title: 'No order history',
                        subtitle: 'Your past orders will appear here',
                      );
                    }

                    return ListView.builder(
                      itemCount: state.orders.length,
                      itemBuilder: (context, index) {
                        final order = state.orders[index];
                        return _buildOrderCard(context, order);
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, dynamic order) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          'Order #${order.orderNumber}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(order.supplierName),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text('${order.items.length} items'),
                const SizedBox(width: 16),
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text('${order.orderDate.day}/${order.orderDate.month}/${order.orderDate.year}'),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '\$${order.total.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getStatusColor(order.status.name).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            order.status.name.toUpperCase(),
            style: TextStyle(
              color: _getStatusColor(order.status.name),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        onTap: () {
          // Show order details
          context.read<OrderCubit>().loadOrderDetails(order.id);
        },
      ),
    );
  }
}

