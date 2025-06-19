import 'package:aromex/models/phone_brand.dart';
import 'package:aromex/models/storage_location.dart';
import 'package:aromex/widgets/searchable_dropdown.dart';
import 'package:flutter/material.dart';

class LocationBrandFilter extends StatelessWidget {
  final List<StorageLocation>? storageLocations;
  final List<PhoneBrand>? phoneBrands;
  final void Function(StorageLocation?) onLocationSelected;
  final void Function(PhoneBrand?) onBrandSelected;
  final StorageLocation? selectedStorageLocation;
  final PhoneBrand? selectedPhoneBrand;

  const LocationBrandFilter({
    super.key,
    required this.storageLocations,
    required this.phoneBrands,
    required this.onLocationSelected,
    required this.onBrandSelected,
    required this.selectedStorageLocation,
    required this.selectedPhoneBrand,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          children: [
            Expanded(
              child: SearchableDropdown<StorageLocation>(
                title: "Location",
                items: storageLocations,
                selectedItem: selectedStorageLocation,
                onChanged: onLocationSelected,
                getLabel: (StorageLocation location) => location.name,
                controller: TextEditingController(
                  text: selectedStorageLocation?.name ?? "",
                ),
                onClear: () => onLocationSelected(null),
                isMandatory: false,
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: SearchableDropdown<PhoneBrand>(
                title: "Brand",
                items: phoneBrands,
                selectedItem: selectedPhoneBrand,
                onChanged: onBrandSelected,
                getLabel: (PhoneBrand brand) => brand.name,
                controller: TextEditingController(
                  text: selectedPhoneBrand?.name ?? "",
                ),
                onClear: () => onBrandSelected(null),
                isMandatory: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
