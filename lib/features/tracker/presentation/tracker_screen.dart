import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:my_pills/app/providers.dart';
import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/core/theme/serene_theme.dart';
import 'package:my_pills/core/widgets/app_notification.dart';
import 'package:my_pills/core/widgets/sanctuary_app_bar.dart';
import 'package:my_pills/features/medications/domain/entities/medication.dart';
import 'package:my_pills/features/medications/presentation/providers/medications_providers.dart';
import 'package:my_pills/features/medications/presentation/utils/medication_visual_helpers.dart';
import 'package:my_pills/features/profile/presentation/providers/profile_providers.dart';
import 'package:my_pills/features/timeline/presentation/providers/timeline_providers.dart';
import 'package:my_pills/features/tracker/domain/entities/dose_event.dart';
import 'package:my_pills/features/tracker/presentation/providers/tracker_providers.dart';
import 'package:my_pills/features/tracker/presentation/widgets/timeline_card.dart';
import 'package:my_pills/features/tracker/presentation/widgets/timeline_node.dart';
import 'package:my_pills/l10n/app_localizations.dart';

class TrackerScreen extends ConsumerStatefulWidget {
  const TrackerScreen({super.key});

  @override
  ConsumerState<TrackerScreen> createState() => _TrackerScreenState();
}

class _TrackerScreenState extends ConsumerState<TrackerScreen> {
  final GlobalKey _centerKey = GlobalKey();
  late final ScrollController _scrollController;

  static const double _loadThreshold = 200;

  bool _expandingPast = false;
  bool _expandingFuture = false;
  double _lastScrollPixels = 0;

  // Range managed as local state: today ± N days.
  int _pastDays = 0;
  int _futureDays = 2;

  // Cache last successful data — prevents spinner during range expansion.
  Result<List<DoseEvent>>? _cachedEvents;
  Result<List<Medication>>? _cachedMeds;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (!pos.hasContentDimensions) return;

    final px = pos.pixels;
    final toPast = px < _lastScrollPixels;
    final toFuture = px > _lastScrollPixels;
    _lastScrollPixels = px;

    if (toPast && !_expandingPast && pos.extentBefore < _loadThreshold) {
      _expandPast();
    }
    if (toFuture && !_expandingFuture && pos.extentAfter < _loadThreshold) {
      _expandFuture();
    }
  }

  void _expandPast() {
    _expandingPast = true;
    setState(() => _pastDays++);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _expandingPast = false;
    });
  }

  void _expandFuture() {
    _expandingFuture = true;
    setState(() => _futureDays++);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _expandingFuture = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final serene = theme.extension<SereneTheme>()!;
    final now = ref.watch(clockProvider);
    final today = DateTime(now.year, now.month, now.day);

    final range = (
      start: today.subtract(Duration(days: _pastDays)),
      end: today.add(Duration(days: _futureDays)),
    );

    final eventsAsync = ref.watch(timelineEventsProvider(range));
    final medsAsync = ref.watch(medicationsStreamProvider);

    // Update cache when fresh data arrives.
    if (eventsAsync case AsyncData(:final value)) _cachedEvents = value;
    if (medsAsync case AsyncData(:final value)) _cachedMeds = value;

    // Show spinner only on the very first load (no cache yet).
    if (_cachedEvents == null || _cachedMeds == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final eventsResult = _cachedEvents!;
    final medsResult = _cachedMeds!;

    if (eventsResult case FailureResult()) {
      return Scaffold(body: Center(child: Text(l10n.errorUnexpected)));
    }
    if (medsResult case FailureResult()) {
      return Scaffold(body: Center(child: Text(l10n.errorUnexpected)));
    }

    final medications = medsResult.valueOrNull!;
    final medicationIds = medications.map((m) => m.id).toSet();
    final allDoses =
        eventsResult.valueOrNull!
            .where((d) => medicationIds.contains(d.medicationId))
            .toList(growable: false)
          ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

    // Partition doses into past / today / future.
    final pastByDay = <DateTime, List<DoseEvent>>{};
    final todayDoses = <DoseEvent>[];
    final futureByDay = <DateTime, List<DoseEvent>>{};

    for (final dose in allDoses) {
      final day = DateTime(
        dose.scheduledAt.year,
        dose.scheduledAt.month,
        dose.scheduledAt.day,
      );
      if (day.isBefore(today)) {
        pastByDay.putIfAbsent(day, () => []).add(dose);
      } else if (day == today) {
        todayDoses.add(dose);
      } else {
        futureByDay.putIfAbsent(day, () => []).add(dose);
      }
    }

    final pastDays = pastByDay.keys.toList()..sort();
    final futureDays = futureByDay.keys.toList()..sort();
    final pendingToday = todayDoses
        .where((d) => d.status == DoseStatus.pending)
        .length;

    // Height reserved so today's content starts below the floating app bar.
    final topPadding =
        MediaQuery.paddingOf(context).top + kToolbarHeight + serene.spacing.sm;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const SanctuaryAppBar(),
      body: CustomScrollView(
        controller: _scrollController,
        center: _centerKey,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── REVERSE AREA ─────────────────────────────────────────────────
          // Past-edge indicator — triggered when user scrolls up far enough.
          _buildEdgeIndicator(
            theme,
            serene,
            isPast: true,
            isLoading: _expandingPast,
            l10n: l10n,
          ),
          // Past days, oldest first in list → last item renders closest to
          // today because the reverse area places slivers bottom-up.
          for (final day in pastDays)
            _buildDaySection(
              day: day,
              doses: pastByDay[day]!,
              medications: medications,
              today: today,
              isPast: true,
              serene: serene,
            ),

          // ── CENTER ANCHOR (scroll offset 0 = top of today) ────────────────
          SliverToBoxAdapter(
            key: _centerKey,
            child: SizedBox(height: topPadding),
          ),

          // ── FORWARD AREA ──────────────────────────────────────────────────
          // Today hero: date headline + pending-dose count.
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              serene.spacing.lg,
              0,
              serene.spacing.lg,
              serene.spacing.lg,
            ),
            sliver: SliverToBoxAdapter(
              child: _TodayHero(
                now: now,
                pendingCount: pendingToday,
                l10n: l10n,
                theme: theme,
                serene: serene,
              ),
            ),
          ),
          if (todayDoses.isEmpty)
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: serene.spacing.lg),
              sliver: SliverToBoxAdapter(
                child: Text(
                  l10n.emptyTodayDoses,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            _buildDaySection(
              day: today,
              doses: todayDoses,
              medications: medications,
              today: today,
              isPast: false,
              serene: serene,
            ),
          for (final day in futureDays)
            _buildDaySection(
              day: day,
              doses: futureByDay[day]!,
              medications: medications,
              today: today,
              isPast: false,
              serene: serene,
            ),
          // Future-edge indicator.
          _buildEdgeIndicator(
            theme,
            serene,
            isPast: false,
            isLoading: _expandingFuture,
            l10n: l10n,
          ),
          // Stats.
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: serene.spacing.lg),
            sliver: SliverToBoxAdapter(
              child: _StatsRow(
                streakAsync: ref.watch(streakProvider),
                adherenceAsync: ref.watch(adherenceProvider),
              ),
            ),
          ),
          // Bottom padding for floating nav bar.
          SliverPadding(
            padding: EdgeInsets.only(
              bottom:
                  serene.spacing.xxxxl * 2.5 +
                  MediaQuery.paddingOf(context).bottom,
            ),
          ),
        ],
      ),
    );
  }

  SliverToBoxAdapter _buildEdgeIndicator(
    ThemeData theme,
    SereneTheme serene, {
    required bool isPast,
    required bool isLoading,
    required AppLocalizations l10n,
  }) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.all(serene.spacing.lg),
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              : Text(
                  isPast
                      ? l10n.trackerScrollPastHint
                      : l10n.trackerScrollFutureHint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
        ),
      ),
    );
  }

  SliverPadding _buildDaySection({
    required DateTime day,
    required List<DoseEvent> doses,
    required List<Medication> medications,
    required DateTime today,
    required bool isPast,
    required SereneTheme serene,
  }) {
    final isToday = day == today;
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: serene.spacing.lg),
      sliver: SliverToBoxAdapter(
        child: Opacity(
          opacity: isPast ? 0.65 : 1.0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isToday) _DayHeader(day: day),
              ...doses.asMap().entries.map((e) {
                final i = e.key;
                final dose = e.value;
                final med = medications.firstWhere(
                  (m) => m.id == dose.medicationId,
                );
                return _DoseRow(
                  dose: dose,
                  medication: med,
                  isFirst: i == 0,
                  isLast: i == doses.length - 1,
                  isToday: isToday,
                  isPast: isPast,
                );
              }),
              SizedBox(height: serene.spacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Today hero header ────────────────────────────────────────────────────────

class _TodayHero extends StatelessWidget {
  const _TodayHero({
    required this.now,
    required this.pendingCount,
    required this.l10n,
    required this.theme,
    required this.serene,
  });

  final DateTime now;
  final int pendingCount;
  final AppLocalizations l10n;
  final ThemeData theme;
  final SereneTheme serene;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.navToday.toUpperCase(),
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.outline,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        SizedBox(height: serene.spacing.xs),
        Text(
          DateFormat('MMMM d', 'es').format(now),
          style: theme.textTheme.headlineLarge?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: serene.spacing.sm),
        Text(
          l10n.trackerSubtitle(pendingCount),
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: serene.spacing.xl),
      ],
    );
  }
}

// ── Non-today day header ─────────────────────────────────────────────────────

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final serene = theme.extension<SereneTheme>()!;
    final label = DateFormat('EEE, d MMM', 'es').format(day);

    return Padding(
      padding: EdgeInsets.only(
        top: serene.spacing.sm,
        bottom: serene.spacing.md,
      ),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: serene.spacing.md,
          vertical: serene.spacing.xs,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: serene.radius.sm,
        ),
        child: Text(
          label.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}

// ── Dose row ─────────────────────────────────────────────────────────────────

class _DoseRow extends ConsumerWidget {
  const _DoseRow({
    required this.dose,
    required this.medication,
    required this.isFirst,
    required this.isLast,
    required this.isToday,
    required this.isPast,
  });

  final DoseEvent dose;
  final Medication medication;
  final bool isFirst;
  final bool isLast;
  final bool isToday;
  final bool isPast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final serene = theme.extension<SereneTheme>()!;
    final time = DateFormat('h:mm a').format(dose.scheduledAt.toLocal());

    // Only today's pending/missed doses can be acted upon.
    final isActionable =
        isToday &&
        (dose.status == DoseStatus.pending || dose.status == DoseStatus.missed);

    final Color chipColor;
    final Color chipTextColor;
    final IconData? trailingIcon;
    final String timeLabel;

    switch (dose.status) {
      case DoseStatus.taken:
        chipColor = theme.colorScheme.secondaryContainer.withValues(alpha: 0.3);
        chipTextColor = theme.colorScheme.secondary;
        trailingIcon = null;
        timeLabel = '${l10n.doseStatusTaken} • $time';
      case DoseStatus.pending:
        if (isToday) {
          chipColor = theme.colorScheme.primary;
          chipTextColor = theme.colorScheme.onPrimary;
          timeLabel = '${l10n.trackerUpcoming} • $time';
        } else if (isPast) {
          chipColor = theme.colorScheme.tertiaryFixedDim;
          chipTextColor = theme.colorScheme.onSurface;
          timeLabel = '${l10n.trackerMissedAlert} • $time';
        } else {
          chipColor = theme.colorScheme.surfaceContainerHigh;
          chipTextColor = theme.colorScheme.onSurfaceVariant;
          timeLabel = '${l10n.trackerUpcoming} • $time';
        }
        trailingIcon = isActionable ? Icons.delete_outline : null;
      case DoseStatus.missed:
        chipColor = theme.colorScheme.tertiaryFixedDim;
        chipTextColor = theme.colorScheme.onSurface;
        trailingIcon = isActionable ? Icons.delete_outline : null;
        timeLabel = '${l10n.trackerMissedAlert} • $time';
    }

    final formIcon = medicationFormIcon(medication.form);
    final formLabel = medicationFormLabel(l10n, medication.form);
    final medColor = resolveMedicationColor(medication.colorToken, theme);

    final allProfiles = ref.watch(allProfilesProvider);
    final currentProfile = ref.watch(currentUserProfileProvider);
    final matchedProfile =
        currentProfile ?? (allProfiles.isNotEmpty ? allProfiles.first : null);
    final profileName = matchedProfile?.name;
    final profilePhotoPath = matchedProfile?.photoPath;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : serene.spacing.md),
      child: TimelineNode(
        status: dose.status,
        isFirst: isFirst,
        isLast: isLast,
        medicationIcon: formIcon,
        medicationColor: medColor,
        child: TimelineCard(
          title: medication.name,
          subtitle: medication.notes ?? '',
          profileName: profileName,
          profilePhotoPath: profilePhotoPath,
          category: medication.category,
          formLabel: formLabel,
          accentColor: medColor,
          timeLabel: timeLabel,
          isFocus: isActionable,
          chipColor: chipColor,
          chipTextColor: chipTextColor,
          trailingIcon: trailingIcon,
          primaryActionLabel: isActionable ? l10n.trackerLogAsTaken : null,
          onPrimaryAction: isActionable
              ? () => unawaited(_markTaken(context, ref, dose.id))
              : null,
          onTrailingIconPressed: isActionable
              ? () => unawaited(
                  _showCancelAlertOptions(context, ref, dose, medication),
                )
              : null,
        ),
      ),
    );
  }

  Future<void> _markTaken(BuildContext context, WidgetRef ref, int id) async {
    final result = await ref.read(markDoseTakenUseCaseProvider).call(id);
    if (!context.mounted) return;
    if (result case FailureResult()) {
      AppNotification.showError(
        context,
        AppLocalizations.of(context).errorUnexpected,
      );
      return;
    }
    ref
      ..invalidate(streakProvider)
      ..invalidate(adherenceProvider);
  }

  Future<void> _showCancelAlertOptions(
    BuildContext context,
    WidgetRef ref,
    DoseEvent dose,
    Medication medication,
  ) async {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final serene = theme.extension<SereneTheme>()!;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) => SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          serene.spacing.lg,
          serene.spacing.lg,
          serene.spacing.lg,
          serene.spacing.lg + MediaQuery.paddingOf(bottomSheetContext).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: serene.spacing.lg),
            Text(
              l10n.cancelAlertTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: serene.spacing.xs),
            Text(
              l10n.cancelAlertSubtitle(medication.name),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: serene.spacing.xl),
            InkWell(
              onTap: () {
                Navigator.of(bottomSheetContext).pop();
                unawaited(_cancelSingleDoseEvent(context, ref, dose.id));
              },
              borderRadius: serene.radius.lg,
              child: Container(
                padding: EdgeInsets.all(serene.spacing.md),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: serene.radius.lg,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withValues(
                          alpha: 0.3,
                        ),
                        borderRadius: serene.radius.md,
                      ),
                      child: Icon(
                        Icons.notifications_off_outlined,
                        color: theme.colorScheme.primary,
                        size: 22,
                      ),
                    ),
                    SizedBox(width: serene.spacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.cancelSingleAlertOption,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n.cancelSingleAlertOptionDesc,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: serene.spacing.md),
            InkWell(
              onTap: () {
                Navigator.of(bottomSheetContext).pop();
                unawaited(
                  _cancelRecurringAlerts(context, ref, dose.scheduleId),
                );
              },
              borderRadius: serene.radius.lg,
              child: Container(
                padding: EdgeInsets.all(serene.spacing.md),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: serene.radius.lg,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.tertiaryContainer.withValues(
                          alpha: 0.3,
                        ),
                        borderRadius: serene.radius.md,
                      ),
                      child: Icon(
                        Icons.event_repeat_rounded,
                        color: theme.colorScheme.tertiary,
                        size: 22,
                      ),
                    ),
                    SizedBox(width: serene.spacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.cancelRecurringAlertsOption,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n.cancelRecurringAlertsOptionDesc,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: serene.spacing.lg),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(bottomSheetContext).pop(),
                child: Text(l10n.cancelButton),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _cancelSingleDoseEvent(
    BuildContext context,
    WidgetRef ref,
    int id,
  ) async {
    final result = await ref.read(deleteDoseEventUseCaseProvider).call(id);
    if (!context.mounted) return;
    if (result case FailureResult()) {
      AppNotification.showError(
        context,
        AppLocalizations.of(context).errorUnexpected,
      );
      return;
    }
    AppNotification.showSuccess(
      context,
      AppLocalizations.of(context).singleAlertCancelledMessage,
    );
    ref
      ..invalidate(streakProvider)
      ..invalidate(adherenceProvider);
  }

  Future<void> _cancelRecurringAlerts(
    BuildContext context,
    WidgetRef ref,
    int scheduleId,
  ) async {
    final result = await ref
        .read(cancelRecurringNotificationsUseCaseProvider)
        .call(
          scheduleId: scheduleId,
        );
    if (!context.mounted) return;
    if (result case FailureResult()) {
      AppNotification.showError(
        context,
        AppLocalizations.of(context).errorUnexpected,
      );
      return;
    }
    AppNotification.showSuccess(
      context,
      AppLocalizations.of(context).recurringAlertsCancelledMessage,
    );
    ref
      ..invalidate(streakProvider)
      ..invalidate(adherenceProvider);
  }
}

// ── Stats ────────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.streakAsync,
    required this.adherenceAsync,
  });

  final AsyncValue<dynamic> streakAsync;
  final AsyncValue<dynamic> adherenceAsync;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final serene = theme.extension<SereneTheme>()!;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: serene.spacing.lg),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              icon: Icons.local_fire_department,
              label: l10n.trackerStreak,
              tooltipMessage: l10n.trackerStreakTooltip,
              valueAsync: streakAsync,
              unit: l10n.trackerDays,
              valueColor: theme.colorScheme.primary,
            ),
          ),
          SizedBox(width: serene.spacing.md),
          Expanded(
            child: _StatCard(
              icon: Icons.pie_chart,
              label: l10n.trackerAdherence,
              tooltipMessage: l10n.trackerAdherenceTooltip,
              valueAsync: adherenceAsync,
              unit: l10n.trackerWeekly,
              valueColor: theme.colorScheme.secondary,
              isPercentage: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.tooltipMessage,
    required this.valueAsync,
    required this.unit,
    required this.valueColor,
    this.isPercentage = false,
  });

  final IconData icon;
  final String label;
  final String tooltipMessage;
  final AsyncValue<dynamic> valueAsync;
  final String unit;
  final Color valueColor;
  final bool isPercentage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final serene = theme.extension<SereneTheme>()!;

    return Container(
      padding: EdgeInsets.all(serene.spacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: serene.radius.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
              SizedBox(width: serene.spacing.xs),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Tooltip(
                message: tooltipMessage,
                child: Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          SizedBox(height: serene.spacing.xl),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              valueAsync.when(
                data: (value) => Text(
                  isPercentage
                      ? '${(value as num).toStringAsFixed(0)}%'
                      : value.toString(),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: valueColor,
                  ),
                ),
                loading: () => SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: valueColor,
                  ),
                ),
                error: (_, _) => Text(
                  '--',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: valueColor,
                  ),
                ),
              ),
              SizedBox(width: serene.spacing.xs),
              Text(
                unit,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
