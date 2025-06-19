import 'package:aromex/models/phone.dart';
import 'package:aromex/util.dart';
import 'package:flutter/material.dart';

class CustomProductTable extends StatelessWidget {
  final List<Phone> phones;
  final Function(int) onRemove, onCopy;

  const CustomProductTable({
    super.key,
    required this.phones,
    required this.onRemove,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: SizedBox(
        width: double.infinity,
        child: DataTable(
          columns: [
            DataColumn(
              label: Expanded(
                child: Text(
                  'Model',
                  style: textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            DataColumn(
              label: Expanded(
                child: Text(
                  'IMEI/Serial',
                  style: textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            DataColumn(
              label: Expanded(
                child: Text(
                  'Capacity',
                  style: textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            DataColumn(
              label: Expanded(
                child: Text(
                  'Status',
                  style: textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            DataColumn(
              label: Expanded(
                child: Text(
                  'Price',
                  style: textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            DataColumn(
              label: Expanded(
                child: Text(
                  'Actions',
                  style: textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
          rows:
              phones.isEmpty
                  ? [
                    DataRow(
                      cells: List.generate(
                        6,
                        (_) => const DataCell(SizedBox.shrink()),
                      ),
                    ),
                  ]
                  : phones.asMap().entries.map((entry) {
                    int idx = entry.key;
                    Phone phone = entry.value;

                    final modelName = phone.model?.get('name') ?? 'Unknown';

                    return DataRow(
                      cells: [
                        DataCell(Text(modelName)),
                        DataCell(Text(phone.imei)),
                        DataCell(Text('${phone.capacity.toInt()} gb')),
                        DataCell(Text(phone.status ? 'Active' : 'Inactive')),
                        DataCell(Text(formatCurrency(phone.price))),
                        DataCell(
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.copy_outlined, size: 19),
                                onPressed: () {
                                  onCopy(idx);
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.delete_outline, size: 22),
                                onPressed: () {
                                  onRemove(idx);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
        ),
      ),
    );
  }
}
