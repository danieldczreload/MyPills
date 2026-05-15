import 'package:flutter/material.dart';
import 'package:my_pills/core/theme/serene_theme.dart';

class SoftDropdownField<T> extends StatelessWidget {
  const SoftDropdownField({
    required this.labelText,
    required this.items,
    this.value,
    this.onChanged,
    this.hintText,
    super.key,
  });

  final String labelText;
  final String? hintText;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final serene = theme.extension<SereneTheme>()!;

    return DropdownButtonFormField<T>(
      initialValue: value,
      items: items,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
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
      ),
    );
  }
}
