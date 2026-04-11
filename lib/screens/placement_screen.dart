import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/placement_provider.dart';
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
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      _jsonController.text = data.text!;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'JSON 붙여넣기',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: SizedBox(
          width: 400,
          height: 300,
          child: TextField(
            controller: _jsonController,
            maxLines: null,
            expands: true,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
            decoration: InputDecoration(
              hintText: 'furniture_sizes.json 내용을 붙여넣으세요...',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
              filled: true,
              fillColor: const Color(0xFF16213E),
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
            child: Text('취소',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
          ),
          ElevatedButton(
            onPressed: () {
              ref
                  .read(placementProvider.notifier)
                  .loadJson(_jsonController.text);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5B8DEF),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('적용', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _copyJson() async {
    final json = ref.read(placementProvider.notifier).exportJson();
    await Clipboard.setData(ClipboardData(text: json));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('클립보드에 복사되었습니다'),
        backgroundColor: const Color(0xFF5BCA8A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(placementProvider);
    final isWide = MediaQuery.of(context).size.width > 768;

    // Listen for errors
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
      backgroundColor: const Color(0xFF0F0F23),
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            _buildTopBar(state),
            // Main content
            Expanded(
              child: isWide
                  ? _buildWideLayout(state)
                  : _buildNarrowLayout(state),
            ),
            // Status bar
            _buildStatusBar(state),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(PlacementState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.06),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF5B8DEF), Color(0xFF7C5BEF)],
              ),
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
          const SizedBox(width: 12),
          Text(
            '가구 배치 도구',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 13,
            ),
          ),
          const Spacer(),
          _ActionButton(
            icon: Icons.content_paste,
            label: '붙여넣기',
            onTap: _pasteJson,
            color: const Color(0xFF5B8DEF),
          ),
          const SizedBox(width: 8),
          _ActionButton(
            icon: Icons.copy,
            label: 'JSON 복사',
            onTap: state.furniture.any((f) => f.isPlaced) ? _copyJson : null,
            color: const Color(0xFF5BCA8A),
          ),
        ],
      ),
    );
  }

  Widget _buildWideLayout(PlacementState state) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: const IsometricRoom(),
        ),
        if (state.furniture.isNotEmpty)
          SizedBox(
            width: 280,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: const FurniturePanel(),
            ),
          ),
      ],
    );
  }

  Widget _buildNarrowLayout(PlacementState state) {
    return Column(
      children: [
        Expanded(
          flex: 3,
          child: const IsometricRoom(),
        ),
        if (state.furniture.isNotEmpty)
          SizedBox(
            height: 220,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: const FurniturePanel(),
            ),
          ),
      ],
    );
  }

  Widget _buildStatusBar(PlacementState state) {
    if (state.room == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.06),
          ),
        ),
      ),
      child: Row(
        children: [
          _StatusChip(
            icon: Icons.view_in_ar,
            label: '${state.placedCount}/${state.furniture.length} 배치',
            color: const Color(0xFF5B8DEF),
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
                : const Color(0xFF5BCA8A),
          ),
          const Spacer(),
          if (state.selectedFurniture != null)
            Text(
              '${state.selectedFurniture!.name} · ${state.selectedFurniture!.rotation}°',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
        ],
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
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
