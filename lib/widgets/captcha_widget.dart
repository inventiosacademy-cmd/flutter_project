import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class CaptchaWidget extends StatefulWidget {
  final ValueChanged<String> onCaptchaChanged;

  const CaptchaWidget({super.key, required this.onCaptchaChanged});

  @override
  State<CaptchaWidget> createState() => _CaptchaWidgetState();
}

class _CaptchaWidgetState extends State<CaptchaWidget> with SingleTickerProviderStateMixin {
  bool _isVerified = false;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    // Don't call callback here - it causes setState during build
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTap() async {
    if (_isVerified || _isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    // Simulate verification delay
    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      setState(() {
        _isLoading = false;
        _isVerified = true;
      });
      
      _animationController.forward();
      widget.onCaptchaChanged("VERIFIED");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFD3D3D3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Checkbox area
          GestureDetector(
            onTap: _onTap,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(
                  color: _isVerified ? AppColors.success : const Color(0xFFC1C1C1),
                  width: 2,
                ),
              ),
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(4),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                      ),
                    )
                  : _isVerified
                      ? ScaleTransition(
                          scale: _scaleAnimation,
                          child: const Icon(
                            Icons.check,
                            color: AppColors.success,
                            size: 20,
                          ),
                        )
                      : null,
            ),
          ),
          const SizedBox(width: 12),
          
          // Text
          Expanded(
            child: GestureDetector(
              onTap: _onTap,
              child: Text(
                "Saya bukan robot",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
          
          // reCAPTCHA logo simulation
          Column(
            children: [
              Icon(
                Icons.security,
                size: 28,
                color: Colors.grey.shade400,
              ),
              Text(
                "reCAPTCHA",
                style: TextStyle(
                  fontSize: 8,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
