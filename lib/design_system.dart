import 'package:flutter/material.dart';

/// CHAKCHAK의 공식 의미 색상 토큰.
abstract final class ChakchakColors {
  static const brandPrimary = Color(0xFF007C67);
  static const canvas = Color(0xFFFFFCF8);
  static const surface = Color(0xFFFFFFFF);
  static const brandSubtle = Color(0xFFEAF9F5);

  static const textPrimary = Color(0xFF000000);
  static const textStrongSecondary = Color(0xFF202A38);
  static const textDisabled = Color(0xFF9C9DA1);
  static const textNavInactive = Color(0xFF020202);

  static const borderDefault = Color(0xFFE6E9F2);
  static const borderSubtle = Color(0xFFE2E8E6);
  static const borderBrandSubtle = Color(0xFFB8E7DA);

  static const disabledFill = Color(0xFF9C9DA1);
  static const disabledText = Color(0xFFD8D8D8);
}

abstract final class ChakchakSpacing {
  static const xxs = 2.0;
  static const xs = 4.0;
  static const sm = 8.0;
  static const iconGap = 10.0;
  static const md = 12.0;
  static const controlVertical = 14.0;
  static const controlHorizontal = 16.0;
  static const lg = 20.0;
  static const section = 30.0;
  static const sectionLarge = 40.0;
}

abstract final class ChakchakRadii {
  static const controlSmall = 4.0;
  static const medium = 10.0;
  static const control = 14.0;
  static const card = 20.0;
  static const full = 999.0;
}

abstract final class ChakchakTypography {
  static const weather = TextStyle(
    fontFamily: 'Paperlogy',
    fontSize: 56,
    fontWeight: FontWeight.w800,
    height: 1,
    letterSpacing: -2.8,
    color: ChakchakColors.textPrimary,
  );
  static const hero = TextStyle(
    fontFamily: 'Paperlogy',
    fontSize: 30,
    fontWeight: FontWeight.w700,
    height: 1,
    color: ChakchakColors.textPrimary,
  );
  static const section = TextStyle(
    fontFamily: 'Paperlogy',
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1,
    color: ChakchakColors.textPrimary,
  );
  static const card = TextStyle(
    fontFamily: 'Paperlogy',
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1,
    color: ChakchakColors.textPrimary,
  );
  static const bodyStrong = TextStyle(
    fontFamily: 'Paperlogy',
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1,
    color: ChakchakColors.textPrimary,
  );
  static const body = TextStyle(
    fontFamily: 'Paperlogy',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1,
    color: ChakchakColors.textPrimary,
  );
  static const bodyLight = TextStyle(
    fontFamily: 'Paperlogy',
    fontSize: 16,
    fontWeight: FontWeight.w300,
    height: 1,
    color: ChakchakColors.textPrimary,
  );
  static const label = TextStyle(
    fontFamily: 'Paperlogy',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1,
    color: ChakchakColors.textPrimary,
  );
  static const labelStrong = TextStyle(
    fontFamily: 'Paperlogy',
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1,
    color: ChakchakColors.textPrimary,
  );
  static const caption = TextStyle(
    fontFamily: 'Paperlogy',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1,
    color: ChakchakColors.textPrimary,
  );
  static const nav = TextStyle(
    fontFamily: 'Paperlogy',
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1,
    color: ChakchakColors.textNavInactive,
  );
}

abstract final class ChakchakTheme {
  static ThemeData light() {
    const colorScheme = ColorScheme.light(
      primary: ChakchakColors.brandPrimary,
      onPrimary: Colors.white,
      secondary: ChakchakColors.brandPrimary,
      onSecondary: Colors.white,
      surface: ChakchakColors.surface,
      onSurface: ChakchakColors.textPrimary,
      outline: ChakchakColors.borderDefault,
      outlineVariant: ChakchakColors.borderSubtle,
    );

    const controlShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(
        Radius.circular(ChakchakRadii.control),
      ),
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Paperlogy',
      scaffoldBackgroundColor: ChakchakColors.canvas,
      canvasColor: ChakchakColors.canvas,
      colorScheme: colorScheme,
      dividerColor: ChakchakColors.borderSubtle,
      splashColor: ChakchakColors.brandPrimary.withValues(alpha: .08),
      highlightColor: ChakchakColors.brandPrimary.withValues(alpha: .05),
      textTheme: const TextTheme(
        displayLarge: ChakchakTypography.weather,
        displayMedium: ChakchakTypography.hero,
        headlineLarge: ChakchakTypography.hero,
        headlineMedium: ChakchakTypography.section,
        titleLarge: ChakchakTypography.section,
        titleMedium: ChakchakTypography.card,
        titleSmall: ChakchakTypography.bodyStrong,
        bodyLarge: ChakchakTypography.body,
        bodyMedium: ChakchakTypography.body,
        bodySmall: ChakchakTypography.caption,
        labelLarge: ChakchakTypography.bodyStrong,
        labelMedium: ChakchakTypography.labelStrong,
        labelSmall: ChakchakTypography.caption,
      ),
      iconTheme: const IconThemeData(
        size: 24,
        color: ChakchakColors.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        toolbarHeight: 56,
        backgroundColor: ChakchakColors.canvas,
        foregroundColor: ChakchakColors.textPrimary,
        surfaceTintColor: ChakchakColors.canvas,
        titleTextStyle: ChakchakTypography.section,
        iconTheme: IconThemeData(
          size: 24,
          color: ChakchakColors.textPrimary,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size.square(48),
          iconSize: 24,
          foregroundColor: ChakchakColors.textPrimary,
          shape: controlShape,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(
            horizontal: ChakchakSpacing.iconGap,
            vertical: ChakchakSpacing.controlVertical,
          ),
          backgroundColor: ChakchakColors.brandPrimary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: ChakchakColors.disabledFill,
          disabledForegroundColor: ChakchakColors.disabledText,
          textStyle: ChakchakTypography.bodyStrong,
          shape: controlShape,
          side: const BorderSide(color: ChakchakColors.borderSubtle),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(
            horizontal: ChakchakSpacing.iconGap,
            vertical: ChakchakSpacing.controlVertical,
          ),
          backgroundColor: ChakchakColors.surface,
          foregroundColor: ChakchakColors.textStrongSecondary,
          textStyle: ChakchakTypography.bodyStrong,
          shape: controlShape,
          side: const BorderSide(color: ChakchakColors.borderDefault),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: ChakchakColors.brandPrimary,
          textStyle: ChakchakTypography.labelStrong,
          shape: controlShape,
        ),
      ),
      cardTheme: const CardThemeData(
        margin: EdgeInsets.zero,
        color: ChakchakColors.surface,
        surfaceTintColor: ChakchakColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: ChakchakColors.borderDefault),
          borderRadius: BorderRadius.all(
            Radius.circular(ChakchakRadii.card),
          ),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(
          horizontal: ChakchakSpacing.controlHorizontal,
          vertical: ChakchakSpacing.xs,
        ),
        minTileHeight: 48,
        iconColor: ChakchakColors.textPrimary,
        textColor: ChakchakColors.textPrimary,
        titleTextStyle: ChakchakTypography.bodyStrong,
        subtitleTextStyle: ChakchakTypography.caption,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(ChakchakRadii.control),
          ),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: ChakchakColors.surface,
        contentPadding: EdgeInsets.symmetric(
          horizontal: ChakchakSpacing.controlHorizontal,
          vertical: ChakchakSpacing.md,
        ),
        hintStyle: ChakchakTypography.body,
        labelStyle: ChakchakTypography.bodyStrong,
        floatingLabelStyle: ChakchakTypography.bodyStrong,
        helperStyle: ChakchakTypography.caption,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(ChakchakRadii.control),
          ),
          borderSide: BorderSide(color: ChakchakColors.borderDefault),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(ChakchakRadii.control),
          ),
          borderSide: BorderSide(color: ChakchakColors.borderDefault),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(ChakchakRadii.control),
          ),
          borderSide: BorderSide(
            color: ChakchakColors.brandPrimary,
            width: 1.5,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(ChakchakRadii.control),
          ),
          borderSide: BorderSide(color: ChakchakColors.borderSubtle),
        ),
      ),
      chipTheme: const ChipThemeData(
        backgroundColor: ChakchakColors.surface,
        selectedColor: ChakchakColors.brandPrimary,
        disabledColor: ChakchakColors.surface,
        side: BorderSide(color: ChakchakColors.borderDefault),
        shape: StadiumBorder(),
        padding: EdgeInsets.symmetric(
          horizontal: ChakchakSpacing.controlHorizontal,
          vertical: ChakchakSpacing.sm,
        ),
        labelStyle: TextStyle(
          fontFamily: 'Paperlogy',
          fontSize: 15,
          fontWeight: FontWeight.w400,
          height: 1,
          color: ChakchakColors.textPrimary,
        ),
        secondaryLabelStyle: TextStyle(
          fontFamily: 'Paperlogy',
          fontSize: 15,
          fontWeight: FontWeight.w400,
          height: 1,
          color: Colors.white,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        materialTapTargetSize: MaterialTapTargetSize.padded,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ChakchakRadii.controlSmall),
        ),
        side: const BorderSide(color: ChakchakColors.borderDefault),
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? ChakchakColors.brandPrimary
              : ChakchakColors.surface,
        ),
        checkColor: const WidgetStatePropertyAll(Colors.white),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        height: 66,
        backgroundColor: ChakchakColors.surface,
        indicatorColor: Colors.transparent,
        labelTextStyle: WidgetStatePropertyAll(ChakchakTypography.nav),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: ChakchakColors.canvas,
        surfaceTintColor: ChakchakColors.canvas,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(ChakchakRadii.card),
          ),
        ),
        titleTextStyle: ChakchakTypography.section,
        contentTextStyle: ChakchakTypography.body,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: ChakchakColors.canvas,
        surfaceTintColor: ChakchakColors.canvas,
        elevation: 0,
        modalElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(ChakchakRadii.card),
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: ChakchakColors.brandPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(ChakchakRadii.control),
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : ChakchakColors.textDisabled,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? ChakchakColors.brandPrimary
              : ChakchakColors.borderSubtle,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
    );
  }
}

enum ChakchakButtonKind { main, sub, point }

/// 화면별 임의 스타일을 만들지 않도록 사용하는 48px 공용 버튼.
class ChakchakButton extends StatelessWidget {
  const ChakchakButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.kind = ChakchakButtonKind.main,
    this.leading,
  });

  final String label;
  final VoidCallback? onPressed;
  final ChakchakButtonKind kind;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final (background, foreground, border) = switch (kind) {
      ChakchakButtonKind.main => (
          enabled ? ChakchakColors.brandPrimary : ChakchakColors.disabledFill,
          enabled ? Colors.white : ChakchakColors.disabledText,
          ChakchakColors.borderSubtle,
        ),
      ChakchakButtonKind.sub => (
          ChakchakColors.surface,
          enabled
              ? ChakchakColors.textStrongSecondary
              : ChakchakColors.textDisabled,
          ChakchakColors.borderDefault,
        ),
      ChakchakButtonKind.point => (
          ChakchakColors.brandSubtle,
          enabled ? ChakchakColors.textPrimary : ChakchakColors.textDisabled,
          ChakchakColors.borderBrandSubtle,
        ),
    };

    return Semantics(
      button: true,
      enabled: enabled,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(ChakchakRadii.control),
          child: Ink(
            height: 48,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: ChakchakSpacing.iconGap,
              vertical: ChakchakSpacing.controlVertical,
            ),
            decoration: BoxDecoration(
              color: background,
              border: Border.all(color: border),
              borderRadius: BorderRadius.circular(ChakchakRadii.control),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: ChakchakSpacing.iconGap),
                ],
                Text(
                  label,
                  style: ChakchakTypography.bodyStrong.copyWith(
                    color: foreground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ChakchakRoundChip extends StatelessWidget {
  const ChakchakRoundChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(ChakchakRadii.card),
            child: Ink(
              height: 36,
              padding: const EdgeInsets.symmetric(
                horizontal: ChakchakSpacing.controlHorizontal,
                vertical: ChakchakSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: selected
                    ? ChakchakColors.brandPrimary
                    : ChakchakColors.surface,
                border: Border.all(
                  color: selected
                      ? ChakchakColors.brandPrimary
                      : ChakchakColors.borderDefault,
                ),
                borderRadius: BorderRadius.circular(ChakchakRadii.card),
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Paperlogy',
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  height: 1,
                ).copyWith(
                  color: selected ? Colors.white : ChakchakColors.textPrimary,
                ),
              ),
            ),
          ),
        ),
      );
}
