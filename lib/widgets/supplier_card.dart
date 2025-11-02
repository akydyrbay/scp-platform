import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/supplier_model.dart';

/// Supplier card widget
class SupplierCard extends StatelessWidget {
  final SupplierModel supplier;
  final VoidCallback? onTap;
  final VoidCallback? onLinkRequest;
  final bool showLinkButton;

  const SupplierCard({
    super.key,
    required this.supplier,
    this.onTap,
    this.onLinkRequest,
    this.showLinkButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Logo
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: supplier.logoUrl != null
                    ? CachedNetworkImage(
                        imageUrl: supplier.logoUrl!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey[200],
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey[200],
                          child: const Icon(Icons.business),
                        ),
                      )
                    : Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[200],
                        child: const Icon(Icons.business),
                      ),
              ),
              const SizedBox(width: 16),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      supplier.companyName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (supplier.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        supplier.description!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (supplier.rating != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.star, size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            supplier.rating!.toStringAsFixed(1),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                    if (supplier.categories.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        children: supplier.categories.take(3).map((category) {
                          return Chip(
                            label: Text(
                              category,
                              style: const TextStyle(fontSize: 10),
                            ),
                            padding: EdgeInsets.zero,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              // Actions
              if (showLinkButton && !supplier.isLinked && onLinkRequest != null)
                IconButton(
                  onPressed: onLinkRequest,
                  icon: supplier.isLinked
                      ? const Icon(Icons.check_circle, color: AppTheme.successColor)
                      : const Icon(Icons.add_link),
                  tooltip: supplier.isLinked ? 'Linked' : 'Request Link',
                ),
              if (supplier.isLinked)
                const Icon(Icons.check_circle, color: AppTheme.successColor),
            ],
          ),
        ),
      ),
    );
  }
}

