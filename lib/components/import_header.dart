import 'package:flutter/material.dart';

class ImportHeader extends StatelessWidget {
  const ImportHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '从教务系统导入课程表',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 20),
      ],
    );
  }
}