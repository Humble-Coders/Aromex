import 'package:aromex/models/person.dart';
import 'package:aromex/util.dart';
import 'package:aromex/widgets/custom_text_field.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddPerson extends StatefulWidget {
  const AddPerson({super.key});

  @override
  State<AddPerson> createState() => _AddPersonState();
}

class _AddPersonState extends State<AddPerson> {
  final TextEditingController personNameController = TextEditingController();
  final TextEditingController personPhoneController = TextEditingController();
  final TextEditingController personEmailController = TextEditingController();
  final TextEditingController personAddressController = TextEditingController();
  final TextEditingController personNotesController = TextEditingController();

  // Errors
  String? customerNameError;
  String? customerPhoneError;
  String? customerEmailError;

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
                "Add Person",
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
                            textController: personNameController,
                            description: "Enter Person name",
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
                            textController: personPhoneController,
                            description: "Enter Person phone",
                            //  error: customerPhoneError,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            title: "Email",
                            error: customerEmailError,
                            textController: personEmailController,
                            description: "Enter Person email",
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
                            textController: personAddressController,
                            description: "Enter Person address",
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
                            textController: personNotesController,
                            description: "Enter Person notes",
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
                          onPressed: !validate()
                              ? null
                              : () async {
                                  debugPrint(
                                      "Validation passed. Creating person...");

                                  final person = Person(
                                    name: personNameController.text,
                                    phone: personPhoneController.text,
                                    email: personEmailController.text,
                                    address: personAddressController.text,
                                    createdAt: DateTime.now(),
                                    updatedAt: Timestamp.now(),
                                    notes: personNotesController.text,
                                  );

                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (context) {
                                      return const Center(
                                          child: CircularProgressIndicator());
                                    },
                                  );

                                  try {
                                    debugPrint(
                                        "Saving person to Firestore:()}");
                                    await person.create();
                                    debugPrint("Person saved successfully.");

                                    if (context.mounted) {
                                      Navigator.of(context, rootNavigator: true)
                                          .pop(); // remove dialog
                                      Navigator.pop(context); // close form
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                "Person saved successfully")),
                                      );
                                    }
                                  } catch (e, stackTrace) {
                                    debugPrint("Error saving person: $e");
                                    debugPrint("Stack trace: $stackTrace");

                                    if (context.mounted) {
                                      Navigator.of(context, rootNavigator: true)
                                          .pop(); // remove dialog
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                "Error saving person: $e")),
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
                            "Add Person Details",
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
    return customerNameError == null &&
        customerPhoneError == null &&
        customerEmailError == null &&
        personNameController.text.isNotEmpty &&
        personPhoneController.text.isNotEmpty &&
        personEmailController.text.isNotEmpty;
  }
}
