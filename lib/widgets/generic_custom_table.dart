import 'package:flutter/material.dart';

class GenericCustomTable<T> extends StatelessWidget {
  final List<T> entries;
  final List<String> headers;
  final List<String Function(T)> valueGetters;
  final void Function(T)? onTap;
  final List<Widget> Function(T)? rowActions;

  const GenericCustomTable({
    super.key,
    required this.entries,
    required this.headers,
    required this.valueGetters,
    this.onTap,
    this.rowActions,
  }) : assert(headers.length == valueGetters.length);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Add "Actions" header if rowActions is provided
    final allHeaders = rowActions != null
        ? [...headers, "Actions"]
        : headers;

    return Center(
      child: SizedBox(
        width: double.infinity,
        child: DataTable(
          dividerThickness: 0,
          columns: allHeaders
              .map(
                (h) => DataColumn(
                  label: Text(
                    h,
                    style: textTheme.titleLarge?.copyWith(
                      color: colorScheme.onSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
              .toList(),
          rows: entries.isEmpty
              ? [
                  DataRow(
                    cells: List.generate(
                      allHeaders.length,
                      (_) => const DataCell(SizedBox.shrink()),
                    ),
                  ),
                ]
              : List<DataRow>.generate(entries.length, (index) {
                  final entry = entries[index];
                  final cells = valueGetters
                      .map((getter) => DataCell(Text(getter(entry))))
                      .toList();

                  // Add actions cell if needed
                  if (rowActions != null) {
                    cells.add(
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: rowActions!(entry),
                        ),
                      ),
                    );
                  }

                  return DataRow(
                    color: WidgetStateProperty.resolveWith<Color?>(
                        (Set<WidgetState> states) {
                      return index.isOdd ? Colors.grey[200] : null;
                    }),
                    onSelectChanged:
                        onTap != null ? (_) => onTap!(entry) : null,
                    cells: cells,
                  );
                }),
          showCheckboxColumn: false,
        ),
      ),
    );
  }
}