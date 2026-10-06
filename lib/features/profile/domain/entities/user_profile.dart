import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_profile.freezed.dart';

@freezed
abstract class UserProfile with _$UserProfile {
  const factory UserProfile({
    required String name,
    required DateTime birthDate,
    // 'male' | 'female' | 'other'
    required String gender,
    @Default('default') String id,
    // Local file path from image_picker.
    String? photoPath,
    @Default(false) bool isDefault,
  }) = _UserProfile;

  const UserProfile._();

  /// Computed age from birth date.
  int get age {
    final now = DateTime.now();
    var years = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      years--;
    }
    return years;
  }
}
