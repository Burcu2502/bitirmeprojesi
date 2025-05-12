import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  final Color? color;
  final bool isOutlined;
  final bool isLoading;
  final double? width;
  final double? height;
  
  const CustomButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.color,
    this.isOutlined = false,
    this.isLoading = false,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final buttonColor = color ?? Theme.of(context).colorScheme.primary;
    
    return SizedBox(
      width: width,
      height: height,
      child: isOutlined 
        ? OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: buttonColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
            child: _buildButtonContent(context, buttonColor),
          )
        : ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
            child: _buildButtonContent(context, Colors.white),
          ),
    );
  }

  Widget _buildButtonContent(BuildContext context, Color contentColor) {
    if (isLoading) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.0,
          valueColor: AlwaysStoppedAnimation<Color>(
            isOutlined ? contentColor : Colors.white,
          ),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isOutlined ? contentColor : Colors.white, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: isOutlined ? contentColor : Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    }

    return Text(
      label,
      style: TextStyle(
        color: isOutlined ? contentColor : Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );
  }
} 