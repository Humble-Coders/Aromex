import 'package:aromex/models/phone.dart';
import 'package:aromex/models/storage_location.dart';
import 'package:aromex/util.dart';
import 'package:flutter/material.dart';

class ProductDetailCard extends StatelessWidget {
  const ProductDetailCard({
    super.key,
    required this.phone,
    required this.onBack,
  });
  final VoidCallback onBack;

  final Phone phone;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(36.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(icon: const Icon(Icons.arrow_back), onPressed: onBack),
          const SizedBox(height: 12),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: colorScheme.primary.withAlpha(170),
                width: 1.0,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    'Product Details',
                    style: textTheme.titleLarge?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Brand:',
                                  style: textTheme.bodyLarge?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  phone.brand != null && phone.brand!.exists
                                      ? (phone.brand!.data()
                                              as Map<
                                                String,
                                                dynamic
                                              >)['name'] ??
                                          'Unknown Brand'
                                      : 'Unknown Brand',
                                  style: textTheme.bodyLarge?.copyWith(
                                    color: colorScheme.primary.withAlpha(200),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Model:',
                                  style: textTheme.bodyLarge?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  phone.model != null && phone.model!.exists
                                      ? (phone.model!.data()
                                              as Map<
                                                String,
                                                dynamic
                                              >)['name'] ??
                                          'Unknown Model'
                                      : 'Unknown Model',
                                  style: textTheme.bodyLarge?.copyWith(
                                    color: colorScheme.primary.withAlpha(200),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'IMEI/Serial:',
                                  style: textTheme.bodyLarge?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  phone.imei,
                                  style: textTheme.bodyLarge?.copyWith(
                                    color: colorScheme.primary.withAlpha(200),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Capacity:',
                                  style: textTheme.bodyLarge?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${phone.capacity} GB',
                                  style: textTheme.bodyLarge?.copyWith(
                                    color: colorScheme.primary.withAlpha(200),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Status:',
                                  style: textTheme.bodyLarge?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  phone.status == true ? 'Active' : 'Inactive',
                                  style: textTheme.bodyLarge?.copyWith(
                                    color: colorScheme.primary.withAlpha(200),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Carrier:',
                                  style: textTheme.bodyLarge?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  phone.carrier,
                                  style: textTheme.bodyLarge?.copyWith(
                                    color: colorScheme.primary.withAlpha(200),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Color:',
                                  style: textTheme.bodyLarge?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  phone.color,
                                  style: textTheme.bodyLarge?.copyWith(
                                    color: colorScheme.primary.withAlpha(200),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Storage Location:',
                                  style: textTheme.bodyLarge?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  StorageLocation.fromFirestore(
                                    phone.storageLocation!,
                                  ).name,
                                  style: textTheme.bodyLarge?.copyWith(
                                    color: colorScheme.primary.withAlpha(200),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Price:',
                                  style: textTheme.bodyLarge?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  formatCurrency(phone.price),
                                  style: textTheme.bodyLarge?.copyWith(
                                    color: colorScheme.primary.withAlpha(200),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
