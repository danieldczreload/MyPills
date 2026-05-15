import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_pills/app/providers.dart';
import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/core/theme/serene_theme.dart';
import 'package:my_pills/core/widgets/gradient_primary_button.dart';
import 'package:my_pills/core/widgets/soft_dropdown_field.dart';
import 'package:my_pills/core/widgets/soft_input_field.dart';
import 'package:my_pills/features/medications/domain/entities/medication.dart';
import 'package:my_pills/l10n/app_localizations.dart';

class CreateMedicationSheet extends ConsumerStatefulWidget {
  const CreateMedicationSheet({super.key});

  @override
  ConsumerState<CreateMedicationSheet> createState() =>
      _CreateMedicationSheetState();
}

class _CreateMedicationSheetState extends ConsumerState<CreateMedicationSheet> {
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _notesController = TextEditingController();

  MedicationForm _form = MedicationForm.pill;
  String _colorToken = 'primary';
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final serene = theme.extension<SereneTheme>()!;
    final l10n = AppLocalizations.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.vertical(top: serene.radius.xl.topLeft),
          ),
          child: Column(
            children: [
              SizedBox(height: serene.spacing.md),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: serene.radius.full,
                  ),
                ),
              ),
              Expanded(
                child: Scrollbar(
                  controller: scrollController,
                  child: ListView(
                    controller: scrollController,
                    padding: EdgeInsets.only(
                      left: serene.spacing.xl,
                      right: serene.spacing.xl,
                      top: serene.spacing.lg,
                      bottom:
                          serene.spacing.xl +
                          MediaQuery.of(context).viewInsets.bottom,
                    ),
                    children: [
                      Text(
                        l10n.addMedicationButton,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      SizedBox(height: serene.spacing.xl),
                      SoftInputField(
                        controller: _nameController,
                        labelText: l10n.nameLabel,
                      ),
                      SizedBox(height: serene.spacing.lg),
                      SoftInputField(
                        controller: _categoryController,
                        labelText: l10n.categoryLabel,
                      ),
                      SizedBox(height: serene.spacing.lg),
                      SoftDropdownField<MedicationForm>(
                        value: _form,
                        labelText: l10n.medicationFormLabel,
                        items: [
                          DropdownMenuItem(
                            value: MedicationForm.pill,
                            child: Text(l10n.medicationFormPill),
                          ),
                          DropdownMenuItem(
                            value: MedicationForm.capsule,
                            child: Text(l10n.medicationFormCapsule),
                          ),
                          DropdownMenuItem(
                            value: MedicationForm.liquid,
                            child: Text(l10n.medicationFormLiquid),
                          ),
                          DropdownMenuItem(
                            value: MedicationForm.injection,
                            child: Text(l10n.medicationFormInjection),
                          ),
                          DropdownMenuItem(
                            value: MedicationForm.drops,
                            child: Text(l10n.medicationFormDrops),
                          ),
                          DropdownMenuItem(
                            value: MedicationForm.inhaler,
                            child: Text(l10n.medicationFormInhaler),
                          ),
                          DropdownMenuItem(
                            value: MedicationForm.patch,
                            child: Text(l10n.medicationFormPatch),
                          ),
                          DropdownMenuItem(
                            value: MedicationForm.other,
                            child: Text(l10n.medicationFormOther),
                          ),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _form = v);
                        },
                      ),
                      SizedBox(height: serene.spacing.xl),
                      Text(
                        l10n.colorTokenLabel,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(height: serene.spacing.md),
                      Row(
                        children: [
                          _colorChip(
                            label: l10n.colorTokenPrimary,
                            token: 'primary',
                            color: theme.colorScheme.primary,
                          ),
                          SizedBox(width: serene.spacing.sm),
                          _colorChip(
                            label: l10n.colorTokenSecondary,
                            token: 'secondary',
                            color: theme.colorScheme.secondary,
                          ),
                          SizedBox(width: serene.spacing.sm),
                          _colorChip(
                            label: l10n.colorTokenTertiary,
                            token: 'tertiary',
                            color: theme.colorScheme.tertiary,
                          ),
                        ],
                      ),
                      SizedBox(height: serene.spacing.lg),
                      SoftInputField(
                        controller: _notesController,
                        labelText: l10n.notesLabel,
                        maxLines: 3,
                      ),
                      SizedBox(height: serene.spacing.xxl),
                      GradientPrimaryButton(
                        label: l10n.saveButton,
                        onPressed: _isSaving ? null : _save,
                      ),
                      SizedBox(height: serene.spacing.xl),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _colorChip({
    required String label,
    required String token,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final serene = theme.extension<SereneTheme>()!;
    final selected = _colorToken == token;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _colorToken = token),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.symmetric(vertical: serene.spacing.md),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: serene.radius.md,
            border: Border.all(
              color: selected ? color : theme.colorScheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              SizedBox(height: serene.spacing.xs),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: selected ? color : theme.colorScheme.onSurfaceVariant,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final name = _nameController.text.trim();
    final category = _categoryController.text.trim();

    if (name.isEmpty || category.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorUnexpected)),
      );
      return;
    }

    setState(() => _isSaving = true);

    final result = await ref
        .read(addMedicationUseCaseProvider)
        .call(
          name: name,
          form: _form,
          category: category,
          colorToken: _colorToken,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
        );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (result case FailureResult()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorUnexpected)),
      );
      return;
    }

    Navigator.of(context).pop();
  }
}
