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

  // Focus nodes to detect field changes
  final FocusNode nameFocusNode = FocusNode();
  final FocusNode phoneFocusNode = FocusNode();
  final FocusNode emailFocusNode = FocusNode();

  // Loading state for name check
  bool isCheckingName = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();

    // Add listener to name focus node to check when user moves away from name field
    nameFocusNode.addListener(() {
      if (!nameFocusNode.hasFocus && customerNameController.text.trim().isNotEmpty) {
        _checkNameExists();
      }
    });
  }

  @override
  void dispose() {
    nameFocusNode.dispose();
    phoneFocusNode.dispose();
    emailFocusNode.dispose();
    customerNameController.dispose();
    customerPhoneController.dispose();
    customerEmailController.dispose();
    customerAddressController.dispose();
    customerNotesController.dispose();
    super.dispose();
  }

  Future<void> _checkNameExists() async {
    final name = customerNameController.text.trim();
    if (name.isEmpty) return;

    setState(() {
      isCheckingName = true;
      customerNameError = null;
    });

    try {
      print('🔍 Checking name: $name'); // Debug log

      // Check if customer with same name already exists (case insensitive)
      final customerQuery = await _firestore
          .collection('Customers')
          .get();

      print('🔍 Found ${customerQuery.docs.length} customers'); // Debug log

      bool customerExists = customerQuery.docs.any((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final existingName = data['name'] as String? ?? '';
        print('🔍 Comparing customer: "${existingName.toLowerCase()}" with "${name.toLowerCase()}"'); // Debug log
        return existingName.toLowerCase() == name.toLowerCase();
      });

      if (customerExists) {
        // Customer already exists
        setState(() {
          customerNameError = "A customer with this name already exists";
          isCheckingName = false;
        });
        return;
      }

      print('🔍 No duplicate customer found, checking Person collection...'); // Debug log

      // Check if person with same name exists (case insensitive)
      final personQuery = await _firestore
          .collection('Person')
          .get();

      print('🔍 Found ${personQuery.docs.length} persons'); // Debug log

      DocumentSnapshot? existingPersonDoc;
      for (var doc in personQuery.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final existingName = data['name'] as String? ?? '';
        print('🔍 Comparing person: "${existingName.toLowerCase()}" with "${name.toLowerCase()}"'); // Debug log

        if (existingName.toLowerCase() == name.toLowerCase()) {
          existingPersonDoc = doc;
          print('🔍 Found matching person: ${existingName}'); // Debug log
          break;
        }
      }

      if (existingPersonDoc != null) {
        print('🔍 Converting person to customer dialog...'); // Debug log
        final person = Person.fromFirestore(existingPersonDoc);

        // Show dialog asking if user wants to convert person to customer
        final shouldConvert = await _showConvertPersonDialog(person);

        if (shouldConvert == true) {
          await _convertPersonToCustomer(person);
        }
      } else {
        print('🔍 No matching person found'); // Debug log
      }

    } catch (e) {
      print('🔴 Error checking name: $e');
    } finally {
      setState(() {
        isCheckingName = false;
      });
    }
  }

  Future<bool?> _showConvertPersonDialog(Person person) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Person Found'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('A person named "${person.name}" already exists with the following details:'),
              const SizedBox(height: 8),
              if (person.phone.isNotEmpty) Text('Phone: ${person.phone}'),
              if (person.email.isNotEmpty) Text('Email: ${person.email}'),
              if (person.address.isNotEmpty) Text('Address: ${person.address}'),
              if (person.notes.isNotEmpty) Text('Notes: ${person.notes}'),
              const SizedBox(height: 16),
              Text('Do you want to convert this person to a customer?'),
            ],
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
      // Pre-fill form fields with person's data
      setState(() {
        customerNameController.text = person.name;
        if (person.phone.isNotEmpty) customerPhoneController.text = person.phone;
        if (person.email.isNotEmpty) customerEmailController.text = person.email;
        if (person.address.isNotEmpty) customerAddressController.text = person.address;
        if (person.notes.isNotEmpty) customerNotesController.text = person.notes;
      });

      // Create customer with person's data
      Customer customer = Customer(
        name: person.name,
        phone: person.phone,
        email: person.email,
        address: person.address,
        createdAt: DateTime.now(),
        updatedAt: Timestamp.now(),
        notes: person.notes,
        balance: person.balance, // Keep existing balance
      );

      await customer.create();

      // Delete the person record
      await _firestore.collection('Person').doc(person.id).delete();

      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Close loading dialog
        Navigator.pop(context); // Close add customer dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Person converted to customer successfully"),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error converting person: $e"))
        );
      }
    }
  }

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
                          child: Stack(
                            children: [
                              CustomTextField(
                                title: "Name",
                                error: customerNameError,
                                textController: customerNameController,
                                description: "Enter customer name",
                                focusNode: nameFocusNode,
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
                              if (isCheckingName)
                                Positioned(
                                  right: 12,
                                  top: 38,
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            title: "Phone",
                            textController: customerPhoneController,
                            description: "Enter customer phone",
                            focusNode: phoneFocusNode,
                            isMandatory: false,
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
                            focusNode: emailFocusNode,
                            isMandatory: false,
                            onChanged: (val) {
                              setState(() {
                                if (val.isEmpty || validateEmail(val)) {
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
                                  SnackBar(content: Text("Please fill required fields")),
                                );
                              }
                            }
                          },
                          onPressed: !(validate()) ? null : () async {
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
      // Create customer directly since we've already checked for duplicates
      Customer customer = Customer(
        name: customerNameController.text.trim(),
        phone: customerPhoneController.text.trim(),
        email: customerEmailController.text.trim(),
        address: customerAddressController.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: Timestamp.now(),
        notes: customerNotesController.text.trim(),
      );

      await customer.create();

      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Close loading dialog
        Navigator.pop(context); // Close add customer dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Customer saved successfully")),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  bool validate() {
    return customerNameError == null &&
        customerEmailError == null &&
        customerNameController.text.trim().isNotEmpty;
  }
}