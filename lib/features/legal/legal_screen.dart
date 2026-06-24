import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';

enum LegalDocumentType { terms, privacy }

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.document});

  final LegalDocumentType document;

  @override
  Widget build(BuildContext context) {
    final colors = context.chezMoiColors;
    final isTerms = document == LegalDocumentType.terms;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isTerms
              ? "Conditions d'utilisation"
              : 'Politique de confidentialité',
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/dashboard'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isTerms
                    ? "Conditions d'utilisation — ChezMoi"
                    : 'Politique de confidentialité — ChezMoi',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Dernière mise à jour : juin 2026',
                style: TextStyle(color: colors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 24),
              ...(isTerms ? _termsSections(colors) : _privacySections(colors)),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _privacySections(ChezMoiColors colors) {
    return [
      _section(
        colors,
        title: '1. Qui sommes-nous',
        body:
            "ChezMoi est une application de réservation de voyage au Gabon. "
            "Elle vous aide à découvrir des hôtels, des restaurants et des activités, "
            "et à effectuer vos réservations.",
      ),
      _section(
        colors,
        title: '2. Données que nous collectons',
        body:
            "Nous collectons les données nécessaires au fonctionnement du service :\n\n"
            "• Données de compte : prénom, nom, adresse e-mail, et numéro de téléphone si vous l'ajoutez.\n"
            "• Activité de recherche : recherches effectuées, filtres utilisés, établissements consultés.\n"
            "• Favoris : établissements que vous enregistrez pour les retrouver plus tard.\n"
            "• Localisation et zones de recherche : ville, quartier ou zones que vous indiquez.\n"
            "• Réservations : dates, nombre de personnes et coordonnées associées à vos réservations.",
      ),
      _section(
        colors,
        title: '3. Comment nous utilisons vos données',
        body:
            "Nous utilisons vos données pour :\n\n"
            "• créer et sécuriser votre compte ;\n"
            "• afficher des établissements pertinents selon vos recherches ;\n"
            "• enregistrer et gérer vos réservations ;\n"
            "• améliorer la qualité, la sécurité et la performance de ChezMoi ;\n"
            "• prévenir la fraude et les usages abusifs.",
      ),
      _section(
        colors,
        title: '4. Supabase, authentification et stockage',
        body:
            "ChezMoi s'appuie sur Supabase pour l'authentification, la base de données PostgreSQL, "
            "la sécurité au niveau des lignes (RLS) et le stockage des photos des établissements. "
            "Vos données de compte et vos réservations sont hébergées via cette infrastructure. "
            "L'accès aux données est limité par des règles de sécurité strictes.",
      ),
      _section(
        colors,
        title: '5. Partage des données',
        body:
            "Nous ne vendons pas vos données personnelles. Certaines informations peuvent être partagées "
            "uniquement lorsque cela est nécessaire au service, par exemple lorsque vous effectuez une "
            "réservation auprès d'un établissement, ou avec nos prestataires techniques "
            "sous contrat de confidentialité.",
      ),
      _section(
        colors,
        title: '6. Vos droits',
        body:
            "Conformément à la réglementation applicable, vous pouvez demander l'accès, la correction "
            "ou la suppression de vos données personnelles. Vous pouvez également retirer votre consentement "
            "lorsque le traitement repose sur celui-ci. Pour exercer vos droits, contactez-nous via les "
            "canaux de support ChezMoi.",
      ),
      _section(
        colors,
        title: '7. Conservation et sécurité',
        body:
            "Nous conservons vos données aussi longtemps que votre compte est actif ou que la loi l'exige. "
            "Nous mettons en œuvre des mesures techniques et organisationnelles raisonnables pour protéger "
            "vos informations contre l'accès non autorisé, la perte ou la divulgation.",
      ),
      _section(
        colors,
        title: '8. Modifications',
        body:
            "Nous pouvons mettre à jour cette politique. En cas de changement important, nous vous en "
            "informerons via l'application ou par e-mail.",
      ),
    ];
  }

  List<Widget> _termsSections(ChezMoiColors colors) {
    return [
      _section(
        colors,
        title: '1. Objet du service',
        body:
            "ChezMoi est une plateforme de réservation de voyage au Gabon. "
            "Elle permet de découvrir des hôtels, des restaurants et des activités, "
            "et d'effectuer des réservations.",
      ),
      _section(
        colors,
        title: '2. Comptes et exactitude des informations',
        body:
            "Vous devez fournir des informations exactes, complètes et à jour lors de la création de votre compte. "
            "Vous êtes responsable de la confidentialité de votre accès et de toute activité réalisée via votre compte.",
      ),
      _section(
        colors,
        title: '3. Voyageurs',
        body:
            "Les voyageurs doivent fournir des coordonnées fiables pour permettre la confirmation "
            "et le bon déroulement de leurs réservations. "
            "Vous êtes responsable de l'exactitude des informations associées à votre compte.",
      ),
      _section(
        colors,
        title: '4. Établissements et disponibilité',
        body:
            "Les informations sur les établissements (description, prix, équipements, photos) "
            "sont fournies à titre indicatif. ChezMoi facilite la découverte et la réservation "
            "mais ne garantit pas la disponibilité, l'état réel ou la conformité d'un établissement.",
      ),
      _section(
        colors,
        title: '5. Comportements interdits',
        body:
            "Il est strictement interdit de :\n\n"
            "• publier de fausses informations ou des contenus trompeurs ;\n"
            "• utiliser des photos volées, falsifiées ou non autorisées ;\n"
            "• afficher des prix mensongers ou des offres frauduleuses ;\n"
            "• harceler, spammer ou détourner les outils de la plateforme ;\n"
            "• tenter d'accéder à des données ou comptes qui ne vous appartiennent pas.",
      ),
      _section(
        colors,
        title: '6. Modération',
        body:
            "ChezMoi se réserve le droit de modérer, masquer, suspendre ou supprimer toute fiche "
            "ou tout compte en cas de signalement, de fraude suspectée ou de violation des présentes conditions.",
      ),
      _section(
        colors,
        title: '7. Réservations et transactions',
        body:
            "Les confirmations, paiements et prestations se déroulent en dehors de ChezMoi, "
            "sauf si des fonctionnalités de paiement en ligne sont ajoutées ultérieurement. "
            "ChezMoi n'est pas partie aux contrats conclus entre utilisateurs et établissements.",
      ),
      _section(
        colors,
        title: '8. Suspension de compte',
        body:
            "Nous pouvons suspendre ou résilier un compte en cas d'abus, de fraude, "
            "de non-respect des présentes conditions ou de comportement préjudiciable à la communauté.",
      ),
      _section(
        colors,
        title: '9. Propriété intellectuelle',
        body:
            "ChezMoi, son identité visuelle et les éléments de la plateforme restent la propriété de leurs titulaires respectifs. "
            "Vous conservez vos droits sur le contenu que vous publiez, tout en nous accordant une licence "
            "limitée pour l'afficher dans le cadre du service.",
      ),
      _section(
        colors,
        title: '10. Limitation de responsabilité',
        body:
            "Dans les limites autorisées par la loi, ChezMoi ne pourra être tenu responsable des dommages "
            "indirects liés à l'utilisation du service, ni des litiges survenant entre utilisateurs "
            "et établissements.",
      ),
      _section(
        colors,
        title: '11. Contact',
        body:
            "Pour toute question relative à ces conditions, contactez l'équipe ChezMoi via les canaux "
            "de support disponibles dans l'application.",
      ),
    ];
  }

  Widget _section(
    ChezMoiColors colors, {
    required String title,
    required String body,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
