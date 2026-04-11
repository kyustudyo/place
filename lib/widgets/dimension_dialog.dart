import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/app_theme.dart';

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

class DimensionDialog extends StatefulWidget {
  final AppTheme theme;
  final String? initialName;
  final double? initialX;
  final double? initialY;
  final double? initialZ;
  final bool isEdit;

  const DimensionDialog({
    super.key,
    required this.theme,
    this.initialName,
    this.initialX,
    this.initialY,
    this.initialZ,
    this.isEdit = false,
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
    _nameCtrl = TextEditingController(
        text: widget.initialName ?? '');
    _xCtrl = TextEditingController(
        text: widget.initialX?.toString() ?? '1.5');
    _yCtrl = TextEditingController(
        text: widget.initialY?.toString() ?? '0.8');
    _zCtrl = TextEditingController(
        text: widget.initialZ?.toString() ?? '1.0');
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

    if (x == null || y == null || z == null || x <= 0 || y <= 0 || z <= 0) {
      return;
    }

    final name = _nameCtrl.text.trim().isEmpty
        ? '가구'
        : _nameCtrl.text.trim();

    Navigator.pop(
      context,
      DimensionResult(name: name, x: x, y: y, z: z),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;

    return AlertDialog(
      backgroundColor: t.headerBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(
            widget.isEdit ? Icons.edit : Icons.add_box_rounded,
            color: t.accent,
            size: 22,
          ),
          const SizedBox(width: 10),
          Text(
            widget.isEdit ? '크기 수정' : '가구 추가',
            style: TextStyle(
              color: t.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildField(t, '이름', _nameCtrl, '예: 소파, 테이블',
                isText: true),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                    child: _buildField(t, 'X (가로)', _xCtrl, '1.5')),
                const SizedBox(width: 10),
                Expanded(
                    child: _buildField(t, 'Y (높이)', _yCtrl, '0.8')),
                const SizedBox(width: 10),
                Expanded(
                    child: _buildField(t, 'Z (세로)', _zCtrl, '1.0')),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '단위: 미터 (m)',
              style: TextStyle(color: t.textSecondary, fontSize: 11),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('취소', style: TextStyle(color: t.textSecondary)),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: t.accent,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: Text(
            widget.isEdit ? '수정' : '추가',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600),
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
        Text(
          label,
          style: TextStyle(
            color: t.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          keyboardType:
              isText ? TextInputType.text : const TextInputType.numberWithOptions(decimal: true),
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
            hintStyle: TextStyle(color: t.textSecondary.withValues(alpha: 0.5)),
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
