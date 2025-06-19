import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final String title;
  final TextEditingController textController;
  final String description;
  final bool isReadOnly;
  final Icon? suffixIcon;
  final VoidCallback? onTap;
  final Function(String)? onChanged;
  final bool? isEnabled;
  final String? error;
  final TextStyle? descriptionStyle;
  final bool isMandatory;
  final bool showVerifiedIfValid;

  const CustomTextField({
    super.key,
    required this.title,
    required this.textController,
    required this.description,
    this.isReadOnly = false,
    this.suffixIcon,
    this.onTap,
    this.isEnabled,
    this.onChanged,
    this.error,
    this.descriptionStyle,
    this.isMandatory = true,
    this.showVerifiedIfValid = true,
  });
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: title,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isMandatory)
                    TextSpan(
                      text: " *",
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.error,
                      ),
                    ),
                ],
              ),
            ),
            if (showVerifiedIfValid &&
                error == null &&
                textController.text.trim().isNotEmpty) ...[
              const SizedBox(width: 8),
              Icon(Icons.verified_outlined, size: 16, color: Colors.green),
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: textController,
          readOnly: isReadOnly,
          onTap: onTap,
          enabled: isEnabled,
          onChanged: onChanged,
          decoration: InputDecoration(
            suffixIcon: suffixIcon,
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: error != null ? colorScheme.error : colorScheme.outline,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: error != null ? colorScheme.error : colorScheme.primary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          error ?? description,
          maxLines: 2,
          style:
              descriptionStyle ??
              textTheme.bodySmall?.copyWith(
                color:
                    error != null
                        ? colorScheme.error
                        : colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
