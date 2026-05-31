// features/design/item_picker_sheet.dart — SwiftUI ItemPickerView.swift 1:1 이식 (172줄).
// 다크 toolbar(CANCEL / "ITEM · DISPLAY · VISIBLE RANGE" / DONE) +
// 선택 미리보기 카드(아이콘 + 라벨 + Display 칩 + Range 칩 + helpText) +
// 3-컬럼 휠 picker (Item 45% / Display 30% / Range 25%).
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../design_system/duo_tokens.dart';
import '../../models/item_type.dart';
import '../../models/item_type_detail.dart';
import '../../models/show_type.dart';

/// SwiftUI ItemPickerView.pickableTypes 와 동일 순서 + 동일 15개.
/// timeoutEnd 는 timeoutStart 배치 시 자동 페어링이라 picker 에 없음.
const _pickableTypes = [
  ItemType.start, ItemType.end, ItemType.simple, ItemType.quiz,
  ItemType.random, ItemType.timeoutStart,
  ItemType.mine, ItemType.black, ItemType.mineNoBomb,
  ItemType.solution, ItemType.coupon, ItemType.store,
  ItemType.radarAR, ItemType.radarMap, ItemType.radarMine,
];

/// SwiftUI ItemPickerView.rangePresets — 레거시 AppDelegate.rangeAR 동일.
const _rangePresets = [10, 20, 30, 40, 50, 60, 70, 80, 100, 150, 200, 300, 500];

class ItemPickerResult {
  final ItemType type;
  final ShowType showType;
  final int rangeAR;
  const ItemPickerResult({required this.type, required this.showType, required this.rangeAR});
}

class ItemPickerSheet extends StatefulWidget {
  final ItemType initialType;
  final ShowType initialShow;
  final int initialRange;
  const ItemPickerSheet({
    super.key,
    this.initialType = ItemType.start,
    this.initialShow = ShowType.all,
    this.initialRange = 30,
  });

  @override
  State<ItemPickerSheet> createState() => _ItemPickerSheetState();
}

class _ItemPickerSheetState extends State<ItemPickerSheet> {
  late ItemType _type = widget.initialType;
  late ShowType _show = widget.initialShow;
  late int _range = widget.initialRange;

  static const _show3 = ShowType.selectableCases; // Visible/Hidden/Stealth

  @override
  Widget build(BuildContext context) {
    return Container(
      color: DuoColors.snow,
      child: SafeArea(
        top: false,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _toolbarHeader(),
          _previewHeader(),
          SizedBox(height: 200, child: _wheelRow()),
        ]),
      ),
    );
  }

  /// 다크 toolbar — CANCEL (좌, 흰색 85%) / 가운데 라벨 (75%) / DONE (우, bee).
  Widget _toolbarHeader() {
    return Container(
      color: const Color(0xFF3D3D3D),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Text('CANCEL',
              style: TextStyle(
                  fontFamily: DuoFonts.display, fontSize: 11, letterSpacing: 0.66,
                  color: Colors.white.withValues(alpha: 0.85))),
        ),
        Expanded(
          child: Center(
            child: Text('ITEM · DISPLAY · VISIBLE RANGE',
                style: TextStyle(
                    fontFamily: DuoFonts.display, fontSize: 9, letterSpacing: 0.5,
                    color: Colors.white.withValues(alpha: 0.75))),
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.pop(context,
              ItemPickerResult(type: _type, showType: _show, rangeAR: _range)),
          child: const Text('DONE',
              style: TextStyle(
                  fontFamily: DuoFonts.display, fontSize: 11, letterSpacing: 0.66, color: DuoColors.bee)),
        ),
      ]),
    );
  }

  /// 흰 카드 — 선택된 아이템 핀 48 + 라벨 + Display 칩(blue) + Range 칩(green) + helpText.
  Widget _previewHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        // 핀 48 - real PNG asset
        Image.asset(
          _type.mapIcon(mandatory: false),
          width: 48, height: 48,
          errorBuilder: (_, _, _) => Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: DuoColors.swan2, shape: BoxShape.circle),
            child: const Icon(Icons.help_outline, color: DuoColors.eel2, size: 24),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_type.displayLabel,
                style: const TextStyle(fontFamily: DuoFonts.display, fontSize: 16, color: DuoColors.eel2)),
            const SizedBox(height: 4),
            // 아이템 설명 — Help 화면 detailGuide.effect 와 동일. 이름 바로 아래.
            Text(_type.detailGuide.effect,
                style: const TextStyle(fontSize: 12, color: DuoColors.wolf2, fontWeight: FontWeight.w600),
                maxLines: 3, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            Row(children: [
              _chip(_show.displayName, DuoColors.macawBg, DuoColors.macawDeep),
              const SizedBox(width: 6),
              _chip('$_range m', DuoColors.green100, DuoColors.green800),
            ]),
            const SizedBox(height: 4),
            // 표시 방식 보조 설명 (회색 보조).
            Text(_show.helpText,
                style: const TextStyle(fontSize: 11, color: DuoColors.hare), maxLines: 1, overflow: TextOverflow.ellipsis),
          ]),
        ),
      ]),
    );
  }

  Widget _chip(String text, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
        child: Text(text,
            style: TextStyle(fontFamily: DuoFonts.display, fontSize: 10, color: fg)),
      );

  /// 3-컬럼 휠 — Item 45% / Display 30% / Range 25%. CupertinoPicker 로 wheel 느낌.
  Widget _wheelRow() {
    return LayoutBuilder(builder: (_, c) {
      return Row(children: [
        // Item picker — 45% 폭.
        SizedBox(
          width: c.maxWidth * 0.45,
          child: CupertinoPicker(
            itemExtent: 32,
            scrollController: FixedExtentScrollController(initialItem: _pickableTypes.indexOf(_type)),
            onSelectedItemChanged: (i) => setState(() => _type = _pickableTypes[i]),
            children: [for (final t in _pickableTypes) Center(child: Text(t.displayLabel, style: const TextStyle(fontSize: 17)))],
          ),
        ),
        // Display picker — 30%.
        SizedBox(
          width: c.maxWidth * 0.30,
          child: CupertinoPicker(
            itemExtent: 32,
            scrollController: FixedExtentScrollController(initialItem: _show3.indexOf(_show)),
            onSelectedItemChanged: (i) => setState(() => _show = _show3[i]),
            children: [for (final s in _show3) Center(child: Text(s.displayName, style: const TextStyle(fontSize: 17)))],
          ),
        ),
        // Range picker — 25%.
        SizedBox(
          width: c.maxWidth * 0.25,
          child: CupertinoPicker(
            itemExtent: 32,
            scrollController: FixedExtentScrollController(
                initialItem: _rangePresets.indexOf(_range).clamp(0, _rangePresets.length - 1)),
            onSelectedItemChanged: (i) => setState(() => _range = _rangePresets[i]),
            children: [for (final r in _rangePresets) Center(child: Text('$r', style: const TextStyle(fontSize: 17)))],
          ),
        ),
      ]);
    });
  }
}

/// 빌더에서 호출하는 헬퍼 — sheet 띄우고 결과 반환.
Future<ItemPickerResult?> showItemPickerSheet(
  BuildContext context, {
  ItemType initialType = ItemType.start,
  ShowType initialShow = ShowType.all,
  int initialRange = 30,
}) {
  return showModalBottomSheet<ItemPickerResult>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => ItemPickerSheet(
      initialType: initialType,
      initialShow: initialShow,
      initialRange: initialRange,
    ),
  );
}
