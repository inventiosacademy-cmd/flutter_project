import 'package:flutter/material.dart';
import '../theme/warna.dart';

/// Reusable Pagination Button widget
/// Digunakan di Dashboard dan Riwayat Evaluasi untuk navigasi halaman
class PaginationButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  const PaginationButton({
    super.key,
    required this.label,
    this.isActive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: isActive 
              ? null 
              : Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            color: isActive ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
