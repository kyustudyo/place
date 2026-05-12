import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../models/app_theme.dart';
import '../providers/placement_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/isometric_room.dart';
import '../widgets/furniture_panel.dart';
import '../widgets/dimension_dialog.dart';
import '../utils/session_storage.dart';
import '../main.dart' show isScreenshotMode;

enum PlacementMode { floor, wall }
enum SelectedWall { none, right, left }

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
    {"id": "bed", "name": "침대", "size": {"x": 2.0, "y": 0.5, "z": 3.0}, "position": {"x": 8, "y": 0, "z": 10}, "rotation": 0},
    {"id": "door", "name": "문", "size": {"x": 1.5, "y": 2.4, "z": 0.16}, "position": {"x": 5, "y": 0, "z": 0}, "rotation": 0},
    {"id": "window", "name": "창문", "size": {"x": 0.18, "y": 1.5, "z": 1.2}, "position": {"x": 0, "y": 1.0, "z": 6}, "rotation": 0}
  ]
}''';

const _jsonHelpText = '''● room (선택) — 방 크기
  width/depth: 가로/세로(m)
  height: 천장 높이(m)
  tileSize: 그리드 칸 크기(m)

● furniture — 사물 목록
  id: 고유 식별자
  name: 이름
  size: {x: 가로, y: 높이, z: 세로}
  position: {x, y, z} (y=바닥에서 높이)
  rotation: 0/90/180/270

● 벽 가구 규칙
  오른벽: position.z = 0, size.z 얇게 (<1.0)
  왼벽: position.x = 0, size.x 얇게 (<1.0)
  예) 문: z=0.16 → 오른벽에 자동 배치
  예) 창문: x=0.18 → 왼벽에 자동 배치''';

class _PlacementScreenState extends ConsumerState<PlacementScreen> {
  bool _initialFlowStarted = false;
  bool _showingReference = false;
  String? _currentRoomName;
  PlacementMode _currentMode = PlacementMode.floor;
  SelectedWall _selectedWall = SelectedWall.none;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

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
    if (isScreenshotMode) {
      // 스크린샷 모드: 다이얼로그 스킵, 예시 데이터 자동 로드
      ref.read(placementProvider.notifier).loadJson(_jsonExample);
      // 스크린샷 모드: 필요 시 자동 UI 조작
      // Future.delayed(const Duration(seconds: 2), () {
      //   if (mounted) _showSettings();
      // });
      return;
    }

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

  Future<RoomSizeResult?> _showRoomSizeDialog({bool canClose = false}) async {
    final theme = ref.read(currentThemeProvider);
    final room = ref.read(placementProvider).room;

    return showDialog<RoomSizeResult>(
      context: context,
      barrierDismissible: canClose,
      builder: (ctx) => RoomSizeDialog(
        theme: theme,
        initialWidth: room.width,
        initialDepth: room.depth,
        initialHeight: room.height,
        initialTileSize: room.tileSize,
        showCloseButton: canClose,
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

  /// Show dimension dialog for wall-attached furniture
  Future<void> _showWallDimensionDialog() async {
    final theme = ref.read(currentThemeProvider);
    final isRightWall = _selectedWall == SelectedWall.right;

    // Default: back wall → wide X, thin Z / left wall → thin X, wide Z
    final defaultX = isRightWall ? 1.5 : 0.1;
    final defaultY = 2.0;
    final defaultZ = isRightWall ? 0.1 : 1.5;

    final result = await showDialog<DimensionResult>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => DimensionDialog(
        theme: theme,
        initialX: defaultX,
        initialY: defaultY,
        initialZ: defaultZ,
        wallMode: true,
      ),
    );

    if (result == null) return;

    ref.read(placementProvider.notifier).addWallFurniture(
          name: result.name,
          x: result.x,
          y: result.y,
          z: result.z,
          isRightWall: _selectedWall == SelectedWall.right,
        );
  }

  void _switchMode(PlacementMode mode) {
    if (_currentMode == mode) return;
    setState(() {
      _currentMode = mode;
      _showingReference = false;
      if (mode == PlacementMode.wall) {
        _selectedWall = SelectedWall.none;
        ref.read(placementProvider.notifier).selectFurniture(null);
        ref.read(wallHighlightProvider.notifier).set('both');
      } else {
        _selectedWall = SelectedWall.none;
        ref.read(wallHighlightProvider.notifier).set(null);
      }
    });
  }

  Future<void> _pasteJson() async {
    final theme = ref.read(currentThemeProvider);
    final controller = TextEditingController();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.headerBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Text('JSON 가져오기',
                style: TextStyle(color: theme.textPrimary, fontSize: 16)),
            const Spacer(),
            GestureDetector(
              onTap: () async {
                final data = await Clipboard.getData(Clipboard.kTextPlain);
                if (data?.text != null) {
                  controller.text = data!.text!;
                  controller.selection = TextSelection.collapsed(
                      offset: controller.text.length);
                }
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: theme.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.content_paste_rounded, color: theme.accent, size: 18),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Example + Help buttons
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () {
                      controller.text = _jsonExample;
                      controller.selection = TextSelection.collapsed(
                          offset: controller.text.length);
                    },
                    icon: Icon(Icons.code,
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
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () {
                      showDialog(
                        context: ctx,
                        builder: (hCtx) => AlertDialog(
                          backgroundColor: theme.headerBg,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          title: Text('JSON 형식 도움말',
                              style: TextStyle(color: theme.textPrimary, fontSize: 16)),
                          content: SizedBox(
                            width: 360,
                            child: SingleChildScrollView(
                              child: Text(
                                _jsonHelpText,
                                style: TextStyle(
                                  color: theme.textPrimary.withValues(alpha: 0.85),
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(hCtx),
                              child: Text('닫기', style: TextStyle(color: theme.accent)),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: Icon(Icons.help_outline,
                        size: 14, color: theme.textSecondary),
                    label: Text(
                      '도움말',
                      style: TextStyle(
                        color: theme.textSecondary,
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
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 260,
                child: TextField(
                  controller: controller,
                  autofocus: true,
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
    final theme = ref.read(currentThemeProvider);
    final hasExisting = _currentRoomName != null;

    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => _SaveDialog(
        theme: theme,
        existingName: hasExisting ? _currentRoomName! : null,
      ),
    );

    if (name == null || name.isEmpty) return;

    final state = ref.read(placementProvider);
    final axisMapping = ref.read(axisMappingProvider);
    await SessionStorage.saveRoom(name, state.room, state.furniture, axisMapping: axisMapping);
    if (!mounted) return;
    setState(() => _currentRoomName = name);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"$name" 저장 완료'),
        backgroundColor: theme.accentSecondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _loadSession() async {
    final theme = ref.read(currentThemeProvider);
    final names = await SessionStorage.getSavedRoomNames();

    if (names.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('저장된 방이 없습니다'),
          backgroundColor: theme.textSecondary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _SavedRoomsSheet(
        theme: theme,
        names: names,
        onLoad: (name) async {
          Navigator.pop(ctx);
          final json = await SessionStorage.loadRoom(name);
          if (json != null) {
            final savedMapping = ref.read(placementProvider.notifier).loadJson(json);
            if (savedMapping != null) {
              ref.read(axisMappingProvider.notifier).set(savedMapping);
            }
            if (!mounted) return;
            setState(() => _currentRoomName = name);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('"$name" 불러오기 완료'),
                backgroundColor: theme.accentSecondary,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
        onDelete: (name) async {
          await SessionStorage.deleteRoom(name);
        },
      ),
    );
  }

  Future<void> _resetRoom() async {
    final theme = ref.read(currentThemeProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.headerBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('초기화', style: TextStyle(color: theme.textPrimary, fontSize: 16)),
        content: Text(
          '현재 배치를 모두 초기화하시겠습니까?\n저장하지 않은 내용은 사라집니다.',
          style: TextStyle(color: theme.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('취소', style: TextStyle(color: theme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('초기화', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    ref.read(placementProvider.notifier).reset();
    setState(() => _currentRoomName = null);
    _runInitialFlow();
  }

  Future<void> _copyJson() async {
    final theme = ref.read(currentThemeProvider);
    final axisMapping = ref.read(axisMappingProvider);
    final json = ref.read(placementProvider.notifier).exportJson(mapping: axisMapping);
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
        onReset: _resetRoom,
        onRoomSize: () async {
          final result = await _showRoomSizeDialog(canClose: true);
          if (result != null && mounted) {
            final notifier = ref.read(placementProvider.notifier);
            if (!result.keepFurniture) {
              notifier.reset();
            }
            notifier.setRoom(
                  width: result.width,
                  depth: result.depth,
                  height: result.height,
                  tileSize: result.tileSize,
                );
          }
        },
        onAppearance: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (_) => _AppearanceSheet(
              theme: theme,
              ref: ref,
              onBack: () {
                Navigator.pop(context);
                Future.delayed(const Duration(milliseconds: 300), _showSettings);
              },
            ),
          );
        },
        onAxisConfig: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (_) => _AxisConfigSheet(
              theme: theme,
              ref: ref,
              onBack: () {
                Navigator.pop(context);
                Future.delayed(const Duration(milliseconds: 300), _showSettings);
              },
            ),
          );
        },
        onReferenceImagePicked: (bytes) {
          ref.read(referenceImageProvider.notifier).set(bytes);
          precacheImage(MemoryImage(bytes), context);
        },
        hasFurniture: state.furniture.isNotEmpty,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(placementProvider);
    final theme = ref.watch(currentThemeProvider);
    final refImage = ref.watch(referenceImageProvider);
    final isWide = MediaQuery.of(context).size.width > 768;

    // Listen for wall tap from IsometricRoom
    ref.listen<String?>(wallHighlightProvider, (prev, next) {
      if (_currentMode == PlacementMode.wall && next != null && next != 'both') {
        setState(() {
          _selectedWall = next == 'right' ? SelectedWall.right : SelectedWall.left;
        });
      }
    });

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
            _buildTopBar(state, theme, refImage != null),
            Expanded(
              child: refImage != null && _currentMode == PlacementMode.floor
                  ? PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      onPageChanged: (i) =>
                          setState(() => _showingReference = i == 1),
                      children: [
                        isWide
                            ? _buildWideLayout(state)
                            : _buildNarrowLayout(state),
                        InteractiveViewer(
                          minScale: 0.5,
                          maxScale: 5.0,
                          child: Center(
                            child:
                                Image.memory(refImage, fit: BoxFit.contain),
                          ),
                        ),
                      ],
                    )
                  : isWide
                      ? _buildWideLayout(state)
                      : _buildNarrowLayout(state),
            ),
            _buildStatusBar(state, theme, _showingReference),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(PlacementState state, AppTheme theme, bool hasRefImage) {
    final isWallMode = _currentMode == PlacementMode.wall;
    final wallSelected = _selectedWall != SelectedWall.none;
    // In wall mode without selection → hide all action buttons
    final showActions = !isWallMode || wallSelected;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: theme.headerBg,
        border: Border(bottom: BorderSide(color: theme.headerBorder)),
      ),
      child: Row(
        children: [
          // Main mode tabs
          _ModeTab(
            label: '바닥',
            active: _currentMode == PlacementMode.floor && !_showingReference,
            theme: theme,
            onTap: () {
              _switchMode(PlacementMode.floor);
              if (_showingReference) {
                _pageController.animateToPage(0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut);
              }
            },
          ),
          const SizedBox(width: 6),
          _ModeTab(
            label: '벽',
            active: isWallMode,
            theme: theme,
            onTap: () => _switchMode(PlacementMode.wall),
          ),
          // Show which wall is selected — tap to go back to wall selection
          if (isWallMode && wallSelected) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                // Toggle to the other wall
                final other = _selectedWall == SelectedWall.right
                    ? SelectedWall.left
                    : SelectedWall.right;
                setState(() => _selectedWall = other);
                ref.read(wallHighlightProvider.notifier).set(
                    other == SelectedWall.right ? 'right' : 'left');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFE74C3C),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _selectedWall == SelectedWall.right ? '오른벽' : '왼벽',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
          if (!isWallMode && hasRefImage) ...[
            const SizedBox(width: 6),
            _RefImageBtn(
              active: _showingReference,
              theme: theme,
              onTap: () {
                _pageController.animateToPage(1,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut);
              },
            ),
          ],
          const Spacer(),
          // Always render buttons to keep layout stable; hide with Opacity
          Opacity(
            opacity: showActions ? 1.0 : 0.0,
            child: IgnorePointer(
              ignoring: !showActions,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _TopBarBtn(
                    icon: Icons.settings_outlined,
                    onTap: _showSettings,
                    theme: theme,
                  ),
                  if (!_showingReference) ...[
                    const SizedBox(width: 6),
                    _AddItemBtn(
                      onTap: isWallMode
                          ? () => _showWallDimensionDialog()
                          : () => _showDimensionDialog(),
                      theme: theme,
                      highlight: !isWallMode && state.furniture.isEmpty,
                    ),
                    const SizedBox(width: 6),
                    if (state.furniture.isNotEmpty) ...[
                      _TopBarBtn(
                        icon: Icons.list_rounded,
                        onTap: () => _showFurnitureSheet(),
                        theme: theme,
                      ),
                      const SizedBox(width: 6),
                    ],
                  ],
                ],
              ),
            ),
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

  Widget _buildStatusBar(PlacementState state, AppTheme theme, bool hideContent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: theme.headerBg,
        border: Border(top: BorderSide(color: theme.headerBorder)),
      ),
      child: hideContent
          ? Opacity(
              opacity: 0,
              child: Row(
                children: [
                  _StatusChip(
                    icon: Icons.view_in_ar,
                    label: '0/0',
                    color: theme.accent,
                  ),
                ],
              ),
            )
          : Row(
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

class _ModeTab extends StatelessWidget {
  final String label;
  final bool active;
  final AppTheme theme;
  final VoidCallback onTap;

  const _ModeTab({
    required this.label,
    required this.active,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? theme.accent : theme.accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : theme.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _RefImageBtn extends StatefulWidget {
  final bool active;
  final AppTheme theme;
  final VoidCallback onTap;

  const _RefImageBtn({
    required this.active,
    required this.theme,
    required this.onTap,
  });

  @override
  State<_RefImageBtn> createState() => _RefImageBtnState();
}

class _RefImageBtnState extends State<_RefImageBtn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _blink());
  }

  Future<void> _blink() async {
    await _anim.forward();
    if (!mounted) return;
    await _anim.reverse();
    if (!mounted) return;
    await _anim.forward();
    if (!mounted) return;
    await _anim.reverse();
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
        builder: (context, _) {
          final glow = _anim.value;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: widget.active
                  ? t.accent
                  : Color.lerp(
                      t.accent.withValues(alpha: 0.12),
                      t.accent.withValues(alpha: 0.5),
                      glow,
                    ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Color.lerp(
                  t.accent.withValues(alpha: 0.4),
                  t.accent,
                  glow,
                )!,
                width: 1 + glow,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.image_outlined,
                    size: 16,
                    color: widget.active ? Colors.white : t.accent),
                const SizedBox(width: 4),
                Text(
                  '참조',
                  style: TextStyle(
                    color: widget.active ? Colors.white : t.accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AddItemBtn extends StatefulWidget {
  final VoidCallback? onTap;
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
  final VoidCallback onReset;
  final VoidCallback onRoomSize;
  final VoidCallback onAppearance;
  final VoidCallback onAxisConfig;
  final void Function(Uint8List bytes) onReferenceImagePicked;
  final bool hasFurniture;

  const _SettingsSheet({
    required this.ref,
    required this.theme,
    required this.onSave,
    required this.onLoad,
    required this.onImport,
    required this.onExport,
    required this.onReset,
    required this.onRoomSize,
    required this.onAppearance,
    required this.onAxisConfig,
    required this.onReferenceImagePicked,
    required this.hasFurniture,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final axisMapping = ref.watch(axisMappingProvider);
    final hasRefImage = ref.watch(referenceImageProvider) != null;
    final dataActions = <Widget>[
      if (hasFurniture)
        _SettingsActionBtn(
          icon: Icons.save_outlined,
          label: '저장',
          theme: theme,
          onTap: () {
            Navigator.pop(context);
            Future.delayed(const Duration(milliseconds: 300), onSave);
          },
        ),
      _SettingsActionBtn(
        icon: Icons.folder_open_outlined,
        label: '불러오기',
        theme: theme,
        onTap: () {
          Navigator.pop(context);
          Future.delayed(const Duration(milliseconds: 300), onLoad);
        },
      ),
      _SettingsActionBtn(
        icon: Icons.file_download_outlined,
        label: 'JSON 가져오기',
        theme: theme,
        onTap: () {
          Navigator.pop(context);
          Future.delayed(const Duration(milliseconds: 300), onImport);
        },
      ),
      if (hasFurniture)
        _SettingsActionBtn(
          icon: Icons.file_upload_outlined,
          label: 'JSON 내보내기',
          theme: theme,
          onTap: () {
            Navigator.pop(context);
            Future.delayed(const Duration(milliseconds: 300), onExport);
          },
        ),
      _SettingsActionBtn(
        icon: Icons.refresh_rounded,
        label: '초기화',
        theme: theme,
        isDestructive: true,
        onTap: () {
          Navigator.pop(context);
          Future.delayed(const Duration(milliseconds: 300), onReset);
        },
      ),
    ];

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
          // Axis config button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
                Future.delayed(const Duration(milliseconds: 300), onAxisConfig);
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.cardBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.threed_rotation, color: theme.accent, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('축 방향 설정', style: TextStyle(
                            color: theme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          )),
                          const SizedBox(height: 2),
                          Text(
                            '${axisMapping.flipRD ? "−" : "+"}${AxisMapping.axisName(axisMapping.rightDown)}→오른쪽  '
                            '${axisMapping.flipLD ? "−" : "+"}${AxisMapping.axisName(axisMapping.leftDown)}→왼쪽  '
                            '${axisMapping.flipUp ? "−" : "+"}${AxisMapping.axisName(axisMapping.up)}→위',
                            style: TextStyle(
                              color: theme.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: theme.textSecondary, size: 20),
                  ],
                ),
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
                  if (dataActions.length == 2)
                    Column(
                      children: [
                        for (var i = 0; i < dataActions.length; i++) ...[
                          SizedBox(width: double.infinity, child: dataActions[i]),
                          if (i != dataActions.length - 1)
                            const SizedBox(height: 8),
                        ],
                      ],
                    )
                  else
                    Column(
                      children: [
                        for (var i = 0; i < dataActions.length; i += 2) ...[
                          Row(
                            children: [
                              Expanded(child: dataActions[i]),
                              if (i + 1 < dataActions.length) ...[
                                const SizedBox(width: 8),
                                Expanded(child: dataActions[i + 1]),
                              ] else
                                const Expanded(child: SizedBox.shrink()),
                            ],
                          ),
                          if (i + 2 < dataActions.length)
                            const SizedBox(height: 8),
                        ],
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Reference image
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
                  Icon(Icons.image_outlined, color: theme.accent, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('참조 이미지', style: TextStyle(
                      color: theme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    )),
                  ),
                  if (hasRefImage)
                    GestureDetector(
                      onTap: () {
                        ref.read(referenceImageProvider.notifier).clear();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: Colors.red.withValues(alpha: 0.3)),
                        ),
                        child: Text('삭제', style: TextStyle(
                          color: Colors.red.shade300,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        )),
                      ),
                    ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        final picker = ImagePicker();
                        final picked = await picker.pickImage(
                            source: ImageSource.gallery);
                        if (picked == null) return;
                        final bytes = await picked.readAsBytes();
                        onReferenceImagePicked(bytes);
                        if (context.mounted) Navigator.pop(context);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('이미지 선택 실패: $e')),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.accent.withValues(alpha: 0.15),
                      foregroundColor: theme.accent,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                            color: theme.accent.withValues(alpha: 0.25)),
                      ),
                    ),
                    child: Text(
                      hasRefImage ? '변경' : '추가',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Map size
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
                Future.delayed(const Duration(milliseconds: 300), onRoomSize);
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.cardBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.aspect_ratio, color: theme.accent, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('맵 크기 변경', style: TextStyle(
                        color: theme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      )),
                    ),
                    Icon(Icons.chevron_right, color: theme.textSecondary, size: 20),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Appearance (guide color + theme) — opens sub sheet
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
                Future.delayed(const Duration(milliseconds: 300), onAppearance);
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.cardBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.palette_outlined, color: theme.accent, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('꾸미기', style: TextStyle(
                        color: theme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      )),
                    ),
                    // Current theme preview dot
                    Container(
                      width: 20, height: 20,
                      decoration: BoxDecoration(
                        color: theme.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.chevron_right, color: theme.textSecondary, size: 20),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _AppearanceSheet extends ConsumerWidget {
  final AppTheme theme;
  final WidgetRef ref;
  final VoidCallback? onBack;

  const _AppearanceSheet({required this.theme, required this.ref, this.onBack});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                if (onBack != null)
                  GestureDetector(
                    onTap: onBack,
                    child: Icon(Icons.arrow_back_ios_rounded, size: 20, color: theme.textSecondary),
                  ),
                const Spacer(),
                Text('꾸미기', style: TextStyle(
                  color: theme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                )),
                const Spacer(),
                if (onBack != null)
                  const SizedBox(width: 20),
              ],
            ),
          ),
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
                  const SizedBox(height: 16),
                  // Guide opacity slider
                  Row(
                    children: [
                      Icon(Icons.opacity, color: theme.accent, size: 16),
                      const SizedBox(width: 6),
                      Text('투명도', style: TextStyle(
                        color: theme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      )),
                      const SizedBox(width: 4),
                      Expanded(
                        child: SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                            inactiveTrackColor: theme.textSecondary.withValues(alpha: 0.3),
                          ),
                          child: Slider(
                            value: ref.watch(guideOpacityProvider),
                            min: 0.0,
                            max: 1.0,
                            divisions: 10,
                            activeColor: ref.watch(guideColorProvider),
                            thumbColor: ref.watch(guideColorProvider),
                            onChanged: (v) =>
                                ref.read(guideOpacityProvider.notifier).set(v),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: theme.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${(ref.watch(guideOpacityProvider) * 100).round()}%',
                          style: TextStyle(
                            color: theme.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
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
                            _dot(t.rightWallColor, 8),
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

class _AxisConfigSheet extends ConsumerWidget {
  final AppTheme theme;
  final WidgetRef ref;
  final VoidCallback? onBack;

  const _AxisConfigSheet({required this.theme, required this.ref, this.onBack});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapping = ref.watch(axisMappingProvider);

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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                if (onBack != null)
                  GestureDetector(
                    onTap: onBack,
                    child: Icon(Icons.arrow_back_ios_rounded, size: 20, color: theme.textSecondary),
                  ),
                const Spacer(),
                Text('축 방향 설정', style: TextStyle(
                  color: theme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                )),
                const Spacer(),
                GestureDetector(
                  onTap: () => ref.read(axisMappingProvider.notifier).reset(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.textSecondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('초기화', style: TextStyle(
                      color: theme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    )),
                  ),
                ),
              ],
            ),
          ),
          // Isometric cuboid preview
          SizedBox(
            height: 220,
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: CustomPaint(
                painter: _AxisPreviewPainter(mapping: mapping, theme: theme),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Axis selectors
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.cardBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _axisRow(
                    context, ref, mapping,
                    label: '오른쪽아래',
                    icon: Icons.south_east,
                    current: mapping.rightDown,
                    flipped: mapping.flipRD,
                    color: const Color(0xFF5B8DEF),
                    onChanged: (axis) {
                      final swapped = _swapMapping(mapping, 'rightDown', axis);
                      ref.read(axisMappingProvider.notifier).set(swapped);
                    },
                    onFlip: () {
                      ref.read(axisMappingProvider.notifier).set(
                        mapping.copyWith(flipRD: !mapping.flipRD),
                      );
                    },
                  ),
                  Divider(color: theme.textSecondary.withValues(alpha: 0.15), height: 20),
                  _axisRow(
                    context, ref, mapping,
                    label: '왼쪽아래',
                    icon: Icons.south_west,
                    current: mapping.leftDown,
                    flipped: mapping.flipLD,
                    color: const Color(0xFF5BCA8A),
                    onChanged: (axis) {
                      final swapped = _swapMapping(mapping, 'leftDown', axis);
                      ref.read(axisMappingProvider.notifier).set(swapped);
                    },
                    onFlip: () {
                      ref.read(axisMappingProvider.notifier).set(
                        mapping.copyWith(flipLD: !mapping.flipLD),
                      );
                    },
                  ),
                  Divider(color: theme.textSecondary.withValues(alpha: 0.15), height: 20),
                  _axisRow(
                    context, ref, mapping,
                    label: '위',
                    icon: Icons.north,
                    current: mapping.up,
                    flipped: mapping.flipUp,
                    color: const Color(0xFFE8A838),
                    onChanged: (axis) {
                      final swapped = _swapMapping(mapping, 'up', axis);
                      ref.read(axisMappingProvider.notifier).set(swapped);
                    },
                    onFlip: () {
                      ref.read(axisMappingProvider.notifier).set(
                        mapping.copyWith(flipUp: !mapping.flipUp),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _axisRow(
    BuildContext context,
    WidgetRef ref,
    AxisMapping mapping, {
    required String label,
    required IconData icon,
    required WorldAxis current,
    required bool flipped,
    required Color color,
    required void Function(WorldAxis) onChanged,
    required VoidCallback onFlip,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(
          color: theme.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        )),
        const SizedBox(width: 8),
        // +/- flip toggle
        GestureDetector(
          onTap: onFlip,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 36,
            height: 28,
            decoration: BoxDecoration(
              color: flipped
                  ? color.withValues(alpha: 0.15)
                  : theme.scaffoldBg.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: flipped ? color.withValues(alpha: 0.5) : theme.textSecondary.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              flipped ? '−' : '+',
              style: TextStyle(
                color: flipped ? color : theme.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const Spacer(),
        for (final axis in WorldAxis.values)
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: GestureDetector(
              onTap: () => onChanged(axis),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 40,
                height: 36,
                decoration: BoxDecoration(
                  color: current == axis
                      ? color.withValues(alpha: 0.2)
                      : theme.scaffoldBg.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: current == axis ? color : theme.textSecondary.withValues(alpha: 0.2),
                    width: current == axis ? 2 : 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  AxisMapping.axisName(axis),
                  style: TextStyle(
                    color: current == axis ? color : theme.textSecondary,
                    fontSize: 14,
                    fontWeight: current == axis ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// When user picks a new axis for a slot, swap with whichever slot had it
  AxisMapping _swapMapping(AxisMapping m, String slot, WorldAxis newAxis) {
    var rd = m.rightDown;
    var ld = m.leftDown;
    var up = m.up;

    // Find which slot currently has the newAxis
    final oldSlot = newAxis == rd ? 'rightDown'
        : newAxis == ld ? 'leftDown'
        : 'up';

    // Get the current value of the target slot
    final currentValue = slot == 'rightDown' ? rd
        : slot == 'leftDown' ? ld
        : up;

    // Swap: put currentValue into the old slot
    if (oldSlot == 'rightDown') rd = currentValue;
    if (oldSlot == 'leftDown') ld = currentValue;
    if (oldSlot == 'up') up = currentValue;

    // Set new axis into the target slot
    if (slot == 'rightDown') rd = newAxis;
    if (slot == 'leftDown') ld = newAxis;
    if (slot == 'up') up = newAxis;

    return AxisMapping(rightDown: rd, leftDown: ld, up: up);
  }
}

/// Custom painter for the axis preview cuboid
class _AxisPreviewPainter extends CustomPainter {
  final AxisMapping mapping;
  final AppTheme theme;

  _AxisPreviewPainter({required this.mapping, required this.theme});

  static const double _cos30 = 0.866025;
  static const double _sin30 = 0.5;

  Offset _toScreen(double x, double y, double z, Offset origin, double scale) {
    final sx = (x - z) * _cos30 * scale;
    final sy = (x + z) * _sin30 * scale - y * scale;
    return Offset(origin.dx + sx, origin.dy + sy);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width / 2, size.height * 0.6);
    const s = 30.0;
    const w = 3.0, h = 2.0, d = 2.5;

    // Faces
    final topFace = [
      _toScreen(0, h, 0, origin, s),
      _toScreen(w, h, 0, origin, s),
      _toScreen(w, h, d, origin, s),
      _toScreen(0, h, d, origin, s),
    ];
    final leftFace = [
      _toScreen(0, 0, d, origin, s),
      _toScreen(w, 0, d, origin, s),
      _toScreen(w, h, d, origin, s),
      _toScreen(0, h, d, origin, s),
    ];
    final rightFace = [
      _toScreen(w, 0, 0, origin, s),
      _toScreen(w, 0, d, origin, s),
      _toScreen(w, h, d, origin, s),
      _toScreen(w, h, 0, origin, s),
    ];

    final topColor = theme.floorColor.withValues(alpha: 0.8);
    final leftColor = theme.leftWallColor.withValues(alpha: 0.7);
    final rightColor = theme.rightWallColor.withValues(alpha: 0.7);

    void drawFace(List<Offset> pts, Color fill) {
      final path = Path()..moveTo(pts[0].dx, pts[0].dy);
      for (int i = 1; i < pts.length; i++) {
        path.lineTo(pts[i].dx, pts[i].dy);
      }
      path.close();
      canvas.drawPath(path, Paint()..color = fill);
      canvas.drawPath(path, Paint()
        ..color = theme.wallBorderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5);
    }

    drawFace(leftFace, leftColor);
    drawFace(rightFace, rightColor);
    drawFace(topFace, topColor);

    // Axis arrows with +/- labels
    final corner = _toScreen(0, 0, 0, origin, s);

    // Right-down axis
    final rdEnd = _toScreen(w + 1.2, 0, 0, origin, s);
    final rdSign = mapping.flipRD ? '−' : '+';
    _drawAxisArrow(canvas, corner, rdEnd, const Color(0xFF5B8DEF),
        '$rdSign${AxisMapping.axisName(mapping.rightDown)}');

    // Left-down axis
    final ldEnd = _toScreen(0, 0, d + 1.2, origin, s);
    final ldSign = mapping.flipLD ? '−' : '+';
    _drawAxisArrow(canvas, corner, ldEnd, const Color(0xFF5BCA8A),
        '$ldSign${AxisMapping.axisName(mapping.leftDown)}');

    // Up axis
    final upEnd = _toScreen(0, h + 1.5, 0, origin, s);
    final upSign = mapping.flipUp ? '−' : '+';
    _drawAxisArrow(canvas, corner, upEnd, const Color(0xFFE8A838),
        '$upSign${AxisMapping.axisName(mapping.up)}');
  }

  void _drawAxisArrow(Canvas canvas, Offset from, Offset to, Color color, String label) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(from, to, paint);

    // Arrowhead
    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;
    final len = Offset(dx, dy).distance;
    if (len == 0) return;
    final ux = dx / len;
    final uy = dy / len;
    const arrowLen = 8.0;
    final ax = to.dx - ux * arrowLen + uy * arrowLen * 0.4;
    final ay = to.dy - uy * arrowLen - ux * arrowLen * 0.4;
    final bx = to.dx - ux * arrowLen - uy * arrowLen * 0.4;
    final by = to.dy - uy * arrowLen + ux * arrowLen * 0.4;
    final arrowPath = Path()
      ..moveTo(to.dx, to.dy)
      ..lineTo(ax, ay)
      ..lineTo(bx, by)
      ..close();
    canvas.drawPath(arrowPath, Paint()..color = color);

    // Label
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: color,
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(to.dx + ux * 8 - tp.width / 2, to.dy + uy * 8 - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _AxisPreviewPainter oldDelegate) =>
      mapping != oldDelegate.mapping;
}

class _SaveDialog extends StatefulWidget {
  final AppTheme theme;
  final String? existingName;

  const _SaveDialog({required this.theme, this.existingName});

  @override
  State<_SaveDialog> createState() => _SaveDialogState();
}

class _SaveDialogState extends State<_SaveDialog> {
  late final TextEditingController _controller;
  bool _newName = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.existingName ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() async {
    final hasExisting = widget.existingName != null;
    if (hasExisting && !_newName) {
      Navigator.pop(context, widget.existingName);
      return;
    }
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    // 같은 이름 체크
    if (hasExisting && text == widget.existingName) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('기존과 같은 이름입니다. 다른 이름을 입력해주세요.'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    Navigator.pop(context, text);
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    final hasExisting = widget.existingName != null;
    final editable = !hasExisting || _newName;

    return Dialog(
      backgroundColor: t.headerBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('파일 저장', style: TextStyle(color: t.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              enabled: editable,
              autofocus: !hasExisting,
              style: TextStyle(
                color: editable ? t.textPrimary : t.textSecondary,
              ),
              decoration: InputDecoration(
                hintText: '예: 한국 내 방',
                hintStyle: TextStyle(color: t.textSecondary),
                filled: true,
                fillColor: editable ? t.cardBg : t.cardBg.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: !editable
                    ? Icon(Icons.lock_outline, size: 16, color: t.textSecondary.withValues(alpha: 0.5))
                    : null,
              ),
            ),
            if (hasExisting) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => setState(() {
                  _newName = !_newName;
                  if (_newName) {
                    // 포커스를 텍스트필드로
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _controller.selection = TextSelection(
                        baseOffset: 0,
                        extentOffset: _controller.text.length,
                      );
                    });
                  }
                }),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: Checkbox(
                        value: _newName,
                        onChanged: (v) => setState(() {
                          _newName = v ?? false;
                          if (_newName) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _controller.selection = TextSelection(
                                baseOffset: 0,
                                extentOffset: _controller.text.length,
                              );
                            });
                          }
                        }),
                        activeColor: t.accent,
                        side: BorderSide(color: t.textSecondary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('새 이름으로 저장', style: TextStyle(
                      color: t.textPrimary,
                      fontSize: 13,
                    )),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('취소', style: TextStyle(color: t.textSecondary)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: t.accent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('저장', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedRoomsSheet extends StatefulWidget {
  final AppTheme theme;
  final List<String> names;
  final void Function(String name) onLoad;
  final void Function(String name) onDelete;

  const _SavedRoomsSheet({
    required this.theme,
    required this.names,
    required this.onLoad,
    required this.onDelete,
  });

  @override
  State<_SavedRoomsSheet> createState() => _SavedRoomsSheetState();
}

class _SavedRoomsSheetState extends State<_SavedRoomsSheet> {
  late final List<String> _names;

  @override
  void initState() {
    super.initState();
    _names = List.of(widget.names);
  }

  Future<void> _confirmDelete(String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: widget.theme.headerBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('삭제', style: TextStyle(color: widget.theme.textPrimary, fontSize: 16)),
        content: Text(
          '"$name"을(를) 삭제하시겠습니까?',
          style: TextStyle(color: widget.theme.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('취소', style: TextStyle(color: widget.theme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('삭제', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    widget.onDelete(name);
    setState(() => _names.remove(name));
    if (_names.isEmpty && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.55,
      ),
      decoration: BoxDecoration(
        color: theme.panelBg,
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
              color: theme.textSecondary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('저장된 방', style: TextStyle(
              color: theme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            )),
          ),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _names.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final name = _names[i];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.cardBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.meeting_room_outlined, color: theme.accent, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(name, style: TextStyle(
                          color: theme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        )),
                      ),
                      GestureDetector(
                        onTap: () => _confirmDelete(name),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(Icons.delete_outline, size: 16, color: Colors.red.shade300),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => widget.onLoad(name),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: theme.accent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('열기', style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          )),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _SettingsActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final AppTheme theme;
  final VoidCallback onTap;
  final bool isDestructive;

  const _SettingsActionBtn({
    required this.icon,
    required this.label,
    required this.theme,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? Colors.red : theme.accent;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(
              color: color,
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
