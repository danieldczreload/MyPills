import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_profile.freezed.dart';

@freezed
abstract class UserProfile with _$UserProfile {
  const factory UserProfile({
    @Default('default') String id,
    required String name,
    required DateTime birthDate,
    required String gender, // 'male' | 'female' | 'other'
    String? photoPath, // local file path from image_picker
    @Default(false) bool isDefault,
  }) = _UserProfile;

  const UserProfile._();

  /// Computed age from birth date.
  int get age {
    final now = DateTime.now();
    int years = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      years--;
    }
    return years;
  }
}
