import 'dart:convert';
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
  static const _keyProfilesList = 'profiles_list_json';
  static const _keyActiveProfileId = 'active_profile_id';

  @override
  UserProfile? getProfile() {
    final activeId = getActiveProfileId();
    final all = getProfiles();
    if (all.isEmpty) return null;

    if (activeId != null) {
      final match = all.where((p) => p.id == activeId).firstOrNull;
      if (match != null) return match;
    }

    return all.first;
  }

  @override
  List<UserProfile> getProfiles() {
    final jsonStr = _prefs.getString(_keyProfilesList);
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final list = jsonDecode(jsonStr) as List<dynamic>;
        return list.map((item) {
          final map = item as Map<String, dynamic>;
          return UserProfile(
            id: map['id'] as String? ?? 'default',
            name: map['name'] as String? ?? '',
            birthDate:
                DateTime.tryParse(map['birthDate'] as String? ?? '') ??
                DateTime(2000),
            gender: map['gender'] as String? ?? 'other',
            photoPath: map['photoPath'] as String?,
            isDefault: map['isDefault'] as bool? ?? false,
          );
        }).toList();
      } catch (_) {}
    }

    // Fallback: migrate legacy single-profile format
    final legacyName = _prefs.getString(_keyName);
    final legacyBirthDateStr = _prefs.getString(_keyBirthDate);
    final legacyGender = _prefs.getString(_keyGender);
    final legacyPhotoPath = _prefs.getString(_keyPhotoPath);

    if (legacyName != null && legacyBirthDateStr != null) {
      final legacyProfile = UserProfile(
        id: _prefs.getString(_keyActiveProfileId) ?? 'default',
        name: legacyName,
        birthDate: DateTime.tryParse(legacyBirthDateStr) ?? DateTime(2000),
        gender: legacyGender ?? 'other',
        photoPath: legacyPhotoPath,
        isDefault: true,
      );
      return [legacyProfile];
    }

    return [];
  }

  @override
  UserProfile? getProfileById(String id) {
    return getProfiles().where((p) => p.id == id).firstOrNull;
  }

  @override
  Future<void> saveProfile(UserProfile profile) async {
    final all = getProfiles().toList();
    final index = all.indexWhere((p) => p.id == profile.id);

    if (index >= 0) {
      all[index] = profile;
    } else {
      all.add(profile);
    }

    await _saveProfilesList(all);

    // If active profile is this one or not set, update legacy and active keys
    final activeId = getActiveProfileId();
    if (activeId == null || activeId == profile.id || all.length == 1) {
      await setActiveProfileId(profile.id);
      await _syncLegacyFields(profile);
    }
  }

  @override
  Future<void> deleteProfile(String id) async {
    final all = getProfiles().where((p) => p.id != id).toList();
    await _saveProfilesList(all);

    if (getActiveProfileId() == id) {
      if (all.isNotEmpty) {
        await setActiveProfileId(all.first.id);
        await _syncLegacyFields(all.first);
      } else {
        await _prefs.remove(_keyActiveProfileId);
      }
    }
  }

  @override
  String? getActiveProfileId() {
    return _prefs.getString(_keyActiveProfileId);
  }

  @override
  Future<void> setActiveProfileId(String id) async {
    await _prefs.setString(_keyActiveProfileId, id);
    final profile = getProfileById(id);
    if (profile != null) {
      await _syncLegacyFields(profile);
    }
  }

  Future<void> _saveProfilesList(List<UserProfile> list) async {
    final data = list
        .map(
          (p) => {
            'id': p.id,
            'name': p.name,
            'birthDate': p.birthDate.toIso8601String(),
            'gender': p.gender,
            'photoPath': p.photoPath,
            'isDefault': p.isDefault,
          },
        )
        .toList();
    await _prefs.setString(_keyProfilesList, jsonEncode(data));
  }

  Future<void> _syncLegacyFields(UserProfile profile) async {
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
