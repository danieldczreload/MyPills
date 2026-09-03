import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_pills/features/notifications/domain/entities/in_app_banner.dart';
import 'package:my_pills/features/notifications/presentation/in_app_reminder_overlay.dart';
import 'package:my_pills/l10n/app_localizations.dart';

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('es'));
  });

  test('uses dose + profile when both are present', () {
    expect(
      doseReminderBannerBody(
        l10n,
        banner: const InAppBanner(
          medicationName: 'Ibuprofeno',
          doseDisplay: '400 mg',
        ),
        profileName: 'Ana',
      ),
      'Es hora de tomar Ibuprofeno (400 mg) — Ana',
    );
  });

  test('uses dose without dropping to the no-dose profile template', () {
    expect(
      doseReminderBannerBody(
        l10n,
        banner: const InAppBanner(
          medicationName: 'Ibuprofeno',
          doseDisplay: '400 mg',
        ),
      ),
      'Es hora de tomar Ibuprofeno (400 mg)',
    );
  });

  test('uses profile template when there is no dose display', () {
    expect(
      doseReminderBannerBody(
        l10n,
        banner: const InAppBanner(medicationName: 'Ibuprofeno'),
        profileName: 'Ana',
      ),
      'Es hora de tomar Ibuprofeno (Ana)',
    );
  });
}
