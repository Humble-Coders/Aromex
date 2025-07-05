import 'package:aromex/currency_constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../pages/home/pages/add_people.dart';
import 'add_commission_dialog.dart';

class CurrencyFormWidget extends StatefulWidget {
  final List<Map<String, String>> allPeople;
  final VoidCallback onEntryAdded;
  final Function(String) onError;
  final Function? onPageChange;

  const CurrencyFormWidget({
    super.key,
    required this.allPeople,
    required this.onEntryAdded,
    required this.onError,
    this.onPageChange,
  });

  @override
  State<CurrencyFormWidget> createState() => _CurrencyFormWidgetState();
}

class _CurrencyFormWidgetState extends State<CurrencyFormWidget> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Form controllers
  final TextEditingController amountController = TextEditingController();
  final TextEditingController exchangeRateController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final TextEditingController commissionController = TextEditingController();

  // Form state
  String? selectedP1;
  String? selectedP2;
  String? selectedAmountCurrency = 'INR';
  String? selectedRateCurrency = 'USD';
  String? transactionDirection = 'give_to';
  bool isCurrencyExchange = true;
  String? selectedCommissionPerson;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    _updateExchangeRate();
  }

  @override
  void dispose() {
    amountController.dispose();
    exchangeRateController.dispose();
    notesController.dispose();
    commissionController.dispose();
    super.dispose();
  }

  void _updateExchangeRate() {
    if (selectedAmountCurrency != null && selectedRateCurrency != null) {
      if (selectedAmountCurrency == selectedRateCurrency) {
        exchangeRateController.text = '1.0';
      } else {
        final rate =
            CurrencyConstants
                .exchangeRates[selectedAmountCurrency]?[selectedRateCurrency];
        if (rate != null) {
          exchangeRateController.text = rate.toStringAsFixed(4);
        } else {
          exchangeRateController.text = '1.0';
        }
      }
    }
  }

  bool _validateForm() {
    if (selectedP1 == null) {
      widget.onError('Please select Person 1');
      return false;
    }
    if (selectedP2 == null) {
      widget.onError('Please select Person 2');
      return false;
    }
    if (selectedP1 == selectedP2) {
      widget.onError('Please select different people for the transaction');
      return false;
    }
    if (amountController.text.trim().isEmpty) {
      widget.onError('Please enter an amount');
      return false;
    }
    if (isCurrencyExchange && exchangeRateController.text.trim().isEmpty) {
      widget.onError('Please enter exchange rate');
      return false;
    }

    final amount = double.tryParse(amountController.text.trim());
    if (amount == null || amount <= 0) {
      widget.onError('Please enter a valid amount greater than 0');
      return false;
    }

    return true;
  }

  Future<void> _confirmEntry() async {
    if (!_validateForm()) return;

    setState(() => isSaving = true);

    try {
      final amount = double.parse(amountController.text.trim());
      final exchangeRate =
          isCurrencyExchange
              ? double.parse(exchangeRateController.text.trim())
              : 1.0;
      final commission =
          double.tryParse(commissionController.text.trim()) ?? 0.0;
      final convertedAmount = amount * exchangeRate;

      final entry = {
        'person1': selectedP1,
        'person2': selectedP2,
        'direction': transactionDirection,
        'fromCurrency': isCurrencyExchange ? selectedAmountCurrency : 'USD',
        'toCurrency': isCurrencyExchange ? selectedRateCurrency : 'USD',
        'amount': amount,
        'exchangeRate': exchangeRate,
        'convertedAmount': convertedAmount,
        'commission': commission,
        'commissionPerson': selectedCommissionPerson,
        'notes': notesController.text.trim(),
        'isCurrencyExchange': isCurrencyExchange,
        'timestamp': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('currency_exchanges').add(entry);

      setState(() {
        selectedP1 = null;
        selectedP2 = null;
        amountController.clear();
        exchangeRateController.clear();
        commissionController.clear();
        notesController.clear();
        selectedCommissionPerson = null;
      });

      widget.onEntryAdded();
    } catch (e) {
      widget.onError('Error saving entry: $e');
    } finally {
      setState(() => isSaving = false);
    }
  }

  void _showAddCommissionDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AddCommissionDialog(
            selectedP1: selectedP1,
            selectedP2: selectedP2,
            selectedRateCurrency: selectedRateCurrency ?? 'USD',
            commissionController: commissionController,
            onCommissionPersonSelected: (person) {
              setState(() {
                selectedCommissionPerson = person;
              });
            },
          ),
    );
  }

  void _showAddPersonDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddPerson()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.grey.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            offset: const Offset(0, 4),
            blurRadius: 16,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(colorScheme),
          const SizedBox(height: 20),
          _buildFormRow(colorScheme),
          const SizedBox(height: 16),
          _buildNotesField(),
        ],
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.currency_exchange,
            color: colorScheme.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'New Transaction',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        const Spacer(),
        _buildExchangeToggle(colorScheme),
      ],
    );
  }

  Widget _buildExchangeToggle(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color:
            isCurrencyExchange
                ? colorScheme.primary.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Exchange',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isCurrencyExchange ? colorScheme.primary : Colors.grey,
            ),
          ),
          Transform.scale(
            scale: 0.7,
            child: Switch(
              value: isCurrencyExchange,
              onChanged: (value) {
                setState(() {
                  isCurrencyExchange = value;
                  if (!value) {
                    selectedAmountCurrency = selectedRateCurrency = 'USD';
                    exchangeRateController.text = '1.0';
                  } else {
                    selectedAmountCurrency = 'INR';
                    selectedRateCurrency = 'USD';
                    _updateExchangeRate();
                  }
                });
              },
              activeColor: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormRow(ColorScheme colorScheme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildPersonDropdown(
            value: selectedP1,
            hint: 'From',
            icon: Icons.person_outline,
            onChanged: (value) => setState(() => selectedP1 = value),
          ),
          const SizedBox(width: 10),
          _buildDirectionSelector(),
          const SizedBox(width: 10),
          _buildPersonDropdown(
            value: selectedP2,
            hint: 'To',
            icon: Icons.person,
            onChanged: (value) => setState(() => selectedP2 = value),
          ),
          const SizedBox(width: 10),
          _buildAmountField(),
          if (isCurrencyExchange) ...[
            const SizedBox(width: 10),
            _buildExchangeRateSection(),
          ],
          const SizedBox(width: 10),
          if (isCurrencyExchange) ...[
            _buildCommissionButton(colorScheme),
            const SizedBox(width: 8),
          ],
          _buildAddPersonButton(colorScheme),
          const SizedBox(width: 8),
          _buildSaveButton(colorScheme),
        ],
      ),
    );
  }

  Widget _buildPersonDropdown({
    required String? value,
    required String hint,
    required IconData icon,
    required void Function(String?) onChanged,
  }) {
    return Container(
      width: 140,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                hint: Text(hint, style: const TextStyle(fontSize: 13)),
                isExpanded: true,
                isDense: true,
                items:
                    [
                      {'name': 'Myself', 'type': 'You'},
                      ...widget.allPeople,
                    ].map((item) {
                      return DropdownMenuItem<String>(
                        value: item['name'],
                        child: Text(
                          item['name'] ?? '',
                          style: const TextStyle(fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectionSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: ButtonTheme(
          alignedDropdown: true,
          child: DropdownButton<String>(
            value: transactionDirection,
            isDense: true,
            items: [
              DropdownMenuItem(
                value: 'give_to',
                child: Row(
                  children: const [
                    Icon(Icons.arrow_forward, color: Colors.green, size: 16),
                    SizedBox(width: 4),
                    Text('Give to', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: 'take_from',
                child: Row(
                  children: const [
                    Icon(Icons.arrow_back, color: Colors.red, size: 16),
                    SizedBox(width: 4),
                    Text('Take from', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ],
            onChanged: (value) => setState(() => transactionDirection = value),
          ),
        ),
      ),
    );
  }

  Widget _buildAmountField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          if (isCurrencyExchange) ...[
            Container(
              width: 70,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedAmountCurrency,
                  isExpanded: true,
                  isDense: true,
                  items:
                      CurrencyConstants.currencies.map((currency) {
                        return DropdownMenuItem<String>(
                          value: currency,
                          child: Text(
                            currency,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedAmountCurrency = value;
                      _updateExchangeRate();
                    });
                  },
                ),
              ),
            ),
          ] else ...[
            Container(
              width: 70,
              height: 45,
              alignment: Alignment.center,
              child: const Text(
                'USD',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
          Container(width: 1, height: 30, color: Colors.grey.shade300),
          SizedBox(
            width: 100,
            child: TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 14),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Amount',
                hintStyle: TextStyle(fontSize: 13),
                contentPadding: EdgeInsets.symmetric(horizontal: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExchangeRateSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.blue.shade300),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedAmountCurrency,
                isDense: true,
                items:
                    CurrencyConstants.currencies.map((currency) {
                      return DropdownMenuItem<String>(
                        value: currency,
                        child: Text(
                          currency,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedAmountCurrency = value;
                    _updateExchangeRate();
                  });
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.compare_arrows, size: 16),
          const SizedBox(width: 8),
          SizedBox(
            width: 70,
            child: TextField(
              controller: exchangeRateController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.blue.shade300),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedRateCurrency,
                isDense: true,
                items:
                    CurrencyConstants.currencies.map((currency) {
                      return DropdownMenuItem<String>(
                        value: currency,
                        child: Text(
                          currency,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedRateCurrency = value;
                    _updateExchangeRate();
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommissionButton(ColorScheme colorScheme) {
    return _buildActionButton(
      icon: Icons.calculate,
      label:
          commissionController.text.isEmpty
              ? 'Commission'
              : commissionController.text,
      onPressed: _showAddCommissionDialog,
      color: colorScheme.primary,
    );
  }

  Widget _buildAddPersonButton(ColorScheme colorScheme) {
    return _buildActionButton(
      icon: Icons.person_add,
      onPressed: _showAddPersonDialog,
      color: colorScheme.primary,
    );
  }

  Widget _buildSaveButton(ColorScheme colorScheme) {
    return ElevatedButton(
      onPressed: isSaving ? null : _confirmEntry,
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 2,
      ),
      child:
          isSaving
              ? SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colorScheme.onPrimary,
                ),
              )
              : const Text(
                'Add Entry',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    String? label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 18),
                if (label != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotesField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.note_add, color: Colors.grey.shade600, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: notesController,
              maxLines: 1,
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Add notes (optional)',
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
