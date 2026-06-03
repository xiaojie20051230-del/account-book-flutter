import 'package:flutter/material.dart';

class AmountInput extends StatelessWidget {
  final TextEditingController controller;

  const AmountInput({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: const InputDecoration(
        labelText: '金额',
        prefixText: '¥ ',
        border: OutlineInputBorder(),
        hintText: '0.00',
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return '请输入金额';
        final n = double.tryParse(v);
        if (n == null || n <= 0) return '请输入有效金额';
        return null;
      },
    );
  }
}
