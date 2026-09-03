import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:my_pills/core/db/app_database.dart';
import 'package:my_pills/core/network/media_upload_service.dart';
import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/core/sync/sync_engine.dart';
import 'package:my_pills/core/utils/calendar_date.dart';
import 'package:my_pills/core/utils/device_timezone.dart';
import 'package:my_pills/features/profile/domain/entities/user_profile.dart';
import 'package:my_pills/features/profile/domain/repositories/user_profile_repository.dart';
import 'package:uuid/uuid.dart';

class SyncedProfileRepository implements UserProfileRepository {
  SyncedProfileRepository({
    required UserProfileRepository localRepo,
    required AppDatabase db,
    required SyncEngine syncEngine,
    MediaUploadService? mediaUploadService,
  }) : _localRepo = localRepo,
       _db = db,
       _syncEngine = syncEngine,
       _mediaUploadService = mediaUploadService;

  final UserProfileRepository _localRepo;
  final AppDatabase _db;
  final SyncEngine _syncEngine;
  final MediaUploadService? _mediaUploadService;
  static const _uuid = Uuid();

  @override
  UserProfile? getProfile() {
    return _localRepo.getProfile();
  }

  @override
  List<UserProfile> getProfiles() {
    return _localRepo.getProfiles();
  }

  @override
  UserProfile? getProfileById(String id) {
    return _localRepo.getProfileById(id);
  }

  @override
  Future<void> saveProfile(UserProfile profile) async {
    var effectiveProfile = profile;
    String? photoUrl = profile.photoPath;

    if (photoUrl != null &&
        !photoUrl.startsWith('http://') &&
        !photoUrl.startsWith('https://') &&
        !photoUrl.startsWith('/uploads/') &&
        _mediaUploadService != null) {
      try {
        final file = File(photoUrl);
        if (file.existsSync()) {
          final uploadRes = await _mediaUploadService.uploadImage(file);
          if (uploadRes case Success(:final value)) {
            photoUrl = value;
            effectiveProfile = profile.copyWith(photoPath: value);
          }
        }
      } catch (_) {}
    }

    final existing = _localRepo.getProfileById(effectiveProfile.id);
    final isUpdate =
        existing != null &&
        effectiveProfile.id != 'default' &&
        effectiveProfile.id.isNotEmpty;

    await _localRepo.saveProfile(effectiveProfile);

    final clientId = _uuid.v4();
    final targetProfileId = isUpdate
        ? effectiveProfile.id
        : (effectiveProfile.id == 'default' ? 'default' : effectiveProfile.id);
    final action = isUpdate ? 'UPDATE' : 'CREATE';

    final timezone = DeviceTimezone.currentIanaId();
    final payload = <String, dynamic>{
      'name': effectiveProfile.name,
      'birthDate': CalendarDate.toIso(effectiveProfile.birthDate),
      'gender': effectiveProfile.gender,
      'timezone': ?timezone,
      'photoUrl': ?photoUrl,
    };

    await _db
        .into(_db.outboxTable)
        .insert(
          OutboxTableCompanion.insert(
            profileId: targetProfileId,
            entityType: 'profile',
            entityId: profile.id,
            clientId: clientId,
            action: action,
            payloadJson: jsonEncode(payload),
            createdAt: DateTime.now().toUtc(),
          ),
        );

    // Trigger asynchronous outbox flush
    unawaited(_syncEngine.flushOutbox());
  }

  @override
  Future<void> deleteProfile(String id) async {
    await _localRepo.deleteProfile(id);

    final clientId = _uuid.v4();
    await _db
        .into(_db.outboxTable)
        .insert(
          OutboxTableCompanion.insert(
            profileId: id,
            entityType: 'profile',
            entityId: id,
            clientId: clientId,
            action: 'DELETE',
            payloadJson: jsonEncode({'id': id}),
            createdAt: DateTime.now().toUtc(),
          ),
        );

    unawaited(_syncEngine.flushOutbox());
  }

  @override
  String? getActiveProfileId() {
    return _localRepo.getActiveProfileId();
  }

  @override
  Future<void> setActiveProfileId(String id) async {
    await _localRepo.setActiveProfileId(id);
    if (id != 'default' && id.isNotEmpty) {
      unawaited(_syncEngine.syncProfile(id));
    }
  }

  @override
  bool isOnboardingComplete() {
    return _localRepo.isOnboardingComplete();
  }

  @override
  Future<void> setOnboardingComplete(bool complete) async {
    await _localRepo.setOnboardingComplete(complete);
  }
}
