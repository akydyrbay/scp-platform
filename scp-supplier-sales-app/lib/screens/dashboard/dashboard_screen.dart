import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/dashboard_cubit.dart';
import 'package:scp_mobile_shared/widgets/loading_indicator.dart';
import 'package:scp_mobile_shared/widgets/error_widget.dart';
import 'package:scp_mobile_shared/config/app_theme_supplier.dart';

/// Dashboard screen for supplier sales reps
class SupplierDashboardScreen extends StatefulWidget {
  const SupplierDashboardScreen({super.key});

  @override
  State<SupplierDashboardScreen> createState() => _SupplierDashboardScreenState();
}

class _SupplierDashboardScreenState extends State<SupplierDashboardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<DashboardCubit>().loadDashboard();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // Navigate to notifications
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<DashboardCubit>().refresh(),
        child: BlocBuilder<DashboardCubit, DashboardState>(
          builder: (context, state) {
            if (state.isLoading && state.conversations.isEmpty) {
              return const LoadingIndicator();
            }

            if (state.error != null && state.conversations.isEmpty) {
              return ErrorDisplay(
                message: state.error!,
                onRetry: () => context.read<DashboardCubit>().loadDashboard(),
              );
            }

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats cards
                  _buildStatsCards(context, state),
                  const SizedBox(height: 24),
                  
                  // Recent conversations
                  _buildSectionHeader('Recent Conversations', Icons.chat_bubble_outline),
                  const SizedBox(height: 12),
                  _buildRecentConversations(state.conversations),
                  const SizedBox(height: 24),
                  
                  // Recent orders
                  _buildSectionHeader('Recent Orders', Icons.receipt_long_outlined),
                  const SizedBox(height: 12),
                  _buildRecentOrders(state.recentOrders),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatsCards(BuildContext context, DashboardState state) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            'Unread Messages',
            state.unreadMessagesCount.toString(),
            Icons.mark_chat_unread,
            AppThemeSupplier.primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            'New Orders',
            state.newOrdersCount.toString(),
            Icons.shopping_cart,
            AppThemeSupplier.accentColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppThemeSupplier.primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentConversations(List conversations) {
    if (conversations.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('No recent conversations'),
        ),
      );
    }

    final recent = conversations.take(5).toList();
    
    return Column(
      children: recent.map((conv) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: conv.consumerAvatarUrl != null
                  ? NetworkImage(conv.consumerAvatarUrl!)
                  : null,
              child: conv.consumerAvatarUrl == null
                  ? const Icon(Icons.person)
                  : null,
            ),
            title: Text(conv.consumerName),
            subtitle: Text(conv.lastMessage ?? ''),
            trailing: conv.unreadCount > 0
                ? Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppThemeSupplier.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      conv.unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : null,
            onTap: () {
              // Navigate to chat
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecentOrders(List orders) {
    if (orders.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('No recent orders'),
        ),
      );
    }

    final recent = orders.take(5).toList();
    
    return Column(
      children: recent.map((order) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text('Order #${order.orderNumber}'),
            subtitle: Text(
              '\$${order.total.toStringAsFixed(2)} • ${order.supplierName}',
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
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            onTap: () {
              // Navigate to order details
            },
          ),
        );
      }).toList(),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'delivered':
        return AppThemeSupplier.successColor;
      case 'cancelled':
        return AppThemeSupplier.errorColor;
      case 'processing':
      case 'shipped':
        return AppThemeSupplier.primaryColor;
      default:
        return AppThemeSupplier.pendingColor;
    }
  }
}

