// services/haptic_service.dart — HapticService 대응 (Flutter 내장 HapticFeedback).
import 'package:flutter/services.dart';

class HapticService {
  void vibrate() => HapticFeedback.mediumImpact();
  void success() => HapticFeedback.heavyImpact();
  void light() => HapticFeedback.selectionClick();
}
