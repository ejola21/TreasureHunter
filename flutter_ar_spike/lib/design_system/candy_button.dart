// design_system/candy_button.dart — Duolingo 풍 캔디 버튼 (아래 그림자 offset + press 시 눌림).
import 'package:flutter/material.dart';
import 'duo_tokens.dart';

class CandyButton extends StatefulWidget {
  final String label;
  final Color tint;
  final Color shadowColor;
  final Color fg;
  final VoidCallback? onPressed;
  const CandyButton({
    super.key,
    required this.label,
    this.tint = DuoColors.green500,
    this.shadowColor = DuoColors.green700,
    this.fg = Colors.white,
    this.onPressed,
  });

  @override
  State<CandyButton> createState() => _CandyButtonState();
}

class _CandyButtonState extends State<CandyButton> {
  bool _down = false;
  static const _depth = 4.0;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _down = true) : null,
      onTapUp: enabled ? (_) => setState(() => _down = false) : null,
      onTapCancel: enabled ? () => setState(() => _down = false) : null,
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        padding: EdgeInsets.only(top: _down ? _depth : 0, bottom: _down ? 0 : _depth),
        decoration: BoxDecoration(
          color: widget.shadowColor,
          borderRadius: BorderRadius.circular(DuoRadius.md),
        ),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: enabled ? widget.tint : DuoColors.swan,
            borderRadius: BorderRadius.circular(DuoRadius.md),
          ),
          child: Text(
            widget.label.toUpperCase(),
            style: TextStyle(
              fontFamily: DuoFonts.display,
              fontSize: 15,
              letterSpacing: 0.8,
              color: enabled ? widget.fg : DuoColors.hare,
            ),
          ),
        ),
      ),
    );
  }
}
