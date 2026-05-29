// main.dart — PlaySpot Flutter AR 스파이크 진입점 (Web 우선).
import 'package:flutter/material.dart';

import 'ar_overlay_view.dart';

void main() {
  runApp(const ArSpikeApp());
}

class ArSpikeApp extends StatelessWidget {
  const ArSpikeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'PlaySpot AR Spike',
      debugShowCheckedModeBanner: false,
      home: ArOverlayView(),
    );
  }
}
