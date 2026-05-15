import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:my_pills/core/db/app_database.dart';
import 'package:my_pills/features/schedules/domain/entities/schedule.dart';

const _dailyRuleType = 'daily';
const _dailyIntervalRuleType = 'daily_interval';
const _specificDaysRuleType = 'specific_days';

Schedule toScheduleEntity(SchedulesTableData row) {
  final map = jsonDecode(row.ruleJson) as Map<String, dynamic>;

  switch (row.ruleType) {
    case _dailyRuleType:
      return Schedule.daily(
        id: row.id,
        medicationId: row.medicationId,
        timesOfDay: _timesFromJson(map['timesOfDay'] as List<dynamic>),
        startDate: row.startDateUtc.toLocal(),
        endDate: row.endDateUtc?.toLocal(),
      );
    case _dailyIntervalRuleType:
      final endAtRaw = map['endAt'];
      return Schedule.dailyInterval(
        id: row.id,
        medicationId: row.medicationId,
        everyHours: map['everyHours'] as int,
        startAt: _timeFromJson(map['startAt'] as Map<String, dynamic>),
        startDate: row.startDateUtc.toLocal(),
        endAt: endAtRaw is Map<String, dynamic>
            ? _timeFromJson(endAtRaw)
            : null,
        endDate: row.endDateUtc?.toLocal(),
      );
    case _specificDaysRuleType:
      return Schedule.specificDays(
        id: row.id,
        medicationId: row.medicationId,
        daysOfWeek: (map['daysOfWeek'] as List<dynamic>).cast<int>(),
        timesOfDay: _timesFromJson(map['timesOfDay'] as List<dynamic>),
        startDate: row.startDateUtc.toLocal(),
        endDate: row.endDateUtc?.toLocal(),
      );
    default:
      throw FormatException('Unknown schedule rule type: ${row.ruleType}');
  }
}

SchedulesTableCompanion toScheduleInsertCompanion(Schedule schedule) {
  return SchedulesTableCompanion.insert(
    medicationId: schedule.medicationId,
    ruleType: _ruleTypeOf(schedule),
    ruleJson: jsonEncode(_ruleJsonOf(schedule)),
    startDateUtc: schedule.startDate.toUtc(),
    endDateUtc: Value(schedule.endDate?.toUtc()),
  );
}

String _ruleTypeOf(Schedule schedule) {
  return switch (schedule) {
    DailySchedule() => _dailyRuleType,
    DailyIntervalSchedule() => _dailyIntervalRuleType,
    SpecificDaysSchedule() => _specificDaysRuleType,
  };
}

Map<String, dynamic> _ruleJsonOf(Schedule schedule) {
  return switch (schedule) {
    DailySchedule(:final timesOfDay) => {
      'timesOfDay': timesOfDay.map(_timeToJson).toList(growable: false),
    },
    DailyIntervalSchedule(:final everyHours, :final startAt, :final endAt) => {
      'everyHours': everyHours,
      'startAt': _timeToJson(startAt),
      'endAt': endAt == null ? null : _timeToJson(endAt),
    },
    SpecificDaysSchedule(:final daysOfWeek, :final timesOfDay) => {
      'daysOfWeek': daysOfWeek,
      'timesOfDay': timesOfDay.map(_timeToJson).toList(growable: false),
    },
  };
}

List<TimeOfDayValue> _timesFromJson(List<dynamic> values) {
  return values
      .cast<Map<String, dynamic>>()
      .map(_timeFromJson)
      .toList(growable: false);
}

Map<String, int> _timeToJson(TimeOfDayValue t) => {
  'hour': t.hour,
  'minute': t.minute,
};

TimeOfDayValue _timeFromJson(Map<String, dynamic> map) => (
  hour: map['hour'] as int,
  minute: map['minute'] as int,
);
