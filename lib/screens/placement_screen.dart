import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_theme.dart';
import '../providers/placement_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/isometric_room.dart';
import '../widgets/furniture_panel.dart';
import '../widgets/dimension_dialog.dart';
import '../utils/session_storage.dart';

class PlacementScreen extends ConsumerStatefulWidget {
  const PlacementScreen({super.key});

  @override
  ConsumerState<PlacementScreen> createState() => _PlacementScreenState();
}

const _jsonExample = '''{
  "room": {
    "width": 15, "height": 4,
    "depth": 15, "tileSize": 1,
    "gridSize": 15
  },
  "furniture": [
    {"id": "sofa", "name": "소파", "size": {"x": 3.0, "y": 0.8, "z": 1.5}, "position": {"x": 1, "y": 0, "z": 6}, "rotation": 0},
    {"id": "table", "name": "테이블", "size": {"x": 2.0, "y": 0.7, "z": 1.0}, "position": {"x": 2, "y": 0, "z": 4}, "rotation": 0},
    {"id": "desk", "name": "책상", "size": {"x": 1.5, "y": 0.8, "z": 0.8}, "position": {"x": 10, "y": 0, "z": 1}, "rotation": 0},
    {"id": "chair", "name": "의자", "size": {"x": 0.5, "y": 1.0, "z": 0.5}, "position": {"x": 11, "y": 0, "z": 2}, "rotation": 0},
    {"id": "bookshelf", "name": "책장", "size": {"x": 1.0, "y": 2.5, "z": 0.4}, "position": {"x": 0, "y": 0, "z": 0}, "rotation": 0},
    {"id": "bed", "name": "침대", "size": {"x": 2.0, "y": 0.5, "z": 3.0}, "position": {"x": 8, "y": 0, "z": 10}, "rotation": 0},
    {"id": "wardrobe", "name": "옷장", "size": {"x": 1.8, "y": 2.2, "z": 0.6}, "position": {"x": 13, "y": 0, "z": 0}, "rotation": 0},
    {"id": "lamp", "name": "스탠드", "size": {"x": 0.3, "y": 1.5, "z": 0.3}, "position": {"x": 14, "y": 0, "z": 10}, "rotation": 0}
  ]
}''';

class _PlacementScreenState extends ConsumerState<PlacementScreen> {
  bool _initialFlowStarted = false;
  bool _hasSession = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialFlowStarted) {
      _initialFlowStarted = true;
      SessionStorage.hasSession().then((v) {
        if (mounted) setState(() => _hasSession = v);
      });
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Example button
              TextButton.icon(
                onPressed: () {
                  controller.text = _jsonExample;
                  controller.selection = TextSelection.collapsed(
                      offset: controller.text.length);
                },
                icon: Icon(Icons.info_outline,
                    size: 14, color: theme.accent),
                label: Text(
                  '예시 채우기',
                  style: TextStyle(
                    color: theme.accent,
                    fontSize: 12,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 260,
                child: TextField(
                  controller: controller,
                  maxLines: null,
                  expands: true,
                  style: TextStyle(
                    color: theme.textPrimary.withValues(alpha: 0.8),
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                  decoration: InputDecoration(
                    hintText: 'furniture_sizes.json 붙여넣기...',
                    hintStyle:
                        TextStyle(color: theme.textSecondary),
                    filled: true,
                    fillColor: theme.cardBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ],
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

  Future<void> _saveSession() async {
    final state = ref.read(placementProvider);
    await SessionStorage.save(state.room, state.furniture);
    if (!mounted) return;
    setState(() => _hasSession = true);
    final theme = ref.read(currentThemeProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('저장 완료'),
        backgroundColor: theme.accentSecondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _loadSession() async {
    final json = await SessionStorage.load();
    if (json == null) {
      if (!mounted) return;
      final theme = ref.read(currentThemeProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('저장된 세션이 없습니다'),
          backgroundColor: theme.textSecondary,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    ref.read(placementProvider.notifier).loadJson(json);
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

  void _showSettings() {
    final theme = ref.read(currentThemeProvider);
    final state = ref.read(placementProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _SettingsSheet(
        ref: ref,
        theme: theme,
        onSave: _saveSession,
        onLoad: _loadSession,
        onImport: _pasteJson,
        onExport: _copyJson,
        hasFurniture: state.furniture.isNotEmpty,
        hasSession: _hasSession,
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
            icon: Icons.settings_outlined,
            onTap: _showSettings,
            theme: theme,
          ),
          const SizedBox(width: 6),
          // Add item — blink when empty
          _AddItemBtn(
            onTap: () => _showDimensionDialog(),
            theme: theme,
            highlight: state.furniture.isEmpty,
          ),
          const SizedBox(width: 6),
          // Item list (opens bottom sheet)
          if (state.furniture.isNotEmpty) ...[
            _TopBarBtn(
              icon: Icons.list_rounded,
              onTap: () => _showFurnitureSheet(),
              theme: theme,
            ),
            const SizedBox(width: 6),
          ],
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
    // Mobile: full screen map, item list via top bar button
    return const IsometricRoom();
  }

  void _showFurnitureSheet() {
    final theme = ref.read(currentThemeProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.55,
        ),
        decoration: BoxDecoration(
          color: theme.panelBg,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: FurniturePanel(
                  onEditDimension: (id) {
                    Navigator.pop(ctx);
                    _showDimensionDialog(editId: id);
                  },
                ),
              ),
            ),
            // Add item button at bottom
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showDimensionDialog();
                  },
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('사물 추가'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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

class _AddItemBtn extends StatefulWidget {
  final VoidCallback onTap;
  final AppTheme theme;
  final bool highlight;

  const _AddItemBtn({
    required this.onTap,
    required this.theme,
    required this.highlight,
  });

  @override
  State<_AddItemBtn> createState() => _AddItemBtnState();
}

class _AddItemBtnState extends State<_AddItemBtn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    if (widget.highlight) _anim.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _AddItemBtn old) {
    super.didUpdateWidget(old);
    if (widget.highlight && !_anim.isAnimating) {
      _anim.repeat(reverse: true);
    } else if (!widget.highlight && _anim.isAnimating) {
      _anim.stop();
      _anim.value = 0;
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, child) {
          final glow = widget.highlight ? _anim.value : 0.0;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Color.lerp(
                    t.accent.withValues(alpha: 0.12),
                    t.accent.withValues(alpha: 0.4),
                    glow,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Color.lerp(
                      t.accent.withValues(alpha: 0.25),
                      t.accent,
                      glow,
                    )!,
                    width: 1 + glow,
                  ),
                ),
                child: Icon(Icons.add_rounded, size: 20, color: t.accent),
              ),
            ],
          );
        },
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

class _SettingsSheet extends ConsumerWidget {
  final WidgetRef ref;
  final AppTheme theme;
  final VoidCallback onSave;
  final VoidCallback onLoad;
  final VoidCallback onImport;
  final VoidCallback onExport;
  final bool hasFurniture;
  final bool hasSession;

  const _SettingsSheet({
    required this.ref,
    required this.theme,
    required this.onSave,
    required this.onLoad,
    required this.onImport,
    required this.onExport,
    required this.hasFurniture,
    required this.hasSession,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final axisSwapped = ref.watch(axisSwapProvider);
    final currentThemeIndex = ref.watch(themeProvider);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: BoxDecoration(
        color: theme.panelBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: ListView(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: theme.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text('설정', style: TextStyle(
                color: theme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              )),
            ),
          ),
          // Axis swap toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.cardBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.swap_horiz, color: theme.accent, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('X-Z 축 방향 스왑', style: TextStyle(
                          color: theme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        )),
                        const SizedBox(height: 2),
                        Text(
                          axisSwapped
                              ? 'X→왼쪽아래  Z→오른쪽아래'
                              : 'X→오른쪽아래  Z→왼쪽아래',
                          style: TextStyle(
                            color: theme.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: axisSwapped,
                    activeTrackColor: theme.accent,
                    onChanged: (_) =>
                        ref.read(axisSwapProvider.notifier).toggle(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Data management
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.cardBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.storage, color: theme.accent, size: 18),
                      const SizedBox(width: 10),
                      Text('데이터', style: TextStyle(
                        color: theme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      )),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (hasFurniture)
                        Expanded(
                          child: _SettingsActionBtn(
                            icon: Icons.save_outlined,
                            label: '저장',
                            theme: theme,
                            onTap: () {
                              onSave();
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      if (hasFurniture && hasSession)
                        const SizedBox(width: 8),
                      if (hasSession)
                        Expanded(
                          child: _SettingsActionBtn(
                            icon: Icons.folder_open_outlined,
                            label: '불러오기',
                            theme: theme,
                            onTap: () {
                              onLoad();
                              Navigator.pop(context);
                            },
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _SettingsActionBtn(
                          icon: Icons.file_download_outlined,
                          label: 'JSON 가져오기',
                          theme: theme,
                          onTap: () {
                            Navigator.pop(context);
                            onImport();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (hasFurniture)
                        Expanded(
                          child: _SettingsActionBtn(
                            icon: Icons.file_upload_outlined,
                            label: 'JSON 내보내기',
                            theme: theme,
                            onTap: () {
                              Navigator.pop(context);
                              onExport();
                            },
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Guide line color
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.cardBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.palette, color: theme.accent, size: 18),
                      const SizedBox(width: 10),
                      Text('가이드 점선 색상', style: TextStyle(
                        color: theme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      )),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final c in guideColorOptions)
                        GestureDetector(
                          onTap: () =>
                              ref.read(guideColorProvider.notifier).set(c),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: ref.watch(guideColorProvider) == c
                                  ? Border.all(
                                      color: theme.textPrimary, width: 3)
                                  : Border.all(
                                      color: c.withValues(alpha: 0.3),
                                      width: 1),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Theme picker
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('테마', style: TextStyle(
                color: theme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              )),
            ),
          ),
          const SizedBox(height: 10),
          GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.8,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: appThemes.length,
              itemBuilder: (ctx, i) {
                final t = appThemes[i];
                final selected = i == currentThemeIndex;
                return GestureDetector(
                  onTap: () =>
                      ref.read(themeProvider.notifier).setTheme(i),
                  child: Container(
                    decoration: BoxDecoration(
                      color: t.scaffoldBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? t.accent : theme.textSecondary.withValues(alpha: 0.3),
                        width: selected ? 2.5 : 1,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                              Text(t.nameKo, style: TextStyle(
                                color: t.textPrimary, fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ), overflow: TextOverflow.ellipsis),
                              Text(t.name, style: TextStyle(
                                color: t.textSecondary, fontSize: 10,
                              ), overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        if (selected)
                          Icon(Icons.check_circle, size: 16, color: t.accent),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _dot(Color c, double s) => Container(
        width: s, height: s,
        decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2)),
      );
}

class _SettingsActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final AppTheme theme;
  final VoidCallback onTap;

  const _SettingsActionBtn({
    required this.icon,
    required this.label,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: theme.accent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: theme.accent.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: theme.accent),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(
              color: theme.accent,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            )),
          ],
        ),
      ),
    );
  }
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
