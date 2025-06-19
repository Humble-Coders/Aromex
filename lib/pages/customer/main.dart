import 'package:aromex/models/customer.dart';
import 'package:aromex/pages/customer/widgets/customer_list.dart';
import 'package:aromex/pages/customer/widgets/customer_profile.dart';
import 'package:flutter/material.dart';

class CustomerPage extends StatefulWidget {
  const CustomerPage({super.key});

  @override
  State<CustomerPage> createState() => _CustomerPageState();
}

class _CustomerPageState extends State<CustomerPage> {
  Customer? customer;
  int pageNo = 1;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child:
            pageNo == 1
                ? CustomerList(
                  onTap: (Customer customer) {
                    setState(() {
                      this.customer = customer;
                      pageNo = 2;
                    });
                  },
                )
                : CustomerProfile(
                  customer: customer!,
                  onBack: () {
                    setState(() {
                      pageNo = 1;
                    });
                  },
                ),
      ),
    );
  }
}
