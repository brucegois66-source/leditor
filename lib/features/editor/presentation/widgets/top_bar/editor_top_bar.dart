import 'package:flutter/material.dart';

class EditorTopBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onImport;
  final VoidCallback? onExport;
  final bool isLoading;
  final bool canExport;

  const EditorTopBar({
    super.key,
    required this.onImport,
    required this.onExport,
    required this.isLoading,
    required this.canExport,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF18181D),
      foregroundColor: Colors.white,
      title: const Text('Leditor'),
      actions: [
        ElevatedButton.icon(
          onPressed: isLoading ? null : onImport,
          icon: isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.file_upload_outlined),
          label: const Text('Importar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.blueGrey,
            disabledForegroundColor: Colors.white70,
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: !canExport || isLoading ? null : onExport,
          icon: const Icon(Icons.file_download_outlined),
          label: const Text('Exportar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: canExport
                ? Colors.blueAccent
                : Colors.grey.shade800,
            foregroundColor: canExport
                ? Colors.white
                : Colors.white38,
            disabledBackgroundColor: Colors.grey.shade800,
            disabledForegroundColor: Colors.white38,
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(width: 12),
      ],
    );
  }
}