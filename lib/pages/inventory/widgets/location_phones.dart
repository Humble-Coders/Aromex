import 'package:aromex/models/phone.dart';
import 'package:aromex/models/phone_brand.dart';
import 'package:aromex/models/phone_model.dart';
import 'package:aromex/models/storage_location.dart';
import 'package:aromex/util.dart';
import 'package:aromex/widgets/generic_custom_table.dart';
import 'package:flutter/material.dart';

class LocationPhones extends StatelessWidget {
  final List<Phone> phones;
  final StorageLocation storageLocation;
  final PhoneBrand phoneBrand;
  final PhoneModel phoneModel;

  const LocationPhones({
    super.key,
    required this.phones,
    required this.storageLocation,
    required this.phoneBrand,
    required this.phoneModel,
  });

  @override
  Widget build(BuildContext context) {
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
                          text:
                              "${storageLocation.name} > ${phoneBrand.name} > ${phoneModel.name}",
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    "Total: ${phones.length} units",
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: GenericCustomTable<Phone>(
                entries: phones,
                headers: [
                  "Serial/IMEI",
                  "Capacity",
                  "Color",
                  "Carrier",
                  "Status",
                  "Price",
                ],
                valueGetters: [
                  (phone) => phone.imei,
                  (phone) => "${phone.capacity} GB",
                  (phone) => phone.color,
                  (phone) => phone.carrier,
                  (phone) => phone.status ? "Active" : "Inactive",
                  (phone) => formatCurrency(phone.price),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
