import 'package:aromex/models/middleman.dart';
import 'package:aromex/util.dart';
import 'package:aromex/widgets/custom_text_field.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddMiddleman extends StatefulWidget {
  const AddMiddleman({super.key});

  @override
  State<AddMiddleman> createState() => _AddMiddlemanState();
}

class _AddMiddlemanState extends State<AddMiddleman> {
  // Controllers
  final TextEditingController middlemanNameController = TextEditingController();
  final TextEditingController middlemanPhoneController =
      TextEditingController();
  final TextEditingController middlemanEmailController =
      TextEditingController();
  final TextEditingController middlemanAddressController =
      TextEditingController();
  final TextEditingController middlemanNotesController =
      TextEditingController();

  // Errors
  String? middlemanNameError;
  String? middlemanPhoneError;
  String? middlemanEmailError;

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
                "Add Middleman",
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
                            textController: middlemanNameController,
                            description: "Enter middleman name",
                            error: middlemanNameError,
                            onChanged: (val) {
                              setState(() {
                                if (validateName(val)) {
                                  middlemanNameError = null;
                                } else {
                                  middlemanNameError = "Invalid name";
                                }
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            title: "Phone",
                            textController: middlemanPhoneController,
                            description: "Enter middleman phone",
                            error: middlemanPhoneError,
                            onChanged: (val) {
                              setState(() {
                                if (validatePhone(val)) {
                                  middlemanPhoneError = null;
                                } else {
                                  middlemanPhoneError = "Invalid phone number";
                                }
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            title: "Email",
                            textController: middlemanEmailController,
                            description: "Enter middleman email",
                            error: middlemanEmailError,
                            onChanged: (val) {
                              setState(() {
                                if (validateEmail(val)) {
                                  middlemanEmailError = null;
                                } else {
                                  middlemanEmailError = "Invalid email";
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
                            textController: middlemanAddressController,
                            description: "Enter middleman address",
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
                            textController: middlemanNotesController,
                            description: "Enter middleman notes",
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
                                    Middleman middleman = Middleman(
                                      name: middlemanNameController.text,
                                      phone: middlemanPhoneController.text,
                                      email: middlemanEmailController.text,
                                      address: middlemanAddressController.text,
                                      commission: 0.0,
                                      createdAt: DateTime.now(),
                                      updatedAt: Timestamp.now(),
                                      balance: 0.0,
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
                                      await middleman.create();
                                      if (context.mounted) {
                                        Navigator.of(
                                          context,
                                          rootNavigator: true,
                                        ).pop(); 
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              "Middleman saved successfully",
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
                            "Add Middleman",
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
    return middlemanNameError == null &&
        middlemanPhoneError == null &&
        middlemanEmailError == null && 
        middlemanNameController.text.isNotEmpty &&
        middlemanPhoneController.text.isNotEmpty &&
        middlemanEmailController.text.isNotEmpty;
  }
}
