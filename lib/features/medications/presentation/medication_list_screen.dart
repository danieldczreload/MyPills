import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_pills/app/providers.dart';
import 'package:my_pills/app/router.dart';
import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/core/theme/serene_theme.dart';
import 'package:my_pills/core/widgets/app_notification.dart';
import 'package:my_pills/core/widgets/sanctuary_app_bar.dart';
import 'package:my_pills/core/widgets/soft_input_field.dart';
import 'package:my_pills/features/medications/domain/entities/medication.dart';
import 'package:my_pills/features/medications/presentation/providers/medications_providers.dart';
import 'package:my_pills/features/medications/presentation/widgets/medication_card.dart';
import 'package:my_pills/l10n/app_localizations.dart';

/// Main "Medicamentos" tab destination.
///
/// Shows the list of all medications with search, edit (tap card), and
/// delete (tap trash icon) capabilities.  The FAB is wired at the scaffold
/// level in `_ScaffoldWithNavBar` inside `router.dart` to keep it outside
/// the tab body — this screen therefore does not declare its own FAB.
class MedicationListScreen extends ConsumerStatefulWidget {
  const MedicationListScreen({super.key});

  @override
  ConsumerState<MedicationListScreen> createState() =>
      _MedicationListScreenState();
}

class _MedicationListScreenState extends ConsumerState<MedicationListScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
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
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Header ────────────────────────────────────────────────────────
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              serene.spacing.lg,
              120,
              serene.spacing.lg,
              serene.spacing.lg,
            ),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.navToday.toUpperCase(),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  SizedBox(height: serene.spacing.xs),
                  Text(
                    l10n.medicationsTitle,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: serene.spacing.xs),
                  Text(
                    l10n.medicationListSubtitle,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: serene.spacing.xl),
                  SoftInputField(
                    controller: _searchController,
                    labelText: '',
                    hintText: l10n.searchMedicationsPlaceholder,
                    prefixIcon: Icon(
                      Icons.search,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    onChanged: (v) => setState(() => _query = v.toLowerCase()),
                  ),
                ],
              ),
            ),
          ),

          // ── List or empty state ───────────────────────────────────────────
          medsAsync.when(
            data: (result) {
              if (result case FailureResult()) {
                return SliverFillRemaining(
                  child: Center(child: Text(l10n.errorUnexpected)),
                );
              }

              final all = result.valueOrNull!;
              final filtered = _query.isEmpty
                  ? all
                  : all
                        .where(
                          (m) =>
                              m.name.toLowerCase().contains(_query) ||
                              m.category.toLowerCase().contains(_query),
                        )
                        .toList(growable: false);

              if (all.isEmpty) {
                return SliverFillRemaining(
                  child: _EmptyState(l10n: l10n),
                );
              }

              if (filtered.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Text(
                      l10n.emptyMedications,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  serene.spacing.lg,
                  0,
                  serene.spacing.lg,
                  serene.spacing.xxxxl * 2.5 +
                      MediaQuery.paddingOf(context).bottom,
                ),
                sliver: SliverList.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) =>
                      SizedBox(height: serene.spacing.md),
                  itemBuilder: (context, index) {
                    final med = filtered[index];
                    return Dismissible(
                      key: ValueKey(med.id),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (_) => _confirmDelete(context, med),
                      background: _DeleteBackground(label: l10n.deleteButton),
                      child: MedicationCard(
                        medication: med,
                        onTap: () => context.push(
                          AppRoutes.medicationDetail,
                          extra: med,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => SliverFillRemaining(
              child: Center(child: Text(l10n.errorUnexpected)),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, Medication med) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteMedicationTitle),
        content: Text(l10n.deleteMedicationConfirmation(med.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancelButton),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: Text(l10n.deleteButton),
          ),
        ],
      ),
    );

    if (confirmed != true) return false;
    if (!mounted) return false;

    final result = await ref.read(deleteMedicationUseCaseProvider).call(med.id);
    if (!mounted) return false;

    if (result case FailureResult()) {
      AppNotification.showWithMessenger(
        messenger,
        context: context,
        message: l10n.errorUnexpected,
        tone: AppNotificationTone.error,
      );
      return false;
    }

    AppNotification.showWithMessenger(
      messenger,
      context: context,
      message: l10n.medicationDeletedMessage,
      tone: AppNotificationTone.success,
    );
    return true;
  }
}

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final serene = theme.extension<SereneTheme>()!;

    return Container(
      alignment: Alignment.centerRight,
      padding: EdgeInsets.symmetric(horizontal: serene.spacing.xl),
      decoration: BoxDecoration(
        color: theme.colorScheme.error,
        borderRadius: serene.radius.lg,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.delete_rounded, color: Colors.white, size: 26),
          SizedBox(height: serene.spacing.xs),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final serene = theme.extension<SereneTheme>()!;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(serene.spacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.15,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.medication_outlined,
                size: 40,
                color: theme.colorScheme.primary,
              ),
            ),
            SizedBox(height: serene.spacing.xl),
            Text(
              l10n.medicationsTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            SizedBox(height: serene.spacing.sm),
            Text(
              l10n.emptyMedications,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
