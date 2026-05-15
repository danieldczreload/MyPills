import 'package:my_pills/features/profile/domain/entities/user_profile.dart';

abstract class UserProfileRepository {
  UserProfile? getProfile();
  Future<void> saveProfile(UserProfile profile);
  bool isOnboardingComplete();
  Future<void> setOnboardingComplete(bool complete);
}
