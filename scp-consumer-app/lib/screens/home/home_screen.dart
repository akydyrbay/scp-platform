import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/product_cubit.dart';
import '../../cubits/cart_cubit.dart';
import 'package:scp_mobile_shared/widgets/product_card.dart';
import 'package:scp_mobile_shared/widgets/loading_indicator.dart';
import 'package:scp_mobile_shared/widgets/error_widget.dart';
import 'package:scp_mobile_shared/widgets/empty_state_widget.dart';

/// Home screen - displays products from linked suppliers
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
    context.read<ProductCubit>().loadProducts();
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
      context.read<ProductCubit>().loadProducts();
    } else {
      context.read<ProductCubit>().searchProducts(query);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              // Navigate to cart
            },
          ),
          // Debug button - refresh products
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<ProductCubit>().loadProducts();
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
            child: BlocListener<ProductCubit, ProductState>(
              listener: (context, state) {
                // Log state changes for debugging
                print('═══════════════════════════════════════');
                print('🏠 [HOME] State changed');
                print('🏠 [HOME] Products count: ${state.products.length}');
                print('🏠 [HOME] Is loading: ${state.isLoading}');
                print('🏠 [HOME] Error: ${state.error ?? "none"}');
                if (state.products.isNotEmpty) {
                  print('✅ [HOME] Products available: ${state.products.length}');
                  print('✅ [HOME] First product: ${state.products.first.name}');
                } else if (!state.isLoading && state.error == null) {
                  print('⚠️  [HOME] No products and no error - may not have approved links');
                  print('⚠️  [HOME] Check: 1) User has approved supplier links');
                  print('⚠️  [HOME] Check: 2) Linked suppliers have products');
                  print('⚠️  [HOME] Check: 3) Consumer ID in token matches database');
                } else if (state.error != null) {
                  print('❌ [HOME] Error occurred: ${state.error}');
                }
                print('═══════════════════════════════════════');
              },
              child: BlocBuilder<ProductCubit, ProductState>(
                builder: (context, state) {
                  // Show error if there is one (regardless of loading state)
                  if (state.error != null && state.products.isEmpty && !state.isLoading) {
                    return ErrorDisplay(
                      message: state.error!,
                      onRetry: () => context.read<ProductCubit>().loadProducts(),
                    );
                  }

                  if (state.isLoading && state.products.isEmpty) {
                    return const LoadingIndicator();
                  }

                  if (state.products.isEmpty) {
                    print('⚠️  [HOME_UI] Showing empty state - products list is empty');
                    print('⚠️  [HOME_UI] IsLoading: ${state.isLoading}');
                    print('⚠️  [HOME_UI] Error: ${state.error ?? "none"}');
                    return EmptyStateWidget(
                      icon: Icons.inventory_2_outlined,
                      title: 'No products found',
                      subtitle: state.error != null 
                          ? 'Error: ${state.error}'
                          : 'Start by linking with a supplier. Once approved, products will appear here.',
                    );
                  }

                  print('✅ [HOME_UI] Rendering ${state.products.length} products in GridView');
                  return GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
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
                        // Show product details
                        context.read<ProductCubit>().loadProductDetails(product.id);
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
          ),
        ],
      ),
    );
  }
}

