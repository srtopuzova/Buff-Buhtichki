import 'package:flutter/material.dart';
import 'package:medshelf/core/theme/app_colors.dart';

class AuthTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final bool isPassword;
  final String? Function(String?)? validator;
  final Widget? prefixIcon;
  final TextInputAction textInputAction;
  final FocusNode? focusNode;
  final VoidCallback? onEditingComplete;
  final bool enabled;

  const AuthTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.keyboardType = TextInputType.text,
    this.isPassword = false,
    this.validator,
    this.prefixIcon,
    this.textInputAction = TextInputAction.next,
    this.focusNode,
    this.onEditingComplete,
    this.enabled = true,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          obscureText: widget.isPassword && _obscure,
          validator: widget.validator,
          textInputAction: widget.textInputAction,
          focusNode: widget.focusNode,
          onEditingComplete: widget.onEditingComplete,
          enabled: widget.enabled,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: widget.prefixIcon != null
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: IconTheme(
                      data: const IconThemeData(
                          color: AppColors.textSecondary, size: 20),
                      child: widget.prefixIcon!,
                    ),
                  )
                : null,
            prefixIconConstraints: const BoxConstraints(minWidth: 48),
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
