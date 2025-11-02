import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/supplier_cubit.dart';
import 'package:scp_mobile_shared/widgets/supplier_card.dart';
import 'package:scp_mobile_shared/widgets/loading_indicator.dart';
import 'package:scp_mobile_shared/widgets/error_widget.dart';
import 'package:scp_mobile_shared/widgets/empty_state_widget.dart';

/// Supplier discovery screen
class SupplierDiscoveryScreen extends StatefulWidget {
  const SupplierDiscoveryScreen({super.key});

  @override
  State<SupplierDiscoveryScreen> createState() => _SupplierDiscoveryScreenState();
}

class _SupplierDiscoveryScreenState extends State<SupplierDiscoveryScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<SupplierCubit>().discoverSuppliers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    context.read<SupplierCubit>().discoverSuppliers(searchQuery: query);
  }

  void _showLinkRequestDialog(String supplierId, String supplierName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Send Link Request'),
          content: Text('Send a link request to $supplierName?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<SupplierCubit>().sendLinkRequest(supplierId);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Link request sent!'),
                  ),
                );
              },
              child: const Text('Send Request'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Suppliers'),
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
                if (state.isLoading && state.suppliers.isEmpty) {
                  return const LoadingIndicator();
                }

                if (state.error != null && state.suppliers.isEmpty) {
                  return ErrorDisplay(
                    message: state.error!,
                    onRetry: () => context.read<SupplierCubit>().discoverSuppliers(),
                  );
                }

                if (state.suppliers.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.search_off,
                    title: 'No suppliers found',
                    subtitle: 'Try a different search term',
                  );
                }

                return ListView.builder(
                  itemCount: state.suppliers.length,
                  itemBuilder: (context, index) {
                    final supplier = state.suppliers[index];
                    return SupplierCard(
                      supplier: supplier,
                      onLinkRequest: () => _showLinkRequestDialog(
                        supplier.id,
                        supplier.companyName,
                      ),
                      showLinkButton: !supplier.isLinked,
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

