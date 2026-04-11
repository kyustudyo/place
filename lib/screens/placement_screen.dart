import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_theme.dart';
import '../providers/placement_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/isometric_room.dart';
import '../widgets/furniture_panel.dart';

class PlacementScreen extends ConsumerStatefulWidget {
  const PlacementScreen({super.key});

  @override
  ConsumerState<PlacementScreen> createState() => _PlacementScreenState();
}

class _PlacementScreenState extends ConsumerState<PlacementScreen> {
  final _jsonController = TextEditingController();

  @override
  void dispose() {
    _jsonController.dispose();
    super.dispose();
  }

  Future<void> _pasteJson() async {
    final theme = ref.read(currentThemeProvider);
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      _jsonController.text = data.text!;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.headerBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'JSON 붙여넣기',
          style: TextStyle(color: theme.textPrimary, fontSize: 16),
        ),
        content: SizedBox(
          width: 400,
          height: 300,
          child: TextField(
            controller: _jsonController,
            maxLines: null,
            expands: true,
            style: TextStyle(
              color: theme.textPrimary.withValues(alpha: 0.8),
              fontSize: 12,
              fontFamily: 'monospace',
            ),
            decoration: InputDecoration(
              hintText: 'furniture_sizes.json 내용을 붙여넣으세요...',
              hintStyle: TextStyle(color: theme.textSecondary),
              filled: true,
              fillColor: theme.cardBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('취소', style: TextStyle(color: theme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              ref
                  .read(placementProvider.notifier)
                  .loadJson(_jsonController.text);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.accent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('적용',
                style: TextStyle(
                    color: theme.brightness == Brightness.dark
                        ? Colors.white
                        : Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _copyJson() async {
    final theme = ref.read(currentThemeProvider);
    final json = ref.read(placementProvider.notifier).exportJson();
    await Clipboard.setData(ClipboardData(text: json));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('클립보드에 복사되었습니다'),
        backgroundColor: theme.accentSecondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showThemePicker() {
    final currentIndex = ref.read(themeProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _ThemePickerSheet(
          currentIndex: currentIndex,
          onSelect: (index) {
            ref.read(themeProvider.notifier).setTheme(index);
            Navigator.pop(ctx);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(placementProvider);
    final theme = ref.watch(currentThemeProvider);
    final isWide = MediaQuery.of(context).size.width > 768;

    ref.listen<PlacementState>(placementProvider, (prev, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        ref.read(placementProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: theme.scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(state, theme),
            Expanded(
              child: isWide
                  ? _buildWideLayout(state)
                  : _buildNarrowLayout(state),
            ),
            _buildStatusBar(state, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(PlacementState state, AppTheme theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: theme.headerBg,
        border: Border(
          bottom: BorderSide(color: theme.headerBorder),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.accent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Place',
              style: TextStyle(
                color: theme.brightness == Brightness.dark
                    ? Colors.white
                    : Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              '가구 배치 도구',
              style: TextStyle(
                color: theme.textSecondary,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Spacer(),
          // Settings (theme) button
          GestureDetector(
            onTap: _showThemePicker,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: theme.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.accent.withValues(alpha: 0.3),
                ),
              ),
              child: Icon(Icons.palette_outlined, size: 18, color: theme.accent),
            ),
          ),
          const SizedBox(width: 8),
          _ActionButton(
            icon: Icons.content_paste,
            label: '붙여넣기',
            onTap: _pasteJson,
            color: theme.accent,
          ),
          const SizedBox(width: 8),
          _ActionButton(
            icon: Icons.copy,
            label: 'JSON',
            onTap: state.furniture.any((f) => f.isPlaced) ? _copyJson : null,
            color: theme.accentSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildWideLayout(PlacementState state) {
    return Row(
      children: [
        const Expanded(flex: 3, child: IsometricRoom()),
        if (state.furniture.isNotEmpty)
          const SizedBox(
            width: 280,
            child: Padding(
              padding: EdgeInsets.all(12),
              child: FurniturePanel(),
            ),
          ),
      ],
    );
  }

  Widget _buildNarrowLayout(PlacementState state) {
    return Column(
      children: [
        const Expanded(flex: 3, child: IsometricRoom()),
        if (state.furniture.isNotEmpty)
          const SizedBox(
            height: 220,
            child: Padding(
              padding: EdgeInsets.all(12),
              child: FurniturePanel(),
            ),
          ),
      ],
    );
  }

  Widget _buildStatusBar(PlacementState state, AppTheme theme) {
    if (state.room == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: theme.headerBg,
        border: Border(top: BorderSide(color: theme.headerBorder)),
      ),
      child: Row(
        children: [
          _StatusChip(
            icon: Icons.view_in_ar,
            label: '${state.placedCount}/${state.furniture.length} 배치',
            color: theme.accent,
          ),
          const SizedBox(width: 16),
          _StatusChip(
            icon: state.collisionCount > 0
                ? Icons.warning_rounded
                : Icons.check_circle,
            label: state.collisionCount > 0
                ? '충돌 ${state.collisionCount}건'
                : '충돌 없음',
            color: state.collisionCount > 0
                ? Colors.red.shade400
                : theme.accentSecondary,
          ),
          const Spacer(),
          if (state.selectedFurniture != null)
            Text(
              '${state.selectedFurniture!.name} \u00b7 ${state.selectedFurniture!.rotation}\u00b0',
              style: TextStyle(color: theme.textSecondary, fontSize: 12),
            ),
        ],
      ),
    );
  }
}

class _ThemePickerSheet extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onSelect;

  const _ThemePickerSheet({
    required this.currentIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 420),
      decoration: BoxDecoration(
        color: appThemes[currentIndex].headerBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: appThemes[currentIndex].textSecondary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '테마 선택',
              style: TextStyle(
                color: appThemes[currentIndex].textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Flexible(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.8,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: appThemes.length,
              itemBuilder: (ctx, i) {
                final t = appThemes[i];
                final isSelected = i == currentIndex;
                return GestureDetector(
                  onTap: () => onSelect(i),
                  child: Container(
                    decoration: BoxDecoration(
                      color: t.scaffoldBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? t.accent
                            : appThemes[currentIndex]
                                .textSecondary
                                .withValues(alpha: 0.3),
                        width: isSelected ? 2.5 : 1,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        // Preview colors
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                _dot(t.backWallColor, 8),
                                const SizedBox(width: 2),
                                _dot(t.leftWallColor, 8),
                              ],
                            ),
                            const SizedBox(height: 2),
                            _dot(t.floorColor, 10),
                          ],
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.nameKo,
                                style: TextStyle(
                                  color: t.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                t.name,
                                style: TextStyle(
                                  color: t.textSecondary,
                                  fontSize: 10,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.check_circle, size: 16, color: t.accent),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: isDisabled ? 0.3 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatusChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
