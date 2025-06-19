import 'package:aromex/models/middleman.dart';
import 'package:aromex/pages/middleman/widgets/middleman_list.dart';
import 'package:aromex/pages/middleman/widgets/middleman_profile.dart';
import 'package:flutter/material.dart';

class MiddlemanPage extends StatefulWidget {
  const MiddlemanPage({super.key});

  @override
  State<MiddlemanPage> createState() => _MiddlemanPageState();
}

class _MiddlemanPageState extends State<MiddlemanPage> {
  Middleman? middleman;
  int pageNo = 1;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child:
            pageNo == 1
                ? MiddlemanList(
                  onTap: (Middleman middleman) {
                    setState(() {
                      this.middleman = middleman;
                      pageNo = 2;
                    });
                  },
                )
                : MiddlemanProfile(
                  middleman: middleman!,
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
