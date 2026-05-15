import 'package:my_pills/features/profile/domain/entities/user_profile.dart';
import 'package:my_pills/features/profile/domain/repositories/user_profile_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsUserProfileRepository implements UserProfileRepository {
  const SharedPrefsUserProfileRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _keyName = 'profile.name';
  static const _keyBirthDate = 'profile.birth_date';
  static const _keyGender = 'profile.gender';
  static const _keyPhotoPath = 'profile.photo_path';
  static const _keyOnboardingComplete = 'profile.onboarding_complete';

  @override
  UserProfile? getProfile() {
    final name = _prefs.getString(_keyName);
    final birthDateStr = _prefs.getString(_keyBirthDate);
    final gender = _prefs.getString(_keyGender);
    final photoPath = _prefs.getString(_keyPhotoPath);

    if (name == null || birthDateStr == null || gender == null) {
      return null;
    }

    final birthDate = DateTime.tryParse(birthDateStr);
    if (birthDate == null) return null;

    return UserProfile(
      name: name,
      birthDate: birthDate,
      gender: gender,
      photoPath: photoPath,
    );
  }

  @override
  Future<void> saveProfile(UserProfile profile) async {
    await Future.wait([
      _prefs.setString(_keyName, profile.name),
      _prefs.setString(_keyBirthDate, profile.birthDate.toIso8601String()),
      _prefs.setString(_keyGender, profile.gender),
      if (profile.photoPath != null)
        _prefs.setString(_keyPhotoPath, profile.photoPath!)
      else
        _prefs.remove(_keyPhotoPath),
    ]);
  }

  @override
  bool isOnboardingComplete() {
    return _prefs.getBool(_keyOnboardingComplete) ?? false;
  }

  @override
  Future<void> setOnboardingComplete(bool complete) async {
    await _prefs.setBool(_keyOnboardingComplete, complete);
  }
}
