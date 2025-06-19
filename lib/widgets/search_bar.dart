import 'package:flutter/material.dart';

class CustomSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;

  const CustomSearchBar({
    super.key,
    this.hintText = 'Search by name...',
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        suffixIcon: const Icon(Icons.search),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: colorScheme.primary.withAlpha(200)),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: colorScheme.primary),
        ),
        hintText: hintText,
        hintStyle: textTheme.bodyLarge?.copyWith(color: colorScheme.primary),
      ),
    );
  }
}
