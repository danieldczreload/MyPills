import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_pills/core/theme/serene_theme.dart';
import 'package:my_pills/features/medications/domain/entities/taxonomy_group.dart';
import 'package:my_pills/features/medications/domain/entities/taxonomy_type.dart';
import 'package:my_pills/features/medications/presentation/providers/taxonomy_providers.dart';
import 'package:my_pills/l10n/app_localizations.dart';

class CreateTaxonomySheet extends ConsumerStatefulWidget {
  const CreateTaxonomySheet({required this.type, super.key});

  final TaxonomyType type;

  @override
  ConsumerState<CreateTaxonomySheet> createState() =>
      _CreateTaxonomySheetState();
}

class _CreateTaxonomySheetState extends ConsumerState<CreateTaxonomySheet> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedIcon = 'heart';
  Color _selectedColor = Colors.red;

  final List<String> _icons = [
    'heart',
    'pills',
    'bandage',
    'respiratory',
    'stomach',
    'blood_pressure',
    'brain',
    'eye',
  ];

  final List<Color> _colors = [
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.blue,
    Colors.yellow,
    Colors.purple,
    Colors.teal,
  ];

  IconData _getIconData(String name) {
    switch (name) {
      case 'heart':
        return Icons.favorite;
      case 'pills':
        return Icons.medication;
      case 'bandage':
        return Icons.healing;
      case 'respiratory':
        return Icons.air;
      case 'stomach':
        return Icons.restaurant;
      case 'blood_pressure':
        return Icons.monitor_heart;
      case 'brain':
        return Icons.psychology;
      case 'eye':
        return Icons.visibility;
      default:
        return Icons.favorite;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final serene = theme.extension<SereneTheme>()!;
    final l10n = AppLocalizations.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.vertical(top: serene.radius.xl.topLeft),
          ),
          child: Column(
            children: [
              SizedBox(height: serene.spacing.md),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: serene.radius.full,
                  ),
                ),
              ),
              Expanded(
                child: Scrollbar(
                  controller: scrollController,
                  child: ListView(
                    controller: scrollController,
                    padding: EdgeInsets.only(
                      left: serene.spacing.xl,
                      right: serene.spacing.xl,
                      top: serene.spacing.lg,
                      bottom:
                          serene.spacing.xl +
                          MediaQuery.of(context).viewInsets.bottom,
                    ),
                    children: [
                      Text(
                        widget.type == TaxonomyType.category
                            ? l10n.createCategoryButton
                            : l10n.createDiseaseButton,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      SizedBox(height: serene.spacing.xl),
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: l10n.nameLabel,
                          hintText: 'e.g. Cardiovascular',
                        ),
                      ),
                      SizedBox(height: serene.spacing.lg),
                      TextField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: l10n.descriptionLabel,
                          hintText: 'e.g. Heart health management',
                        ),
                      ),
                      SizedBox(height: serene.spacing.xl),
                      Text(
                        'Select Icon',
                        style: theme.textTheme.titleSmall,
                      ),
                      SizedBox(height: serene.spacing.md),
                      SizedBox(
                        height: 50,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _icons.length,
                          separatorBuilder: (context, index) =>
                              SizedBox(width: serene.spacing.md),
                          itemBuilder: (context, index) {
                            final iconName = _icons[index];
                            final isSelected = _selectedIcon == iconName;
                            return GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedIcon = iconName),
                              child: Container(
                                width: 50,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? theme.colorScheme.primaryContainer
                                      : theme
                                            .colorScheme
                                            .surfaceContainerHighest
                                            .withValues(alpha: 0.3),
                                  shape: BoxShape.circle,
                                  border: isSelected
                                      ? Border.all(
                                          color: theme.colorScheme.primary,
                                          width: 2,
                                        )
                                      : null,
                                ),
                                child: Icon(
                                  _getIconData(iconName),
                                  color: isSelected
                                      ? theme.colorScheme.onPrimary
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(height: serene.spacing.xl),
                      Text(
                        'Select Color',
                        style: theme.textTheme.titleSmall,
                      ),
                      SizedBox(height: serene.spacing.md),
                      SizedBox(
                        height: 40,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _colors.length,
                          separatorBuilder: (context, index) =>
                              SizedBox(width: serene.spacing.md),
                          itemBuilder: (context, index) {
                            final color = _colors[index];
                            final isSelected = _selectedColor == color;
                            return GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedColor = color),
                              child: Container(
                                width: 40,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: isSelected
                                      ? Border.all(
                                          color: theme.colorScheme.onSurface,
                                          width: 2,
                                        )
                                      : null,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(height: serene.spacing.xxl),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (_nameController.text.isEmpty) return;

                            final taxonomyGroup = TaxonomyGroup(
                              id: 0, // Auto-incremented in DB
                              type: widget.type,
                              name: _nameController.text,
                              description: _descriptionController.text,
                              iconName: _selectedIcon,
                              colorValue: _selectedColor.toARGB32(),
                            );

                            await ref
                                .read(addTaxonomyGroupProvider)
                                .call(taxonomyGroup);
                            if (context.mounted) Navigator.pop(context);
                          },
                          child: Text(l10n.saveButton),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
