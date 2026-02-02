import 'package:flutter/material.dart';
import '../theme/warna.dart';

/// Reusable Table Header Cell widget
/// Digunakan di Dashboard dan Riwayat Evaluasi untuk header tabel
class TableHeaderCell extends StatelessWidget {
  final String label;
  final int flex;
  final bool center;

  const TableHeaderCell({
    super.key,
    required this.label,
    this.flex = 1,
    this.center = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        textAlign: center ? TextAlign.center : TextAlign.left,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
