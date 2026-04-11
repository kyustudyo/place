import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/furniture.dart';
import '../models/app_theme.dart';
import '../providers/placement_provider.dart';
import '../providers/theme_provider.dart';

class FurniturePanel extends ConsumerWidget {
  const FurniturePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(placementProvider);
    final theme = ref.watch(currentThemeProvider);
    final furniture = state.furniture;

    if (furniture.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.panelBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: theme.accentSecondary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '가구 목록',
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                  ),
                ),
                const Spacer(),
                Text(
                  '${state.placedCount}/${furniture.length}',
                  style: TextStyle(
                    color: theme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              itemCount: furniture.length,
              itemBuilder: (context, index) {
                final item = furniture[index];
                return _FurnitureCard(
                  item: item,
                  theme: theme,
                  isSelected: state.selectedId == item.id,
                  onTap: () {
                    ref
                        .read(placementProvider.notifier)
                        .selectFurniture(item.id);
                  },
                  onPlace: () {
                    if (!item.isPlaced) {
                      ref
                          .read(placementProvider.notifier)
                          .placeFurniture(item.id, 1.0, 1.0);
                    }
                  },
                  onRotate: () {
                    ref
                        .read(placementProvider.notifier)
                        .rotateFurniture(item.id);
                  },
                  onRemove: () {
                    ref
                        .read(placementProvider.notifier)
                        .unplaceFurniture(item.id);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FurnitureCard extends StatelessWidget {
  final Furniture item;
  final AppTheme theme;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onPlace;
  final VoidCallback onRotate;
  final VoidCallback onRemove;

  const _FurnitureCard({
    required this.item,
    required this.theme,
    required this.isSelected,
    required this.onTap,
    required this.onPlace,
    required this.onRotate,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? item.color.withValues(alpha: 0.15)
              : theme.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? item.color.withValues(alpha: 0.5)
                : item.hasCollision
                    ? Colors.red.withValues(alpha: 0.5)
                    : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: item.color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      color: theme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.size.x}\u00d7${item.size.z}\u00d7${item.size.y}m',
                    style: TextStyle(
                      color: theme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (item.hasCollision)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(
                  Icons.warning_rounded,
                  color: Colors.red.shade400,
                  size: 18,
                ),
              ),
            if (item.isPlaced) ...[
              _IconBtn(
                icon: Icons.rotate_right,
                onTap: onRotate,
                color: theme.textSecondary,
              ),
              const SizedBox(width: 4),
              _IconBtn(
                icon: Icons.close,
                onTap: onRemove,
                color: Colors.red.shade400,
              ),
            ] else
              _IconBtn(
                icon: Icons.add,
                onTap: onPlace,
                color: theme.accentSecondary,
              ),
          ],
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _IconBtn({
    required this.icon,
    required this.onTap,
    this.color = Colors.white54,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}
