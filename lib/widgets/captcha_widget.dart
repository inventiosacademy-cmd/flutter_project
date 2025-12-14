import 'dart:math';
import 'package:flutter/material.dart';

class CaptchaWidget extends StatefulWidget {
  final ValueChanged<String> onCaptchaChanged;

  const CaptchaWidget({super.key, required this.onCaptchaChanged});

  @override
  State<CaptchaWidget> createState() => _CaptchaWidgetState();
}

class _CaptchaWidgetState extends State<CaptchaWidget> {
  String _captcha = "";

  @override
  void initState() {
    super.initState();
    _generateCaptcha();
  }

  void _generateCaptcha() {
    const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    final random = Random();
    String newCaptcha = String.fromCharCodes(Iterable.generate(
      5, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
    
    setState(() {
      _captcha = newCaptcha;
    });
    
    // Defer the callback to avoid "setState() called during build" error
    // when this is called from initState (which happens during parent build)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onCaptchaChanged(newCaptcha);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _captcha,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
              fontFamily: 'Courier', // Monospace for captcha look
              decoration: TextDecoration.lineThrough, // Strikethrough for effect
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _generateCaptcha,
            tooltip: "Ganti Captcha",
          ),
        ],
      ),
    );
  }
}
