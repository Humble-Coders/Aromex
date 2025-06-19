import 'package:flutter/material.dart';

class ProfileCard extends StatelessWidget {
  final String name;
  final String phoneNumber;
  final String? email;
  final String? address;
  final DateTime createdAt;

  const ProfileCard({
    super.key,
    required this.name,
    required this.phoneNumber,
    this.email,
    this.address,
    required this.createdAt,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final Map<String, String> userFields = {
      'Phone': phoneNumber,
      if (email != null && email!.isNotEmpty) 'Email': email!,
      if (address != null && address!.isNotEmpty) 'Address': address!,
    };

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.secondary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.primary.withAlpha(200)),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: colorScheme.primary,
                radius: 20,
                child: Icon(
                  Icons.person,
                  size: 30,
                  color: colorScheme.secondary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  name,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children:
                userFields.entries.map((entry) {
                  return Text(
                    "${entry.key}: ${entry.value}",
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.primary,
                    ),
                  );
                }).toList(),
          ),
          const SizedBox(height: 8),
          Text(
            "Created on: ${createdAt.toLocal().toString().split(' ')[0]}",
            style: textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
