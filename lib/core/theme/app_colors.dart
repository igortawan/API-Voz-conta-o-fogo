// ============================================================================
// app_colors.dart
// ----------------------------------------------------------------------------
// Paleta de cores centralizada do aplicativo Voz Contra o Fogo.
//
// Todas as cores do design system estão definidas aqui como constantes
// estáticas. Nunca utilize cores diretamente nos widgets (ex.: Color(0xFF…))
// — sempre referencie uma constante desta classe para facilitar futuras
// mudanças de tema ou modo escuro.
//
// Paleta principal: verde-floresta (#1B7A1B) inspirado na Caatinga piauiense.
// ============================================================================

import 'package:flutter/material.dart';

class AppColors {
  // ── Verdes principais ───────────────────────────────────────────────────────

  /// Verde primário escuro — cor principal do app, botões, ícones ativos.
  static const Color primary = Color(0xFF1B7A1B);

  /// Verde primário brilhante — usado em gradientes e destaques animados.
  static const Color primaryLight = Color(0xFF16E216);

  /// Verde médio — variante mais suave do primário para fundos e containers.
  static const Color primarySoft = Color(0xFF2E7D32);

  /// Verde acentuado — badges, indicadores ativos, efeitos de brilho.
  static const Color primaryGlow = Color(0xFF43A047);

  // ── Fundos e superfícies ────────────────────────────────────────────────────

  /// Fundo geral das telas (cinza-esverdeado muito claro).
  static const Color background = Color(0xFFF6F8F6);

  /// Superfície branca pura — cards, modais, bottom sheets.
  static const Color surface = Color(0xFFFFFFFF);

  /// Superfície com leve tonalidade verde — seções de destaque suave.
  static const Color surfaceVariant = Color(0xFFF1F8E9);

  // ── Textos ──────────────────────────────────────────────────────────────────

  /// Texto principal escuro — títulos e conteúdo primário.
  static const Color textDark = Color(0xFF1A1A1A);

  /// Texto médio — subtítulos e labels secundários.
  static const Color textMedium = Color(0xFF4A4A4A);

  /// Texto claro — placeholders, metadados, datas.
  static const Color textLight = Color(0xFF8A8A8A);

  // ── Status das denúncias ────────────────────────────────────────────────────
  // Usados nos badges de status nas listas de denúncias.

  /// Laranja — denúncia pendente, aguardando processamento.
  static const Color statusPending = Color(0xFFFF9800);

  /// Azul — denúncia enviada ao sistema, visível às autoridades.
  static const Color statusSent = Color(0xFF2196F3);

  /// Roxo — denúncia em análise pela autoridade responsável.
  static const Color statusAnalyzing = Color(0xFF9C27B0);

  /// Verde — denúncia atendida / ocorrência resolvida.
  static const Color statusAttended = Color(0xFF4CAF50);

  /// Vermelho — denúncia rejeitada (fora de área, duplicada, etc.).
  static const Color statusRejected = Color(0xFFF44336);

  // ── Alertas e emergências ────────────────────────────────────────────────────

  /// Vermelho de emergência — alertas críticos, incêndios urgentes.
  static const Color emergency = Color(0xFFD32F2F);

  /// Fundo claro para containers de emergência (vermelho 5%).
  static const Color emergencyLight = Color(0xFFFFEBEE);

  /// Laranja de alerta — risco moderado, avisos de seca.
  static const Color warning = Color(0xFFF57C00);

  /// Fundo claro para containers de aviso (laranja 5%).
  static const Color warningLight = Color(0xFFFFF3E0);

  // ── Sombras ─────────────────────────────────────────────────────────────────

  /// Sombra suave — elevação baixa (cards normais).
  static const Color shadow = Color(0x14000000); // 8% opacidade

  /// Sombra média — elevação alta (modais, FAB, bottom sheets).
  static const Color shadowMedium = Color(0x1F000000); // 12% opacidade

  // ── Divisores ────────────────────────────────────────────────────────────────

  /// Linha divisória esverdeada suave entre itens de lista.
  static const Color divider = Color(0xFFE8F5E9);
}
