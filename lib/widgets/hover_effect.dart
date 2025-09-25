import 'package:flutter/material.dart';

class HoverEffect extends StatefulWidget {
  final Widget child;
  const HoverEffect({super.key, required this.child});

  @override
  State<HoverEffect> createState() => _HoverEffectState();
}

class _HoverEffectState extends State<HoverEffect> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 200),
        scale: _hovering ? 1.05 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            boxShadow: _hovering
                ? [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 12,
                offset: const Offset(0, 6),
              )
            ]
                : [],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}