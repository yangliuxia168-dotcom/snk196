import 'package:flutter/material.dart';
import '../../../ui/theme/app_theme.dart';

/// 通用头像组件
class AvatarWidget extends StatelessWidget {
  final String? url;
  final String name;
  final double size;
  final bool isGroup;

  const AvatarWidget({
    super.key,
    this.url,
    required this.name,
    this.size = 40,
    this.isGroup = false,
  });

  @override
  Widget build(BuildContext context) {
    if (url != null && url!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(isGroup ? size * 0.2 : size * 0.5),
        child: Image.network(
          url!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildDefault(),
        ),
      );
    }
    return _buildDefault();
  }

  Widget _buildDefault() {
    final colors = [
      const Color(0xFF1890FF),
      const Color(0xFF52C41A),
      const Color(0xFFFAAD14),
      const Color(0xFFFA541C),
      const Color(0xFF722ED1),
      const Color(0xFF13C2C2),
      const Color(0xFFEB2F96),
    ];
    
    final colorIndex = name.isEmpty ? 0 : name.codeUnitAt(0) % colors.length;
    final displayChar = name.isEmpty ? '?' : name.characters.first;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors[colorIndex],
        borderRadius: BorderRadius.circular(isGroup ? size * 0.2 : size * 0.5),
      ),
      child: Center(
        child: Text(
          displayChar,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
