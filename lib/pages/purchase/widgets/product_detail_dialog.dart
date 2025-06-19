import 'package:aromex/models/phone.dart';
import 'package:aromex/models/phone_brand.dart';
import 'package:aromex/models/phone_model.dart';
import 'package:aromex/models/storage_location.dart';
import 'package:aromex/models/util.dart';
import 'package:aromex/services/carriers.dart';
import 'package:aromex/widgets/custom_text_field.dart';
import 'package:aromex/widgets/searchable_dropdown.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProductDetailDialog extends StatefulWidget {
  final Function(Phone) onProductAdded;
  final Phone? prefillWith;

  const ProductDetailDialog({
    super.key,
    required this.onProductAdded,
    this.prefillWith,
  });

  @override
  State<ProductDetailDialog> createState() => _ProductDetailDialogState();
}

class _ProductDetailDialogState extends State<ProductDetailDialog> {
  final TextEditingController _capacityController = TextEditingController();
  final TextEditingController _imeiController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  bool _isActive = true;

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

  // Errors
  String? capacityError;
  String? imeiError;
  String? priceError;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    if (widget.prefillWith != null) {
      prefillWithPhone();
      return;
    }

    getBrands();
    getStorageLocations();
    getCarriers();
  }

  void prefillWithPhone() async {
    Future.wait(<Future<void>>[
      () async {
        await getBrands();
        selectedBrand = PhoneBrand.fromFirestore(widget.prefillWith!.brand!);
        brandController.text = selectedBrand!.name;
        await getModels();
        selectedModel = PhoneModel.fromFirestore(widget.prefillWith!.model!);
        modelController.text = selectedModel!.name;
        setState(() {});
      }(),
      () async {
        await getStorageLocations();
        selectedLocation = StorageLocation.fromFirestore(
          widget.prefillWith!.storageLocation!,
        );
        locationController.text = selectedLocation!.name;
        setState(() {});
      }(),
      () async {
        await getCarriers();
        selectedCarrier = widget.prefillWith!.carrier;
        carrierController.text = selectedCarrier!;
        setState(() {});
      }(),
    ]);

    _capacityController.text = widget.prefillWith!.capacity.toString();
    _imeiController.text = widget.prefillWith!.imei;
    _colorController.text = widget.prefillWith!.color;
    _priceController.text = widget.prefillWith!.price.toString();
    _isActive = widget.prefillWith!.status;

    setState(() {});
  }

  Future<void> getCarriers() async {
    carriers = await FirestoreHelper.findById<List<String>>(
      "Carriers",
      (DocumentSnapshot doc) => List<String>.from(doc["carriers"] as List),
      "Data",
    );

    setState(() {
      // carriers = carriers;
    });
  }

  Future<void> getStorageLocations() async {
    storageLocations = await FirestoreHelper.getAll(
      StorageLocation.fromFirestore,
      FirebaseFirestore.instance.collection(StorageLocation.collectionName),
    );
    setState(() {
      // storageLocations = storageLocations;
    });
  }

  Future<void> getBrands() async {
    brands = await FirestoreHelper.getAll(
      PhoneBrand.fromFirestore,
      FirebaseFirestore.instance.collection(PhoneBrand.collectionName),
    );
    setState(() {
      // brands = brands;
    });
  }

  Future<void> getModels() async {
    setState(() {
      selectedModel = null;
      models = null;
    });

    if (selectedBrand == null || selectedBrand!.snapshot == null) return;

    final modelsCollection = selectedBrand!.snapshot!.reference.collection(
      "Models",
    );

    models = await FirestoreHelper.getAll(
      PhoneModel.fromFirestore,
      modelsCollection,
    );

    setState(() {});
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
                  child: SearchableDropdown<PhoneBrand>(
                    title: "Brand",
                    description: "The brand of the phone",
                    items: brands,
                    selectedItem: selectedBrand,
                    onChanged: (brand) {
                      setState(() {
                        selectedBrand = brand;
                        selectedModel = null;
                        models = null;
                      });
                      getModels();
                    },
                    getLabel: (brand) => brand.name,
                    controller: brandController,
                    onClear: () {
                      setState(() {
                        selectedBrand = null;
                        selectedModel = null;
                        modelController.clear();
                        models = null;
                      });
                    },
                    allowAddingNew: true,
                    defaultConstructor: () => PhoneBrand.empty(),
                    onNewItemSelected: (item) async {
                      setState(() {
                        selectedBrand = null;
                        selectedModel = null;
                        models = null;
                        modelController.clear();
                        brandController.text = "Creating brand...";
                      });

                      // Create a new brand
                      final newBrand = PhoneBrand(name: item);
                      await newBrand.create();

                      await getBrands();

                      // Set the new brand as selected
                      setState(() {
                        selectedBrand =
                            brands!.where((brand) => brand == newBrand).first;
                        brandController.text = newBrand.name;
                      });

                      getModels();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Flexible(
                  child: SearchableDropdown<PhoneModel>(
                    title: "Model",
                    description: "The model of the phone",
                    hintText:
                        selectedBrand == null ? "Select a brand first" : null,
                    items: models,
                    selectedItem: selectedModel,
                    onChanged: (model) {
                      setState(() {
                        selectedModel = model;
                      });
                    },
                    getLabel: (model) => model.name,
                    controller: modelController,
                    onClear: () {
                      setState(() {
                        selectedModel = null;
                      });
                    },
                    allowAddingNew: selectedBrand != null,
                    defaultConstructor:
                        selectedBrand != null
                            ? () => PhoneModel.empty(
                              selectedBrand!.snapshot!.reference,
                            )
                            : null,
                    onNewItemSelected: (model) async {
                      setState(() {
                        selectedModel = null;
                        modelController.text = "Creating model...";
                      });

                      // Create a new model
                      final newModel = PhoneModel(
                        name: model,
                        brand: selectedBrand!.snapshot!.reference,
                      );
                      await newModel.create();
                      await getModels();

                      // Set the new model as selected
                      setState(() {
                        selectedModel =
                            models!.where((m) => m.id == newModel.id).first;
                        modelController.text = newModel.name;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Flexible(
                  flex: 1,
                  child: CustomTextField(
                    title: "Capacity (GB)",
                    textController: _capacityController,
                    error: capacityError,
                    onChanged: (val) {
                      setState(() {
                        try {
                          double.parse(val.trim());
                          capacityError = null;
                        } catch (_) {
                          // Set error
                          capacityError = "Invalid capacity";
                        }
                      });
                    },
                    description: "The storage capacity of the phone",
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Flexible(
                  flex: 1,
                  child: CustomTextField(
                    isMandatory: false,
                    title: "IMEI/Serial",
                    textController: _imeiController,
                    error: imeiError,
                    onChanged: (val) {
                      setState(() {
                        // regex to check if only numbers
                        imeiError = null;
                      });
                    },
                    description: "The IMEI number of the phone",
                  ),
                ),
                const SizedBox(width: 16),
                Flexible(
                  flex: 1,
                  child: SearchableDropdown<String>(
                    title: "Carrier",
                    description: "The carrier phone is locked to",
                    items: carriers,
                    selectedItem: selectedCarrier,
                    onChanged: (carrier) {
                      setState(() {
                        selectedCarrier = carrier;
                      });
                    },
                    getLabel: (carrier) => carrier,
                    controller: carrierController,
                    onClear: () {
                      setState(() {
                        selectedCarrier = null;
                      });
                    },
                    allowAddingNew: true,
                    defaultConstructor: () => "",
                    onNewItemSelected: (item) async {
                      setState(() {
                        selectedCarrier = null;
                        carrierController.text = "Creating carrier...";
                      });

                      // Create a new carrier
                      final newCarrier = item;
                      await createCarrier(newCarrier);

                      await getCarriers();

                      // Set the new carrier as selected
                      setState(() {
                        selectedCarrier = newCarrier;
                        carrierController.text = newCarrier;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Flexible(
                  flex: 1,
                  child: CustomTextField(
                    title: "Color",
                    textController: _colorController,
                    onChanged: (_) {
                      setState(() {});
                    },
                    description: "The color of the phone",
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Status",
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Switch(
                            value: _isActive,
                            onChanged: (value) {
                              setState(() {
                                _isActive = value;
                              });
                            },
                            activeColor: Colors.green,
                          ),
                          Text(
                            _isActive ? "Active" : "Inactive",
                            style: TextStyle(
                              color:
                                  _isActive
                                      ? Colors.green
                                      : colorScheme.onPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Whether the phone is active and ready for sale",
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Flexible(
                  flex: 1,
                  child: CustomTextField(
                    title: "Price",
                    textController: _priceController,
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
                    description: "Base price per unit",
                  ),
                ),
                const SizedBox(width: 16),
                Flexible(
                  flex: 1,
                  child: SearchableDropdown<StorageLocation>(
                    title: "Storage Location",
                    description: "Where the phone will be stored",
                    items: storageLocations,
                    selectedItem: selectedLocation,
                    onChanged: (location) {
                      setState(() {
                        selectedLocation = location;
                      });
                    },
                    getLabel: (location) => location.name,
                    controller: locationController,
                    onClear: () {
                      setState(() {
                        selectedLocation = null;
                      });
                    },
                    allowAddingNew: true,
                    defaultConstructor: () => StorageLocation.empty(),
                    onNewItemSelected: (item) async {
                      setState(() {
                        selectedLocation = null;
                        locationController.text = "Creating location...";
                      });

                      // Create a new location
                      final newLocation = StorageLocation(name: item);
                      await newLocation.create();

                      await getStorageLocations();

                      // Set the new location as selected
                      setState(() {
                        for (final location in storageLocations!) {
                          if (location.name == newLocation.name) {
                            selectedLocation = location;
                          }
                        }
                        locationController.text = newLocation.name;
                      });
                    },
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
                            // Create phone out of the data
                            Phone phone = Phone(
                              brand: selectedBrand!.snapshot,
                              model: selectedModel!.snapshot,
                              modelRef: selectedModel!.snapshot!.reference,
                              brandRef: selectedBrand!.snapshot!.reference,
                              capacity: double.parse(
                                _capacityController.text.trim(),
                              ),
                              imei:
                                  _imeiController.text.trim().isNotEmpty
                                      ? _imeiController.text.trim()
                                      : "-",
                              color: _colorController.text.trim(),
                              price: double.parse(_priceController.text.trim()),
                              status: _isActive,
                              carrier: selectedCarrier!,
                              storageLocation: selectedLocation!.snapshot,
                              storageLocationRef:
                                  selectedLocation!.snapshot!.reference,
                            );

                            widget.onProductAdded(phone);
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
    return capacityError != null || imeiError != null || priceError != null;
  }

  bool allFieldsFilled() {
    return _capacityController.text.trim().isNotEmpty &&
        _colorController.text.trim().isNotEmpty &&
        _priceController.text.trim().isNotEmpty &&
        selectedBrand != null &&
        selectedModel != null &&
        selectedCarrier != null &&
        selectedLocation != null;
  }

  bool validate() {
    return !hasErrors() && allFieldsFilled();
  }
}
