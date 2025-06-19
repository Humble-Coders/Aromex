import 'package:aromex/models/balance_generic.dart';
import 'package:aromex/models/transaction.dart';
import 'package:aromex/pages/home/main.dart';
import 'package:aromex/util.dart';
import 'package:aromex/widgets/custom_text_field.dart';
import 'package:aromex/widgets/searchable_dropdown.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddExpense extends StatefulWidget {
  final Function(Pages) onPageChange;
  const AddExpense({super.key, required this.onPageChange});

  @override
  State<AddExpense> createState() => _AddExpenseState();
}

class _AddExpenseState extends State<AddExpense> {
  final TextEditingController amountController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();
  String? selectedCategory;
  final TextEditingController dateController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  List<String>? categories;

  String? amountError;
  String? categoryError;
  String? dateError;
  String? notesError;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    getCategories();
  }

  Future<void> getCategories() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection("Data")
              .doc("ExpenseCategories")
              .get();
      categories = snapshot.get("categories")?.cast<String>();
      setState(() {});
    } catch (e) {
      print("Error fetching categories: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Card(
      color: colorScheme.secondary,
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(36.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "Add Expense",
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onPageChange(Pages.expenseRecord);
                    },
                    child: Text("View Expense Record"),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.secondary,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colorScheme.onSurfaceVariant.withAlpha(50),
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            title: "Amount",
                            error: amountError,
                            textController: amountController,
                            description: "Enter expense amount",
                            onChanged: (val) {
                              setState(() {
                                try {
                                  double.parse(val);
                                  amountError = null;
                                } catch (e) {
                                  amountError = "Invalid amount";
                                }
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SearchableDropdown<String>(
                            title: "Category",
                            description: "Select or add a new category",
                            controller: categoryController,
                            items: categories,
                            onChanged: (item) {
                              setState(() {
                                selectedCategory = item;
                              });
                            },
                            selectedItem: selectedCategory,
                            getLabel: (item) => item,
                            onClear: () {
                              setState(() {
                                selectedCategory = null;
                              });
                            },
                            allowAddingNew: true,
                            onNewItemSelected: (item) {
                              // Create category
                              createCategory(item);
                            },
                            defaultConstructor: () => "",
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            title: "Date",
                            error: dateError,
                            isReadOnly: true,
                            textController: dateController,
                            description: "Enter expense date",
                            suffixIcon: const Icon(Icons.calendar_today),
                            onChanged: (val) {},
                            onTap: () async {
                              DateTime? selectedDate = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (selectedDate != null) {
                                dateController.text = formatDate(selectedDate);
                                setState(() {
                                  dateError = null;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            title: "Notes/Comments",
                            textController: notesController,
                            description: "Enter notes/comments",
                            onChanged: (_) {
                              setState(() {});
                            },
                            isMandatory: false,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            padding: EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 16,
                            ),
                          ),
                          child: Text(
                            "Cancel",
                            style: TextStyle(color: colorScheme.onPrimary),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onHover: (isHover) {
                            if (isHover) {
                              if (!validate()) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Please fill")),
                                );
                              }
                            }
                          },
                          onPressed:
                              !(validate())
                                  ? null
                                  : () async {
                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (context) {
                                        return Center(
                                          child: CircularProgressIndicator(),
                                        );
                                      },
                                    );
                                    // Add expense to firebase
                                    Balance? balance = await Balance.fromType(
                                      BalanceType.expenseRecord,
                                    );
                                    await balance.addAmount(
                                      double.parse(amountController.text),
                                      category: selectedCategory,
                                      expenseNote: notesController.text,
                                      transactionType: TransactionType.self,
                                    );
                                    Navigator.pop(context);
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          "Expense added successfully",
                                        ),
                                      ),
                                    );
                                  },
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 16,
                            ),
                            backgroundColor: colorScheme.primary,
                          ),
                          child: Text(
                            "Add Expense",
                            style: TextStyle(color: colorScheme.onPrimary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool validate() {
    return amountController.text.isNotEmpty &&
        selectedCategory != null &&
        dateController.text.isNotEmpty &&
        amountError == null &&
        categoryError == null &&
        dateError == null &&
        notesError == null;
  }

  void createCategory(String item) {
    // Add to firebase
    setState(() {
      categoryController.text = "Creating category...";
    });
    FirebaseFirestore.instance
        .collection("Data")
        .doc("ExpenseCategories")
        .update({
          "categories": FieldValue.arrayUnion([item]),
        })
        .then((_) {
          setState(() {
            categories?.add(item);
            selectedCategory = item;
            categoryController.text = item;
            categoryError = null;
          });
        })
        .catchError((error) {
          setState(() {
            categoryError = "Failed to create category";
          });
          print("Error creating category: $error");
        });
  }
}
