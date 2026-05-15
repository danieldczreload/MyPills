import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_pills/core/theme/serene_theme.dart';
import 'package:my_pills/core/widgets/sanctuary_app_bar.dart';
import 'package:my_pills/core/widgets/soft_input_field.dart';
import 'package:my_pills/features/medications/domain/entities/medication.dart';
import 'package:my_pills/features/medications/domain/entities/taxonomy_group.dart';
import 'package:my_pills/features/medications/domain/entities/taxonomy_type.dart';
import 'package:my_pills/features/medications/presentation/providers/medications_providers.dart';
import 'package:my_pills/features/medications/presentation/providers/taxonomy_providers.dart';
import 'package:my_pills/features/medications/presentation/widgets/category_card.dart';
import 'package:my_pills/features/medications/presentation/widgets/create_category_button.dart';
import 'package:my_pills/features/medications/presentation/widgets/health_icon_helper.dart';
import 'package:my_pills/features/medications/presentation/widgets/taxonomy_header.dart';
import 'package:my_pills/features/medications/presentation/widgets/taxonomy_segmented_control.dart';
import 'package:my_pills/l10n/app_localizations.dart';

class TaxonomyScreen extends ConsumerStatefulWidget {
  const TaxonomyScreen({super.key});

  @override
  ConsumerState<TaxonomyScreen> createState() => _TaxonomyScreenState();
}

class _TaxonomyScreenState extends ConsumerState<TaxonomyScreen> {
  int _selectedSegment = 0;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showGroupDetail(
    BuildContext context,
    TaxonomyGroup group,
    TaxonomyType type,
  ) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useRootNavigator: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _GroupDetailSheet(group: group, type: type),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final serene = theme.extension<SereneTheme>()!;

    final currentType = _selectedSegment == 0
        ? TaxonomyType.category
        : TaxonomyType.disease;
    final taxonomyAsync = ref.watch(taxonomyGroupsByTypeProvider(currentType));

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const SanctuaryAppBar(),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                serene.spacing.lg,
                120, // Space for app bar
                serene.spacing.lg,
                serene.spacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const TaxonomyHeader(),
                  SizedBox(height: serene.spacing.xl),
                  TaxonomySegmentedControl(
                    selectedIndex: _selectedSegment,
                    onChanged: (index) =>
                        setState(() => _selectedSegment = index),
                  ),
                  SizedBox(height: serene.spacing.lg),
                  SoftInputField(
                    controller: _searchController,
                    labelText: '',
                    hintText: l10n.searchGroupsPlaceholder,
                    prefixIcon: Icon(
                      Icons.search,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: serene.spacing.xl),
                ],
              ),
            ),
          ),
          taxonomyAsync.when(
            data: (groups) => SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: serene.spacing.lg),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index < groups.length) {
                      final group = groups[index];
                      return Padding(
                        padding: EdgeInsets.only(bottom: serene.spacing.lg),
                        child: _CategoryCardWithCount(
                          group: group,
                          onTap: () =>
                              _showGroupDetail(context, group, currentType),
                        ),
                      );
                    }
                    if (index == groups.length) {
                      return Padding(
                        padding: EdgeInsets.only(
                          top: serene.spacing.md,
                          bottom:
                              serene.spacing.xxxxl +
                              MediaQuery.paddingOf(context).bottom,
                        ),
                        child: CreateCategoryButton(type: currentType),
                      );
                    }
                    return null;
                  },
                  childCount: groups.length + 1,
                ),
              ),
            ),
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, stack) => SliverFillRemaining(
              child: Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }
}

// Widget that connects a TaxonomyGroup to medication count from the stream.
class _CategoryCardWithCount extends ConsumerWidget {
  const _CategoryCardWithCount({required this.group, required this.onTap});

  final TaxonomyGroup group;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medsAsync = ref.watch(medicationsStreamProvider);
    final count = medsAsync.maybeWhen(
      data: (result) =>
          result.valueOrNull?.where((m) => m.category == group.name).length ??
          0,
      orElse: () => 0,
    );

    return CategoryCard(
      title: group.name,
      description: group.description,
      icon: HealthIconHelper.getIconData(group.iconName),
      color: Color(group.colorValue),
      itemCount: count,
      onTap: onTap,
    );
  }
}

// Bottom sheet with group detail and options.
class _GroupDetailSheet extends ConsumerWidget {
  const _GroupDetailSheet({required this.group, required this.type});

  final TaxonomyGroup group;
  final TaxonomyType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final serene = theme.extension<SereneTheme>()!;
    final color = Color(group.colorValue);

    final medsAsync = ref.watch(medicationsStreamProvider);
    final meds = medsAsync.maybeWhen<List<Medication>>(
      data: (result) =>
          result.valueOrNull?.where((m) => m.category == group.name).toList() ??
          [],
      orElse: () => [],
    );

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        serene.spacing.lg,
        serene.spacing.lg,
        serene.spacing.lg,
        serene.spacing.lg + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
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
          // Header
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: serene.radius.md,
                ),
                child: Icon(
                  HealthIconHelper.getIconData(group.iconName),
                  color: color,
                  size: 26,
                ),
              ),
              SizedBox(width: serene.spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (group.description.isNotEmpty)
                      Text(
                        group.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: serene.spacing.xl),
          // Medications in this category
          Text(
            '${meds.length} medicamento${meds.length != 1 ? 's' : ''}',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (meds.isNotEmpty) ...[
            SizedBox(height: serene.spacing.md),
            ...meds.map(
              (m) => Padding(
                padding: EdgeInsets.only(bottom: serene.spacing.sm),
                child: Container(
                  padding: EdgeInsets.all(serene.spacing.md),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow,
                    borderRadius: serene.radius.md,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.medication_outlined,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      SizedBox(width: serene.spacing.sm),
                      Text(
                        m.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          SizedBox(height: serene.spacing.xl),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancelButton),
            ),
          ),
        ],
      ),
    );
  }
}
