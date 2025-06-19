import 'package:aromex/models/phone_brand.dart';
import 'package:aromex/models/storage_location.dart';
import 'package:flutter/material.dart';

class LocationInventoryData {
  final PhoneBrand phoneBrands;
  final int count;

  LocationInventoryData({required this.phoneBrands, required this.count});
}

class LocationInventoryBrands extends StatelessWidget {
  final StorageLocation storageLocation;
  final List<LocationInventoryData>? data;
  final void Function(StorageLocation, PhoneBrand) onBrandSelected;
  const LocationInventoryBrands({
    super.key,
    required this.storageLocation,
    required this.onBrandSelected,
    this.data,
  });

  @override
  Widget build(BuildContext context) {
    int count = data?.fold(0, (sum, item) => sum! + item.count) ?? 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      children: [
                        WidgetSpan(
                          child: Transform(
                            transform: Matrix4.translationValues(0, 3, 0),
                            child: Icon(
                              Icons.store_mall_directory_outlined,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        WidgetSpan(child: const SizedBox(width: 4)),
                        TextSpan(
                          text: storageLocation.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    "Total: $count units",
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (count == 0) ...[
              const Spacer(),
              Center(
                child:
                    data != null
                        ? const Text("No phones available")
                        : const CircularProgressIndicator(),
              ),
              const Spacer(),
            ] else
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    ...?data?.map(
                      (item) => Card(
                        child: Container(
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          width: double.infinity,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap:
                                  () => onBrandSelected(
                                    storageLocation,
                                    item.phoneBrands,
                                  ),
                              hoverColor: Colors.grey.shade200,
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.phone_iphone,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.phoneBrands.name,
                                          style:
                                              Theme.of(
                                                context,
                                              ).textTheme.titleMedium,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          "${item.count} units",
                                          style:
                                              Theme.of(
                                                context,
                                              ).textTheme.bodySmall,
                                        ),
                                      ],
                                    ),

                                    const Spacer(),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
