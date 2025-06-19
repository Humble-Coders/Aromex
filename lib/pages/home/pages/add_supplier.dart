import 'package:aromex/models/supplier.dart';
import 'package:aromex/util.dart';
import 'package:aromex/widgets/custom_text_field.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddSupplier extends StatefulWidget {
  const AddSupplier({super.key});

  @override
  State<AddSupplier> createState() => _AddSupplierState();
}

class _AddSupplierState extends State<AddSupplier> {
  // Controllers
  final TextEditingController supplierNameController = TextEditingController();
  final TextEditingController supplierPhoneController = TextEditingController();
  final TextEditingController supplierEmailController = TextEditingController();
  final TextEditingController supplierAddressController =
      TextEditingController();
  final TextEditingController supplierNotesController = TextEditingController();

  // Errors
  String? supplierNameError;
  String? supplierPhoneError;
  String? supplierEmailError;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Card(
      color: colorScheme.secondary,
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(36.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Add Supplier",
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.secondary,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colorScheme.onSurfaceVariant.withAlpha(50),
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            title: "Name",
                            textController: supplierNameController,
                            description: "Enter supplier name",
                            error: supplierNameError,
                            onChanged: (val) {
                              setState(() {
                                if (validateName(val)) {
                                  supplierNameError = null;
                                } else {
                                  supplierNameError = "Name cannot be empty";
                                }
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            title: "Phone",
                            textController: supplierPhoneController,
                            description: "Enter supplier phone",
                            error: supplierPhoneError,
                            onChanged: (val) {
                              setState(() {
                                if (validatePhone(val)) {
                                  supplierPhoneError = null;
                                } else {
                                  supplierPhoneError = "Invalid phone number";
                                }
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            title: "Email",
                            textController: supplierEmailController,
                            description: "Enter supplier email",
                            error: supplierEmailError,
                            onChanged: (val) {
                              setState(() {
                                if (validateEmail(val)) {
                                  supplierEmailError = null;
                                } else {
                                  supplierEmailError = "Invalid email address";
                                }
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            title: "Address",
                            textController: supplierAddressController,
                            description: "Enter supplier address",
                            onChanged: (_) {
                              setState(() {});
                            },
                            isMandatory: false,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            title: "Notes",
                            textController: supplierNotesController,
                            description: "Enter supplier notes",
                            onChanged: (_) {
                              setState(() {});
                            },
                            isMandatory: false,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            padding: EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 16,
                            ),
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
                                  : () async {
                                    Supplier supplier = Supplier(
                                      name: supplierNameController.text,
                                      phone: supplierPhoneController.text,
                                      email: supplierEmailController.text,
                                      address: supplierAddressController.text,
                                      createdAt: DateTime.now(),
                                      updatedAt: Timestamp.now(),
                                      notes: supplierNotesController.text,
                                    );
                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (context) {
                                        return Center(
                                          child: CircularProgressIndicator(),
                                        );
                                      },
                                    );
                                    try {
                                      await supplier.create();
                                      if (context.mounted) {
                                        Navigator.of(
                                          context,
                                          rootNavigator: true,
                                        ).pop(); // closes dialog
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              "Supplier saved successfully",
                                            ),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        if (context.mounted) {
                                          Navigator.pop(context);
                                        }
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(content: Text("Error: $e")),
                                        );
                                      }
                                    }
                                  },
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 16,
                            ),
                            backgroundColor: colorScheme.primary,
                          ),
                          child: Text(
                            "Add Supplier",
                            style: TextStyle(color: colorScheme.onPrimary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool validate() {
    return supplierNameController.text.isNotEmpty &&
        supplierPhoneController.text.isNotEmpty &&
        supplierEmailController.text.isNotEmpty &&
        supplierNameError == supplierEmailError &&
        supplierPhoneError == null;
  }
}
