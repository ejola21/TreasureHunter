// design_system/seg_btn_pair.dart — SwiftUI SegBtnPair 이식.
// 가로 2개 candy 버튼 segmented control. 선택 macaw + 비선택 swan2.
import 'package:flutter/material.dart';
import 'duo_tokens.dart';

class SegBtnPair<T> extends StatelessWidget {
  final T selection;
  final List<(T, String)> options;
  final ValueChanged<T> onChanged;
  const SegBtnPair({super.key, required this.selection, required this.options, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: DuoColors.swan2,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        for (final (val, label) in options)
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(val),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: val == selection ? DuoColors.macaw : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: val == selection
                      ? [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2))]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: DuoFonts.display, fontSize: 13,
                    color: val == selection ? Colors.white : DuoColors.eel2,
                  ),
                ),
              ),
            ),
          ),
      ]),
    );
  }
}
