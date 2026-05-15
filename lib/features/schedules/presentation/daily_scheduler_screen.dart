import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:my_pills/app/providers.dart';
import 'package:my_pills/app/router.dart';
import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/core/theme/serene_theme.dart';
import 'package:my_pills/core/widgets/gradient_primary_button.dart';
import 'package:my_pills/core/widgets/sanctuary_app_bar.dart';
import 'package:my_pills/core/widgets/selection_card.dart';
import 'package:my_pills/core/widgets/soft_dropdown_field.dart';
import 'package:my_pills/core/widgets/soft_input_field.dart';
import 'package:my_pills/features/medications/domain/entities/medication.dart';
import 'package:my_pills/features/medications/presentation/providers/medications_providers.dart';
import 'package:my_pills/features/schedules/domain/entities/schedule.dart';
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
  bool _isContinuous = true;
  bool _isSetTimesMode = true;

  late final TextEditingController _startDateController;
  late final TextEditingController _endDateController;

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final serene = theme.extension<SereneTheme>()!;
    final medsAsync = ref.watch(medicationsStreamProvider);

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
                      for (var i = 0; i < _times.length; i++)
                        _timePickerCard(i),
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
                SizedBox(height: serene.spacing.xxxxl),
                GradientPrimaryButton(
                  label: l10n.confirmScheduleButton,
                  onPressed: () => _save(medications),
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

  Widget _timePickerCard(int index) {
    final theme = Theme.of(context);
    final serene = theme.extension<SereneTheme>()!;
    final time = _times[index];
    final isAM = time.period == DayPeriod.am;

    return Container(
      padding: EdgeInsets.all(serene.spacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: serene.radius.lg,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _timePart(
            time.hourOfPeriod.toString().padLeft(2, '0'),
            () => _pickTime(index),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              ':',
              style: theme.textTheme.displaySmall?.copyWith(
                color: theme.colorScheme.outlineVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _timePart(
            time.minute.toString().padLeft(2, '0'),
            () => _pickTime(index),
          ),
          SizedBox(width: serene.spacing.lg),
          Column(
            children: [
              _periodButton('AM', isAM, () => _togglePeriod(index, true)),
              const SizedBox(height: 8),
              _periodButton('PM', !isAM, () => _togglePeriod(index, false)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _timePart(String value, VoidCallback onTap) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(Icons.expand_less, color: theme.colorScheme.outlineVariant),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value,
              style: theme.textTheme.displaySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Icon(Icons.expand_more, color: theme.colorScheme.outlineVariant),
        ],
      ),
    );
  }

  Widget _periodButton(String label, bool isActive, VoidCallback onTap) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? theme.colorScheme.primary
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : theme.colorScheme.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.bold,
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

  void _togglePeriod(int index, bool isAM) {
    final time = _times[index];
    if (time.period == DayPeriod.am && !isAM) {
      setState(() => _times[index] = time.replacing(hour: time.hour + 12));
    } else if (time.period == DayPeriod.pm && isAM) {
      setState(() => _times[index] = time.replacing(hour: time.hour - 12));
    }
  }

  Future<void> _pickTime(int index) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _times[index],
    );
    if (selected == null) return;
    setState(() => _times[index] = selected);
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

  Future<void> _save(List<Medication> medications) async {
    final l10n = AppLocalizations.of(context);
    if (_medicationId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.noMedicationsForSchedule)));
      return;
    }

    final schedule = Schedule.daily(
      id: 0,
      medicationId: _medicationId!,
      timesOfDay: _times
          .map((t) => (hour: t.hour, minute: t.minute))
          .toList(growable: false),
      startDate: DateTime(_startDate.year, _startDate.month, _startDate.day),
      endDate: _isContinuous || _endDate == null
          ? null
          : DateTime(_endDate!.year, _endDate!.month, _endDate!.day),
    );

    final result = await ref.read(createScheduleUseCaseProvider).call(schedule);
    if (!mounted) return;
    if (result case FailureResult()) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.errorUnexpected)));
      return;
    }
    context.go(AppRoutes.today);
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
