import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_pills/app/providers.dart';
import 'package:my_pills/app/router.dart';
import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/core/theme/serene_theme.dart';
import 'package:my_pills/core/widgets/gradient_primary_button.dart';
import 'package:my_pills/core/widgets/sanctuary_app_bar.dart';
import 'package:my_pills/core/widgets/soft_dropdown_field.dart';
import 'package:my_pills/core/widgets/soft_input_field.dart';
import 'package:my_pills/features/medications/domain/entities/medication.dart';
import 'package:my_pills/features/medications/domain/entities/taxonomy_group.dart';
import 'package:my_pills/features/medications/domain/entities/taxonomy_type.dart';
import 'package:my_pills/features/medications/presentation/providers/taxonomy_providers.dart';
import 'package:my_pills/features/medications/presentation/widgets/create_taxonomy_sheet.dart';
import 'package:my_pills/features/schedules/presentation/widgets/medication_schedules_sheet.dart';
import 'package:my_pills/l10n/app_localizations.dart';

/// Create or edit a medication.
///
/// **Create mode** (`medication == null`): wizard step 1 of 3 — after saving
/// the medication, navigation proceeds to the daily scheduler.
///
/// **Edit mode** (`medication != null`): form pre-filled with existing data —
/// saving calls `UpdateMedication` and pops back to the list.
class AddMedicationScreen extends ConsumerStatefulWidget {
  /// Pass a [Medication] to open in edit mode; leave null to create a new one.
  const AddMedicationScreen({this.medication, super.key});

  final Medication? medication;

  @override
  ConsumerState<AddMedicationScreen> createState() =>
      _AddMedicationScreenState();
}

class _AddMedicationScreenState extends ConsumerState<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _notesController;

  late MedicationForm _form;
  late String _colorToken;
  int? _selectedGroupId;
  bool _isSaving = false;
  String? _categoryError;

  bool get _isEditMode => widget.medication != null;

  @override
  void initState() {
    super.initState();
    final med = widget.medication;
    _nameController = TextEditingController(text: med?.name ?? '');
    _notesController = TextEditingController(text: med?.notes ?? '');
    _form = med?.form ?? MedicationForm.pill;
    _colorToken = med?.colorToken ?? 'primary';
    // selectedGroupId will be resolved lazily once taxonomy data loads
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final serene = theme.extension<SereneTheme>()!;
    final groupsAsync = ref.watch(
      taxonomyGroupsByTypeProvider(TaxonomyType.category),
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const SanctuaryAppBar(),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          serene.spacing.lg,
          120,
          serene.spacing.lg,
          serene.spacing.xxxxl + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              (_isEditMode
                      ? l10n.editMedicationStepLabel
                      : l10n.addMedicationStepLabel)
                  .toUpperCase(),
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
                letterSpacing: 1.5,
              ),
            ),
            SizedBox(height: serene.spacing.xs),
            Text(
              _isEditMode
                  ? l10n.editMedicationHeading
                  : l10n.addMedicationHeading,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
            SizedBox(height: serene.spacing.sm),
            Text(
              _isEditMode
                  ? l10n.editMedicationSubheading
                  : l10n.addMedicationSubheading,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: serene.spacing.xl),
            SoftInputField(
              controller: _nameController,
              labelText: l10n.nameLabel,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? l10n.errorNameRequired
                  : null,
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
            SizedBox(height: serene.spacing.lg),
            groupsAsync.when(
              data: (groups) {
                // In edit mode, resolve the group id from the category name
                // once data is available (only on first build).
                if (_isEditMode && _selectedGroupId == null) {
                  final cat = widget.medication!.category;
                  final match = groups.where((g) => g.name == cat).firstOrNull;
                  if (match != null) {
                    // schedule the state update after the current build frame
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() => _selectedGroupId = match.id);
                      }
                    });
                  }
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CategoryField(
                      groups: groups,
                      selectedId: _selectedGroupId,
                      onChanged: (id) {
                        setState(() {
                          _selectedGroupId = id;
                          _categoryError = null;
                        });
                      },
                      onCreateNew: () => _openCreateCategory(groups),
                    ),
                    if (_categoryError != null)
                      Padding(
                        padding: EdgeInsets.only(
                          top: serene.spacing.xs,
                          left: serene.spacing.lg,
                        ),
                        child: Text(
                          _categoryError!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Text(l10n.errorUnexpected),
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
            SizedBox(height: serene.spacing.xxxxl),
            groupsAsync.maybeWhen(
              data: (groups) => GradientPrimaryButton(
                label: _isEditMode ? l10n.saveButton : l10n.nextButton,
                onPressed: _isSaving
                    ? null
                    : () => _isEditMode ? _update(groups) : _create(groups),
              ),
              orElse: () => const SizedBox.shrink(),
            ),
            // ── Schedules — only in edit mode ──────────────────────────────
            if (_isEditMode) ...[
              SizedBox(height: serene.spacing.lg),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _openSchedulesSheet(context),
                  icon: const Icon(Icons.schedule_outlined),
                  label: Text(l10n.activeSchedulesTitle),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: serene.radius.md,
                    ),
                  ),
                ),
              ),
            ],
            // ── Delete action — only in edit mode ──────────────────────────
            if (_isEditMode) ...[
              SizedBox(height: serene.spacing.lg),
              Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: Theme.of(
                        context,
                      ).colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
              SizedBox(height: serene.spacing.lg),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isSaving ? null : _delete,
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: Text(l10n.deleteMedicationTitle),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                    side: BorderSide(
                      color: Theme.of(
                        context,
                      ).colorScheme.error.withValues(alpha: 0.4),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: Theme.of(
                        context,
                      ).extension<SereneTheme>()!.radius.md,
                    ),
                  ),
                ),
              ),
              SizedBox(height: serene.spacing.lg),
            ],
          ],
        ),
      ),
      ),
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

  void _openSchedulesSheet(BuildContext ctx) {
    unawaited(
      showModalBottomSheet<void>(
        context: ctx,
        isScrollControlled: true,
        useRootNavigator: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (_) => MedicationSchedulesSheet(
          medicationId: widget.medication!.id,
          medicationName: widget.medication!.name,
        ),
      ),
    );
  }

  Future<void> _openCreateCategory(List<TaxonomyGroup> currentGroups) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CreateTaxonomySheet(type: TaxonomyType.category),
    );
    if (!mounted) return;
    final latest = ref.read(
      taxonomyGroupsByTypeProvider(TaxonomyType.category),
    );
    if (latest case AsyncData(:final value)) {
      final existingIds = currentGroups.map((g) => g.id).toSet();
      final newGroup = value
          .where((g) => !existingIds.contains(g.id))
          .firstOrNull;
      if (newGroup != null) setState(() => _selectedGroupId = newGroup.id);
    }
  }

  Future<void> _create(List<TaxonomyGroup> groups) async {
    final l10n = AppLocalizations.of(context);
    final name = _nameController.text.trim();

    final category = _selectedGroupId != null
        ? groups.firstWhere((g) => g.id == _selectedGroupId).name
        : '';

    if (category.isEmpty) {
      setState(() => _categoryError = l10n.errorCategoryRequired);
    }

    if (!_formKey.currentState!.validate() || category.isEmpty) return;

    setState(() => _categoryError = null);

    setState(() => _isSaving = true);

    final result = await ref
        .read(addMedicationUseCaseProvider)
        .call(
          name: name,
          form: _form,
          category: category,
          colorToken: _colorToken,
          notes: _notesController.text.isEmpty
              ? null
              : _notesController.text.trim(),
        );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (result case FailureResult()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorUnexpected)),
      );
      return;
    }

    final medicationId = result.valueOrNull!.id;
    unawaited(context.push(AppRoutes.schedulerDaily, extra: medicationId));
  }

  Future<void> _update(List<TaxonomyGroup> groups) async {
    final l10n = AppLocalizations.of(context);
    final name = _nameController.text.trim();

    final category = _selectedGroupId != null
        ? groups.firstWhere((g) => g.id == _selectedGroupId).name
        : widget.medication!.category;

    if (category.isEmpty) {
      setState(() => _categoryError = l10n.errorCategoryRequired);
    }

    if (!_formKey.currentState!.validate() || category.isEmpty) return;

    setState(() => _categoryError = null);

    setState(() => _isSaving = true);

    final result = await ref
        .read(updateMedicationUseCaseProvider)
        .call(
          id: widget.medication!.id,
          name: name,
          form: _form,
          category: category,
          colorToken: _colorToken,
          notes: _notesController.text.isEmpty
              ? null
              : _notesController.text.trim(),
        );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (result case FailureResult()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorUnexpected)),
      );
      return;
    }

    if (context.canPop()) context.pop();
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteMedicationTitle),
        content: Text(
          l10n.deleteMedicationConfirmation(widget.medication!.name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancelButton),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: Text(l10n.deleteButton),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSaving = true);
    final result = await ref
        .read(deleteMedicationUseCaseProvider)
        .call(widget.medication!.id);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (result case FailureResult()) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.errorUnexpected)),
      );
      return;
    }

    messenger.showSnackBar(
      SnackBar(content: Text(l10n.medicationDeletedMessage)),
    );
    navigator.pop();
  }
}

class _CategoryField extends StatelessWidget {
  const _CategoryField({
    required this.groups,
    required this.selectedId,
    required this.onChanged,
    required this.onCreateNew,
  });

  final List<TaxonomyGroup> groups;
  final int? selectedId;
  final ValueChanged<int?> onChanged;
  final VoidCallback onCreateNew;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final serene = theme.extension<SereneTheme>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (groups.isEmpty)
          _EmptyCategoryHint(onCreateNew: onCreateNew)
        else ...[
          SoftDropdownField<int>(
            value: selectedId,
            labelText: l10n.categoryLabel,
            items: groups
                .map(
                  (g) => DropdownMenuItem(value: g.id, child: Text(g.name)),
                )
                .toList(growable: false),
            onChanged: onChanged,
          ),
          SizedBox(height: serene.spacing.xs),
        ],
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: onCreateNew,
            icon: const Icon(Icons.add_circle_outline, size: 18),
            label: Text(l10n.newCategoryButton),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.secondary,
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyCategoryHint extends StatelessWidget {
  const _EmptyCategoryHint({required this.onCreateNew});

  final VoidCallback onCreateNew;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final serene = theme.extension<SereneTheme>()!;
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: EdgeInsets.all(serene.spacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: serene.radius.md,
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.label_outline,
            color: theme.colorScheme.onSurfaceVariant,
            size: 20,
          ),
          SizedBox(width: serene.spacing.md),
          Expanded(
            child: Text(
              l10n.newCategoryButton,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          TextButton(
            onPressed: onCreateNew,
            child: Text(l10n.createCategoryButton),
          ),
        ],
      ),
    );
  }
}
