import 'package:aromex/models/balance_generic.dart';
import 'package:aromex/pages/home/pages/widgets/update_balance_card.dart';
import 'package:aromex/pages/home/pages/widgets/update_total_owe_due.dart';
import 'package:aromex/pages/home/widgets/balance_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

class BalanceSection extends StatefulWidget {
  const BalanceSection({super.key});

  @override
  State<BalanceSection> createState() => _BalanceSectionState();
}

class _BalanceSectionState extends State<BalanceSection> {
  double cashBalance = 0,
      bankBalance = 0,
      creditCardBalance = 0,
      totalOwe = 0,
      totalDue = 0,
      expenseRecord = 0;

  // Store updatedAt for each balance type
  String cashUpdatedAt = '';
  String bankUpdatedAt = '';
  String creditCardUpdatedAt = '';
  String totalOweUpdatedAt = '';
  String totalDueUpdatedAt = '';
  String expenseUpdatedAt = '';

  Map<BalanceType, Balance> balances = {};

  bool isLoading = true;
  final FirebaseFirestore db = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();

    db.collection(Balance.collectionName).snapshots().listen((snapshot) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        final updatedBalances = <BalanceType, Balance>{};

        for (final doc in snapshot.docs) {
          final balanceType =
              balanceTypeTitles.entries
                  .firstWhere((e) => e.value == doc.id)
                  .key;

          final balance = Balance.fromFirestore(doc);
          updatedBalances[balanceType] = balance;
        }

        setState(() {
          isLoading = false;
          balances = updatedBalances;

          cashBalance = balances[BalanceType.cash]?.amount ?? 0;
          bankBalance = balances[BalanceType.bank]?.amount ?? 0;
          creditCardBalance = balances[BalanceType.creditCard]?.amount ?? 0;
          totalOwe = balances[BalanceType.totalOwe]?.amount ?? 0;
          totalDue = balances[BalanceType.totalDue]?.amount ?? 0;
          expenseRecord = balances[BalanceType.expenseRecord]?.amount ?? 0;

          cashUpdatedAt =
              balances[BalanceType.cash]?.lastTransaction != null
                  ? DateFormat.yMd().add_jm().format(
                    balances[BalanceType.cash]!.lastTransaction.toDate(),
                  )
                  : '';
          bankUpdatedAt =
              balances[BalanceType.bank]?.lastTransaction != null
                  ? DateFormat.yMd().add_jm().format(
                    balances[BalanceType.bank]!.lastTransaction.toDate(),
                  )
                  : '';
          creditCardUpdatedAt =
              balances[BalanceType.creditCard]?.lastTransaction != null
                  ? DateFormat.yMd().add_jm().format(
                    balances[BalanceType.creditCard]!.lastTransaction.toDate(),
                  )
                  : '';
          totalOweUpdatedAt =
              balances[BalanceType.totalOwe]?.lastTransaction != null
                  ? DateFormat.yMd().add_jm().format(
                    balances[BalanceType.totalOwe]!.lastTransaction.toDate(),
                  )
                  : '';
          totalDueUpdatedAt =
              balances[BalanceType.totalDue]?.lastTransaction != null
                  ? DateFormat.yMd().add_jm().format(
                    balances[BalanceType.totalDue]!.lastTransaction.toDate(),
                  )
                  : '';
          expenseUpdatedAt =
              balances[BalanceType.expenseRecord]?.lastTransaction != null
                  ? DateFormat.yMd().add_jm().format(
                    balances[BalanceType.expenseRecord]!.lastTransaction
                        .toDate(),
                  )
                  : '';
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Expanded(
                child: BalanceCard(
                  isLoading: isLoading,
                  icon: Image.asset(
                    'assets/icons/cash_balance.png',
                    width: 40,
                    height: 40,
                  ),
                  title: 'Cash balance',
                  amount: cashBalance,
                  updatedAt: cashUpdatedAt, 
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return Align(
                          alignment: Alignment.center,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal:
                                  MediaQuery.of(context).size.width * 0.125,
                              vertical:
                                  MediaQuery.of(context).size.height * 0.125,
                            ),
                            child: UpdateBalanceCard(
                              title: 'Cash balance',
                              amount: cashBalance,
                              updatedAt: cashUpdatedAt,
                              icon: Image.asset(
                                'assets/icons/cash_balance.png',
                                width: 40,
                                height: 40,
                              ),
                              balance: balances[BalanceType.cash]!,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: BalanceCard(
                  isLoading: isLoading,
                  icon: SvgPicture.asset(
                    'assets/icons/bank_balance.svg',
                    width: 40,
                    height: 40,
                  ),
                  title: 'Bank balance',
                  amount: bankBalance,
                  updatedAt: bankUpdatedAt,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return Align(
                          alignment: Alignment.center,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal:
                                  MediaQuery.of(context).size.width * 0.125,
                              vertical:
                                  MediaQuery.of(context).size.height * 0.125,
                            ),
                            child: UpdateBalanceCard(
                              title: 'Bank balance',
                              amount: bankBalance,
                              updatedAt: bankUpdatedAt,
                              icon: SvgPicture.asset(
                                'assets/icons/bank_balance.svg',
                                width: 40,
                                height: 40,
                              ),
                              balance: balances[BalanceType.bank]!,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: BalanceCard(
                    isLoading: isLoading,
                    icon: SvgPicture.asset(
                      'assets/icons/credit_card.svg',
                      width: 40,
                      height: 40,
                    ),
                    title: 'Credit card balance',
                    amount: creditCardBalance,
                    updatedAt:
                        creditCardUpdatedAt, 
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal:
                                    MediaQuery.of(context).size.width * 0.125,
                                vertical:
                                    MediaQuery.of(context).size.height * 0.125,
                              ),
                              child: UpdateBalanceCard(
                                title: 'Credit Card balance',
                                amount: creditCardBalance,
                                updatedAt: creditCardUpdatedAt,
                                icon: SvgPicture.asset(
                                  'assets/icons/credit_card.svg',
                                  width: 40,
                                  height: 40,
                                ),
                                balance: balances[BalanceType.creditCard]!,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TotalOweDueCard(
                    isLoading: isLoading,
                    icon: SvgPicture.asset(
                      'assets/icons/total_owe.svg',
                      width: 40,
                      height: 40,
                    ),
                    oweAmount: totalOwe,
                    dueAmount: totalDue,
                    updatedAt:
                        totalOweUpdatedAt,
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal:
                                    MediaQuery.of(context).size.width * 0.125,
                                vertical:
                                    MediaQuery.of(context).size.height * 0.125,
                              ),
                              child: UpdateTotalOweDue(
                                title: "Total Owe/Due",
                                oweAmount: totalOwe,
                                dueAmount: totalDue,
                                updatedAt: totalOweUpdatedAt,
                                icon: SvgPicture.asset(
                                  'assets/icons/total_owe.svg',
                                  width: 40,
                                  height: 40,
                                ),
                                oweBalance: balances[BalanceType.totalOwe],
                                dueBalance: balances[BalanceType.totalDue],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        Row(
          children: [
            Expanded(
              child: BalanceCard(
                isLoading: isLoading,
                icon: SvgPicture.asset(
                  'assets/icons/expense_record.svg',
                  width: 40,
                  height: 40,
                ),
                title: 'Expense record',
                amount: expenseRecord,
                updatedAt: expenseUpdatedAt,
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return Align(
                        alignment: Alignment.center,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal:
                                MediaQuery.of(context).size.width * 0.125,
                            vertical:
                                MediaQuery.of(context).size.height * 0.125,
                          ),
                          child: UpdateBalanceCard(
                            title: 'Expense record',
                            amount: expenseRecord,
                            updatedAt: expenseUpdatedAt,
                            icon: SvgPicture.asset(
                              'assets/icons/expense_record.svg',
                              width: 40,
                              height: 40,
                            ),
                            balance: balances[BalanceType.expenseRecord]!,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const Expanded(child: SizedBox()),
          ],
        ),
      ],
    );
  }
}
