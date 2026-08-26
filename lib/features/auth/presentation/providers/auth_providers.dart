import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_pills/app/providers.dart';
import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/features/auth/data/services/microsoft_auth_service.dart';
import 'package:my_pills/features/auth/domain/entities/auth_user.dart';
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
    final syncEngine = ref.read(syncEngineProvider);
    unawaited(syncEngine.flushOutbox());
    final prefs = ref.read(sharedPreferencesProvider);
    final profileId = prefs.getString('active_profile_id');
    if (profileId != null && profileId.isNotEmpty && profileId != 'default') {
      unawaited(syncEngine.syncProfile(profileId));
    } else {
      unawaited(syncEngine.fetchAndRestoreProfiles());
    }
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
      _postLoginSync();
    } else {
      state = const AsyncValue.data(null);
    }
    return result;
  }
}

final microsoftAuthServiceProvider = Provider<MicrosoftAuthService>((ref) {
  return MicrosoftAuthService(
    dio: ref.watch(apiClientProvider).dio,
    prefs: ref.watch(sharedPreferencesProvider),
    authRepository: ref.watch(authRepositoryProvider),
  );
});
