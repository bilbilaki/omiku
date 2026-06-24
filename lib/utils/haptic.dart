import 'dart:io';

import 'package:flutter/services.dart';

void triggerVibration() {
    if (Platform.isAndroid) {
      HapticFeedback.lightImpact();
    }
  }
void tVheavy() {
    if (Platform.isAndroid) {
      HapticFeedback.heavyImpact();
    }
  }
void tVmedium() {
    if (Platform.isAndroid) {
      HapticFeedback.mediumImpact();
    }
  }
void tVClick() {
    if (Platform.isAndroid) {
      HapticFeedback.selectionClick();
    }
  }
