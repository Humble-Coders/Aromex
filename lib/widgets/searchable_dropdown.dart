import 'package:flutter/material.dart';

class SearchableDropdown<T> extends StatefulWidget {
  final Widget? titleWidget;
  final String? title;
  final Widget? descriptionWidget;
  final String? description;
  final Widget? errorWidget;
  final String? error;
  final List<T>? items;
  final T? selectedItem;
  final void Function(T?)? onChanged;
  final VoidCallback onClear;
  final String Function(T) getLabel;
  final bool enabled;
  final String? hintText;
  final bool allowAddingNew;
  final T Function()? defaultConstructor;
  final String Function(String)? getLabelForNewItem;
  final Function(String)? onNewItemSelected;
  final TextEditingController? controller;
  final bool isMandatory;
  final bool showVerifiedIfValid;

  SearchableDropdown({
    super.key,
    required this.items,
    required this.selectedItem,
    required this.onChanged,
    required this.getLabel,
    required this.onClear,
    this.controller,
    this.titleWidget,
    this.descriptionWidget,
    this.errorWidget,
    this.enabled = true,
    this.hintText,
    this.title,
    this.description,
    this.error,
    this.allowAddingNew = false,
    this.getLabelForNewItem,
    this.onNewItemSelected,
    this.defaultConstructor,
    this.isMandatory = true,
    this.showVerifiedIfValid = true,
  }) : assert(
         allowAddingNew == false || defaultConstructor != null,
         "You must provide a default constructor if allowAddingNew is true.",
       ) {}

  @override
  State<SearchableDropdown<T>> createState() => _SearchableDropdownState<T>();
}

class _SearchableDropdownState<T> extends State<SearchableDropdown<T>> {
  final FocusNode focusNode = FocusNode();
  String _currentInput = "";

  @override
  void initState() {
    super.initState();

    widget.controller?.addListener(() {
      setState(() {
        _currentInput = widget.controller!.text;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    assert(
      widget.title == null || widget.titleWidget == null,
      "You cannot use both title and titleWidget at the same time.",
    );
    assert(
      widget.description == null || widget.descriptionWidget == null,
      "You cannot use both description and descriptionWidget at the same time.",
    );
    assert(
      widget.error == null || widget.errorWidget == null,
      "You cannot use both error and errorWidget at the same time.",
    );
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final bool toShowNew =
        widget.allowAddingNew &&
        widget.items != null &&
        _currentInput.isNotEmpty &&
        widget.items!
            .where(
              (it) =>
                  widget.getLabel(it).toLowerCase() ==
                  _currentInput.toLowerCase(),
            )
            .isEmpty;

    final Widget? _titleTextWidget =
        widget.title != null
            ? RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: widget.title!,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (widget.isMandatory)
                    TextSpan(
                      text: " *",
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.error,
                      ),
                    ),
                ],
              ),
            )
            : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.title != null) ...[
          if (widget.selectedItem != null)
            Row(
              children: [
                _titleTextWidget!,
                if (widget.showVerifiedIfValid) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.verified_outlined, size: 16, color: Colors.green),
                ],
              ],
            ),
          if (widget.selectedItem == null) _titleTextWidget!,
          const SizedBox(height: 8),
        ],
        if (widget.titleWidget != null) widget.titleWidget!,
        DropdownMenu<T>(
          expandedInsets: EdgeInsets.zero,
          filterCallback:
              widget.allowAddingNew
                  ? (entries, filter) {
                    // Filter all items except the new item
                    final filteredItems =
                        entries.where((entry) {
                          if (toShowNew &&
                              entries.indexOf(entry) == entries.length - 1) {
                            return true;
                          }
                          return widget
                              .getLabel(entry.value)
                              .toLowerCase()
                              .contains(filter.toLowerCase());
                        }).toList();

                    return filteredItems;
                  }
                  : null,
          enableFilter: true,
          controller: widget.controller,
          enabled: widget.enabled,
          focusNode:
              focusNode..addListener(() {
                if (!focusNode.hasFocus) {
                  if (widget.selectedItem != null) {
                    widget.controller?.text = widget.getLabel(
                      widget.selectedItem as T,
                    );
                  }
                }
              }),

          leadingIcon:
              widget.selectedItem == null
                  ? null
                  : IconButton(
                    onPressed: () {
                      widget.controller?.clear();
                      widget.onClear();
                    },
                    icon: Icon(Icons.cancel_outlined, size: 16),
                  ),
          hintText:
              widget.hintText ??
              (widget.items == null ? "Loading..." : "Choose an option"),
          textStyle: Theme.of(context).textTheme.titleMedium!.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
          dropdownMenuEntries:
              widget.items == null
                  ? []
                  : [
                    ...List.generate(
                      widget.items!.length,
                      (index) => DropdownMenuEntry<T>(
                        labelWidget: Text(
                          widget.getLabel(widget.items![index]),
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium!.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        value: widget.items![index],
                        label: widget.getLabel(widget.items![index]),
                      ),
                    ),
                    if (toShowNew)
                      DropdownMenuEntry<T>(
                        labelWidget: Text(
                          widget.getLabelForNewItem != null
                              ? widget.getLabelForNewItem!(
                                widget.controller!.text,
                              )
                              : "Add \"${widget.controller?.text.trim()}\"",
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium!.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        value: widget.defaultConstructor!(),
                        label: widget.controller!.text.trim(),
                      ),
                  ],
          onSelected:
              widget.items == null
                  ? null
                  : (item) {
                    if (toShowNew &&
                        widget.items!.indexWhere((it) => item == it) == -1) {
                      widget.onNewItemSelected?.call(_currentInput);
                    } else {
                      widget.onChanged!(item);
                    }
                  },
        ),
        if (widget.descriptionWidget != null) widget.descriptionWidget!,
        if (widget.description != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.description!,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (widget.error != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.error!,
            style: textTheme.bodySmall?.copyWith(color: colorScheme.error),
          ),
        ],
        if (widget.errorWidget != null) widget.errorWidget!,
        if (widget.errorWidget != null) ...[
          const SizedBox(height: 8),
          widget.errorWidget!,
        ],
      ],
    );
  }
}
