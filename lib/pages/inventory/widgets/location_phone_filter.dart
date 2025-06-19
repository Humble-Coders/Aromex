import 'package:aromex/models/phone_brand.dart';
import 'package:aromex/models/storage_location.dart';
import 'package:aromex/widgets/searchable_dropdown.dart';
import 'package:flutter/material.dart';

class LocationPhoneFilter extends StatefulWidget {
  final List<int>? capacities;
  final List<String>? colors;
  final List<String>? carriers;
  final List<bool>? isActive;

  final void Function(
    int? capacity,
    String? color,
    String? carrier,
    bool? status,
  )
  onFilterChanged;

  const LocationPhoneFilter({
    super.key,
    required this.capacities,
    required this.colors,
    required this.carriers,
    required this.isActive,
    required this.onFilterChanged,
  });

  @override
  State<LocationPhoneFilter> createState() => _LocationPhoneFilterState();
}

class _LocationPhoneFilterState extends State<LocationPhoneFilter> {
  int? selectedCapacity;
  String? selectedColor;
  String? selectedCarrier;
  bool? selectedIsActive;

  final TextEditingController capacityController = TextEditingController();
  final TextEditingController colorController = TextEditingController();
  final TextEditingController carrierController = TextEditingController();
  final TextEditingController isActiveController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: SearchableDropdown<int>(
                    title: "Capacity",
                    items: widget.capacities,
                    selectedItem: selectedCapacity,
                    onChanged: (value) {
                      selectedCapacity = value;
                      widget.onFilterChanged(
                        selectedCapacity,
                        selectedColor,
                        selectedCarrier,
                        selectedIsActive,
                      );
                    },
                    onClear: () {
                      selectedCapacity = null;
                      widget.onFilterChanged(
                        null,
                        selectedColor,
                        selectedCarrier,
                        selectedIsActive,
                      );
                    },
                    hintText: "All capacities",
                    getLabel: (int capacity) => "$capacity GB",
                    controller: capacityController,
                    isMandatory: false,
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: SearchableDropdown<String>(
                    title: "Color",
                    items: widget.colors,
                    selectedItem: selectedColor,
                    onChanged: (value) {
                      selectedColor = value;
                      widget.onFilterChanged(
                        selectedCapacity,
                        selectedColor,
                        selectedCarrier,
                        selectedIsActive,
                      );
                    },
                    onClear: () {
                      selectedColor = null;
                      widget.onFilterChanged(
                        selectedCapacity,
                        null,
                        selectedCarrier,
                        selectedIsActive,
                      );
                    },
                    hintText: "All colors",
                    getLabel: (String color) => color,
                    controller: colorController,
                    isMandatory: false,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SearchableDropdown<String>(
                    title: "Carrier",
                    items: widget.carriers,
                    selectedItem: selectedCarrier,
                    onChanged: (value) {
                      selectedCarrier = value;
                      widget.onFilterChanged(
                        selectedCapacity,
                        selectedColor,
                        selectedCarrier,
                        selectedIsActive,
                      );
                    },
                    onClear: () {
                      selectedCarrier = null;
                      widget.onFilterChanged(
                        selectedCapacity,
                        selectedColor,
                        null,
                        selectedIsActive,
                      );
                    },
                    hintText: "All carriers",
                    getLabel: (String carrier) => carrier,
                    controller: carrierController,
                    isMandatory: false,
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: SearchableDropdown<bool>(
                    title: "Active",
                    items: widget.isActive,
                    selectedItem: selectedIsActive,
                    onChanged: (value) {
                      selectedIsActive = value;
                      widget.onFilterChanged(
                        selectedCapacity,
                        selectedColor,
                        selectedCarrier,
                        selectedIsActive,
                      );
                    },
                    onClear: () {
                      selectedIsActive = null;
                      widget.onFilterChanged(
                        selectedCapacity,
                        selectedColor,
                        selectedCarrier,
                        null,
                      );
                    },
                    hintText: "All statuses",
                    getLabel: (bool active) => active ? "Active" : "Inactive",
                    controller: isActiveController,
                    isMandatory: false,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
