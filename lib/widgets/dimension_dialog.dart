import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/app_theme.dart';

// ─── Room size result ───
class RoomSizeResult {
  final double width;
  final double depth;
  final double height;
  final double tileSize;

  const RoomSizeResult({
    required this.width,
    required this.depth,
    required this.height,
    required this.tileSize,
  });
}

// ─── Furniture dimension result ───
class DimensionResult {
  final String name;
  final double x;
  final double y;
  final double z;

  const DimensionResult({
    required this.name,
    required this.x,
    required this.y,
    required this.z,
  });
}

// ─── Step ① 공간 크기 설정 ───
class RoomSizeDialog extends StatefulWidget {
  final AppTheme theme;
  final double? initialWidth;
  final double? initialDepth;
  final double? initialHeight;
  final double? initialTileSize;

  const RoomSizeDialog({
    super.key,
    required this.theme,
    this.initialWidth,
    this.initialDepth,
    this.initialHeight,
    this.initialTileSize,
  });

  @override
  State<RoomSizeDialog> createState() => _RoomSizeDialogState();
}

class _RoomSizeDialogState extends State<RoomSizeDialog> {
  late final TextEditingController _wCtrl;
  late final TextEditingController _dCtrl;
  late final TextEditingController _hCtrl;
  late final TextEditingController _tCtrl;

  @override
  void initState() {
    super.initState();
    _wCtrl =
        TextEditingController(text: (widget.initialWidth ?? 15.0).toString());
    _dCtrl =
        TextEditingController(text: (widget.initialDepth ?? 15.0).toString());
    _hCtrl =
        TextEditingController(text: (widget.initialHeight ?? 4.0).toString());
    _tCtrl = TextEditingController(
        text: (widget.initialTileSize ?? 1.0).toString());
  }

  @override
  void dispose() {
    _wCtrl.dispose();
    _dCtrl.dispose();
    _hCtrl.dispose();
    _tCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final w = double.tryParse(_wCtrl.text);
    final d = double.tryParse(_dCtrl.text);
    final h = double.tryParse(_hCtrl.text);
    final t = double.tryParse(_tCtrl.text);
    if (w == null || d == null || h == null || t == null) return;
    if (w <= 0 || d <= 0 || h <= 0 || t <= 0) return;

    Navigator.pop(
      context,
      RoomSizeResult(width: w, depth: d, height: h, tileSize: t),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;

    return AlertDialog(
      backgroundColor: t.headerBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: t.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '①',
                  style: TextStyle(
                    color: t.accent,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '공간 크기 설정',
                style: TextStyle(
                  color: t.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '배치할 공간의 크기를 입력하세요.\n기본값은 15 × 15 (타일 1) 입니다.',
            style: TextStyle(
              color: t.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                    child: _field(t, '가로 (m)', _wCtrl, '7.5')),
                const SizedBox(width: 10),
                Expanded(
                    child: _field(t, '세로 (m)', _dCtrl, '7.5')),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: _field(t, '높이 (m)', _hCtrl, '4.0')),
                const SizedBox(width: 10),
                Expanded(
                    child: _field(t, '타일 크기 (m)', _tCtrl, '0.5')),
              ],
            ),
          ],
        ),
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: t.accent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text(
              '다음',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _field(
      AppTheme t, String label, TextEditingController ctrl, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: t.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))
          ],
          style: TextStyle(
            color: t.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                TextStyle(color: t.textSecondary.withValues(alpha: 0.4)),
            filled: true,
            fillColor: t.cardBg,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: t.accent, width: 1.5),
            ),
          ),
          onSubmitted: (_) => _submit(),
        ),
      ],
    );
  }
}

// ─── Step ② 사물 추가 ───
class DimensionDialog extends StatefulWidget {
  final AppTheme theme;
  final String? initialName;
  final double? initialX;
  final double? initialY;
  final double? initialZ;
  final bool isEdit;
  final bool showStepNumber;

  const DimensionDialog({
    super.key,
    required this.theme,
    this.initialName,
    this.initialX,
    this.initialY,
    this.initialZ,
    this.isEdit = false,
    this.showStepNumber = false,
  });

  @override
  State<DimensionDialog> createState() => _DimensionDialogState();
}

class _DimensionDialogState extends State<DimensionDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _xCtrl;
  late final TextEditingController _yCtrl;
  late final TextEditingController _zCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName ?? '');
    _xCtrl =
        TextEditingController(text: widget.initialX?.toString() ?? '1.5');
    _yCtrl =
        TextEditingController(text: widget.initialY?.toString() ?? '0.8');
    _zCtrl =
        TextEditingController(text: widget.initialZ?.toString() ?? '1.0');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _xCtrl.dispose();
    _yCtrl.dispose();
    _zCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final x = double.tryParse(_xCtrl.text);
    final y = double.tryParse(_yCtrl.text);
    final z = double.tryParse(_zCtrl.text);
    if (x == null || y == null || z == null) return;
    if (x <= 0 || y <= 0 || z <= 0) return;

    final name =
        _nameCtrl.text.trim().isEmpty ? '사물' : _nameCtrl.text.trim();

    Navigator.pop(
        context, DimensionResult(name: name, x: x, y: y, z: z));
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    final title = widget.isEdit ? '크기 수정' : '사물 추가';
    final buttonText = widget.isEdit
        ? '수정'
        : widget.showStepNumber
            ? '배치하기'
            : '추가';

    return AlertDialog(
      backgroundColor: t.headerBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (widget.showStepNumber) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: t.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '②',
                    style: TextStyle(
                      color: t.accent,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ] else if (!widget.isEdit) ...[
                Icon(Icons.add_box_rounded, color: t.accent, size: 22),
                const SizedBox(width: 10),
              ] else ...[
                Icon(Icons.edit, color: t.accent, size: 20),
                const SizedBox(width: 10),
              ],
              Text(
                title,
                style: TextStyle(
                  color: t.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.showStepNumber
                ? '첫 번째 사물의 크기를 입력하세요.\n입력하면 방 안에 바로 배치됩니다.'
                : widget.isEdit
                    ? '새 크기를 입력하세요.'
                    : '추가할 사물의 크기를 입력하세요.',
            style: TextStyle(
              color: t.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            _buildField(t, '이름', _nameCtrl, '예: 소파, 테이블',
                isText: true),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                    child:
                        _buildField(t, 'X (가로)', _xCtrl, '1.5')),
                const SizedBox(width: 10),
                Expanded(
                    child:
                        _buildField(t, 'Y (높이)', _yCtrl, '0.8')),
                const SizedBox(width: 10),
                Expanded(
                    child:
                        _buildField(t, 'Z (세로)', _zCtrl, '1.0')),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '단위: 미터 (m)',
              style: TextStyle(color: t.textSecondary, fontSize: 11),
            ),
          ],
        ),
      ),
      actions: [
        if (widget.isEdit || !widget.showStepNumber)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('취소', style: TextStyle(color: t.textSecondary)),
          ),
        SizedBox(
          width: (widget.isEdit || !widget.showStepNumber) ? null : double.infinity,
          child: ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: t.accent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
            ),
            child: Text(
              buttonText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildField(
    AppTheme t,
    String label,
    TextEditingController ctrl,
    String hint, {
    bool isText = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: t.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          keyboardType: isText
              ? TextInputType.text
              : const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: isText
              ? null
              : [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
          style: TextStyle(
            color: t.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          textAlign: isText ? TextAlign.start : TextAlign.center,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                TextStyle(color: t.textSecondary.withValues(alpha: 0.4)),
            filled: true,
            fillColor: t.cardBg,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: t.accent, width: 1.5),
            ),
          ),
          onSubmitted: (_) => _submit(),
        ),
      ],
    );
  }
}
