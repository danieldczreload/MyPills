import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_pills/features/profile/domain/entities/user_profile.dart';
import 'package:my_pills/features/profile/presentation/providers/profile_providers.dart';
import 'package:my_pills/features/profile/presentation/widgets/user_profile_form.dart';
import 'package:my_pills/l10n/app_localizations.dart';

class EditProfileScreen extends ConsumerWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final profile = ref.watch(currentUserProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.editProfileTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: UserProfileForm(
          submitLabel: l10n.editProfileSaveButton,
          initialProfile: profile,
          photoPromptLabel: l10n.editProfileChangePhoto,
          onSubmit: (updated) => _submit(context, ref, updated),
        ),
      ),
    );
  }

  Future<void> _submit(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
  ) async {
    await ref.read(currentUserProfileProvider.notifier).updateProfile(profile);
    if (context.mounted) {
      context.pop();
    }
  }
}
