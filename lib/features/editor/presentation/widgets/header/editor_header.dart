import 'package:flutter/material.dart';

class EditorHeader extends StatelessWidget {
  final bool compact;
  final VoidCallback onImport;
  final VoidCallback onExport;

  const EditorHeader({
    super.key,
    required this.compact,
    required this.onImport,
    required this.onExport,
  });

  static const Color bgSoft = Color(0xFF0B0B0B);
  static const Color brand = Color(0xFF7B5CFF);
  static const Color brand2 = Color(0xFF8A63FF);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: compact ? 62 : 70,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: bgSoft,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(7),
                gradient: const LinearGradient(
                  colors: [brand2, brand],
                ),
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 14,
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Luma editor',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            _HeaderAction(
              icon: Icons.file_download_outlined,
              label: compact ? '' : 'Importar',
              onTap: onImport,
            ),
            const SizedBox(width: 8),
            _HeaderAction(
              icon: Icons.ios_share_outlined,
              label: compact ? '' : 'Exportar',
              onTap: onExport,
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _HeaderAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final compact = label.isEmpty;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: compact ? 46 : 56,
        height: compact ? 46 : 56,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: compact ? 20 : 22,
            ),
            if (!compact) ...[
              const SizedBox(height: 3),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}