// ============================================================================
// app_theme.dart
// ----------------------------------------------------------------------------
// Definição do tema visual global do aplicativo (Material 3).
//
// O tema é aplicado no MaterialApp em main.dart via `theme: AppTheme.lightTheme`.
// Todos os componentes padrão do Flutter (AppBar, Button, TextField, Card…)
// herdam automaticamente estas definições — não é necessário estilizá-los
// individualmente nos widgets.
//
// Para adicionar um tema escuro no futuro, crie `darkTheme` aqui e passe-o
// também ao MaterialApp.
// ============================================================================

import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  /// Tema claro — único tema ativo no momento.
  /// Utiliza Material 3 com paleta baseada em [AppColors.primary] (verde-floresta).
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,

        // Cor de fundo padrão de todos os Scaffold
        scaffoldBackgroundColor: AppColors.background,
        primaryColor: AppColors.primary,

        // Esquema de cores gerado a partir da cor primária
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.primaryGlow,
          surface: AppColors.surface,
          error: AppColors.emergency,
        ),

        fontFamily: 'Roboto',

        // ── AppBar ───────────────────────────────────────────────────────────
        // Fundo branco, sem elevação, título centralizado e em negrito.
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textDark,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: AppColors.textDark,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        // ── Card ─────────────────────────────────────────────────────────────
        // Bordas arredondadas (16px), sem elevação padrão (sombra via BoxDecoration).
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),

        // ── ElevatedButton ────────────────────────────────────────────────────
        // Verde primário, texto branco, bordas em pill (40px), sem elevação.
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(40),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // ── OutlinedButton ────────────────────────────────────────────────────
        // Borda verde primária, texto verde.
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(40),
            ),
          ),
        ),

        // ── TextField / InputDecoration ───────────────────────────────────────
        // Fundo branco, bordas invisíveis por padrão, borda verde ao focar.
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(40),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(40),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(40),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        ),

        // ── BottomNavigationBar ───────────────────────────────────────────────
        // Item selecionado em verde, não selecionado em cinza claro.
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textLight,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
          showUnselectedLabels: true,
          selectedLabelStyle: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),

        // ── SnackBar ──────────────────────────────────────────────────────────
        // Flutuante com bordas arredondadas.
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),

        // ── Switch ────────────────────────────────────────────────────────────
        // Thumb verde quando ativado, track verde claro translúcido.
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? AppColors.primary : null,
          ),
          trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? AppColors.primaryLight.withValues(alpha: 0.5)
                : null,
          ),
        ),
      );
}
