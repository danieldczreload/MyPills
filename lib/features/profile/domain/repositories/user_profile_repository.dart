import 'package:my_pills/features/profile/domain/entities/user_profile.dart';

abstract class UserProfileRepository {
  UserProfile? getProfile();
  List<UserProfile> getProfiles();
  UserProfile? getProfileById(String id);
  Future<void> saveProfile(UserProfile profile);
  Future<void> deleteProfile(String id);
  Future<void> setActiveProfileId(String id);
  String? getActiveProfileId();
  bool isOnboardingComplete();
  Future<void> setOnboardingComplete(bool complete);
}
