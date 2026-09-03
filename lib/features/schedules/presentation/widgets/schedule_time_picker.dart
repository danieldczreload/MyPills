import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:my_pills/core/theme/serene_theme.dart';
import 'package:my_pills/core/widgets/gradient_primary_button.dart';
import 'package:my_pills/l10n/app_localizations.dart';

/// Inline dose-time field with working steppers and a wheel bottom sheet.
///
/// Replaces Material's circular `showTimePicker` dial. See DESIGN.md §6
/// "Time picker — Dose time".
class ScheduleTimePickerField extends StatelessWidget {
  const ScheduleTimePickerField({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final TimeOfDay value;
  final ValueChanged<TimeOfDay> onChanged;

  static const hourUpKey = ValueKey<String>('scheduleTimePicker.hourUp');
  static const hourDownKey = ValueKey<String>('scheduleTimePicker.hourDown');
  static const hourValueKey = ValueKey<String>('scheduleTimePicker.hourValue');
  static const minuteUpKey = ValueKey<String>('scheduleTimePicker.minuteUp');
  static const minuteDownKey = ValueKey<String>(
    'scheduleTimePicker.minuteDown',
  );
  static const minuteValueKey = ValueKey<String>(
    'scheduleTimePicker.minuteValue',
  );
  static const periodAmKey = ValueKey<String>('scheduleTimePicker.periodAm');
  static const periodPmKey = ValueKey<String>('scheduleTimePicker.periodPm');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final serene = theme.extension<SereneTheme>()!;
    final l10n = AppLocalizations.of(context);
    final use24h = MediaQuery.alwaysUse24HourFormatOf(context);
    final hourLabel = formatHour(value, use24Hour: use24h);
    final minuteLabel = value.minute.toString().padLeft(2, '0');
    final isAm = value.period == DayPeriod.am;

    return Container(
      padding: EdgeInsets.all(serene.spacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: serene.radius.lg,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _TimeStepper(
            upKey: hourUpKey,
            downKey: hourDownKey,
            valueKey: hourValueKey,
            label: hourLabel,
            semanticsLabel: l10n.timePickerHour,
            onStep: (delta) =>
                onChanged(stepHour(value, delta, use24Hour: use24h)),
            onValueTap: () => _openWheelSheet(context, use24Hour: use24h),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: serene.spacing.sm),
            child: Text(
              ':',
              style: theme.textTheme.displaySmall?.copyWith(
                color: theme.colorScheme.outlineVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _TimeStepper(
            upKey: minuteUpKey,
            downKey: minuteDownKey,
            valueKey: minuteValueKey,
            label: minuteLabel,
            semanticsLabel: l10n.timePickerMinute,
            onStep: (delta) => onChanged(stepMinute(value, delta)),
            onValueTap: () => _openWheelSheet(context, use24Hour: use24h),
          ),
          if (!use24h) ...[
            SizedBox(width: serene.spacing.lg),
            Column(
              children: [
                _PeriodButton(
                  key: periodAmKey,
                  label: l10n.timePickerPeriodAm,
                  isActive: isAm,
                  onTap: () => onChanged(withPeriod(value, DayPeriod.am)),
                ),
                SizedBox(height: serene.spacing.sm),
                _PeriodButton(
                  key: periodPmKey,
                  label: l10n.timePickerPeriodPm,
                  isActive: !isAm,
                  onTap: () => onChanged(withPeriod(value, DayPeriod.pm)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openWheelSheet(
    BuildContext context, {
    required bool use24Hour,
  }) async {
    final selected = await showModalBottomSheet<TimeOfDay>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      showDragHandle: false,
      sheetAnimationStyle: const AnimationStyle(
        duration: Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
        reverseDuration: Duration(milliseconds: 500),
        reverseCurve: Curves.easeInCubic,
      ),
      builder: (ctx) => _TimeWheelSheet(
        initial: value,
        use24Hour: use24Hour,
      ),
    );
    if (selected != null) onChanged(selected);
  }
}

/// Wheel / stepper index for the hour column (0–23 or 0–11).
@visibleForTesting
int displayHourIndex(TimeOfDay time, {required bool use24Hour}) {
  if (use24Hour) return time.hour;
  final hop = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
  return hop - 1;
}

/// Rebuilds [TimeOfDay] from the same index space as [displayHourIndex].
@visibleForTesting
TimeOfDay timeFromDisplayHour({
  required int hourIndex,
  required int minute,
  required bool use24Hour,
  required bool isPm,
}) {
  if (use24Hour) {
    return TimeOfDay(hour: hourIndex, minute: minute);
  }
  final displayHour = hourIndex + 1;
  final hour24 = displayHour == 12
      ? (isPm ? 12 : 0)
      : (isPm ? displayHour + 12 : displayHour);
  return TimeOfDay(hour: hour24, minute: minute);
}

@visibleForTesting
String formatHour(TimeOfDay time, {required bool use24Hour}) {
  final value = use24Hour ? time.hour : time.hourOfPeriod;
  return value.toString().padLeft(2, '0');
}

@visibleForTesting
TimeOfDay stepHour(
  TimeOfDay time,
  int delta, {
  required bool use24Hour,
}) {
  if (use24Hour) {
    final hour = (time.hour + delta) % 24;
    return time.replacing(hour: hour < 0 ? hour + 24 : hour);
  }
  var index = (displayHourIndex(time, use24Hour: false) + delta) % 12;
  if (index < 0) index += 12;
  return timeFromDisplayHour(
    hourIndex: index,
    minute: time.minute,
    use24Hour: false,
    isPm: time.period == DayPeriod.pm,
  );
}

@visibleForTesting
TimeOfDay stepMinute(TimeOfDay time, int delta) {
  final minute = (time.minute + delta) % 60;
  return time.replacing(minute: minute < 0 ? minute + 60 : minute);
}

@visibleForTesting
TimeOfDay withPeriod(TimeOfDay time, DayPeriod period) {
  if (time.period == period) return time;
  if (period == DayPeriod.pm) {
    return time.replacing(hour: time.hour + 12);
  }
  return time.replacing(hour: time.hour - 12);
}

class _TimeStepper extends StatelessWidget {
  const _TimeStepper({
    required this.upKey,
    required this.downKey,
    required this.valueKey,
    required this.label,
    required this.semanticsLabel,
    required this.onStep,
    required this.onValueTap,
  });

  final Key upKey;
  final Key downKey;
  final Key valueKey;
  final String label;
  final String semanticsLabel;
  final ValueChanged<int> onStep;
  final VoidCallback onValueTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final serene = theme.extension<SereneTheme>()!;

    return Semantics(
      label: semanticsLabel,
      value: label,
      child: Column(
        children: [
          IconButton(
            key: upKey,
            onPressed: () => onStep(1),
            tooltip: semanticsLabel,
            style: IconButton.styleFrom(
              minimumSize: const Size(48, 48),
              tapTargetSize: MaterialTapTargetSize.padded,
              padding: EdgeInsets.zero,
            ),
            icon: Icon(
              Icons.expand_less,
              color: theme.colorScheme.outlineVariant,
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              key: valueKey,
              onTap: onValueTap,
              borderRadius: serene.radius.sm,
              child: Ink(
                padding: EdgeInsets.symmetric(
                  horizontal: serene.spacing.lg,
                  vertical: serene.spacing.sm,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.05),
                  borderRadius: serene.radius.sm,
                ),
                child: Text(
                  label,
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            key: downKey,
            onPressed: () => onStep(-1),
            tooltip: semanticsLabel,
            style: IconButton.styleFrom(
              minimumSize: const Size(48, 48),
              tapTargetSize: MaterialTapTargetSize.padded,
              padding: EdgeInsets.zero,
            ),
            icon: Icon(
              Icons.expand_more,
              color: theme.colorScheme.outlineVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodButton extends StatelessWidget {
  const _PeriodButton({
    required this.label,
    required this.isActive,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final serene = theme.extension<SereneTheme>()!;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: serene.radius.full,
        child: Ink(
          decoration: BoxDecoration(
            color: isActive
                ? theme.colorScheme.primary
                : theme.colorScheme.surface,
            borderRadius: serene.radius.full,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: serene.spacing.lg),
              child: Center(
                child: Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: isActive
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TimeWheelSheet extends StatefulWidget {
  const _TimeWheelSheet({
    required this.initial,
    required this.use24Hour,
  });

  final TimeOfDay initial;
  final bool use24Hour;

  @override
  State<_TimeWheelSheet> createState() => _TimeWheelSheetState();
}

class _TimeWheelSheetState extends State<_TimeWheelSheet> {
  static const _itemExtent = 40.0;

  late final FixedExtentScrollController _hourController;
  late final FixedExtentScrollController _minuteController;
  late int _hourIndex;
  late int _minuteIndex;
  late bool _isPm;

  @override
  void initState() {
    super.initState();
    _minuteIndex = widget.initial.minute;
    _isPm = widget.initial.period == DayPeriod.pm;
    _hourIndex = displayHourIndex(
      widget.initial,
      use24Hour: widget.use24Hour,
    );
    _hourController = FixedExtentScrollController(initialItem: _hourIndex);
    _minuteController = FixedExtentScrollController(initialItem: _minuteIndex);
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  TimeOfDay _compose() {
    return timeFromDisplayHour(
      hourIndex: _hourIndex,
      minute: _minuteIndex,
      use24Hour: widget.use24Hour,
      isPm: _isPm,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final serene = theme.extension<SereneTheme>()!;
    final l10n = AppLocalizations.of(context);
    final hourCount = widget.use24Hour ? 24 : 12;

    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: serene.radius.lgRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: serene.glassBlur,
          sigmaY: serene.glassBlur,
        ),
        child: ColoredBox(
          color: theme.colorScheme.surfaceContainerLowest.withValues(
            alpha: serene.glassOpacity,
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              serene.spacing.lg,
              serene.spacing.md,
              serene.spacing.lg,
              serene.spacing.lg + MediaQuery.paddingOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.5,
                      ),
                      borderRadius: serene.radius.sm,
                    ),
                  ),
                ),
                SizedBox(height: serene.spacing.lg),
                Text(
                  l10n.timePickerSheetTitle,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                SizedBox(height: serene.spacing.lg),
                SizedBox(
                  height: 180,
                  child: Row(
                    children: [
                      Expanded(
                        child: Semantics(
                          label: l10n.timePickerHour,
                          child: CupertinoPicker(
                            scrollController: _hourController,
                            itemExtent: _itemExtent,
                            magnification: 1.1,
                            useMagnifier: true,
                            diameterRatio: 1.2,
                            onSelectedItemChanged: (i) =>
                                setState(() => _hourIndex = i),
                            children: [
                              for (var i = 0; i < hourCount; i++)
                                Center(
                                  child: Text(
                                    (widget.use24Hour ? i : i + 1)
                                        .toString()
                                        .padLeft(2, '0'),
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      color: theme.colorScheme.onSurface,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      Text(
                        ':',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                      Expanded(
                        child: Semantics(
                          label: l10n.timePickerMinute,
                          child: CupertinoPicker(
                            scrollController: _minuteController,
                            itemExtent: _itemExtent,
                            magnification: 1.1,
                            useMagnifier: true,
                            diameterRatio: 1.2,
                            onSelectedItemChanged: (i) =>
                                setState(() => _minuteIndex = i),
                            children: [
                              for (var i = 0; i < 60; i++)
                                Center(
                                  child: Text(
                                    i.toString().padLeft(2, '0'),
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      color: theme.colorScheme.onSurface,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      if (!widget.use24Hour) ...[
                        SizedBox(width: serene.spacing.md),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _PeriodButton(
                              label: l10n.timePickerPeriodAm,
                              isActive: !_isPm,
                              onTap: () => setState(() => _isPm = false),
                            ),
                            SizedBox(height: serene.spacing.sm),
                            _PeriodButton(
                              label: l10n.timePickerPeriodPm,
                              isActive: _isPm,
                              onTap: () => setState(() => _isPm = true),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: serene.spacing.xl),
                GradientPrimaryButton(
                  label: l10n.timePickerConfirm,
                  onPressed: () => Navigator.of(context).pop(_compose()),
                ),
                SizedBox(height: serene.spacing.sm),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    l10n.timePickerCancel,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
