// ============================================================================
// login.page.dart
// ----------------------------------------------------------------------------
// Tela de login responsiva — ponto de entrada autenticado do app.
//
// Layouts adaptativos (via LayoutBuilder + breakpoints):
//   • _NarrowLayout   (<  600px) — celular: tela única com scroll
//   • _MediumLayout   (600–899px) — tablet retrato: formulário centralizado
//   • _WideLayout     (≥  900px) — tablet paisagem / desktop: dois painéis
//
// Funcionalidades:
//   • Login com e-mail + senha
//   • Cadastro de nova conta (toggle _isRegisterMode)
//   • Recuperação de senha (sendPasswordReset via AuthController)
//   • Login anônimo (convidado → NavigationPage sem cloud sync)
//
// Roteamento pós-login (_routeAfterLogin):
//   • role == 'admin'      → AdminPage
//   • role == 'autoridade' → AuthorityPage
//   • qualquer outro       → NavigationPage
//
// Estado gerenciado localmente no _LoginPageState:
//   • _emailController, _passwordController, _nameController — TextControllers
//   • _formKey — GlobalKey<FormState> para validação
//   • _obscurePassword — toggle de visibilidade da senha
//   • _isRegisterMode — alterna entre login e cadastro
//
// Observações de arquitetura:
//   • buildForm() e buildBrandPanel() são métodos PÚBLICOS de _LoginPageState
//     para que os widgets de layout (_NarrowLayout, etc.) possam chamá-los
//     diretamente, evitando duplicação de código de UI.
//   • ref.listen detecta erros do authControllerProvider e exibe SnackBar.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../services/api/auth_api_service.dart';
import '../../../../services/api/websocket_service.dart';
import '../../../admin/presentation/pages/admin_page.dart';
import '../../../authority/presentation/pages/authority_page.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../navigation_page.dart';

// ── Breakpoints de layout responsivo ─────────────────────────────────────────

/// Largura mínima para layout tablet retrato (formulário centralizado).
const _kTabletPortrait  = 600.0;

/// Largura mínima para layout tablet paisagem / desktop (dois painéis).
const _kTabletLandscape = 900.0;

// ── Widget principal ──────────────────────────────────────────────────────────

/// Tela de autenticação responsiva com 3 layouts adaptativos.
///
/// Usa [ConsumerStatefulWidget] pois precisa:
///   • Ler e escutar [authControllerProvider] (estado assíncrono do login)
///   • Manter estado local dos TextControllers, FormKey e flags de UI
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  // Controladores dos campos de texto
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController     = TextEditingController(); // usado apenas no modo cadastro

  /// Chave global do formulário — permite chamar _formKey.currentState!.validate()
  final _formKey = GlobalKey<FormState>();

  /// Controla visibilidade da senha no campo de texto
  bool _obscurePassword = true;

  /// Alterna entre modo de login (false) e modo de cadastro (true)
  bool _isRegisterMode  = false;

  @override
  void dispose() {
    // Libera recursos dos controllers para evitar memory leaks
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  // ── Ações de autenticação ─────────────────────────────────────────────────

  /// Executa login ou cadastro dependendo do modo atual.
  ///
  /// Fluxo:
  ///   1. Valida o formulário (campos obrigatórios, formato e-mail, tamanho senha)
  ///   2. Chama registerWithEmail ou signInWithEmail no AuthController
  ///   3. Se sucesso → _routeAfterLogin() detecta o papel e navega
  Future<void> _handleEmailLogin() async {
    if (!_formKey.currentState!.validate()) return;
    final ctrl = ref.read(authControllerProvider.notifier);
    final ok = _isRegisterMode
        ? await ctrl.registerWithEmail(
            _emailController.text, _passwordController.text, _nameController.text)
        : await ctrl.signInWithEmail(_emailController.text, _passwordController.text);
    if (ok && mounted) await _routeAfterLogin();
  }

  /// Determina a tela de destino a partir do role armazenado no JWT (secure storage).
  Future<void> _routeAfterLogin() async {
    if (!mounted) return;

    // Conecta WebSocket com token recém obtido
    WebSocketService.connect();

    final role = await AuthApiService.userRole;
    if (!mounted) return;

    final page = switch (role ?? 'cidadao') {
      AppConstants.roleAdmin     => const AdminPage(),
      AppConstants.roleAuthority => const AuthorityPage(),
      _                          => const NavigationPage(),
    };

    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => page));
  }

  /// Login anônimo — cria conta Firebase anônima, sem e-mail/senha.
  ///
  /// Usuários anônimos:
  ///   • Acessam NavigationPage normalmente
  ///   • Não têm dados salvos no Firestore (offline-only via Hive)
  ///   • Identificados por [AuthService.isAnonymous] == true
  Future<void> _handleAnonymous() async {
    final ok = await ref.read(authControllerProvider.notifier).signInAnonymously();
    if (ok && mounted) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const NavigationPage()));
    }
  }

  /// Envia e-mail de redefinição de senha para o endereço digitado.
  ///
  /// Exige que o campo de e-mail esteja preenchido antes de enviar.
  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showSnack('Digite seu e-mail para recuperar a senha.');
      return;
    }
    await ref.read(authControllerProvider.notifier).sendPasswordReset(email);
    _showSnack('E-mail de recuperação enviado!');
  }

  /// Exibe um [SnackBar] flutuante com a mensagem informada.
  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  /// Constrói o layout adaptativo baseado na largura disponível.
  ///
  /// [LayoutBuilder] fornece [constraints.maxWidth] para selecionar o layout.
  /// ref.listen captura erros do authControllerProvider e exibe SnackBar.
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    // Escuta mudanças de estado para exibir erros de autenticação via SnackBar
    ref.listen<AsyncValue<dynamic>>(authControllerProvider, (_, next) {
      if (next.hasError) _showSnack(next.error.toString());
    });

    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;

      // Tablet landscape / desktop → dois painéis lado a lado
      if (w >= _kTabletLandscape) return _WideLayout(state: this, isLoading: isLoading);

      // Tablet portrait → formulário centralizado com largura limitada
      if (w >= _kTabletPortrait)  return _MediumLayout(state: this, isLoading: isLoading);

      // Phone → tela única com scroll
      return _NarrowLayout(state: this, isLoading: isLoading);
    });
  }

  // ── Painel de marca (usado no layout wide) ────────────────────────────────

  /// Painel esquerdo com gradiente verde e identidade visual do projeto.
  ///
  /// Exibido apenas no [_WideLayout] (tablet paisagem / desktop).
  /// Contém logo, título "Voz Contra o Fogo", subtítulo e crédito IFPI/FAPEPI.
  /// Círculos decorativos posicionados nas bordas criam efeito visual de profundidade.
  Widget buildBrandPanel({double logoSize = 120}) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B7A1B), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Círculos decorativos semitransparentes nas bordas
          Positioned(top: -80, right: -80,
              child: _glowCircle(240)),
          Positioned(bottom: -100, left: -100,
              child: _glowCircle(300)),
          // Conteúdo centralizado: logo + textos
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Ícone de fogo dentro de círculo semitransparente
                  Container(
                    width: logoSize,
                    height: logoSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.15),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3), width: 2),
                    ),
                    child: Icon(Icons.local_fire_department,
                        color: Colors.white, size: logoSize * 0.52),
                  ),
                  const SizedBox(height: 28),
                  const Text('Voz Contra o Fogo',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3)),
                  const SizedBox(height: 10),
                  Text('Protegendo a Caatinga piauiense',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14)),
                  const SizedBox(height: 40),
                  // Crédito institucional em fonte menor
                  Text('IFPI • Campus Paulistana • FAPEPI',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 11,
                          letterSpacing: 1)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Círculo decorativo semitransparente usado nas bordas do painel de marca.
  Widget _glowCircle(double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.06),
        ),
      );

  // ── Conteúdo do formulário (reutilizado em todos os layouts) ──────────────

  /// Constrói o formulário de autenticação adaptado ao layout atual.
  ///
  /// Parâmetros:
  ///   • [isLoading]   — desabilita botões durante requisições
  ///   • [hPadding]    — padding horizontal (varia por layout)
  ///   • [topSpacing]  — espaçamento superior (varia por layout)
  ///   • [showLogo]    — exibe logo e título quando true (narrow/medium),
  ///                     false no wide (logo já aparece no painel esquerdo)
  ///   • [logoSize]    — tamanho do ícone circular (px)
  ///
  /// Conteúdo condicional:
  ///   • Campo "Nome" visível apenas no modo cadastro (_isRegisterMode)
  ///   • Link "Esqueci minha senha" visível apenas no modo login
  ///   • Título de boas-vindas visível apenas no wide (showLogo == false)
  Widget buildForm({
    required bool isLoading,
    required double hPadding,
    required double topSpacing,
    bool showLogo = true,
    double logoSize = 100,
  }) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: hPadding),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: topSpacing),

            // ── Logo e títulos (apenas narrow/medium) ──────────────────
            if (showLogo) ...[
              Center(
                child: Container(
                  width: logoSize,
                  height: logoSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1B7A1B), Color(0xFF2E7D32)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Icon(Icons.local_fire_department,
                      color: Colors.white, size: logoSize * 0.5),
                ),
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text('Voz Contra o Fogo',
                    style: TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 6),
              const Center(
                child: Text('Protegendo a Caatinga piauiense',
                    style: TextStyle(fontSize: 13, color: Colors.black54)),
              ),
              const SizedBox(height: 36),
            ],

            // ── Título do formulário (apenas layout wide, sem logo) ─────
            if (!showLogo) ...[
              Text(
                _isRegisterMode ? 'Criar conta' : 'Bem-vindo de volta',
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                _isRegisterMode
                    ? 'Preencha os campos para se cadastrar'
                    : 'Entre com suas credenciais para continuar',
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textMedium),
              ),
              const SizedBox(height: 28),
            ],

            // ── Campo Nome (visível apenas no modo cadastro) ────────────
            if (_isRegisterMode) ...[
              _inputField(
                controller: _nameController,
                icon: Icons.person_outline,
                label: 'Nome completo',
                hint: 'Seu nome',
                validator: (v) =>
                    v == null || v.isEmpty ? 'Informe seu nome.' : null,
              ),
              const SizedBox(height: 16),
            ],

            // ── Campo E-mail ────────────────────────────────────────────
            _inputField(
              controller: _emailController,
              icon: Icons.mail_outline,
              label: 'E-mail',
              hint: 'nome@exemplo.com',
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Informe seu e-mail.';
                if (!v.contains('@')) return 'E-mail inválido.';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // ── Campo Senha com toggle de visibilidade ──────────────────
            _inputField(
              controller: _passwordController,
              icon: Icons.lock_outline,
              label: 'Senha',
              hint: 'Sua senha',
              obscure: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.grey,
                ),
                // Alterna entre mostrar e ocultar a senha
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Informe sua senha.';
                if (v.length < 6) return 'Mínimo 6 caracteres.';
                return null;
              },
            ),

            // ── Link "Esqueci minha senha" (só no modo login) ──────────
            if (!_isRegisterMode)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _handleForgotPassword,
                  child: const Text('Esqueci minha senha',
                      style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600)),
                ),
              )
            else
              const SizedBox(height: 16),

            // ── Botão principal: Entrar / Criar conta ───────────────────
            // Mostra CircularProgressIndicator enquanto isLoading == true
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: isLoading ? null : _handleEmailLogin,
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(
                        _isRegisterMode ? 'Criar conta' : 'Entrar',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),

            const SizedBox(height: 12),

            // ── Toggle login ↔ cadastro ─────────────────────────────────
            Center(
              child: TextButton(
                onPressed: () =>
                    setState(() => _isRegisterMode = !_isRegisterMode),
                child: Text(
                  _isRegisterMode
                      ? 'Já tenho conta — Entrar'
                      : 'Não tenho conta — Criar',
                  style: const TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.w600),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Divisor "OU" entre login e acesso anônimo ───────────────
            Row(children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('OU',
                    style: TextStyle(
                        color: Colors.black.withValues(alpha: 0.4),
                        fontSize: 12)),
              ),
              const Expanded(child: Divider()),
            ]),

            const SizedBox(height: 16),

            // ── Botão de acesso anônimo (modo convidado) ────────────────
            // Cria conta Firebase anônima — dados ficam apenas no Hive local
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.4)),
                  backgroundColor: AppColors.primary.withValues(alpha: 0.06),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: isLoading ? null : _handleAnonymous,
                icon: const Icon(Icons.person_off_outlined,
                    color: AppColors.primary),
                label: const Text('Entrar como convidado (Anônimo)',
                    style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500)),
              ),
            ),

            const SizedBox(height: 36),

            // ── Crédito institucional (apenas nos layouts com logo) ─────
            if (showLogo)
              Center(
                child: Text('IFPI • Campus Paulistana • FAPEPI',
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.black.withValues(alpha: 0.3),
                        letterSpacing: 0.5)),
              ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Campo de entrada genérico ─────────────────────────────────────────────

  /// Constrói um campo de texto padronizado com label, ícone e validação.
  ///
  /// Usado para os 3 campos do formulário: nome, e-mail e senha.
  /// Bordas arredondadas (radius 40) e fundo branco semitransparente.
  Widget _inputField({
    required TextEditingController controller,
    required IconData icon,
    required String label,
    required String hint,
    bool obscure = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label acima do campo (não usa decoration label para manter controle)
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13)),
        ),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.grey, size: 20),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.85),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            // Borda padrão: sem linha visível (filled + radius)
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(40),
                borderSide: BorderSide.none),
            // Borda ao focar: verde primário
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(40),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 2)),
            // Borda de erro: vermelho
            errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(40),
                borderSide: BorderSide(color: Colors.red.shade400)),
            focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(40),
                borderSide: BorderSide(color: Colors.red.shade400, width: 2)),
          ),
        ),
      ],
    );
  }
}

// ── Layout: Celular (< 600px) ─────────────────────────────────────────────────

/// Layout de tela única para dispositivos mobile (largura < 600px).
///
/// Fundo com gradiente verde suave + círculos decorativos semitransparentes.
/// Formulário com logo centralizado e scroll para telas pequenas.
class _NarrowLayout extends StatelessWidget {
  /// Referência ao estado do LoginPage para chamar buildForm()
  final _LoginPageState state;
  final bool isLoading;
  const _NarrowLayout({required this.state, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fundo gradiente suave (branco-esverdeado)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF1F8E9), Color(0xFFE8F5E9)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Círculos decorativos nos cantos (semitransparentes)
          Positioned(
              top: -100, right: -100,
              child: _decorCircle(260, 0.07)),
          Positioned(
              bottom: -120, left: -120,
              child: _decorCircle(300, 0.05)),
          // Formulário com logo em tela cheia + scroll
          SafeArea(
            child: state.buildForm(
              isLoading: isLoading,
              hPadding: 26,
              topSpacing: 52,
              showLogo: true,
              logoSize: 96,
            ),
          ),
        ],
      ),
    );
  }

  /// Círculo decorativo com a cor primária e opacidade configurável.
  Widget _decorCircle(double size, double alpha) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary.withValues(alpha: alpha),
        ),
      );
}

// ── Layout: Tablet retrato (600–899px) ───────────────────────────────────────

/// Layout centralizado para tablets em modo retrato (600px ≤ largura < 900px).
///
/// Formulário limitado a 500px de largura, centralizado horizontalmente.
/// Mesmo estilo de fundo e decoração do NarrowLayout.
class _MediumLayout extends StatelessWidget {
  final _LoginPageState state;
  final bool isLoading;
  const _MediumLayout({required this.state, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF1F8E9), Color(0xFFE8F5E9)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Positioned(top: -110, right: -110,
              child: _decorCircle(300, 0.07)),
          Positioned(bottom: -130, left: -130,
              child: _decorCircle(350, 0.05)),
          // Formulário centralizado com largura máxima de 500px
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: state.buildForm(
                  isLoading: isLoading,
                  hPadding: 36,
                  topSpacing: 48,
                  showLogo: true,
                  logoSize: 108,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _decorCircle(double size, double alpha) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary.withValues(alpha: alpha),
        ),
      );
}

// ── Layout: Tablet paisagem / desktop (≥ 900px) ───────────────────────────────

/// Layout de dois painéis para telas largas (largura ≥ 900px).
///
/// Estrutura:
///   • Painel esquerdo (flex 4 ou 5) — marca: gradiente verde + logo
///   • Painel direito (flex 6)       — formulário: fundo claro + ConstrainedBox
///
/// Em telas ≥ 1200px o painel de marca ocupa proporção maior (5 vs 6).
/// showLogo = false pois o logo já está no painel esquerdo.
class _WideLayout extends StatelessWidget {
  final _LoginPageState state;
  final bool isLoading;
  const _WideLayout({required this.state, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    // Ajusta proporção dos painéis para telas muito largas (≥ 1200px)
    final brandFlex = screenW >= 1200 ? 5 : 4;
    final formFlex  = screenW >= 1200 ? 6 : 6;

    return Scaffold(
      body: Row(
        children: [
          // ── Painel esquerdo: identidade visual ───────────────────────────
          Expanded(
            flex: brandFlex,
            child: state.buildBrandPanel(
              logoSize: screenW >= 1200 ? 140 : 120,
            ),
          ),

          // ── Painel direito: formulário de login ──────────────────────────
          Expanded(
            flex: formFlex,
            child: Container(
              color: const Color(0xFFF6F8F6), // cinza muito claro
              child: SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: state.buildForm(
                      isLoading: isLoading,
                      hPadding: 40,
                      topSpacing: 32,
                      showLogo: false, // logo já exibido no painel esquerdo
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
