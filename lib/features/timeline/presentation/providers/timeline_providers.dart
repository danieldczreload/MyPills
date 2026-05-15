import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_pills/app/providers.dart';
import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/features/tracker/domain/entities/dose_event.dart';

typedef TimelineRange = ({DateTime start, DateTime end});

// Family provider: TrackerScreen passes its date range as the argument.
// Avoids a mutable global provider (StateProvider removed in Riverpod 3.x).
final timelineEventsProvider = StreamProvider.autoDispose
    .family<Result<List<DoseEvent>>, TimelineRange>((ref, range) {
      final watchRange = ref.watch(watchTimelineRangeUseCaseProvider);
      return watchRange(start: range.start, end: range.end);
    });
