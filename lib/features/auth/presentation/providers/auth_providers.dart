import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_pills/app/providers.dart';
import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/features/auth/data/services/microsoft_auth_service.dart';
import 'package:my_pills/features/auth/domain/entities/auth_user.dart';
import 'package:my_pills/features/profile/presentation/providers/profile_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_providers.g.dart';

@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier {
  @override
  FutureOr<AuthUser?> build() async {
    final tokenStorage = ref.watch(tokenStorageProvider);
    final token = await tokenStorage.getAccessToken();
    if (token == null || token.isEmpty) {
      return null;
    }
    final authRepo = ref.watch(authRepositoryProvider);
    final result = await authRepo.getCurrentUser();
    return switch (result) {
      Success(:final value) => value,
      FailureResult() => null,
    };
  }

  /// Authenticates using Google ID token and initiates sync.
  Future<Result<AuthUser>> loginWithGoogle(
    String idToken, {
    String? displayName,
    String? photoUrl,
  }) async {
    state = const AsyncValue.loading();
    final authRepo = ref.read(authRepositoryProvider);
    final result = await authRepo.loginWithGoogle(
      idToken,
      displayName: displayName,
      photoUrl: photoUrl,
    );
    if (result case Success(:final value)) {
      state = AsyncValue.data(value);
      await _rememberGoogleClaims(value);
      _postLoginSync();
    } else {
      state = const AsyncValue.data(null);
    }
    return result;
  }

  /// Authenticates using Microsoft ID token and initiates sync.
  Future<Result<AuthUser>> loginWithMicrosoft(
    String idToken, {
    String? displayName,
    String? photoUrl,
  }) async {
    state = const AsyncValue.loading();
    final authRepo = ref.read(authRepositoryProvider);
    final result = await authRepo.loginWithMicrosoft(
      idToken,
      displayName: displayName,
      photoUrl: photoUrl,
    );
    if (result case Success(:final value)) {
      state = AsyncValue.data(value);
      await _rememberGoogleClaims(value);
      _postLoginSync();
    } else {
      state = const AsyncValue.data(null);
    }
    return result;
  }

  /// Logs out the user, clears secure tokens, and resets auth state.
  Future<void> logout() async {
    final authRepo = ref.read(authRepositoryProvider);
    await authRepo.logout();
    final prefs = ref.read(sharedPreferencesProvider);
    await Future.wait([
      prefs.remove('active_profile_id'),
      prefs.remove('profiles_list_json'),
      prefs.remove('profile.name'),
      prefs.remove('profile.birth_date'),
      prefs.remove('profile.gender'),
      prefs.remove('profile.photo_path'),
      prefs.setBool('profile.onboarding_complete', false),
    ]);
    state = const AsyncValue.data(null);
  }

  void _postLoginSync() {
    unawaited(_syncThenSeed());
  }

  /// Completes Microsoft PKCE authorization from deep link callback.
  Future<Result<AuthUser>> completeMicrosoftLogin({
    required String code,
    required String oauthState,
  }) async {
    state = const AsyncValue.loading();
    final msService = ref.read(microsoftAuthServiceProvider);
    final result = await msService.completeLogin(code: code, state: oauthState);
    if (result case Success(:final value)) {
      state = AsyncValue.data(value);
      await _rememberGoogleClaims(value);
      _postLoginSync();
    } else {
      state = const AsyncValue.data(null);
    }
    return result;
  }

  /// Store Google name/photo in profile prefs *before* the post-login
  /// sync, so a first-time local API (empty `/profiles`) creates the
  /// patient with those claims instead of "Usuario" and no photo.
  Future<void> _rememberGoogleClaims(AuthUser user) async {
    final prefs = ref.read(sharedPreferencesProvider);
    final name = user.name?.trim();
    if (name != null && name.isNotEmpty) {
      final existing = prefs.getString('profile.name');
      if (existing == null || existing.isEmpty || existing == 'Usuario') {
        await prefs.setString('profile.name', name);
      }
    }
    final photo = user.photoUrl;
    if (photo != null && photo.isNotEmpty) {
      final existingPhoto = prefs.getString('profile.photo_path');
      if (existingPhoto == null || existingPhoto.isEmpty) {
        await prefs.setString('profile.photo_path', photo);
      }
    }
  }

  Future<void> _syncThenSeed() async {
    final syncEngine = ref.read(syncEngineProvider);
    await syncEngine.flushOutbox();
    if (!ref.mounted) return;
    final prefs = ref.read(sharedPreferencesProvider);
    final profileId = prefs.getString('active_profile_id');
    if (profileId != null && profileId.isNotEmpty && profileId != 'default') {
      await syncEngine.syncProfile(profileId);
    } else {
      await syncEngine.fetchAndRestoreProfiles();
    }
    if (!ref.mounted) return;
    ref
      ..invalidate(currentUserProfileProvider)
      ..invalidate(allProfilesProvider);
    final user = state.asData?.value;
    if (user == null) return;
    final profile = ref.read(currentUserProfileProvider);
    if (profile == null) return;
    final photo = user.photoUrl;
    final name = user.name?.trim();
    final needsPhoto =
        (profile.photoPath == null || profile.photoPath!.isEmpty) &&
        photo != null &&
        photo.isNotEmpty;
    final needsName =
        (profile.name.isEmpty || profile.name == 'Usuario') &&
        name != null &&
        name.isNotEmpty;
    if (!needsPhoto && !needsName) return;
    await ref
        .read(currentUserProfileProvider.notifier)
        .updateProfile(
          profile.copyWith(
            name: needsName ? name : profile.name,
            photoPath: needsPhoto ? photo : profile.photoPath,
          ),
        );
  }
}

final microsoftAuthServiceProvider = Provider<MicrosoftAuthService>((ref) {
  return MicrosoftAuthService(
    dio: ref.watch(apiClientProvider).dio,
    prefs: ref.watch(sharedPreferencesProvider),
    authRepository: ref.watch(authRepositoryProvider),
  );
});
