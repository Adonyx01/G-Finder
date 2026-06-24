import 'package:supabase_flutter/supabase_flutter.dart';

String authErrorMessage(Object error, {required AuthAction action}) {
  if (error is AuthException) {
    return _authExceptionMessage(error, action: action);
  }

  final message = error.toString().toLowerCase();
  if (_looksLikeNetworkError(message)) {
    return 'Connexion impossible à Supabase. Vérifiez votre connexion internet puis réessayez.';
  }

  if (_looksLikeEmailDeliveryError(message)) {
    return _emailDeliveryMessage;
  }

  return 'Une erreur est survenue. Veuillez réessayer.';
}

enum AuthAction { loginOtp, signupOtp, resendOtp, verifyOtp, signin, signup }

const _emailDeliveryMessage =
    'Supabase n\'arrive pas à envoyer l\'e-mail de confirmation. Vérifiez la configuration SMTP / Auth Email du projet Supabase, puis réessayez.';

String _authExceptionMessage(
  AuthException error, {
  required AuthAction action,
}) {
  final message = error.message.toLowerCase();

  if (_looksLikeEmailDeliveryError(message)) {
    return _emailDeliveryMessage;
  }
  if (_looksLikeNetworkError(message)) {
    return 'Connexion impossible à Supabase. Vérifiez votre connexion internet puis réessayez.';
  }
  if (message.contains('rate limit')) {
    return 'Trop de tentatives. Veuillez patienter avant de réessayer.';
  }
  if (message.contains('expired') || message.contains('invalid token')) {
    return 'Code invalide ou expiré. Vérifiez le code ou demandez-en un nouveau.';
  }
  if (message.contains('invalid') && message.contains('email')) {
    return 'Adresse e-mail refusée par Supabase. Vérifiez le format ou la configuration Auth Email.';
  }
  if (message.contains('user not found') ||
      (action == AuthAction.loginOtp &&
          message.contains('signups not allowed'))) {
    return 'Aucun compte trouvé pour cette adresse e-mail.';
  }
  if (message.contains('already registered') ||
      message.contains('user already exists')) {
    return 'Un compte existe déjà avec cette adresse e-mail.';
  }
  if (message.contains('invalid login credentials')) {
    return 'E-mail ou mot de passe incorrect.';
  }
  if (message.contains('email not confirmed')) {
    return 'Confirmez votre e-mail avant de vous connecter (ou désactivez la confirmation e-mail dans Supabase).';
  }
  if (message.contains('password') &&
      (message.contains('at least') || message.contains('should be'))) {
    return 'Le mot de passe doit contenir au moins 6 caractères.';
  }
  if (message.contains('signups not allowed')) {
    return 'Les inscriptions sont désactivées dans Supabase (Auth -> Settings).';
  }
  if (message.contains('database error')) {
    return action == AuthAction.verifyOtp
        ? 'Compte créé partiellement : exécutez le schéma SQL ChezMoi dans Supabase.'
        : 'Erreur base de données à l\'inscription. Exécutez le SQL ChezMoi dans Supabase (profiles + handle_new_user).';
  }

  return error.message;
}

bool _looksLikeEmailDeliveryError(String message) {
  return message.contains('error sending confirmation email') ||
      message.contains('error sending magic link email') ||
      message.contains('error sending email') ||
      message.contains('sending confirmation email') ||
      message.contains('unexpected_failure') ||
      message.contains('email provider') ||
      message.contains('smtp') ||
      message.contains('mailer');
}

bool _looksLikeNetworkError(String message) {
  return message.contains('socketexception') ||
      message.contains('clientexception') ||
      message.contains('failed host lookup') ||
      message.contains('network') ||
      message.contains('connection refused') ||
      message.contains('xmlhttprequest error');
}
