import 'package:flutter/material.dart';

/// Interrupteur Actif / Inactif : piste ovale verte (actif) ou rouge (inactif), curseur blanc.
/// Utilisé pour catégories et produits dans l'espace admin.
class ActiveToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const ActiveToggle({
    super.key,
    required this.value,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const width = 48.0;
    const height = 28.0;
    const thumbRadius = 11.0;
    const activeColor = Color(0xFF4CBB5E);
    const inactiveColor = Color(0xFFE57373);

    return GestureDetector(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: value ? activeColor : inactiveColor,
          borderRadius: BorderRadius.circular(height / 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Align(
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: thumbRadius * 2,
            height: thumbRadius * 2,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
