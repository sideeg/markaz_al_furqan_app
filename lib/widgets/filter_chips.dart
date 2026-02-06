import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class FilterOption {
  final String value;
  final String label;
  final IconData? icon;

  const FilterOption(this.value, this.label, [this.icon]);
}

class FilterChips extends StatelessWidget {
  final String selectedFilter;
  final Function(String) onFilterChanged;
  final List<FilterOption> filters;
  final bool scrollable;
  final EdgeInsetsGeometry? padding;

  const FilterChips({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.filters,
    this.scrollable = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    Widget chipList = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: filters.map((filter) => _buildFilterChip(context, filter)).toList(),
    );

    if (scrollable) {
      chipList = SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: filters.map((filter) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _buildFilterChip(context, filter),
          )).toList(),
        ),
      );
    } else if (padding != null) {
      chipList = Padding(
        padding: padding!,
        child: chipList,
      );
    }

    return chipList;
  }

  Widget _buildFilterChip(BuildContext context, FilterOption filter) {
    final isSelected = selectedFilter == filter.value;
    
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (filter.icon != null) ...[
            Icon(
              filter.icon,
              size: 16,
              color: isSelected ? AppColors.onPrimary : AppColors.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            filter.label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: isSelected ? AppColors.onPrimary : AppColors.onSurface,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          onFilterChanged(filter.value);
        }
      },
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.primary,
      checkmarkColor: AppColors.onPrimary,
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.inputBorder,
        width: 1,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

// Animated Filter Chips with smooth transitions
class AnimatedFilterChips extends StatefulWidget {
  final String selectedFilter;
  final Function(String) onFilterChanged;
  final List<FilterOption> filters;
  final Duration animationDuration;

  const AnimatedFilterChips({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.filters,
    this.animationDuration = const Duration(milliseconds: 300),
  });

  @override
  State<AnimatedFilterChips> createState() => _AnimatedFilterChipsState();
}

class _AnimatedFilterChipsState extends State<AnimatedFilterChips>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _scaleAnimations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.filters.length,
      (index) => AnimationController(
        duration: widget.animationDuration,
        vsync: this,
      ),
    );
    _scaleAnimations = _controllers.map((controller) {
      return Tween<double>(begin: 1.0, end: 1.1).animate(
        CurvedAnimation(parent: controller, curve: Curves.elasticOut),
      );
    }).toList();
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _animateSelection(int index) {
    _controllers[index].forward().then((_) {
      _controllers[index].reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: widget.filters.asMap().entries.map((entry) {
          final index = entry.key;
          final filter = entry.value;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: AnimatedBuilder(
              animation: _scaleAnimations[index],
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimations[index].value,
                  child: _buildFilterChip(context, filter, index),
                );
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, FilterOption filter, int index) {
    final isSelected = widget.selectedFilter == filter.value;
    
    return AnimatedContainer(
      duration: widget.animationDuration,
      curve: Curves.easeInOut,
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (filter.icon != null) ...[
              Icon(
                filter.icon,
                size: 16,
                color: isSelected ? AppColors.onPrimary : AppColors.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              filter.label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: isSelected ? AppColors.onPrimary : AppColors.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            _animateSelection(index);
            widget.onFilterChanged(filter.value);
          }
        },
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primary,
        checkmarkColor: AppColors.onPrimary,
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.inputBorder,
          width: 1,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

// Multi-Select Filter Chips
class MultiSelectFilterChips extends StatelessWidget {
  final List<String> selectedFilters;
  final Function(List<String>) onFiltersChanged;
  final List<FilterOption> filters;
  final int? maxSelections;

  const MultiSelectFilterChips({
    super.key,
    required this.selectedFilters,
    required this.onFiltersChanged,
    required this.filters,
    this.maxSelections,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: filters.map((filter) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _buildFilterChip(context, filter),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, FilterOption filter) {
    final isSelected = selectedFilters.contains(filter.value);
    
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (filter.icon != null) ...[
            Icon(
              filter.icon,
              size: 16,
              color: isSelected ? AppColors.onPrimary : AppColors.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            filter.label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: isSelected ? AppColors.onPrimary : AppColors.onSurface,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        List<String> newFilters = List.from(selectedFilters);
        
        if (selected) {
          if (maxSelections == null || newFilters.length < maxSelections!) {
            newFilters.add(filter.value);
          }
        } else {
          newFilters.remove(filter.value);
        }
        
        onFiltersChanged(newFilters);
      },
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.primary,
      checkmarkColor: AppColors.onPrimary,
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.inputBorder,
        width: 1,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

// Filter Chips with Counter
class CounterFilterChips extends StatelessWidget {
  final String selectedFilter;
  final Function(String) onFilterChanged;
  final Map<String, int> filterCounts;
  final List<FilterOption> filters;

  const CounterFilterChips({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.filterCounts,
    required this.filters,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: filters.map((filter) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _buildFilterChip(context, filter),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, FilterOption filter) {
    final isSelected = selectedFilter == filter.value;
    final count = filterCounts[filter.value] ?? 0;
    
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (filter.icon != null) ...[
            Icon(
              filter.icon,
              size: 16,
              color: isSelected ? AppColors.onPrimary : AppColors.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            filter.label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: isSelected ? AppColors.onPrimary : AppColors.onSurface,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
          if (count > 0) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected 
                    ? AppColors.onPrimary.withOpacity(0.2)
                    : AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isSelected ? AppColors.onPrimary : AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          onFilterChanged(filter.value);
        }
      },
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.primary,
      checkmarkColor: AppColors.onPrimary,
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.inputBorder,
        width: 1,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

