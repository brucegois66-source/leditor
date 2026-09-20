import 'package:flutter/material.dart';

class EditorToolbar extends StatelessWidget {
  final int selectedIndex;

  const EditorToolbar({
    super.key,
    required this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      color: const Color(0xFF18181D),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _ToolbarButton(
            icon: Icons.content_cut,
            label: 'Cortar',
            selected: selectedIndex == 0,
          ),
          _ToolbarButton(
            icon: Icons.text_fields,
            label: 'Texto',
            selected: selectedIndex == 1,
          ),
          _ToolbarButton(
            icon: Icons.music_note,
            label: 'Áudio',
            selected: selectedIndex == 2,
          ),
          _ToolbarButton(
            icon: Icons.tune,
            label: 'Ajustes',
            selected: selectedIndex == 3,
          ),
        ],
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;

  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.deepPurpleAccent : Colors.white70;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}