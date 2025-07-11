import 'package:aromex/models/middleman.dart';
import 'package:aromex/models/person.dart'; // Make sure to import Person model
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
                              setState(() {});
                            },
                            isMandatory: false,
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
                            isMandatory: false,
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
                                    await _handleAddMiddleman();
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

  Future<void> _handleAddMiddleman() async {
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
        middlemanNameController.text.trim(),
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
          // Convert person to middleman
          await _convertPersonToMiddleman(existingPerson);
        } else {
          // Don't allow adding with same name
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "A person with this name already exists. Please use a different name or convert the existing person to middleman.",
              ),
            ),
          );
        }
      } else {
        // No existing person, proceed with normal middleman creation
        await _createMiddleman();
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
            'Do you want to convert this person to a middleman?',
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: Text('Convert to Middleman'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _convertPersonToMiddleman(Person person) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Center(child: CircularProgressIndicator());
      },
    );

    try {
      // Create middleman with person's data + new data
      Middleman middleman = Middleman(
        name: person.name,
        phone:
            middlemanPhoneController.text.isNotEmpty
                ? middlemanPhoneController.text
                : person.phone ?? '',
        email:
            middlemanEmailController.text.isNotEmpty
                ? middlemanEmailController.text
                : person.email ?? '',
        address:
            middlemanAddressController.text.isNotEmpty
                ? middlemanAddressController.text
                : person.address ?? '',
        commission: 0.0,
        createdAt: DateTime.now(),
        updatedAt: Timestamp.now(),
        balance: 0.0,
      );

      await middleman.create();

      // Delete the person record
      await _firestore.collection('Person').doc(person.id).delete();

      if (context.mounted) {
        Navigator.of(
          context,
          rootNavigator: true,
        ).pop(); // Close loading dialog
        Navigator.pop(context); // Close add middleman dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Person converted to middleman successfully"),
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

  Future<void> _createMiddleman() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Center(child: CircularProgressIndicator());
      },
    );

    try {
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

      await middleman.create();

      if (context.mounted) {
        Navigator.of(
          context,
          rootNavigator: true,
        ).pop(); // Close loading dialog
        Navigator.pop(context); // Close add middleman dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Middleman saved successfully")),
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
    return middlemanNameError == null &&
        middlemanPhoneError == null &&
        middlemanEmailError == null &&
        middlemanNameController.text.isNotEmpty;
  }
}
