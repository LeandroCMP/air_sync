import 'package:flutter/material.dart';

extension ThemeExtension on BuildContext {
  // Base (dark)
  Color get themeBg => const Color(0xFF0F1216);
  Color get themeSurface => const Color(0xFF1A1F24);
  Color get themeSurfaceAlt => const Color(0xFF14181D);

  // Brand
  Color get themePrimary => const Color(0xFF00B686); // verde/ação
  Color get themeWarning => const Color(0xFFFFA15C); // pendências
  Color get themeInfo => const Color(0xFF4DA3FF);    // neutro/links

  // Texto
  Color get themeTextMain => const Color(0xFFF2F5F7);
  Color get themeTextSubtle => const Color(0xFFA9B2B9);

  // Bordas/sombras
  Color get themeBorder => const Color(0x15FFFFFF); // branco 8~10%
  List<BoxShadow> get shadowCard => [
        const BoxShadow(
          color: Color(0x29000000), // ~16% preto
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ];

  // Manter compat (originais)
  Color get themeDark => themeBg;
  Color get themeGray => themeSurface;
  Color get themeLightGray => const Color(0xFF363437);
  Color get themeGreen => const Color(0xFF73D941);
}
