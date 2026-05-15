import 'package:flutter/material.dart';

import 'package:my_pills/core/theme/serene_theme.dart';

class SoftInputField extends StatelessWidget {
  const SoftInputField({
    required this.labelText,
    required this.controller,
    super.key,
    this.hintText,
    this.keyboardType,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
    this.onChanged,
    this.suffixIcon,
    this.prefixIcon,
    this.validator,
  });

  final String labelText;
  final String? hintText;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool readOnly;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final serene = theme.extension<SereneTheme>()!;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      readOnly: readOnly,
      onTap: onTap,
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerLow,
        contentPadding: EdgeInsets.symmetric(
          horizontal: serene.spacing.lg,
          vertical: serene.spacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: serene.radius.md,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: serene.radius.md,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: serene.radius.md,
          borderSide: BorderSide(
            color: theme.colorScheme.primary.withValues(alpha: 0.20),
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: serene.radius.md,
          borderSide: BorderSide(
            color: theme.colorScheme.error.withValues(alpha: 0.5),
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: serene.radius.md,
          borderSide: BorderSide(color: theme.colorScheme.error),
        ),
      ),
    );
  }
}
