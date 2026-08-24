import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_spacing.dart';

class ExpressiveChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final String? fontFamily;

  const ExpressiveChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.fontFamily,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // "Material Expressive": rounded when selected, square when unselected
    final borderRadius = isSelected
        ? BorderRadius.circular(100.0) // Full pill shape
        : BorderRadius.circular(AppSpacing.radiusSm); // Sharper rounded corners

    final baseStyle = TextStyle(
      color: isSelected
          ? colorScheme.onPrimaryContainer
          : colorScheme.onSurfaceVariant,
      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
    );
    
    TextStyle finalStyle = baseStyle;
    if (fontFamily != null) {
      try {
        finalStyle = GoogleFonts.getFont(fontFamily!, textStyle: baseStyle);
      } catch (_) {
        finalStyle = baseStyle.copyWith(fontFamily: fontFamily);
      }
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      margin: const EdgeInsets.only(right: AppSpacing.sm),
      child: Material(
        color: isSelected
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerHighest,
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Text(
              label,
              style: finalStyle,
            ),
          ),
        ),
      ),
    );
  }
}
