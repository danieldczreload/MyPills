import 'package:flutter_test/flutter_test.dart';
import 'package:my_pills/features/profile/data/user_profile_repository.dart';
import 'package:my_pills/features/profile/domain/entities/user_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SharedPrefsUserProfileRepository Multi-Profile', () {
    test(
      'starts with empty profiles when SharedPreferences is blank',
      () async {
        final prefs = await SharedPreferences.getInstance();
        final repo = SharedPrefsUserProfileRepository(prefs);

        expect(repo.getProfile(), isNull);
        expect(repo.getProfiles(), isEmpty);
      },
    );

    test('saves and retrieves multiple profiles', () async {
      final prefs = await SharedPreferences.getInstance();
      final repo = SharedPrefsUserProfileRepository(prefs);

      final profile1 = UserProfile(
        id: 'p1',
        name: 'Daniel',
        birthDate: DateTime(1995, 5, 10),
        gender: 'male',
      );

      final profile2 = UserProfile(
        id: 'p2',
        name: 'Hijo',
        birthDate: DateTime(2020, 1, 15),
        gender: 'male',
      );

      await repo.saveProfile(profile1);
      await repo.saveProfile(profile2);

      final all = repo.getProfiles();
      expect(all.length, 2);
      expect(all[0].name, 'Daniel');
      expect(all[1].name, 'Hijo');

      expect(repo.getProfileById('p1')?.name, 'Daniel');
      expect(repo.getProfileById('p2')?.name, 'Hijo');
    });

    test('switching active profile updates getProfile()', () async {
      final prefs = await SharedPreferences.getInstance();
      final repo = SharedPrefsUserProfileRepository(prefs);

      final p1 = UserProfile(
        id: 'p1',
        name: 'Daniel',
        birthDate: DateTime(1995, 5, 10),
        gender: 'male',
      );

      final p2 = UserProfile(
        id: 'p2',
        name: 'Hijo',
        birthDate: DateTime(2020, 1, 15),
        gender: 'male',
      );

      await repo.saveProfile(p1);
      await repo.saveProfile(p2);

      expect(repo.getProfile()?.id, 'p1');

      await repo.setActiveProfileId('p2');
      expect(repo.getProfile()?.id, 'p2');
      expect(repo.getProfile()?.name, 'Hijo');
    });

    test('deleting a profile removes it and updates active profile', () async {
      final prefs = await SharedPreferences.getInstance();
      final repo = SharedPrefsUserProfileRepository(prefs);

      final p1 = UserProfile(
        id: 'p1',
        name: 'Daniel',
        birthDate: DateTime(1995, 5, 10),
        gender: 'male',
      );

      final p2 = UserProfile(
        id: 'p2',
        name: 'Hijo',
        birthDate: DateTime(2020, 1, 15),
        gender: 'male',
      );

      await repo.saveProfile(p1);
      await repo.saveProfile(p2);
      await repo.setActiveProfileId('p2');

      await repo.deleteProfile('p2');
      final all = repo.getProfiles();
      expect(all.length, 1);
      expect(all.first.id, 'p1');
      expect(repo.getProfile()?.id, 'p1');
    });

    test('migrates legacy single profile format automatically', () async {
      SharedPreferences.setMockInitialValues({
        'profile.name': 'Legacy User',
        'profile.birth_date': '1990-06-15T00:00:00.000',
        'profile.gender': 'female',
      });

      final prefs = await SharedPreferences.getInstance();
      final repo = SharedPrefsUserProfileRepository(prefs);

      final all = repo.getProfiles();
      expect(all.length, 1);
      expect(all.first.name, 'Legacy User');
      expect(all.first.gender, 'female');
      expect(repo.getProfile()?.name, 'Legacy User');
    });
  });
}
