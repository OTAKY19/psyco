import 'package:flutter/material.dart';

class AppShadows {
  AppShadows._();

  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x142D1F7A),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> cardSm = [
    BoxShadow(
      color: Color(0x0D2D1F7A),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> elevated = [
    BoxShadow(
      color: Color(0x1A2D1F7A),
      blurRadius: 16,
      offset: Offset(0, 6),
    ),
  ];

  static const List<BoxShadow> button = [
    BoxShadow(
      color: Color(0x1A2D1F7A),
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> modal = [
    BoxShadow(
      color: Color(0x26000000),
      blurRadius: 24,
      offset: Offset(0, -8),
    ),
  ];

  static const List<BoxShadow> header = [
    BoxShadow(
      color: Color(0x0A2D1F7A),
      blurRadius: 10,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> ctaLg = [
    BoxShadow(
      color: Color(0x334A3ABA),
      blurRadius: 20,
      offset: Offset(0, 8),
      spreadRadius: -2,
    ),
  ];

  static const List<BoxShadow> cardHoverDarker = [
    BoxShadow(
      color: Color(0x1A1A1A2E),
      blurRadius: 16,
      offset: Offset(0, 6),
    ),
  ];
}
