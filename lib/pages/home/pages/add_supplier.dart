import 'package:aromex/models/person.dart'; // Make sure to import Person model
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

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
                              setState(() {});
                            },isMandatory: false,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            title: "Email",
                            textController: supplierEmailController,
                            description: "Enter supplier email",
                            error: supplierEmailError,
                            onChanged: (_) {
                              setState(() {

                              });
                            },isMandatory: false,
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
                                    await _handleAddSupplier();
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

  Future<void> _handleAddSupplier() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Center(child: CircularProgressIndicator());
      },
    );

    try {
      // Check if person with same name already exists
      Person? existingPerson = await _checkPersonExists(
        supplierNameController.text.trim(),
      );

      if (context.mounted) {
        Navigator.of(
          context,
          rootNavigator: true,
        ).pop(); // Close loading dialog
      }

      if (existingPerson != null) {
        // Show confirmation dialog
        bool? shouldConvert = await _showConvertPersonDialog(existingPerson);

        if (shouldConvert == true) {
          // Convert person to supplier
          await _convertPersonToSupplier(existingPerson);
        } else {
          // Don't allow adding with same name
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "A person with this name already exists. Please use a different name or convert the existing person to supplier.",
              ),
            ),
          );
        }
      } else {
        // No existing person, proceed with normal supplier creation
        await _createSupplier();
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(
          context,
          rootNavigator: true,
        ).pop(); // Close loading dialog if still open
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  Future<Person?> _checkPersonExists(String name) async {
    try {
      final snapshot =
          await _firestore
              .collection('Person')
              .where('name', isEqualTo: name)
              .limit(1)
              .get();

      if (snapshot.docs.isNotEmpty) {
        return Person.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      print('Error checking person exists: $e');
      return null;
    }
  }

  Future<bool?> _showConvertPersonDialog(Person person) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Person Already Exists'),
          content: Text(
            'A person named "${person.name}" already exists in your records. '
            'Do you want to convert this person to a supplier?',
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: Text('Convert to Supplier'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _convertPersonToSupplier(Person person) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Center(child: CircularProgressIndicator());
      },
    );

    try {
      // Create supplier with person's data + new data
      Supplier supplier = Supplier(
        name: person.name,
        phone:
            supplierPhoneController.text.isNotEmpty
                ? supplierPhoneController.text
                : person.phone ?? '',
        email:
            supplierEmailController.text.isNotEmpty
                ? supplierEmailController.text
                : person.email ?? '',
        address:
            supplierAddressController.text.isNotEmpty
                ? supplierAddressController.text
                : person.address ?? '',
        createdAt: DateTime.now(),
        updatedAt: Timestamp.now(),
        notes: supplierNotesController.text,
      );

      await supplier.create();

      // Delete the person record
      await _firestore.collection('Person').doc(person.id).delete();

      if (context.mounted) {
        Navigator.of(
          context,
          rootNavigator: true,
        ).pop(); // Close loading dialog
        Navigator.pop(context); // Close add supplier dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Person converted to supplier successfully"),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(
          context,
          rootNavigator: true,
        ).pop(); // Close loading dialog
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error converting person: $e")));
      }
    }
  }

  Future<void> _createSupplier() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Center(child: CircularProgressIndicator());
      },
    );

    try {
      Supplier supplier = Supplier(
        name: supplierNameController.text,
        phone: supplierPhoneController.text,
        email: supplierEmailController.text,
        address: supplierAddressController.text,
        createdAt: DateTime.now(),
        updatedAt: Timestamp.now(),
        notes: supplierNotesController.text,
      );

      await supplier.create();

      if (context.mounted) {
        Navigator.of(
          context,
          rootNavigator: true,
        ).pop(); // Close loading dialog
        Navigator.pop(context); // Close add supplier dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Supplier saved successfully")),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(
          context,
          rootNavigator: true,
        ).pop(); // Close loading dialog
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  bool validate() {
    return supplierNameController.text.isNotEmpty &&
        supplierNameError == null;
  }
}
