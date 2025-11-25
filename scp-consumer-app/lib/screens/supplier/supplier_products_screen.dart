import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/product_cubit.dart';
import '../../cubits/cart_cubit.dart';
import '../cart/cart_screen.dart';
import 'package:scp_mobile_shared/widgets/product_card.dart';
import 'package:scp_mobile_shared/widgets/loading_indicator.dart';
import 'package:scp_mobile_shared/widgets/error_widget.dart';
import 'package:scp_mobile_shared/widgets/empty_state_widget.dart';
import 'package:scp_mobile_shared/models/supplier_model.dart';

/// Supplier products screen - displays all products from a specific supplier
class SupplierProductsScreen extends StatefulWidget {
  final SupplierModel supplier;

  const SupplierProductsScreen({
    super.key,
    required this.supplier,
  });

  @override
  State<SupplierProductsScreen> createState() => _SupplierProductsScreenState();
}

class _SupplierProductsScreenState extends State<SupplierProductsScreen> {
  final _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    // Load products for this specific supplier
    context.read<ProductCubit>().loadProducts(supplierId: widget.supplier.id);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {});
  }

  void _onSearch(String query) {
    // Cancel previous timer
    _debounceTimer?.cancel();
    
    // Debounce search: wait 500ms after user stops typing
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (query.isEmpty) {
        context.read<ProductCubit>().loadProducts(supplierId: widget.supplier.id);
      } else {
        context.read<ProductCubit>().loadProducts(
              supplierId: widget.supplier.id,
              searchQuery: query,
            );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.supplier.companyName),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              // Navigate to cart
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const CartScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<ProductCubit>().loadProducts(
                    supplierId: widget.supplier.id,
                    searchQuery: _searchController.text.isEmpty
                        ? null
                        : _searchController.text,
                  );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search products...',
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
            // Products list
            Expanded(
              child: BlocBuilder<ProductCubit, ProductState>(
                builder: (context, state) {
                  // Show error if there is one
                  if (state.error != null && state.products.isEmpty && !state.isLoading) {
                    return ErrorDisplay(
                      message: state.error!,
                      onRetry: () {
                        final currentQuery = _searchController.text.isEmpty 
                            ? null 
                            : _searchController.text;
                        context.read<ProductCubit>().loadProducts(
                          supplierId: widget.supplier.id,
                          searchQuery: currentQuery,
                        );
                      },
                    );
                  }

                  if (state.isLoading && state.products.isEmpty) {
                    return const LoadingIndicator();
                  }

                  if (state.products.isEmpty) {
                    final hasSearchQuery = _searchController.text.isNotEmpty;
                    return EmptyStateWidget(
                      icon: hasSearchQuery ? Icons.search_off : Icons.inventory_2_outlined,
                      title: 'No products found',
                      subtitle: state.error != null
                          ? 'Error: ${state.error}'
                          : hasSearchQuery
                              ? 'No products match your search. Try a different term.'
                              : 'This supplier has no products available at the moment.',
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                      childAspectRatio: 0.7,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: state.products.length,
                    itemBuilder: (context, index) {
                      final product = state.products[index];
                      return ProductCard(
                        product: product,
                        onTap: () {
                          // Optional: Could show product details dialog or navigate to detail page
                          // For now, just add to cart on tap if available
                          if (product.isAvailable && product.stockQuantity > 0) {
                            context.read<CartCubit>().addToCart(product);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${product.name} added to cart'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        onAddToCart: () {
                          context.read<CartCubit>().addToCart(product);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${product.name} added to cart'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

