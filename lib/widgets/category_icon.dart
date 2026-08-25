import 'package:flutter/material.dart';

import '../utils/icon_catalog.dart';

class CategoryIconAvatar extends StatelessWidget {
  final String iconKey;
  final int color;
  final double size;

  const CategoryIconAvatar({
    super.key,
    required this.iconKey,
    required this.color,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    final c = Color(color);
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: c.withValues(alpha: 0.15),
      child: Icon(IconCatalog.iconFor(iconKey), color: c, size: size * 0.5),
    );
  }
}
