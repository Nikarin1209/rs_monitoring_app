import 'package:flutter/material.dart';

// NeuroLife — warm pastel design tokens
abstract class NLColors {
  static const bg = Color(0xFFFAF7F2);
  static const surface = Color(0xFFFFFFFF);
  static const surface2 = Color(0xFFF2EEE7);
  static const ink = Color(0xFF1F1B16);
  static const ink2 = Color(0xFF4A4338);
  static const muted = Color(0xFF857C72);

  static const accent = Color(0xFF7B6BE8);
  static const accentSoft = Color(0xFFE8E4FB);
  static const peach = Color(0xFFF4B59A);
  static const peachSoft = Color(0xFFFCE6DA);
  static const mint = Color(0xFFA8D5BA);
  static const mintSoft = Color(0xFFDEF1E5);
  static const sky = Color(0xFFB8CFEA);
  static const skySoft = Color(0xFFE2EBF6);
  static const rose = Color(0xFFE89BAA);
  static const roseSoft = Color(0xFFF8E0E5);

  static const good = Color(0xFF6FBF8C);
  static const warn = Color(0xFFE8B86F);
  static const bad = Color(0xFFD9785C);

  static const line = Color(0x141F1B16);   // rgba(31,27,22,0.08)
  static const line2 = Color(0x0A1F1B16);  // rgba(31,27,22,0.04)
}

abstract class NLRadius {
  static const sm = Radius.circular(10);
  static const md = Radius.circular(14);
  static const lg = Radius.circular(20);
  static const xl = Radius.circular(28);
  static const pill = Radius.circular(999);
}

final shadowCard = [
  BoxShadow(color: Color(0x0A1F1B16), blurRadius: 2, offset: Offset(0, 1)),
  BoxShadow(color: Color(0x0D1F1B16), blurRadius: 24, offset: Offset(0, 8)),
];

ThemeData nlTheme() {
  return ThemeData(
    useMaterial3: true,
    fontFamily: 'SF Pro Text',
    scaffoldBackgroundColor: NLColors.bg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: NLColors.accent,
      brightness: Brightness.light,
    ).copyWith(
      surface: NLColors.bg,
      primary: NLColors.accent,
    ),
  );
}
