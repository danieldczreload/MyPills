import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:my_pills/core/theme/serene_theme.dart';
import 'package:my_pills/core/widgets/app_avatar.dart';
import 'package:my_pills/core/widgets/soft_input_field.dart';
import 'package:my_pills/features/profile/domain/entities/user_profile.dart';
import 'package:my_pills/l10n/app_localizations.dart';

/// Shared profile form used in both onboarding and edit-profile screens.
///
/// Handles photo picker, name, birth date, and gender selection.
/// Callers supply [onSubmit] (which receives the composed [UserProfile])
/// and [submitLabel] for the CTA button.
class UserProfileForm extends StatefulWidget {
  const UserProfileForm({
    required this.onSubmit,
    required this.submitLabel,
    this.initialProfile,
    this.photoPromptLabel,
    super.key,
  });

  final Future<void> Function(UserProfile) onSubmit;
  final String submitLabel;
  final UserProfile? initialProfile;
  final String? photoPromptLabel;

  @override
  State<UserProfileForm> createState() => _UserProfileFormState();
}

class _UserProfileFormState extends State<UserProfileForm> {
  late TextEditingController _nameController;
  DateTime? _birthDate;
  String _gender = 'other';
  String? _photoPath;

  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final profile = widget.initialProfile;
    _nameController = TextEditingController(text: profile?.name ?? '');
    _birthDate = profile?.birthDate;
    _gender = profile?.gender ?? 'other';
    _photoPath = profile?.photoPath;
  }

  @override
  void didUpdateWidget(covariant UserProfileForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialProfile != null && oldWidget.initialProfile == null) {
      if (_nameController.text.isEmpty &&
          widget.initialProfile!.name.isNotEmpty) {
        _nameController.text = widget.initialProfile!.name;
      }
      if (_photoPath == null && widget.initialProfile!.photoPath != null) {
        setState(() {
          _photoPath = widget.initialProfile!.photoPath;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(l10n.onboardingPhotoCamera),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(l10n.onboardingPhotoGallery),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: source);
      if (image != null) {
        setState(() => _photoPath = image.path);
      }
    }
  }

  Future<void> _selectBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(1990, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _birthDate == null) return;
    setState(() => _isSubmitting = true);
    final profile = UserProfile(
      name: _nameController.text.trim(),
      birthDate: _birthDate!,
      gender: _gender,
      photoPath: _photoPath,
    );
    await widget.onSubmit(profile);
    if (mounted) setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final serene = theme.extension<SereneTheme>()!;
    final hasExistingPhoto = widget.initialProfile?.photoPath != null;

    return Form(
      key: _formKey,
      child: ListView(
        padding: EdgeInsets.all(serene.spacing.xxl),
        children: [
          // Photo picker
          Center(
            child: GestureDetector(
              onTap: _pickPhoto,
              child: Stack(
                children: [
                  AppAvatar(
                    photoPath: _photoPath,
                    radius: 48,
                    fallbackIcon: Icons.add_a_photo,
                    fallbackIconSize: 32,
                  ),
                  if (hasExistingPhoto || _photoPath != null)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.edit,
                          size: 16,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(height: serene.spacing.sm),
          Center(
            child: Text(
              widget.photoPromptLabel ?? l10n.onboardingPhotoPrompt,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          SizedBox(height: serene.spacing.xxl),

          // Name
          SoftInputField(
            controller: _nameController,
            labelText: l10n.onboardingNameLabel,
            prefixIcon: const Icon(Icons.person_outline),
            validator: (val) =>
                val == null || val.trim().isEmpty ? 'Requerido' : null,
          ),
          SizedBox(height: serene.spacing.xl),

          // Birth date
          GestureDetector(
            onTap: _selectBirthDate,
            child: AbsorbPointer(
              child: SoftInputField(
                controller: TextEditingController(
                  text: _birthDate != null
                      ? DateFormat.yMMMMd('es').format(_birthDate!)
                      : '',
                ),
                labelText: l10n.onboardingBirthDateLabel,
                prefixIcon: const Icon(Icons.cake_outlined),
                validator: (_) => _birthDate == null ? 'Requerido' : null,
              ),
            ),
          ),
          SizedBox(height: serene.spacing.xl),

          // Gender
          Text(
            l10n.onboardingGenderLabel,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: serene.spacing.sm),
          Wrap(
            spacing: serene.spacing.md,
            children: [
              ChoiceChip(
                label: Text(l10n.onboardingGenderMale),
                selected: _gender == 'male',
                onSelected: (v) {
                  if (v) setState(() => _gender = 'male');
                },
                selectedColor: theme.colorScheme.secondary.withValues(
                  alpha: 0.2,
                ),
              ),
              ChoiceChip(
                label: Text(l10n.onboardingGenderFemale),
                selected: _gender == 'female',
                onSelected: (v) {
                  if (v) setState(() => _gender = 'female');
                },
                selectedColor: theme.colorScheme.secondary.withValues(
                  alpha: 0.2,
                ),
              ),
              ChoiceChip(
                label: Text(l10n.onboardingGenderOther),
                selected: _gender == 'other',
                onSelected: (v) {
                  if (v) setState(() => _gender = 'other');
                },
                selectedColor: theme.colorScheme.secondary.withValues(
                  alpha: 0.2,
                ),
              ),
            ],
          ),
          SizedBox(height: serene.spacing.xxl * 2),

          // Submit
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: serene.spacing.lg),
              shape: RoundedRectangleBorder(
                borderRadius: serene.radius.xl,
              ),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    widget.submitLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
