// test/golden/hud_goldens_test.dart — 핵심 HUD/팝업 픽셀 회귀.
// SwiftUI 원본과 시각적으로 일치해야 할 위젯의 정적 스냅샷 5개.
// 첫 생성: `flutter test --update-goldens test/golden/`
// 회귀 검증: `flutter test test/golden/`
import 'package:flutter/material.dart';
import 'package:flutter_ar_spike/design_system/play_hud.dart';
import 'package:flutter_ar_spike/game/play_alert.dart';
import 'package:flutter_ar_spike/features/play/popups.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _stage(Widget child, {Color bg = Colors.black, double w = 360, double h = 200}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: bg,
      body: Center(child: SizedBox(width: w, height: h, child: child)),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('BearingRadarDisc — heading 0° + item 90° (north-up: 바늘 동쪽)', (tester) async {
    await tester.pumpWidget(_stage(
      const SizedBox(width: 76, height: 76,
        child: BearingRadarDisc(headingDegrees: 0, itemBearingDegrees: 90)),
      w: 76, h: 76,
    ));
    await tester.pump(const Duration(milliseconds: 100));
    await expectLater(
      find.byType(BearingRadarDisc),
      matchesGoldenFile('goldens/radar_disc_h0_i90.png'),
    );
  });

  testWidgets('BearingRadarDisc — heading 45° + 바늘 없음 (Stealth/후보 없음)', (tester) async {
    await tester.pumpWidget(_stage(
      const SizedBox(width: 76, height: 76,
        child: BearingRadarDisc(headingDegrees: 45)),
      w: 76, h: 76,
    ));
    await expectLater(
      find.byType(BearingRadarDisc),
      matchesGoldenFile('goldens/radar_disc_h45_noitem.png'),
    );
  });

  testWidgets('MapBottomBar — 지뢰 2 / 필수 4 / HIDDEN 1 / STEALTH 0 + 카메라', (tester) async {
    await tester.pumpWidget(_stage(
      MapBottomBar(
        mineCount: 2, mandatoryRemaining: 4,
        hiddenCount: 1, stealthCount: 0,
        onCamera: () {},
      ),
      bg: Colors.white, w: 360, h: 90,
    ));
    await expectLater(
      find.byType(MapBottomBar),
      matchesGoldenFile('goldens/map_bottom_bar.png'),
    );
  });

  testWidgets('RadarPillHUD — END 12m / 부유 레이더 / 반경 50m', (tester) async {
    await tester.pumpWidget(_stage(
      RadarPillHUD(
        leftLabel: 'END', leftValue: '12m',
        rightLabel: '반경', rightValue: '50m',
        radar: const BearingRadarDisc(headingDegrees: 0, itemBearingDegrees: 30),
      ),
      bg: Colors.black, w: 360, h: 100,
    ));
    await expectLater(
      find.byType(RadarPillHUD),
      matchesGoldenFile('goldens/radar_pill_hud.png'),
    );
  });

  testWidgets('ItemAcquiredPopup — Defense 획득 (SwiftUI 문구 1:1)', (tester) async {
    bool ok = false;
    await tester.pumpWidget(_stage(
      ItemAcquiredPopup(
        alert: const ItemAcquiredAlert(
          title: 'Defence Item acquired!',
          message: 'Mine damage can be avoided using this Defence item.',
          itemIconName: '', // 폴백 아이콘
        ),
        onOK: () => ok = true,
      ),
      bg: const Color(0x88000000), w: 360, h: 420,
    ));
    // pop 애니메이션이 끝날 시간 (500ms elasticOut + 안정화).
    await tester.pump(const Duration(milliseconds: 700));
    await expectLater(
      find.byType(ItemAcquiredPopup),
      matchesGoldenFile('goldens/popup_defense.png'),
    );
    expect(ok, isFalse); // 탭 안 했으니
  });
}
