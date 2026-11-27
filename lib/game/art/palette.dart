import 'dart:ui';

/// Diorama art palette (procedural placeholder art).
abstract final class Pal {
  // Ink & wood
  static const outline = Color(0xFF451A03);
  static const wallTop = Color(0xFF3D2212);
  static const wallBottom = Color(0xFF2A160B);
  static const groove = Color(0xFF241208);
  static const frameDark = Color(0xFF593014);
  static const frameLight = Color(0xFF9A5B2C);
  static const deskTopLight = Color(0xFF9A5B2C);
  static const deskTopDark = Color(0xFF6E3D1A);
  static const deskFrontTop = Color(0xFF593014);
  static const deskFrontBottom = Color(0xFF3B1E0B);
  static const deskEdge = Color(0xFFD97706);
  static const limb = Color(0xFF6B3D1E);
  static const limbDark = Color(0xFF4A2812);

  // Squirrel fur
  static const fur = Color(0xFFC26D38);
  static const furBelly = Color(0xFFFDE68A);
  static const furTail = Color(0xFF9A4E22);
  static const goldFur = Color(0xFFF59E0B);
  static const goldBelly = Color(0xFFFEF3C7);
  static const goldTail = Color(0xFFD97706);
  static const eye = Color(0xFF1C1917);
  static const cheek = Color(0xFFFB7185);
  static const scarf = Color(0xFFEF4444);
  static const scarfDark = Color(0xFF7F1D1D);
  static const scarfTail = Color(0xFFDC2626);

  // Acorns & metals
  static const acorn = Color(0xFFF59E0B);
  static const acornLine = Color(0xFF92400E);
  static const acornCap = Color(0xFF78350F);
  static const silver = Color(0xFFE2E8F0);
  static const silverLine = Color(0xFF64748B);
  static const gold = Color(0xFFFACC15);
  static const brass = Color(0xFFFBBF24);
  static const brassDark = Color(0xFFB45309);

  // Sky
  static const skyDay = [Color(0xFF7DD3FC), Color(0xFFBAE6FD), Color(0xFFFEF3C7)];
  static const skyFrost = [Color(0xFFBAE6FD), Color(0xFFE0F2FE), Color(0xFFF0F9FF)];
  static const skyTwilight = [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF7C2D12)];
  static const twilightInk = Color(0xFF1E1B4B);

  // Meadow
  static const hillBack = Color(0xFF86EFAC);
  static const hillFront = Color(0xFF4ADE80);
  static const canopyDark = Color(0xFF15803D);
  static const canopyMid = Color(0xFF16A34A);
  static const canopyLight = Color(0xFF22C55E);
  static const frostCanopyDark = Color(0xFF94A3B8);
  static const frostCanopyLight = Color(0xFFCBD5E1);
  static const snow = Color(0xFFF8FAFC);
  static const frostGround = Color(0xFFE2E8F0);

  // Fire
  static const fireOuter = Color(0xFFF97316);
  static const fireInner = Color(0xFFFDE047);
  static const fireGlow = Color(0xFFFBBF24);

  // Frost
  static const frostPane = Color(0xFFE0F2FE);
  static const frostEdge = Color(0xFFBAE6FD);

  // Cellar
  static const earthTop = Color(0xFF382010);
  static const earthBottom = Color(0xFF1E1007);
  static const root = Color(0xFF5A3418);
  static const rootDark = Color(0xFF3A2010);
  static const beam = Color(0xFF1C0F07);
  static const chuteShaft = Color(0xFF180D06);
  static const rail = Color(0xFF92400E);
  static const rung = Color(0xFFB45309);

  // Impulse sand
  static const sandSkip = Color(0xFF38BDF8);
  static const sandDownsize = Color(0xFF10B981);
  static const sandDiy = Color(0xFFF59E0B);
}
