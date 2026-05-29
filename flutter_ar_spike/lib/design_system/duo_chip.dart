// design_system/duo_chip.dart — DuoTokens.swift DuoChip 이식 (캡슐형 라벨).
import 'package:flutter/material.dart';
import 'duo_tokens.dart';

class DuoChip extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const DuoChip(this.label, {super.key, required this.bg, required this.fg});

  factory DuoChip.green(String l) =>
      DuoChip(l, bg: DuoColors.green100, fg: DuoColors.green800);
  factory DuoChip.red(String l) =>
      DuoChip(l, bg: DuoColors.cardinalBg, fg: DuoColors.cardinalDeep);
  factory DuoChip.orange(String l) =>
      DuoChip(l, bg: DuoColors.foxBg, fg: DuoColors.foxDeep);
  factory DuoChip.yellow(String l) =>
      DuoChip(l, bg: DuoColors.beeBg, fg: DuoColors.beeDeep);
  factory DuoChip.blue(String l) =>
      DuoChip(l, bg: DuoColors.macawBg, fg: DuoColors.macawDeep);
  factory DuoChip.purple(String l) =>
      DuoChip(l, bg: const Color(0xFFF1DCFF), fg: DuoColors.beetleDeep);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(13)),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontFamily: DuoFonts.display,
          fontSize: 11,
          letterSpacing: 0.5,
          color: fg,
        ),
      ),
    );
  }
}
