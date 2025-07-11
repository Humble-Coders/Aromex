import 'package:aromex/models/phone.dart';
import 'package:aromex/models/phone_brand.dart';
import 'package:aromex/models/phone_model.dart';
import 'package:aromex/models/storage_location.dart';
import 'package:aromex/util.dart';
import 'package:aromex/widgets/custom_text_field.dart';
import 'package:aromex/widgets/searchable_dropdown.dart';
import 'package:flutter/material.dart';

class ProductDetailDialog extends StatefulWidget {
  final Function(Phone) onProductAdded;
  final Phone? prefillWith;
  final List<Phone> allPhones;
  final List<Phone> filteredPhones = [];

  ProductDetailDialog({
    super.key,
    required this.onProductAdded,
    this.prefillWith,
    required this.allPhones,
  });

  @override
  State<ProductDetailDialog> createState() => _ProductDetailDialogState();
}

class _ProductDetailDialogState extends State<ProductDetailDialog> {
  final TextEditingController _costPriceController = TextEditingController();
  final TextEditingController _sellingPriceController = TextEditingController();

  // Phone Brands
  List<PhoneBrand>? brands;
  PhoneBrand? selectedBrand;
  final TextEditingController brandController = TextEditingController();

  // Phone models
  List<PhoneModel>? models;
  PhoneModel? selectedModel;
  final TextEditingController modelController = TextEditingController();

  // Storage Location
  List<StorageLocation>? storageLocations;
  StorageLocation? selectedLocation;
  final TextEditingController locationController = TextEditingController();

  // Carrier
  List<String>? carriers;
  String? selectedCarrier;
  final TextEditingController carrierController = TextEditingController();

  // Capacities
  List<double>? capacities;
  double? selectedCapacity;
  final TextEditingController capacityController = TextEditingController();

  // IMEIs
  List<String>? imeis;
  String? selectedIMEI;
  final TextEditingController imeiController = TextEditingController();

  // Colors
  List<String>? colors;
  String? selectedColor;
  final TextEditingController colorController = TextEditingController();

  // Status
  List<bool>? statuses = [true, false];
  bool? selectedStatus;
  final TextEditingController statusController = TextEditingController();

  // Other utils
  Phone? selectedPhone;

  // Errors
  String? capacityError;
  String? imeiError;
  String? priceError;
  String? colorError;
  String? brandError;
  String? modelError;
  String? locationError;
  String? carrierError;
  String? statusError;

  @override
  void initState() {
    super.initState();

    if (widget.prefillWith != null) {
      prefillWithPhone();
      return;
    }

    refreshPhoneList();
  }

  void prefillWithPhone() async {
    refreshPhoneList();
    final brand = PhoneBrand.fromFirestore(widget.prefillWith!.brand!);
    if (brands!.contains(brand)) {
      selectedBrand = brand;
      brandController.text = brand.name;
      refreshPhoneList();
    }

    final model = PhoneModel.fromFirestore(widget.prefillWith!.model!);
    if (models!.contains(model)) {
      selectedModel = model;
      modelController.text = model.name;
      refreshPhoneList();
    }

    final location = StorageLocation.fromFirestore(
      widget.prefillWith!.storageLocation!,
    );
    if (storageLocations!.contains(location)) {
      selectedLocation = location;
      locationController.text = location.name;
      refreshPhoneList();
    }

    if (carriers!.contains(widget.prefillWith!.carrier)) {
      selectedCarrier = widget.prefillWith!.carrier;
      carrierController.text = widget.prefillWith!.carrier;
      refreshPhoneList();
    }

    if (capacities!.contains(widget.prefillWith!.capacity)) {
      selectedCapacity = widget.prefillWith!.capacity;
      capacityController.text = widget.prefillWith!.capacity.toString();
      refreshPhoneList();
    }

    if (colors!.contains(widget.prefillWith!.color)) {
      selectedColor = widget.prefillWith!.color;
      colorController.text = widget.prefillWith!.color;
      refreshPhoneList();
    }

    if (statuses!.contains(widget.prefillWith!.status)) {
      selectedStatus = widget.prefillWith!.status;
      statusController.text =
          widget.prefillWith!.status ? "Active" : "Inactive";
      refreshPhoneList();
    }

    refreshPhoneList();
  }

  void prefillFromIMEI(String imei) {
    final phoneWithIMEI = widget.allPhones.firstWhere(
      (phone) => phone.imei == imei,
      orElse: () => throw Exception('Phone with IMEI $imei not found'),
    );

    setState(() {
      // Set brand
      selectedBrand = PhoneBrand.fromFirestore(phoneWithIMEI.brand!);
      brandController.text = selectedBrand!.name;

      // Set model
      selectedModel = PhoneModel.fromFirestore(phoneWithIMEI.model!);
      modelController.text = selectedModel!.name;

      // Set storage location
      selectedLocation = StorageLocation.fromFirestore(phoneWithIMEI.storageLocation!);
      locationController.text = selectedLocation!.name;

      // Set carrier
      selectedCarrier = phoneWithIMEI.carrier;
      carrierController.text = phoneWithIMEI.carrier;

      // Set capacity
      selectedCapacity = phoneWithIMEI.capacity;
      capacityController.text = phoneWithIMEI.capacity.toString();

      // Set color
      selectedColor = phoneWithIMEI.color;
      colorController.text = phoneWithIMEI.color;

      // Set status
      selectedStatus = phoneWithIMEI.status;
      statusController.text = phoneWithIMEI.status ? "Active" : "Inactive";

      // Set IMEI
      selectedIMEI = imei;
      imeiController.text = imei;
    });

    // Refresh the phone list to update all dropdowns
    refreshPhoneList();
  }

  void refreshPhoneList() {
    // If errors, return
    if (hasErrors()) return;

    widget.filteredPhones.clear();
    for (var phone in widget.allPhones) {
      if (selectedBrand != null && phone.brand!.id != selectedBrand!.id) {
        continue;
      } else if (selectedModel != null &&
          phone.model!.id != selectedModel!.id) {
        continue;
      } else if (selectedCarrier != null && phone.carrier != selectedCarrier) {
        continue;
      } else if (selectedLocation != null &&
          phone.storageLocationRef!.id != selectedLocation!.id) {
        continue;
      } else if (selectedCapacity != null &&
          phone.capacity != selectedCapacity) {
        continue;
      } else if (selectedIMEI != null && phone.imei != selectedIMEI) {
        continue;
      } else if (selectedColor != null && phone.color != selectedColor) {
        continue;
      } else if (selectedStatus != null && phone.status != selectedStatus) {
        continue;
      }
      widget.filteredPhones.add(phone);
    }

    setState(() {
      // Update all lists
      brands =
          widget.filteredPhones
              .map((e) => PhoneBrand.fromFirestore(e.brand!))
              .toSet()
              .toList();
      models =
          widget.filteredPhones
              .map((e) => PhoneModel.fromFirestore(e.model!))
              .toSet()
              .toList();
      storageLocations =
          widget.filteredPhones
              .map((e) => StorageLocation.fromFirestore(e.storageLocation!))
              .toSet()
              .toList();
      carriers = widget.filteredPhones.map((e) => e.carrier).toSet().toList();
      capacities =
          widget.filteredPhones.map((e) => e.capacity).toSet().toList();
      imeis = widget.filteredPhones.map((e) => e.imei).toSet().toList();
      colors = widget.filteredPhones.map((e) => e.color).toSet().toList();
      statuses = widget.filteredPhones.map((e) => e.status).toSet().toList();
    });

    // Check if all fields are filled
    setState(() {
      if (allFieldsFilled()) {
        selectedPhone = widget.filteredPhones.first;
        _costPriceController.text = selectedPhone!.price.toString();
      } else {
        selectedPhone = null;
        _costPriceController.text = "NA";
        _sellingPriceController.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Card(
      color: colorScheme.secondary,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Enter product details",
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Flexible(
                  flex: 1,
                  child: SearchableDropdown(
                    title: "Brand",
                    description: "The brand of the phone",
                    items: brands,
                    selectedItem: selectedBrand,
                    controller: brandController,
                    onChanged: (brand) {
                      selectedBrand = brand;
                      refreshPhoneList();
                    },
                    onClear: () {
                      selectedBrand = null;
                      refreshPhoneList();
                    },
                    getLabel: (brand) => brand.name,
                  ),
                ),
                const SizedBox(width: 16),
                Flexible(
                  child: SearchableDropdown<PhoneModel>(
                    title: "Model",
                    description: "The model of the phone",
                    selectedItem: selectedModel,
                    controller: modelController,
                    onClear: () {
                      selectedModel = null;
                      refreshPhoneList();
                    },
                    items: models,
                    getLabel: (model) => model.name,
                    onChanged: (model) {
                      selectedModel = model;
                      refreshPhoneList();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Flexible(
                  flex: 1,
                  child: SearchableDropdown<double>(
                    title: "Capacity",
                    description: "The capacity of the phone",
                    items: capacities,
                    selectedItem: selectedCapacity,
                    onChanged: (capacity) {
                      selectedCapacity = capacity;
                      refreshPhoneList();
                    },
                    getLabel: (capacity) {
                      return "${capacity.toString()} GB";
                    },
                    controller: capacityController,
                    onClear: () {
                      selectedCapacity = null;
                      refreshPhoneList();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Flexible(
                  flex: 1,
                  child: SearchableDropdown<String>(
                    title: "IMEI/Serial",
                    description: "The IMEI of the phone",
                    items: imeis,
                    selectedItem: selectedIMEI,
                    onChanged: (imei) {
                      selectedIMEI = imei;
                      if (imei != null) {
                        prefillFromIMEI(imei);
                      } else {
                        refreshPhoneList();
                      }
                    },
                    getLabel: (imei) => imei,
                    controller: imeiController,
                    onClear: () {
                      selectedIMEI = null;
                      refreshPhoneList();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Flexible(
                  flex: 1,
                  child: SearchableDropdown(
                    title: "Carrier",
                    description: "The carrier phone is locked to",
                    items: carriers,
                    selectedItem: selectedCarrier,
                    onChanged: (carrier) {
                      selectedCarrier = carrier;
                      refreshPhoneList();
                    },
                    getLabel: (carrier) => carrier,
                    controller: carrierController,
                    onClear: () {
                      selectedCarrier = null;
                      refreshPhoneList();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Flexible(
                  flex: 1,
                  child: SearchableDropdown<String>(
                    title: "Color",
                    description: "The color of the phone",
                    items: colors,
                    selectedItem: selectedColor,
                    onChanged: (color) {
                      selectedColor = color;
                      refreshPhoneList();
                    },
                    getLabel: (color) => color,
                    controller: colorController,
                    onClear: () {
                      selectedColor = null;
                      refreshPhoneList();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: SearchableDropdown(
                    title: "Status",
                    description:
                        "Whether the phone is active and ready for sale",
                    error: statusError,
                    items: statuses,
                    selectedItem: selectedStatus,
                    onChanged: (status) {
                      setState(() {
                        selectedStatus = status!;
                        refreshPhoneList();
                      });
                    },
                    getLabel: (status) => status ? "Active" : "Inactive",
                    controller: statusController,
                    onClear: () {
                      setState(() {
                        selectedStatus = null;
                        refreshPhoneList();
                      });
                    },
                  ),
                ),

                const SizedBox(width: 16),
                Flexible(
                  flex: 1,
                  child: SearchableDropdown<StorageLocation>(
                    title: "Storage Location",
                    description: "Where the phone is stored",
                    error: locationError,
                    items: storageLocations,
                    selectedItem: selectedLocation,
                    onChanged: (location) {
                      selectedLocation = location;
                      refreshPhoneList();
                    },
                    getLabel: (location) => location.name,
                    controller: locationController,
                    onClear: () {
                      selectedLocation = null;
                      refreshPhoneList();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Flexible(
                  flex: 1,
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Expanded(
                        child: CustomTextField(
                          title: "Cost Price",
                          textController: _costPriceController,
                          isReadOnly: true,
                          onChanged: (val) {
                            setState(() {
                              try {
                                double.parse(val.trim());
                                priceError = null;
                              } catch (_) {}
                            });
                          },
                          description: "Base price per unit",
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: CustomTextField(
                          title: "Selling Price",
                          textController: _sellingPriceController,
                          isReadOnly: selectedPhone == null,
                          error: priceError,
                          onChanged: (val) {
                            setState(() {
                              try {
                                double.parse(val.trim());
                                priceError = null;
                              } catch (_) {
                                // Set error
                                priceError = "Invalid price";
                              }
                            });
                          },
                          description:
                              (_sellingPriceController.text.trim().isNotEmpty &&
                                      !hasErrors())
                                  ? "P&L: ${formatCurrency(double.parse(_sellingPriceController.text.trim()) - selectedPhone!.price)}"
                                  : "Base price per unit",
                          descriptionStyle: textTheme.bodySmall?.copyWith(
                            color:
                                priceError != null
                                    ? colorScheme.error
                                    : selectedPhone != null &&
                                        !hasErrors() &&
                                        _sellingPriceController.text
                                            .trim()
                                            .isNotEmpty
                                    ? (double.parse(
                                                  _sellingPriceController.text
                                                      .trim(),
                                                ) -
                                                selectedPhone!.price >
                                            0
                                        ? Colors.green
                                        : Colors.red)
                                    : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                    backgroundColor: colorScheme.primary,
                  ),
                  child: Text(
                    "Cancel",
                    style: TextStyle(color: colorScheme.onPrimary),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed:
                      !(validate())
                          ? null
                          : () {
                            widget.onProductAdded(
                              selectedPhone!
                                ..sellingPrice = double.parse(
                                  _sellingPriceController.text.trim(),
                                ),
                            );
                          },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                    backgroundColor: colorScheme.primary,
                  ),
                  child: Text(
                    "Add Product",
                    style: TextStyle(color: colorScheme.onPrimary),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool hasErrors() {
    return capacityError != null ||
        imeiError != null ||
        priceError != null ||
        colorError != null ||
        brandError != null ||
        modelError != null ||
        locationError != null ||
        carrierError != null ||
        statusError != null;
  }

  bool allFieldsFilled() {
    return selectedBrand != null &&
        selectedModel != null &&
        selectedCarrier != null &&
        selectedLocation != null &&
        selectedCapacity != null &&
        selectedIMEI != null &&
        selectedColor != null &&
        selectedStatus != null;
  }

  bool validate() {
    return !hasErrors() &&
        allFieldsFilled() &&
        selectedPhone != null &&
        _sellingPriceController.text.trim().isNotEmpty;
  }
}