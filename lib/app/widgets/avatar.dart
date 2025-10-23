import 'package:flutter/material.dart';

class CircleAvatarPlaceholder extends StatelessWidget {
  const CircleAvatarPlaceholder({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase();
    return CircleAvatar(
      radius: 24,
      child: Text(initials),
    );
  }
}
