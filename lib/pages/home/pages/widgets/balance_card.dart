import 'package:aromex/util.dart';
import 'package:flutter/material.dart';

class BalanceCard extends StatelessWidget {
  final Widget icon;
  final String title;
  final VoidCallback onTap;
  final double amount;
  final String updatedAt;
  final bool isLoading;

  const BalanceCard({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    required this.amount,
    required this.updatedAt,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: colorScheme.secondary,
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Positioned(
              left: -10,
              right: -10,
              bottom: -10,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                child: Image.asset(
                  'assets/images/wave.png',
                  fit: BoxFit.fill,
                  height: 120,
                  width: double.infinity,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: textTheme.titleLarge?.copyWith(
                          color: colorScheme.onSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      isLoading
                          ? Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(),
                            ),
                          )
                          : Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                formatCurrency(amount, showTrail: true),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: textTheme.headlineMedium?.copyWith(
                                  fontFamily: 'Nunito',
                                  fontVariations: [
                                    const FontVariation('wght', 700),
                                  ],
                                  color:
                                      amount < 0
                                          ? const Color.fromRGBO(244, 67, 54, 1)
                                          : const Color(0xFF166534),
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Last updated at $updatedAt',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSecondary,
                                ),
                              ),
                            ],
                          ),
                      SizedBox(height: 65),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.secondaryContainer.withAlpha(13),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: icon,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TotalOweDueCard extends StatelessWidget {
  final Widget icon;
  final double oweAmount;
  final double dueAmount;
  final String updatedAt;
  final bool isLoading;
  final VoidCallback onTap;

  const TotalOweDueCard({
    super.key,
    required this.icon,
    required this.oweAmount,
    required this.dueAmount,
    required this.updatedAt,
    required this.onTap,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: colorScheme.secondary,
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Positioned(
              left: -10,
              right: -10,
              bottom: -10,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                child: Image.asset(
                  'assets/images/wave.png',
                  fit: BoxFit.fill,
                  height: 120,
                  width: double.infinity,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total owe/due',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: textTheme.titleLarge?.copyWith(
                          color: colorScheme.onSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      isLoading
                          ? Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(),
                            ),
                          )
                          : Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Owe',
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                        style: textTheme.bodyMedium?.copyWith(
                                          color: colorScheme.onSecondary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        formatCurrency(oweAmount, showTrail: true),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                        style: textTheme.headlineMedium
                                            ?.copyWith(
                                              fontFamily: 'Nunito',
                                              color: Colors.red,
                                              fontVariations: [
                                                FontVariation('wght', 700),
                                              ],
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 20),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Due',
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                        style: textTheme.bodyMedium?.copyWith(
                                          color: colorScheme.onSecondary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        formatCurrency(dueAmount, showTrail: true),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                        style: textTheme.headlineMedium
                                            ?.copyWith(
                                              fontFamily: 'Nunito',
                                              color: const Color(0xFF166534),
                                              fontVariations: [
                                                FontVariation('wght', 700),
                                              ],
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Last updated at $updatedAt',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSecondary,
                                ),
                              ),
                            ],
                          ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.secondaryContainer.withAlpha(13),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: icon,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
