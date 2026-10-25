import 'package:flutter/material.dart';

/// Shared colour constants for the DocScam app.
///
/// Centralising magic hex values here means a re-theme is a one-file change
/// and every screen uses semantically named references instead of raw numbers.
abstract final class AppColors {
  // ── Backgrounds ────────────────────────────────────────────────────────────
  static const Color bgDark         = Color(0xFF2C0038); // darkest background
  static const Color bgDeepPurple   = Color(0xFF39003D); // landing-screen gradient
  static const Color bgMid          = Color(0xFF4B0059); // mid gradient / blob base
  static const Color bgLightPurple  = Color(0xFF60007A); // landing gradient end
  static const Color screenGradStart = Color(0xFF6B2CA4); // quiz / home bg start

  // ── Header / card gradients ────────────────────────────────────────────────
  static const Color headerTop    = Color(0xFFB46BF2); // header gradient top
  static const Color headerBottom = Color(0xFF4B0F67); // header gradient bottom

  // ── Accents ────────────────────────────────────────────────────────────────
  static const Color seedPurple = Color(0xFF7A00A6); // Material theme seed
  static const Color blobPurple = Color(0xFF8A2BE2); // decorative blobs
  static const Color ctaRed     = Color(0xFFFF3B2E); // primary CTA button

  // ── Quiz tile colours ──────────────────────────────────────────────────────
  static const Color selectedOption = Color(0xFF303F9F); // selected answer tile
  static const Color buttonDark     = Color(0xFF2F2F2F); // next / finish button

  // ── Result / history indicators ────────────────────────────────────────────
  static const Color correctGreen = Color(0xFF1B5E20); // correct answer
  static const Color incorrectRed = Color(0xFFB71C1C); // incorrect / destructive
  static const Color warningAmber = Color(0xFFFFB300); // partial score
  static const Color historyRed   = Color(0xFFD32F2F); // poor-score history icon
}
