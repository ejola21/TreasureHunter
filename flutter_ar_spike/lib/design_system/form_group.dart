// design_system/form_group.dart — DuoTokens 풍 흰 카드 그룹 + 행 (FormGroup/FormRow 이식).
import 'package:flutter/material.dart';
import 'duo_tokens.dart';

/// 섹션 제목(kicker) + 흰 라운드 카드로 자식들을 묶는 그룹.
class FormGroup extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final List<Widget> children;
  const FormGroup({super.key, this.title, this.subtitle, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(
              title!.toUpperCase(),
              style: const TextStyle(
                fontFamily: DuoFonts.display,
                fontSize: 11,
                letterSpacing: 0.6,
                color: DuoColors.hare,
              ),
            ),
          ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(DuoRadius.lg),
            border: Border.all(color: DuoColors.swan2, width: 2),
          ),
          child: Column(children: children),
        ),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 6),
            child: Text(
              subtitle!,
              style: const TextStyle(fontSize: 12, color: DuoColors.hare),
            ),
          ),
      ],
    );
  }
}

/// FormGroup 내부 행 — 라벨 + 값/트레일링.
class FormRow extends StatelessWidget {
  final String label;
  final String? value;
  final Widget? trailing;
  final bool isLast;
  final bool muted;
  final VoidCallback? onTap;
  const FormRow({
    super.key,
    required this.label,
    this.value,
    this.trailing,
    this.isLast = false,
    this.muted = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: DuoFonts.display,
                      fontSize: 14,
                      color: muted ? DuoColors.hare : DuoColors.eel2,
                    ),
                  ),
                ),
                if (value != null)
                  Text(value!, style: const TextStyle(fontSize: 13, color: DuoColors.hare)),
                ?trailing,
              ],
            ),
          ),
        ),
        if (!isLast)
          Container(height: 1, margin: const EdgeInsets.only(left: 14), color: DuoColors.swan),
      ],
    );
  }
}
