import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class SearchBarWidget extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final VoidCallback? onClear;
  final bool enabled;
  final Widget? prefixIcon;
  final Widget? suffixIcon;

  const SearchBarWidget({
    super.key,
    required this.controller,
    required this.hint,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.enabled = true,
    this.prefixIcon,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.inputBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        textDirection: TextDirection.rtl,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: enabled ? AppColors.onSurface : AppColors.onSurfaceVariant,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
          prefixIcon: prefixIcon ?? const Icon(
            Icons.search,
            color: AppColors.onSurfaceVariant,
            size: 20,
          ),
          suffixIcon: _buildSuffixIcon(),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onChanged: onChanged,
        onSubmitted: onSubmitted,
      ),
    );
  }

  Widget? _buildSuffixIcon() {
    if (controller.text.isNotEmpty) {
      return IconButton(
        onPressed: () {
          controller.clear();
          onClear?.call();
          onChanged?.call('');
        },
        icon: const Icon(
          Icons.clear,
          color: AppColors.onSurfaceVariant,
          size: 20,
        ),
      );
    }
    return suffixIcon;
  }
}

// Animated Search Bar that expands on focus
class AnimatedSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final VoidCallback? onClear;
  final bool enabled;
  final double collapsedWidth;
  final double expandedWidth;

  const AnimatedSearchBar({
    super.key,
    required this.controller,
    required this.hint,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.enabled = true,
    this.collapsedWidth = 48,
    this.expandedWidth = 300,
  });

  @override
  State<AnimatedSearchBar> createState() => _AnimatedSearchBarState();
}

class _AnimatedSearchBarState extends State<AnimatedSearchBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _widthAnimation;
  late FocusNode _focusNode;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _widthAnimation = Tween<double>(
      begin: widget.collapsedWidth,
      end: widget.expandedWidth,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus && !_isExpanded) {
      _expand();
    } else if (!_focusNode.hasFocus && _isExpanded && widget.controller.text.isEmpty) {
      _collapse();
    }
  }

  void _expand() {
    setState(() {
      _isExpanded = true;
    });
    _animationController.forward();
  }

  void _collapse() {
    setState(() {
      _isExpanded = false;
    });
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _widthAnimation,
      builder: (context, child) {
        return Container(
          width: _widthAnimation.value,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _isExpanded ? AppColors.primary : AppColors.inputBorder,
              width: _isExpanded ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.cardShadow.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Search Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _isExpanded ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  Icons.search,
                  color: _isExpanded ? AppColors.onPrimary : AppColors.onSurfaceVariant,
                  size: 20,
                ),
              ),
              
              // Text Field
              if (_isExpanded)
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    focusNode: _focusNode,
                    enabled: widget.enabled,
                    textDirection: TextDirection.rtl,
                    style: Theme.of(context).textTheme.bodyMedium,
                    decoration: InputDecoration(
                      hintText: widget.hint,
                      hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onChanged: widget.onChanged,
                    onSubmitted: widget.onSubmitted,
                  ),
                ),
              
              // Clear Button
              if (_isExpanded && widget.controller.text.isNotEmpty)
                IconButton(
                  onPressed: () {
                    widget.controller.clear();
                    widget.onClear?.call();
                    widget.onChanged?.call('');
                  },
                  icon: const Icon(
                    Icons.clear,
                    color: AppColors.onSurfaceVariant,
                    size: 20,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// Search Bar with Voice Input
class VoiceSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final VoidCallback? onVoiceSearch;
  final bool enabled;
  final bool isListening;

  const VoiceSearchBar({
    super.key,
    required this.controller,
    required this.hint,
    this.onChanged,
    this.onSubmitted,
    this.onVoiceSearch,
    this.enabled = true,
    this.isListening = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.inputBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        textDirection: TextDirection.rtl,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: enabled ? AppColors.onSurface : AppColors.onSurfaceVariant,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: AppColors.onSurfaceVariant,
            size: 20,
          ),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (controller.text.isNotEmpty)
                IconButton(
                  onPressed: () {
                    controller.clear();
                    onChanged?.call('');
                  },
                  icon: const Icon(
                    Icons.clear,
                    color: AppColors.onSurfaceVariant,
                    size: 20,
                  ),
                ),
              IconButton(
                onPressed: onVoiceSearch,
                icon: Icon(
                  isListening ? Icons.mic : Icons.mic_none,
                  color: isListening ? AppColors.primary : AppColors.onSurfaceVariant,
                  size: 20,
                ),
              ),
            ],
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onChanged: onChanged,
        onSubmitted: onSubmitted,
      ),
    );
  }
}

