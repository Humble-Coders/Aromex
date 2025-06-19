import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

Future<bool> showPinDialog(BuildContext context) async {
  final TextEditingController pinController = TextEditingController();
  String? errorText;

  final pinDoc =
      await FirebaseFirestore.instance.collection('Data').doc('Pin').get();
  final correctPin = pinDoc.data()?['pin'] ?? '';

  Future<void> showChangePinDialog() async {
    final oldPinController = TextEditingController();
    final newPinController = TextEditingController();
    String? changeError;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              title: Text(
                'Change PIN',
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: oldPinController,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Old PIN'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: newPinController,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'New PIN'),
                  ),
                  if (changeError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        changeError!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: () async {
                    if (oldPinController.text != correctPin) {
                      setState(() {
                        changeError = "Old PIN is incorrect";
                      });
                      return;
                    }
                    if (newPinController.text.isEmpty) {
                      setState(() {
                        changeError = "New PIN cannot be empty";
                      });
                      return;
                    }
                    await FirebaseFirestore.instance
                        .collection('Data')
                        .doc('Pin')
                        .update({'pin': newPinController.text});
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('PIN changed successfully')),
                    );
                  },
                  child: Text(
                    'Change',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                title: const Text('Enter PIN to Delete'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: pinController,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'PIN',
                        errorText: errorText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () async {
                          Navigator.of(context).pop(false);
                          await showChangePinDialog();
                        },
                        child: Text(
                          'Change PIN',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: () {
                      if (pinController.text == correctPin) {
                        Navigator.of(context).pop(true);
                      } else {
                        setState(() {
                          errorText = "Incorrect PIN";
                        });
                      }
                    },
                    child: Text(
                      'Confirm',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ) ??
      false;
}
