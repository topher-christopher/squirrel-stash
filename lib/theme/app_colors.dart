import 'dart:ui' show Color;

/// Warm oak, amber, emerald and frost color tokens shared by the UI and the
/// diorama. Values mirror the palette established in GEMINI_PROTOTYPE.txt.
abstract final class AppColors {
  // Night bark & oak wood
  static const night = Color(0xFF180E08);
  static const bark = Color(0xFF22130A);
  static const barkDeep = Color(0xFF1A0E07);
  static const walnut = Color(0xFF241308);
  static const plaque = Color(0xFF2A170B);
  static const oakDark = Color(0xFF3B1E0B);
  static const oak = Color(0xFF593014);
  static const oakMid = Color(0xFF6E3D1A);
  static const oakLight = Color(0xFF9A5B2C);
  static const ink = Color(0xFF451A03);

  // Amber, honey & brass
  static const amber = Color(0xFFF59E0B);
  static const amberDeep = Color(0xFFD97706);
  static const amberBright = Color(0xFFFBBF24);
  static const honey = Color(0xFFFDE68A);
  static const cream = Color(0xFFFEF3C7);
  static const parchment = Color(0xFFFFF7ED);
  static const brass = Color(0xFFB45309);
  static const rust = Color(0xFF92400E);
  static const umber = Color(0xFF78350F);

  // Emerald (free cash & success)
  static const emerald = Color(0xFF10B981);
  static const emeraldBright = Color(0xFF4ADE80);
  static const emeraldSoft = Color(0xFF6EE7B7);
  static const emeraldDeep = Color(0xFF14532D);
  static const emeraldButton = Color(0xFF059669);

  // Frost & sky
  static const frost = Color(0xFFBAE6FD);
  static const frostPale = Color(0xFFE0F2FE);
  static const frostWhite = Color(0xFFF0F9FF);
  static const sky = Color(0xFF38BDF8);
  static const skyDeep = Color(0xFF0369A1);

  // Signals
  static const ember = Color(0xFFF97316);
  static const flame = Color(0xFFFDE047);
  static const alert = Color(0xFFF87171);
  static const alertSoft = Color(0xFFFCA5A5);
  static const alertDeep = Color(0xFF7F1D1D);
  static const caution = Color(0xFFFACC15);
  static const cautionSoft = Color(0xFFFDE047);
  static const cautionDeep = Color(0xFF854D0E);
  static const leaf = Color(0xFFBEF264);
  static const stone = Color(0xFFD6D3D1);
  static const stoneDim = Color(0xFFA8A29E);
  static const stoneDeep = Color(0xFF292524);
  static const slate = Color(0xFFE2E8F0);
  static const slateDim = Color(0xFF94A3B8);

  // Impulse silo sand layers
  static const sandSkip = Color(0xFF38BDF8);
  static const sandDownsize = Color(0xFF10B981);
  static const sandDiy = Color(0xFFF59E0B);
}
