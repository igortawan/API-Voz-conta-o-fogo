// ============================================================================
// failures.dart
// ----------------------------------------------------------------------------
// Hierarquia de erros tipados do domínio do aplicativo.
//
// Em vez de lançar exceções genéricas (Exception/Error), todos os serviços
// lançam subclasses de [Failure]. Isso permite que a UI decida como exibir
// cada tipo de falha sem depender de strings de exceção.
//
// Uso típico:
//   throw AuthFailure('Senha incorreta.');
//   catch (e) { if (e is AuthFailure) ... }
// ============================================================================

/// Classe base abstrata para todos os erros do domínio.
/// Carrega uma [message] legível pelo usuário.
abstract class Failure {
  final String message;
  const Failure(this.message);
}

/// Falha de conectividade — sem internet ou timeout de rede.
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Sem conexão com a internet.']);
}

/// Falha de autenticação — e-mail/senha inválidos, conta bloqueada, etc.
class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Erro de autenticação.']);
}

/// Falha de servidor — resposta HTTP inesperada ou Firestore indisponível.
class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Erro no servidor. Tente novamente.']);
}

/// Falha de permissão — regras de segurança Firestore negaram acesso.
class PermissionFailure extends Failure {
  const PermissionFailure([super.message = 'Permissão negada.']);
}

/// Falha de armazenamento local — Hive não conseguiu salvar ou ler dados.
class LocalStorageFailure extends Failure {
  const LocalStorageFailure([super.message = 'Erro ao salvar dados localmente.']);
}

/// Falha de validação — campos obrigatórios vazios ou formato incorreto.
class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'Dados inválidos.']);
}

/// Falha de upload — Cloudinary retornou erro ou tempo limite atingido.
class UploadFailure extends Failure {
  const UploadFailure([super.message = 'Erro ao enviar imagem.']);
}

/// Falha de localização — GPS desativado ou permissão negada pelo usuário.
class LocationFailure extends Failure {
  const LocationFailure([super.message = 'Erro ao obter localização.']);
}

// ── Mapeamento de códigos FirebaseAuth → mensagens em português ───────────────

/// Converte os códigos de erro do FirebaseAuth em mensagens amigáveis em PT-BR.
/// Usado pelo [AuthService] para lançar [AuthFailure] com texto legível.
String mapAuthError(String code) {
  switch (code) {
    case 'user-not-found':
      return 'Usuário não encontrado.';
    case 'wrong-password':
      return 'Senha incorreta.';
    case 'email-already-in-use':
      return 'E-mail já cadastrado.';
    case 'weak-password':
      return 'Senha fraca. Use ao menos 6 caracteres.';
    case 'invalid-email':
      return 'E-mail inválido.';
    case 'network-request-failed':
      return 'Sem conexão com a internet.';
    case 'too-many-requests':
      return 'Muitas tentativas. Aguarde e tente novamente.';
    default:
      return 'Erro desconhecido. Tente novamente.';
  }
}
