import 'package:aromex/models/phone_model.dart';
import 'package:aromex/widgets/custom_text_field.dart';
import 'package:aromex/widgets/searchable_dropdown.dart';
import 'package:flutter/material.dart';

class PhoneModelFilter extends StatefulWidget {
  final Function(String) onModelSearchChanged;
  final TextEditingController phoneModelSearchController;

  const PhoneModelFilter({
    super.key,
    required this.onModelSearchChanged,
    required this.phoneModelSearchController,
  });

  @override
  State<PhoneModelFilter> createState() => _PhoneModelFilterState();
}

class _PhoneModelFilterState extends State<PhoneModelFilter> {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          children: [
            Expanded(
              child: CustomTextField(
                title: "Model",
                textController: widget.phoneModelSearchController,
                description: "Search by model name",
                isMandatory: false,
                onChanged: widget.onModelSearchChanged,
                showVerifiedIfValid: false,
                suffixIcon: const Icon(Icons.search),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
