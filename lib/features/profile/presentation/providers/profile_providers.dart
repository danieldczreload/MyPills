import 'package:my_pills/app/providers.dart';
import 'package:my_pills/features/profile/data/user_profile_repository.dart';
import 'package:my_pills/features/profile/domain/entities/user_profile.dart';
import 'package:my_pills/features/profile/domain/repositories/user_profile_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'profile_providers.g.dart';

@Riverpod(keepAlive: true)
UserProfileRepository userProfileRepository(Ref ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SharedPrefsUserProfileRepository(prefs);
}

@Riverpod(keepAlive: true)
class CurrentUserProfile extends _$CurrentUserProfile {
  @override
  UserProfile? build() {
    final repository = ref.watch(userProfileRepositoryProvider);
    return repository.getProfile();
  }

  Future<void> updateProfile(UserProfile profile) async {
    final repository = ref.watch(userProfileRepositoryProvider);
    await repository.saveProfile(profile);
    await repository.setOnboardingComplete(true);
    state = profile;
  }
}
