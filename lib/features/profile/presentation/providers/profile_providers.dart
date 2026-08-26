import 'package:my_pills/app/providers.dart';
import 'package:my_pills/features/profile/data/repositories/synced_profile_repository.dart';
import 'package:my_pills/features/profile/data/user_profile_repository.dart';
import 'package:my_pills/features/profile/domain/entities/user_profile.dart';
import 'package:my_pills/features/profile/domain/repositories/user_profile_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'profile_providers.g.dart';

@Riverpod(keepAlive: true)
UserProfileRepository userProfileRepository(Ref ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final localRepo = SharedPrefsUserProfileRepository(prefs);
  final db = ref.watch(databaseProvider);
  final syncEngine = ref.watch(syncEngineProvider);
  final mediaUploadService = ref.watch(mediaUploadServiceProvider);
  return SyncedProfileRepository(
    localRepo: localRepo,
    db: db,
    syncEngine: syncEngine,
    mediaUploadService: mediaUploadService,
  );
}

@Riverpod(keepAlive: true)
class CurrentUserProfile extends _$CurrentUserProfile {
  @override
  UserProfile? build() {
    final repository = ref.watch(userProfileRepositoryProvider);
    return repository.getProfile();
  }

  Future<void> updateProfile(UserProfile profile) async {
    final repository = ref.read(userProfileRepositoryProvider);
    await repository.saveProfile(profile);
    await repository.setOnboardingComplete(true);
    state = repository.getProfile();
    ref.invalidate(allProfilesProvider);
  }

  Future<void> switchProfile(String id) async {
    final repository = ref.read(userProfileRepositoryProvider);
    await repository.setActiveProfileId(id);
    state = repository.getProfile();
    ref.invalidate(allProfilesProvider);
  }

  Future<void> addProfile(UserProfile profile) async {
    final repository = ref.read(userProfileRepositoryProvider);
    await repository.saveProfile(profile);
    state = repository.getProfile();
    ref.invalidate(allProfilesProvider);
  }

  Future<void> deleteProfile(String id) async {
    final repository = ref.read(userProfileRepositoryProvider);
    await repository.deleteProfile(id);
    state = repository.getProfile();
    ref.invalidate(allProfilesProvider);
  }
}

@Riverpod(keepAlive: true)
List<UserProfile> allProfiles(Ref ref) {
  final repository = ref.watch(userProfileRepositoryProvider);
  return repository.getProfiles();
}
