import 'package:flutter/material.dart';
import 'package:blockies/blockies.dart';

class BlockyAvatar extends StatelessWidget {
  final String seed;
  final double size;
  const BlockyAvatar({super.key, required this.seed, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: ClipOval(child: Blockies(seed: seed, size: 8)),
    );
  }
}
