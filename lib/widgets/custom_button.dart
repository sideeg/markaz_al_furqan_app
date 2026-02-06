import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

enum ButtonType { primary, secondary, outline, text }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonType type;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final double height;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double borderRadius;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = ButtonType.primary,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = 48,
    this.padding,
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null && !isLoading;
    
    Widget child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                _getForegroundColor(context),
              ),
            ),
          )
        else if (icon != null)
          Icon(
            icon,
            size: 20,
            color: _getForegroundColor(context),
          ),
        
        if ((isLoading || icon != null) && text.isNotEmpty)
          const SizedBox(width: 8),
        
        if (text.isNotEmpty)
          Text(
            text,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: _getForegroundColor(context),
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );

    Widget button;
    
    switch (type) {
      case ButtonType.primary:
        button = ElevatedButton(
          onPressed: isEnabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor ?? AppColors.primary,
            foregroundColor: foregroundColor ?? AppColors.onPrimary,
            disabledBackgroundColor: AppColors.neutral300,
            disabledForegroundColor: AppColors.neutral500,
            elevation: isEnabled ? 2 : 0,
            shadowColor: AppColors.cardShadow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            minimumSize: Size(width ?? 0, height),
          ),
          child: child,
        );
        break;
        
      case ButtonType.secondary:
        button = ElevatedButton(
          onPressed: isEnabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor ?? AppColors.secondary,
            foregroundColor: foregroundColor ?? AppColors.onSecondary,
            disabledBackgroundColor: AppColors.neutral300,
            disabledForegroundColor: AppColors.neutral500,
            elevation: isEnabled ? 1 : 0,
            shadowColor: AppColors.cardShadow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            minimumSize: Size(width ?? 0, height),
          ),
          child: child,
        );
        break;
        
      case ButtonType.outline:
        button = OutlinedButton(
          onPressed: isEnabled ? onPressed : null,
          style: OutlinedButton.styleFrom(
            foregroundColor: foregroundColor ?? AppColors.primary,
            disabledForegroundColor: AppColors.neutral500,
            side: BorderSide(
              color: isEnabled 
                  ? (foregroundColor ?? AppColors.primary)
                  : AppColors.neutral300,
              width: 1.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            minimumSize: Size(width ?? 0, height),
          ),
          child: child,
        );
        break;
        
      case ButtonType.text:
        button = TextButton(
          onPressed: isEnabled ? onPressed : null,
          style: TextButton.styleFrom(
            foregroundColor: foregroundColor ?? AppColors.primary,
            disabledForegroundColor: AppColors.neutral500,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            minimumSize: Size(width ?? 0, height),
          ),
          child: child,
        );
        break;
    }

    if (width != null) {
      return SizedBox(
        width: width,
        child: button,
      );
    }

    return button;
  }

  Color _getForegroundColor(BuildContext context) {
    if (!isLoading && onPressed != null) {
      switch (type) {
        case ButtonType.primary:
          return foregroundColor ?? AppColors.onPrimary;
        case ButtonType.secondary:
          return foregroundColor ?? AppColors.onSecondary;
        case ButtonType.outline:
        case ButtonType.text:
          return foregroundColor ?? AppColors.primary;
      }
    }
    return AppColors.neutral500;
  }
}

// Convenience constructors
class PrimaryButton extends CustomButton {
  const PrimaryButton({
    super.key,
    required super.text,
    super.onPressed,
    super.isLoading = false,
    super.icon,
    super.width,
    super.height = 48,
  }) : super(type: ButtonType.primary);
}

class SecondaryButton extends CustomButton {
  const SecondaryButton({
    super.key,
    required super.text,
    super.onPressed,
    super.isLoading = false,
    super.icon,
    super.width,
    super.height = 48,
  }) : super(type: ButtonType.secondary);
}

class OutlineButton extends CustomButton {
  const OutlineButton({
    super.key,
    required super.text,
    super.onPressed,
    super.isLoading = false,
    super.icon,
    super.width,
    super.height = 48,
  }) : super(type: ButtonType.outline);
}

class TextOnlyButton extends CustomButton {
  const TextOnlyButton({
    super.key,
    required super.text,
    super.onPressed,
    super.isLoading = false,
    super.icon,
    super.width,
    super.height = 40,
  }) : super(type: ButtonType.text);
}

