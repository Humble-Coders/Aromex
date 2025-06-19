import 'package:aromex/pages/home/main.dart';
import 'package:aromex/pages/home/widgets/action_section.dart';
import 'package:aromex/pages/home/widgets/balance_section.dart';
import 'package:flutter/material.dart';

class HomePageBase extends StatelessWidget {
  final Function(Pages) onPageChange;
  const HomePageBase({super.key, required this.onPageChange});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome Back, Admin',
              style: textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 20),
            ActionSection(onPageChange: onPageChange),
            const SizedBox(height: 20),
            SelectableRegion(
              selectionControls: MaterialTextSelectionControls(),
              child: BalanceSection(),
            ),
          ],
        ),
      ),
    );
  }
}
