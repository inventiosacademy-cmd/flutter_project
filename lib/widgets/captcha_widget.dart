import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class CaptchaWidget extends StatefulWidget {
  final ValueChanged<String> onCaptchaChanged;

  const CaptchaWidget({super.key, required this.onCaptchaChanged});

  @override
  State<CaptchaWidget> createState() => _CaptchaWidgetState();
}

class _CaptchaWidgetState extends State<CaptchaWidget> with SingleTickerProviderStateMixin {
  String _captcha = "";
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _rotationAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _generateCaptcha();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _generateCaptcha() {
    const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    final random = Random();
    String newCaptcha = String.fromCharCodes(Iterable.generate(
      5, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
    
    setState(() {
      _captcha = newCaptcha;
    });
    
    // Animate refresh button
    _animationController.forward(from: 0);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onCaptchaChanged(newCaptcha);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.grey.shade100,
            Colors.grey.shade200,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Captcha Display
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Noise lines
                  CustomPaint(
                    size: const Size(120, 36),
                    painter: _CaptchaNoisePainter(),
                  ),
                  // Captcha text
                  Text(
                    _captcha,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                      fontFamily: 'Courier',
                      foreground: Paint()
                        ..shader = const LinearGradient(
                          colors: [
                            AppColors.primaryBlue,
                            AppColors.primaryIndigo,
                          ],
                        ).createShader(const Rect.fromLTWH(0, 0, 150, 36)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Refresh Button
          RotationTransition(
            turns: _rotationAnimation,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _generateCaptcha,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.refresh_rounded,
                    color: AppColors.primaryBlue,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for captcha noise effect
class _CaptchaNoisePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(42); // Fixed seed for consistent look
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 1;

    // Draw random lines
    for (int i = 0; i < 5; i++) {
      canvas.drawLine(
        Offset(random.nextDouble() * size.width, random.nextDouble() * size.height),
        Offset(random.nextDouble() * size.width, random.nextDouble() * size.height),
        paint,
      );
    }

    // Draw random dots
    for (int i = 0; i < 20; i++) {
      canvas.drawCircle(
        Offset(random.nextDouble() * size.width, random.nextDouble() * size.height),
        1,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
