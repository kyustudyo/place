import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_theme.dart';
import '../providers/placement_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/isometric_room.dart';
import '../widgets/furniture_panel.dart';
import '../widgets/dimension_dialog.dart';

class PlacementScreen extends ConsumerStatefulWidget {
  const PlacementScreen({super.key});

  @override
  ConsumerState<PlacementScreen> createState() => _PlacementScreenState();
}

class _PlacementScreenState extends ConsumerState<PlacementScreen> {
  bool _initialFlowStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialFlowStarted) {
      _initialFlowStarted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _runInitialFlow();
      });
    }
  }

  /// ① 공간 크기 → ② 사물 추가 순서
  Future<void> _runInitialFlow() async {
    // Step ① 공간 크기 설정
    final roomResult = await _showRoomSizeDialog();
    if (roomResult != null) {
      ref.read(placementProvider.notifier).setRoom(
            width: roomResult.width,
            depth: roomResult.depth,
            height: roomResult.height,
            tileSize: roomResult.tileSize,
          );
    }

    if (!mounted) return;

    // Step ② 첫 사물 추가
    await _showDimensionDialog(showStepNumber: true);
  }

  Future<RoomSizeResult?> _showRoomSizeDialog() async {
    final theme = ref.read(currentThemeProvider);
    final room = ref.read(placementProvider).room;

    return showDialog<RoomSizeResult>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => RoomSizeDialog(
        theme: theme,
        initialWidth: room.width,
        initialDepth: room.depth,
        initialHeight: room.height,
        initialTileSize: room.tileSize,
      ),
    );
  }

  Future<void> _showDimensionDialog({
    String? editId,
    bool showStepNumber = false,
  }) async {
    final theme = ref.read(currentThemeProvider);
    final state = ref.read(placementProvider);

    String? initialName;
    double? initialX, initialY, initialZ;
    bool isEdit = false;

    if (editId != null) {
      final item = state.furniture.firstWhere((f) => f.id == editId);
      initialName = item.name;
      initialX = item.size.x;
      initialY = item.size.y;
      initialZ = item.size.z;
      isEdit = true;
    }

    final result = await showDialog<DimensionResult>(
      context: context,
      barrierDismissible: isEdit || !showStepNumber,
      builder: (ctx) => DimensionDialog(
        theme: theme,
        initialName: initialName,
        initialX: initialX,
        initialY: initialY,
        initialZ: initialZ,
        isEdit: isEdit,
        showStepNumber: showStepNumber,
      ),
    );

    if (result == null) return;

    final notifier = ref.read(placementProvider.notifier);
    if (isEdit && editId != null) {
      notifier.updateFurnitureSize(editId, result.x, result.y, result.z);
      if (result.name.isNotEmpty) {
        notifier.updateFurnitureName(editId, result.name);
      }
    } else {
      notifier.addFurniture(
        name: result.name,
        x: result.x,
        y: result.y,
        z: result.z,
      );
    }
  }

  Future<void> _pasteJson() async {
    final theme = ref.read(currentThemeProvider);
    final controller = TextEditingController();

    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      controller.text = data.text!;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.headerBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('JSON 가져오기',
            style: TextStyle(color: theme.textPrimary, fontSize: 16)),
        content: SizedBox(
          width: 400,
          height: 300,
          child: TextField(
            controller: controller,
            maxLines: null,
            expands: true,
            style: TextStyle(
              color: theme.textPrimary.withValues(alpha: 0.8),
              fontSize: 12,
              fontFamily: 'monospace',
            ),
            decoration: InputDecoration(
              hintText: 'furniture_sizes.json...',
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
                  .loadJson(controller.text);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.accent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child:
                const Text('적용', style: TextStyle(color: Colors.white)),
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
      builder: (ctx) => _ThemePickerSheet(
        currentIndex: currentIndex,
        onSelect: (index) {
          ref.read(themeProvider.notifier).setTheme(index);
          Navigator.pop(ctx);
        },
      ),
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
        border: Border(bottom: BorderSide(color: theme.headerBorder)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.accent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Place',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const Spacer(),
          // Theme
          _TopBarBtn(
            icon: Icons.palette_outlined,
            onTap: _showThemePicker,
            theme: theme,
          ),
          const SizedBox(width: 6),
          // Add furniture
          _TopBarBtn(
            icon: Icons.add_rounded,
            onTap: _showDimensionDialog,
            theme: theme,
          ),
          const SizedBox(width: 6),
          // JSON import
          _TopBarBtn(
            icon: Icons.file_download_outlined,
            onTap: _pasteJson,
            theme: theme,
          ),
          const SizedBox(width: 6),
          // JSON export
          _TopBarBtn(
            icon: Icons.file_upload_outlined,
            onTap: state.furniture.any((f) => f.isPlaced) ? _copyJson : null,
            theme: theme,
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
          SizedBox(
            width: 280,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: FurniturePanel(
                onEditDimension: (id) =>
                    _showDimensionDialog(editId: id),
              ),
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
          SizedBox(
            height: 220,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: FurniturePanel(
                onEditDimension: (id) =>
                    _showDimensionDialog(editId: id),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatusBar(PlacementState state, AppTheme theme) {
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

class _TopBarBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final AppTheme theme;

  const _TopBarBtn({
    required this.icon,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: disabled ? 0.3 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: theme.accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: theme.accent.withValues(alpha: 0.25)),
          ),
          child: Icon(icon, size: 20, color: theme.accent),
        ),
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
    final cur = appThemes[currentIndex];
    return Container(
      constraints: const BoxConstraints(maxHeight: 420),
      decoration: BoxDecoration(
        color: cur.headerBg,
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
              color: cur.textSecondary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '테마 선택',
              style: TextStyle(
                color: cur.textPrimary,
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
                final selected = i == currentIndex;
                return GestureDetector(
                  onTap: () => onSelect(i),
                  child: Container(
                    decoration: BoxDecoration(
                      color: t.scaffoldBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? t.accent
                            : cur.textSecondary.withValues(alpha: 0.3),
                        width: selected ? 2.5 : 1,
                      ),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(children: [
                              _dot(t.backWallColor, 8),
                              const SizedBox(width: 2),
                              _dot(t.leftWallColor, 8),
                            ]),
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
                              Text(t.nameKo,
                                  style: TextStyle(
                                      color: t.textPrimary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis),
                              Text(t.name,
                                  style: TextStyle(
                                      color: t.textSecondary, fontSize: 10),
                                  overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        if (selected)
                          Icon(Icons.check_circle,
                              size: 16, color: t.accent),
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

  Widget _dot(Color c, double s) => Container(
        width: s,
        height: s,
        decoration: BoxDecoration(
            color: c, borderRadius: BorderRadius.circular(2)),
      );
}

class _StatusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatusChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: color),
      const SizedBox(width: 6),
      Text(label,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w500)),
    ]);
  }
}
