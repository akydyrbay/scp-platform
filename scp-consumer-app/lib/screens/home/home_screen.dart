import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/supplier_cubit.dart';
import '../supplier/supplier_products_screen.dart';
import 'package:scp_mobile_shared/widgets/loading_indicator.dart';
import 'package:scp_mobile_shared/widgets/error_widget.dart';
import 'package:scp_mobile_shared/widgets/empty_state_widget.dart';
import 'package:scp_mobile_shared/config/app_theme.dart';
import 'package:scp_mobile_shared/models/supplier_model.dart';

/// Home screen - displays suppliers with Send Request button
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<SupplierCubit>().discoverSuppliers();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {});
  }

  void _onSearch(String query) {
    if (query.isEmpty) {
      context.read<SupplierCubit>().discoverSuppliers();
    } else {
      context.read<SupplierCubit>().discoverSuppliers(searchQuery: query);
    }
  }

  void _handleSendRequest(String supplierId) async {
    try {
      await context.read<SupplierCubit>().sendLinkRequest(supplierId);
      // Refresh supplier list to show updated link status
      await context.read<SupplierCubit>().discoverSuppliers(
        searchQuery: _searchController.text.isEmpty ? null : _searchController.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Link request sent successfully'),
            backgroundColor: AppTheme.successColor,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send request: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suppliers'),
        actions: [
          // Debug button - refresh suppliers
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<SupplierCubit>().discoverSuppliers();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search suppliers...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearch('');
                        },
                      )
                    : null,
              ),
              onChanged: _onSearch,
            ),
          ),
          // Suppliers list
          Expanded(
            child: BlocBuilder<SupplierCubit, SupplierState>(
              builder: (context, state) {
                // Show error if there is one (regardless of loading state)
                if (state.error != null && state.suppliers.isEmpty && !state.isLoading) {
                  return ErrorDisplay(
                    message: state.error!,
                    onRetry: () => context.read<SupplierCubit>().discoverSuppliers(),
                  );
                }

                if (state.isLoading && state.suppliers.isEmpty) {
                  return const LoadingIndicator();
                }

                if (state.suppliers.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.business_outlined,
                    title: 'No suppliers found',
                    subtitle: state.error != null 
                        ? 'Error: ${state.error}'
                        : 'No suppliers available at the moment.',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: state.suppliers.length,
                  itemBuilder: (context, index) {
                    final supplier = state.suppliers[index];
                    final isLinked = supplier.isLinked || 
                        supplier.linkStatus == LinkRequestStatus.accepted;
                    final isPending = supplier.linkStatus == LinkRequestStatus.pending;
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: supplier.logoUrl != null
                            ? CircleAvatar(
                                backgroundImage: NetworkImage(supplier.logoUrl!),
                                radius: 30,
                              )
                            : const CircleAvatar(
                                radius: 30,
                                child: Icon(Icons.business, size: 30),
                              ),
                        title: Text(
                          supplier.companyName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (supplier.description != null && supplier.description!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  supplier.description!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            if (supplier.address != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  children: [
                                    const Icon(Icons.location_on, size: 16),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        supplier.address!,
                                        style: Theme.of(context).textTheme.bodySmall,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (isLinked)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Chip(
                                  label: const Text('Linked'),
                                  backgroundColor: AppTheme.successColor.withOpacity(0.2),
                                  labelStyle: TextStyle(color: AppTheme.successColor),
                                ),
                              )
                            else if (isPending)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Chip(
                                  label: const Text('Pending'),
                                  backgroundColor: AppTheme.pendingColor.withOpacity(0.2),
                                  labelStyle: TextStyle(color: AppTheme.pendingColor),
                                ),
                              ),
                          ],
                        ),
                        trailing: isLinked
                            ? ElevatedButton(
                                onPressed: state.isLoading
                                    ? null
                                    : () {
                                        // Navigate to supplier products page
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => SupplierProductsScreen(
                                              supplier: supplier,
                                            ),
                                          ),
                                        );
                                      },
                                child: const Text('View Products'),
                              )
                            : isPending
                                ? null
                                : ElevatedButton(
                                    onPressed: state.isLoading
                                        ? null
                                        : () => _handleSendRequest(supplier.id),
                                    child: const Text('Send Request'),
                                  ),
                        onTap: isLinked
                            ? () {
                                // Navigate to supplier products page when tapping on linked supplier
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => SupplierProductsScreen(
                                      supplier: supplier,
                                    ),
                                  ),
                                );
                              }
                            : null,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

