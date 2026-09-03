import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:my_pills/app/router.dart';
import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/core/theme/serene_theme.dart';
import 'package:my_pills/core/widgets/app_notification.dart';
import 'package:my_pills/core/widgets/gradient_primary_button.dart';
import 'package:my_pills/core/widgets/sanctuary_app_bar.dart';
import 'package:my_pills/core/widgets/selection_card.dart';
import 'package:my_pills/core/widgets/soft_dropdown_field.dart';
import 'package:my_pills/core/widgets/soft_input_field.dart';
import 'package:my_pills/features/medications/presentation/providers/medications_providers.dart';
import 'package:my_pills/features/profile/presentation/providers/profile_providers.dart';
import 'package:my_pills/features/profile/presentation/widgets/profile_selector_field.dart';
import 'package:my_pills/features/schedules/domain/entities/schedule.dart';
import 'package:my_pills/features/schedules/presentation/dose_input_controller.dart';
import 'package:my_pills/features/schedules/presentation/persist_new_schedule.dart';
import 'package:my_pills/features/schedules/presentation/widgets/dose_picker.dart';
import 'package:my_pills/features/schedules/presentation/widgets/notification_type_selector.dart';
import 'package:my_pills/features/schedules/presentation/widgets/schedule_time_picker.dart';
import 'package:my_pills/l10n/app_localizations.dart';

class DailySchedulerScreen extends ConsumerStatefulWidget {
  const DailySchedulerScreen({this.initialMedicationId, super.key});

  final int? initialMedicationId;

  @override
  ConsumerState<DailySchedulerScreen> createState() =>
      _DailySchedulerScreenState();
}

class _DailySchedulerScreenState extends ConsumerState<DailySchedulerScreen> {
  final List<TimeOfDay> _times = [const TimeOfDay(hour: 8, minute: 0)];
  final DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  late int? _medicationId = widget.initialMedicationId;
  String? _selectedProfileId;
  bool _isContinuous = true;
  bool _isSetTimesMode = true;
  bool _notifyPush = true;
  bool _notifyCalendar = false;

  late final TextEditingController _startDateController;
  late final TextEditingController _endDateController;
  final _doseInput = DoseInputController();

  @override
  void initState() {
    super.initState();
    _startDateController = TextEditingController(
      text: DateFormat.yMMMd('es').format(_startDate),
    );
    _endDateController = TextEditingController();
  }

  @override
  void dispose() {
    _startDateController.dispose();
    _endDateController.dispose();
    _doseInput.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final serene = theme.extension<SereneTheme>()!;
    final medsAsync = ref.watch(medicationsStreamProvider);
    final allProfiles = ref.watch(allProfilesProvider);
    final currentProfile = ref.watch(currentUserProfileProvider);

    _selectedProfileId ??=
        currentProfile?.id ??
        (allProfiles.isNotEmpty ? allProfiles.first.id : 'default');

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const SanctuaryAppBar(),
      body: medsAsync.when(
        data: (result) {
          if (result case FailureResult()) {
            return Center(child: Text(l10n.errorUnexpected));
          }
          final medications = result.valueOrNull!;
          if (medications.isEmpty) {
            return Center(child: Text(l10n.noMedicationsForSchedule));
          }

          _medicationId ??= medications.first.id;
          final selectedMedication = medications.firstWhere(
            (m) => m.id == _medicationId,
            orElse: () => medications.first,
          );
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              serene.spacing.lg,
              120, // Space for the blurred app bar
              serene.spacing.lg,
              serene.spacing.xxxxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.schedulerStepLabel.toUpperCase(),
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                    letterSpacing: 1.5,
                  ),
                ),
                SizedBox(height: serene.spacing.xs),
                Text(
                  l10n.schedulerHeading,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: serene.spacing.sm),
                Text(
                  l10n.schedulerSubheading,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: serene.spacing.xl),
                if (widget.initialMedicationId != null)
                  _MedicationReadOnlyChip(name: selectedMedication.name)
                else
                  SoftDropdownField<int>(
                    value: _medicationId,
                    labelText: l10n.selectMedicationLabel,
                    items: medications
                        .map(
                          (m) => DropdownMenuItem(
                            value: m.id,
                            child: Text(m.name),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (id) => setState(() => _medicationId = id),
                  ),
                SizedBox(height: serene.spacing.xl),
                DosePicker(
                  controller: _doseInput,
                  medicationForm: selectedMedication.form,
                ),
                SizedBox(height: serene.spacing.xl),
                Text(
                  l10n.recurrenceTitle,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                SizedBox(height: serene.spacing.md),
                Row(
                  children: [
                    SelectionCard(
                      title: l10n.recurrenceDaily,
                      description: l10n.recurrenceDailyDesc,
                      isSelected: true,
                      icon: Icons.calendar_today,
                      onTap: () {},
                    ),
                    SizedBox(width: serene.spacing.md),
                    SelectionCard(
                      title: l10n.recurrenceSpecificDays,
                      description: l10n.recurrenceSpecificDaysDesc,
                      isSelected: false,
                      icon: Icons.event_repeat,
                      onTap: () => context.push(
                        AppRoutes.schedulerSpecificDays,
                        extra: _medicationId,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: serene.spacing.xl),
                Container(
                  padding: EdgeInsets.all(serene.spacing.lg),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow,
                    borderRadius: serene.radius.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.frequencyModeTitle,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      SizedBox(height: serene.spacing.lg),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Row(
                          children: [
                            _modeButton(
                              l10n.frequencyModeSetTimes,
                              _isSetTimesMode,
                              () => setState(() => _isSetTimesMode = true),
                            ),
                            _modeButton(
                              l10n.frequencyModeInterval,
                              !_isSetTimesMode,
                              () => setState(() => _isSetTimesMode = false),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: serene.spacing.xl),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.doseLabel(1),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _addTime,
                            icon: const Icon(Icons.add_circle, size: 20),
                            label: Text(l10n.addTimeButton),
                            style: TextButton.styleFrom(
                              foregroundColor: theme.colorScheme.secondary,
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: serene.spacing.md),
                      for (var i = 0; i < _times.length; i++) ...[
                        ScheduleTimePickerField(
                          value: _times[i],
                          onChanged: (time) => setState(() => _times[i] = time),
                        ),
                        if (i < _times.length - 1)
                          SizedBox(height: serene.spacing.sm),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: serene.spacing.xl),
                Text(
                  l10n.durationTitle,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                SizedBox(height: serene.spacing.md),
                _durationOption(
                  title: l10n.durationContinuous,
                  description: l10n.durationContinuousDesc,
                  isSelected: _isContinuous,
                  onTap: () => setState(() => _isContinuous = true),
                ),
                SizedBox(height: serene.spacing.sm),
                _durationOption(
                  title: l10n.durationSpecificEnd,
                  description: l10n.durationSpecificEndDesc,
                  isSelected: !_isContinuous,
                  onTap: () => setState(() => _isContinuous = false),
                ),
                if (!_isContinuous) ...[
                  SizedBox(height: serene.spacing.md),
                  SoftInputField(
                    labelText: l10n.endDateLabel,
                    controller: _endDateController,
                    readOnly: true,
                    onTap: _pickEndDate,
                    suffixIcon: const Icon(Icons.calendar_month),
                  ),
                ],
                if (allProfiles.isNotEmpty) ...[
                  SizedBox(height: serene.spacing.xl),
                  Text(
                    l10n.profileSelectorHeading,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  SizedBox(height: serene.spacing.xs),
                  Text(
                    l10n.profileSelectorSubheading,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: serene.spacing.md),
                  ProfileSelectorField(
                    selectedProfileId: _selectedProfileId,
                    profiles: allProfiles,
                    onSelected: (id) => setState(() => _selectedProfileId = id),
                  ),
                ],
                SizedBox(height: serene.spacing.xl),
                NotificationTypeSelector(
                  notifyPush: _notifyPush,
                  notifyCalendar: _notifyCalendar,
                  onPushChanged: (v) => setState(() => _notifyPush = v),
                  onCalendarChanged: (v) => setState(() => _notifyCalendar = v),
                ),
                SizedBox(height: serene.spacing.xxxxl),
                GradientPrimaryButton(
                  label: l10n.confirmScheduleButton,
                  onPressed: _save,
                ),
                SizedBox(height: serene.spacing.md),
                Center(
                  child: TextButton(
                    onPressed: () => context.go(AppRoutes.medications),
                    child: Text(
                      l10n.skipForNowButton,
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text(l10n.errorUnexpected)),
      ),
    );
  }

  Widget _modeButton(String label, bool isActive, VoidCallback onTap) {
    final theme = Theme.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive
                ? theme.colorScheme.primaryContainer
                : Colors.transparent,
            borderRadius: BorderRadius.circular(100),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: theme.colorScheme.primaryContainer.withValues(
                        alpha: 0.15,
                      ),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isActive
                  ? Colors.white
                  : theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _durationOption({
    required String title,
    required String description,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final serene = theme.extension<SereneTheme>()!;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(serene.spacing.lg),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.surfaceContainerLowest
              : theme.colorScheme.surfaceContainerLow,
          borderRadius: serene.radius.lg,
          border: isSelected
              ? Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  width: 2,
                )
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    description,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  void _addTime() {
    setState(() => _times.add(const TimeOfDay(hour: 20, minute: 0)));
  }

  Future<void> _pickEndDate() async {
    final selected = await showDatePicker(
      context: context,
      firstDate: _startDate,
      lastDate: DateTime(2100),
      initialDate: _endDate ?? _startDate,
      locale: const Locale('es'),
    );
    if (selected == null) return;
    setState(() {
      _endDate = selected;
      _endDateController.text = DateFormat.yMMMd('es').format(selected);
    });
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (_medicationId == null) {
      AppNotification.showWarning(
        context,
        l10n.noMedicationsForSchedule,
      );
      return;
    }

    final dose = readScheduleDose(context, _doseInput);
    if (dose == null) return;

    await persistNewSchedule(
      ref: ref,
      context: context,
      schedule: Schedule.daily(
        id: 0,
        medicationId: _medicationId!,
        timesOfDay: _times
            .map((t) => (hour: t.hour, minute: t.minute))
            .toList(growable: false),
        startDate: DateTime(_startDate.year, _startDate.month, _startDate.day),
        endDate: _isContinuous || _endDate == null
            ? null
            : DateTime(_endDate!.year, _endDate!.month, _endDate!.day),
        notifyPush: _notifyPush,
        notifyCalendar: _notifyCalendar,
        dose: dose,
      ),
      profileId:
          _selectedProfileId ??
          ref.read(currentUserProfileProvider)?.id ??
          'default',
    );
  }
}

class _MedicationReadOnlyChip extends StatelessWidget {
  const _MedicationReadOnlyChip({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final serene = theme.extension<SereneTheme>()!;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: serene.spacing.lg,
        vertical: serene.spacing.md,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: serene.radius.md,
      ),
      child: Row(
        children: [
          Icon(
            Icons.medication,
            size: 18,
            color: theme.colorScheme.primary,
          ),
          SizedBox(width: serene.spacing.sm),
          Text(
            name,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
