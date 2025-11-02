import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/supplier_cubit.dart';
import '../../config/app_theme.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/empty_state_widget.dart';

/// Link requests screen
class LinkRequestsScreen extends StatefulWidget {
  const LinkRequestsScreen({super.key});

  @override
  State<LinkRequestsScreen> createState() => _LinkRequestsScreenState();
}

class _LinkRequestsScreenState extends State<LinkRequestsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SupplierCubit>().loadLinkRequests();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'accepted':
        return AppTheme.successColor;
      case 'rejected':
        return AppTheme.errorColor;
      case 'blocked':
        return AppTheme.blockedColor;
      default:
        return AppTheme.pendingColor;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'accepted':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'blocked':
        return Icons.block;
      default:
        return Icons.pending;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Link Requests'),
      ),
      body: BlocBuilder<SupplierCubit, SupplierState>(
        builder: (context, state) {
          if (state.isLoading && state.linkRequests.isEmpty) {
            return const LoadingIndicator();
          }

          if (state.error != null && state.linkRequests.isEmpty) {
            return ErrorDisplay(
              message: state.error!,
              onRetry: () => context.read<SupplierCubit>().loadLinkRequests(),
            );
          }

          if (state.linkRequests.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.link_off,
              title: 'No link requests',
              subtitle: 'Request links with suppliers to view their products',
            );
          }

          return ListView.builder(
            itemCount: state.linkRequests.length,
            itemBuilder: (context, index) {
              final request = state.linkRequests[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: request.supplierLogoUrl != null
                      ? CircleAvatar(
                          backgroundImage: NetworkImage(request.supplierLogoUrl!),
                        )
                      : const CircleAvatar(
                          child: Icon(Icons.business),
                        ),
                  title: Text(
                    request.supplierName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Status: ${request.status.name.toUpperCase()}'),
                      if (request.message != null && request.message!.isNotEmpty)
                        Text(request.message!),
                      const SizedBox(height: 8),
                      Text(
                        'Requested: ${_formatDate(request.requestedAt)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(request.status.name).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(request.status.name),
                          size: 16,
                          color: _getStatusColor(request.status.name),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          request.status.name.toUpperCase(),
                          style: TextStyle(
                            color: _getStatusColor(request.status.name),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

