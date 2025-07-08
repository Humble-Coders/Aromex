import 'package:aromex/models/customer.dart';
import 'package:aromex/models/person.dart'; // Make sure to import Person model
import 'package:aromex/util.dart';
import 'package:aromex/widgets/custom_text_field.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddCustomer extends StatefulWidget {
  const AddCustomer({super.key});

  @override
  State<AddCustomer> createState() => _AddCustomerState();
}

class _AddCustomerState extends State<AddCustomer> {
  final TextEditingController customerNameController = TextEditingController();
  final TextEditingController customerPhoneController = TextEditingController();
  final TextEditingController customerEmailController = TextEditingController();
  final TextEditingController customerAddressController =
      TextEditingController();
  final TextEditingController customerNotesController = TextEditingController();

  // Errors
  String? customerNameError;
  String? customerPhoneError;
  String? customerEmailError;

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
                "Add Customer",
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
                            error: customerNameError,
                            textController: customerNameController,
                            description: "Enter customer name",
                            onChanged: (val) {
                              setState(() {
                                if (validateName(val)) {
                                  customerNameError = null;
                                } else {
                                  customerNameError = "Invalid name";
                                }
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            title: "Phone",
                            textController: customerPhoneController,
                            description: "Enter customer phone",
                            //    error: customerPhoneError,
                            onChanged: (val) {
                              setState(() {});
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            title: "Email",
                            error: customerEmailError,
                            textController: customerEmailController,
                            description: "Enter customer email",
                            onChanged: (val) {
                              setState(() {
                                if (validateEmail(val)) {
                                  customerEmailError = null;
                                } else {
                                  customerEmailError = "Invalid email";
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
                            textController: customerAddressController,
                            description: "Enter customer address",
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
                            textController: customerNotesController,
                            description: "Enter customer notes",
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
                          onHover: (isHover) {
                            if (isHover) {
                              if (!validate()) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Please fill")),
                                );
                              }
                            }
                          },
                          onPressed:
                              !(validate())
                                  ? null
                                  : () async {
                                    await _handleAddCustomer();
                                  },
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 16,
                            ),
                            backgroundColor: colorScheme.primary,
                          ),
                          child: Text(
                            "Add Customer",
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

  Future<void> _handleAddCustomer() async {
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
        customerNameController.text.trim(),
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
          // Convert person to customer
          await _convertPersonToCustomer(existingPerson);
        } else {
          // Don't allow adding with same name
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "A person with this name already exists. Please use a different name or convert the existing person to customer.",
              ),
            ),
          );
        }
      } else {
        // No existing person, proceed with normal customer creation
        await _createCustomer();
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
            'Do you want to convert this person to a customer?',
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: Text('Convert to Customer'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _convertPersonToCustomer(Person person) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Center(child: CircularProgressIndicator());
      },
    );

    try {
      // Create customer with person's data + new data
      Customer customer = Customer(
        name: person.name,
        phone:
            customerPhoneController.text.isNotEmpty
                ? customerPhoneController.text
                : person.phone ?? '',
        email:
            customerEmailController.text.isNotEmpty
                ? customerEmailController.text
                : person.email ?? '',
        address:
            customerAddressController.text.isNotEmpty
                ? customerAddressController.text
                : person.address ?? '',
        createdAt: DateTime.now(),
        updatedAt: Timestamp.now(),
        notes: customerNotesController.text,
      );

      await customer.create();

      // Delete the person record
      await _firestore.collection('Person').doc(person.id).delete();

      if (context.mounted) {
        Navigator.of(
          context,
          rootNavigator: true,
        ).pop(); // Close loading dialog
        Navigator.pop(context); // Close add customer dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Person converted to customer successfully"),
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

  Future<void> _createCustomer() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Center(child: CircularProgressIndicator());
      },
    );

    try {
      Customer customer = Customer(
        name: customerNameController.text,
        phone: customerPhoneController.text,
        email: customerEmailController.text,
        address: customerAddressController.text,
        createdAt: DateTime.now(),
        updatedAt: Timestamp.now(),
        notes: customerNotesController.text,
      );

      await customer.create();

      if (context.mounted) {
        Navigator.of(
          context,
          rootNavigator: true,
        ).pop(); // Close loading dialog
        Navigator.pop(context); // Close add customer dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Customer saved successfully")),
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
    return customerNameError == null &&
        customerPhoneError == null &&
        customerNameController.text.isNotEmpty &&
        customerPhoneController.text.isNotEmpty &&
        customerEmailController.text.isNotEmpty;
  }
}
