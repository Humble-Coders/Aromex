import 'package:flutter/material.dart';

class MyAppBar extends StatelessWidget {
  final VoidCallback onHamburgerTap, onProfileTap;
  final String title;
  const MyAppBar({
    super.key,
    required this.title,
    required this.onHamburgerTap,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppBar(
      backgroundColor: colorScheme.primary,
      toolbarHeight: 56,
      titleSpacing: 0,
      leading: IconButton(icon: Icon(Icons.menu), onPressed: onHamburgerTap),
      title: Text(
        title,
        style: textTheme.titleLarge?.copyWith(
          color: colorScheme.onPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            radius: 16,
            backgroundColor: colorScheme.onPrimary.withAlpha(77),
            child: IconButton(
              icon: Icon(Icons.person, color: colorScheme.onPrimary, size: 18),
              alignment: Alignment.center,
              onPressed: onProfileTap,
            ),
          ),
        ),
      ],
    );
  }
}
