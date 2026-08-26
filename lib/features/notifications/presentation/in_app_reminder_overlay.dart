import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_pills/app/router.dart';
import 'package:my_pills/core/theme/serene_theme.dart';
import 'package:my_pills/features/medications/domain/entities/medication.dart';
import 'package:my_pills/features/medications/presentation/providers/medications_providers.dart';
import 'package:my_pills/features/notifications/presentation/providers/notification_providers.dart';
import 'package:my_pills/features/profile/presentation/providers/profile_providers.dart';
import 'package:my_pills/l10n/app_localizations.dart';

class InAppReminderOverlay extends ConsumerStatefulWidget {
  const InAppReminderOverlay({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<InAppReminderOverlay> createState() =>
      _InAppReminderOverlayState();
}

class _InAppReminderOverlayState extends ConsumerState<InAppReminderOverlay>
    with SingleTickerProviderStateMixin {
  OverlayEntry? _overlayEntry;
  late final AnimationController _animationController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation =
        Tween<Offset>(
          begin: const Offset(0, -1),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _dismissTimer?.cancel();
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showOverlay(
    BuildContext context,
    String medicationName, {
    String? profileName,
    required VoidCallback onDismiss,
  }) {
    if (_overlayEntry != null) {
      _removeOverlay();
    }

    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sereneTheme = theme.extension<SereneTheme>()!;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: MediaQuery.paddingOf(context).top + sereneTheme.spacing.md,
          left: sereneTheme.spacing.md,
          right: sereneTheme.spacing.md,
          child: SafeArea(
            child: Material(
              color: Colors.transparent,
              child: SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Dismissible(
                    key: UniqueKey(),
                    direction: DismissDirection.up,
                    onDismissed: (_) {
                      _removeOverlay();
                    },
                    child: GestureDetector(
                      onTap: () {
                        _removeOverlay();
                        context.go(AppRoutes.today);
                      },
                      child: Container(
                        padding: EdgeInsets.all(sereneTheme.spacing.md),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: sereneTheme.radius.md,
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.shadow.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(
                            color: colorScheme.primary.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(sereneTheme.spacing.sm),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                borderRadius: sereneTheme.radius.sm,
                              ),
                              child: Icon(
                                Icons.medication,
                                color: colorScheme.primary,
                              ),
                            ),
                            SizedBox(width: sereneTheme.spacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    profileName != null &&
                                            profileName.isNotEmpty
                                        ? l10n.inAppReminderTitleWithProfile(
                                            profileName,
                                          )
                                        : l10n.inAppReminderTitle,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.onSurface,
                                        ),
                                  ),
                                  Text(
                                    profileName != null &&
                                            profileName.isNotEmpty
                                        ? l10n.notificationBodyWithProfile(
                                            medicationName,
                                            profileName,
                                          )
                                        : l10n.notificationBody(medicationName),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    final overlay = rootNavigatorKey.currentState?.overlay;
    if (overlay == null) {
      _overlayEntry = null;
      return;
    }
    overlay.insert(_overlayEntry!);
    _animationController.forward();

    _dismissTimer?.cancel();
    _dismissTimer = Timer(const Duration(seconds: 8), () {
      onDismiss();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Listen to the reminder stream
    ref.listen(inAppRemindersStreamProvider, (previous, next) async {
      final dose = next.value;
      if (dose == null) return;

      final prefs = ref.read(notificationPreferencesProvider);
      if (!prefs.inAppBannersEnabled) return;

      final medsResult = await ref.read(medicationsStreamProvider.future);
      String medName = "Medicamento";
      if (medsResult.isSuccess) {
        final med = medsResult.valueOrNull?.firstWhere(
          (m) => m.id == dose.medicationId,
          orElse: () => const Medication(
            id: 0,
            name: '',
            form: MedicationForm.pill,
            category: '',
            colorToken: '',
          ),
        );
        if (med != null && med.name.isNotEmpty) {
          medName = med.name;
        }
      }

      final currentProfile = ref.read(currentUserProfileProvider);
      final profileName = currentProfile?.name;

      if (mounted) {
        _showOverlay(
          context,
          medName,
          profileName: profileName,
          onDismiss: () {
            _animationController.reverse().then((_) {
              if (mounted) {
                _removeOverlay();
              }
            });
          },
        );
      }
    });

    return widget.child;
  }
}
