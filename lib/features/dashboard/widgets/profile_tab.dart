import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/backend_mode.dart';
import '../../../core/theme.dart';
import '../../../features/account/account_capabilities.dart';
import '../../../features/places/models/place.dart';
import '../../../features/places/services/place_service.dart';
import '../../../shared/widgets/akasha_footer.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({
    super.key,
    required this.profile,
    required this.account,
    required this.loadingProfile,
    required this.bottomPadding,
    required this.onOpenFavorites,
    required this.onOpenAccountSettings,
    required this.onOpenPreferences,
    required this.onContactSupport,
  });

  final ChezMoiProfile? profile;
  final AccountCapabilities account;
  final bool loadingProfile;
  final double bottomPadding;
  final VoidCallback onOpenFavorites;
  final VoidCallback onOpenAccountSettings;
  final VoidCallback onOpenPreferences;
  final VoidCallback onContactSupport;

  @override
  Widget build(BuildContext context) {
    final colors = context.chezMoiColors;
    const accountLabel = 'Compte voyageur';

    return SafeArea(
      top: false,
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.fromLTRB(
                20,
                MediaQuery.paddingOf(context).top + 16,
                20,
                24,
              ),
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border(
                  bottom: BorderSide(
                    color: colors.border.withValues(alpha: 0.7),
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Paramètres',
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 25,
                                fontWeight: FontWeight.w600,
                                height: 1.12,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              profile?.email.isNotEmpty == true
                                  ? '${profile!.email} · $accountLabel'
                                  : accountLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 18),
                      SizedBox(
                        width: 82,
                        height: 82,
                        child: ClipRect(
                          child: Align(
                            alignment: Alignment.center,
                            heightFactor: 0.42,
                            child: Image.asset(
                              'assets/images/nnn.png',
                              height: 196,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (loadingProfile)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (profile?.isAnnonceur == true) ...[
                      const _SettingsSectionLabel(label: 'Espace annonceur'),
                      const SizedBox(height: 8),
                      _SettingsGroup(
                        children: [
                          _SettingsRow(
                            icon: Icons.storefront_outlined,
                            label: 'Mes établissements',
                            onTap: () => context.push('/my-places'),
                          ),
                          _SettingsRow(
                            icon: Icons.add_business_outlined,
                            label: 'Publier un établissement',
                            onTap: () => context.push('/publish-place'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                    ],
                    const _SettingsSectionLabel(label: 'Voyages'),
                    const SizedBox(height: 8),
                    _SettingsGroup(
                      children: [
                        _SettingsRow(
                          icon: Icons.event_available_outlined,
                          label: 'Mes réservations',
                          onTap: () => context.push('/reservations'),
                        ),
                        _SettingsRow(
                          icon: Icons.favorite_border_rounded,
                          label: 'Favoris',
                          onTap: onOpenFavorites,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const _SettingsSectionLabel(label: 'Compte'),
                    const SizedBox(height: 8),
                    _SettingsGroup(
                      children: [
                        _SettingsRow(
                          icon: Icons.manage_accounts_outlined,
                          label: 'Paramètres de compte',
                          onTap: onOpenAccountSettings,
                        ),
                        _SettingsRow(
                          icon: Icons.tune_rounded,
                          label: 'Préférences',
                          onTap: onOpenPreferences,
                        ),
                        _SettingsRow(
                          icon: Icons.privacy_tip_outlined,
                          label: 'Confidentialité',
                          onTap: () => context.push('/legal/privacy'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    HelpCenterSection(onContactSupport: onContactSupport),
                  ],
                ),
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              fillOverscroll: true,
              child: Padding(
                padding: EdgeInsets.fromLTRB(18, 18, 18, bottomPadding),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AkashaFooter(padding: EdgeInsets.symmetric(vertical: 4)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class AccountSettingsSheet extends StatelessWidget {
  const AccountSettingsSheet({
    super.key,
    required this.profile,
    required this.onSignOut,
    required this.onDeactivate,
  });

  final ChezMoiProfile? profile;
  final VoidCallback onSignOut;
  final VoidCallback onDeactivate;

  @override
  Widget build(BuildContext context) {
    final colors = context.chezMoiColors;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final name = profile?.fullName ?? 'Compte ChezMoi';
    final accountType = profile?.accountType ?? 'traveler';
    final accountTypeLabel = accountType == 'traveler'
        ? null
        : profile?.accountTypeLabel;

    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        top: false,
        bottom: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.88,
          ),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(18, 10, 18, bottomInset + 18),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              border: Border(top: BorderSide(color: colors.border)),
              boxShadow: [
                BoxShadow(
                  color: colors.navy.withValues(alpha: 0.10),
                  blurRadius: 20,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _SheetHandle(),
                  const _SheetHeader(title: 'Paramètres de compte'),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(2, 8, 2, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            height: 1.15,
                          ),
                        ),
                        if (accountTypeLabel != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            accountTypeLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  _SettingsGroup(
                    children: [
                      _SettingsInfoRow(
                        icon: Icons.place_outlined,
                        label: 'Zone préférée',
                        value: profile?.location.isNotEmpty == true
                            ? profile!.location
                            : 'Non renseignée',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _SettingsGroup(
                    children: [
                      _SettingsRow(
                        icon: Icons.logout_rounded,
                        label: 'Se déconnecter',
                        onTap: onSignOut,
                      ),
                      _SettingsRow(
                        icon: Icons.no_accounts_outlined,
                        label: 'Désactiver mon compte',
                        danger: true,
                        onTap: () {
                          Navigator.pop(context);
                          onDeactivate();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AppPreferencesSheet extends StatelessWidget {
  const AppPreferencesSheet({
    super.key,
    required this.notifyNewMatches,
    required this.notifyEnquiries,
    required this.pinRent,
    required this.onNotifyNewMatchesChanged,
    required this.onNotifyEnquiriesChanged,
    required this.onPinRentChanged,
  });

  final bool notifyNewMatches;
  final bool notifyEnquiries;
  final bool pinRent;
  final ValueChanged<bool> onNotifyNewMatchesChanged;
  final ValueChanged<bool> onNotifyEnquiriesChanged;
  final ValueChanged<bool> onPinRentChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.chezMoiColors;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        top: false,
        bottom: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.88,
          ),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(18, 10, 18, bottomInset + 18),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              border: Border(top: BorderSide(color: colors.border)),
              boxShadow: [
                BoxShadow(
                  color: colors.navy.withValues(alpha: 0.10),
                  blurRadius: 20,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _SheetHandle(),
                  const _SheetHeader(title: 'Préférences'),
                  const SizedBox(height: 4),
                  _PreferenceSection(
                    title: 'Notifications',
                    children: [
                      _PreferenceSwitchTile(
                        icon: Icons.notifications_active_outlined,
                        label: 'Nouveaux établissements pertinents',
                        description:
                            'Alertes pour les établissements proches de vos recherches.',
                        value: notifyNewMatches,
                        onChanged: onNotifyNewMatchesChanged,
                      ),
                      _PreferenceSwitchTile(
                        icon: Icons.mark_email_unread_outlined,
                        label: 'Demandes et réponses',
                        description:
                            'Suivi des contacts envoyés et des réponses reçues.',
                        value: notifyEnquiries,
                        onChanged: onNotifyEnquiriesChanged,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _PreferenceSection(
                    title: 'Affichage carte',
                    children: [
                      _PreferenceSwitchTile(
                        icon: Icons.hotel_rounded,
                        label: 'Établissements',
                        description: 'Afficher les établissements sur la carte.',
                        value: pinRent,
                        onChanged: onPinRentChanged,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HelpCenterSection extends StatelessWidget {
  const HelpCenterSection({super.key, required this.onContactSupport});

  final VoidCallback onContactSupport;

  @override
  Widget build(BuildContext context) {
    final colors = context.chezMoiColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SettingsSectionLabel(label: 'Centre d\'aide'),
        const SizedBox(height: 8),
        _SettingsGroup(
          children: [
            for (var index = 0; index < _helpCenterFaqItems.length; index++)
              _FaqTile(
                item: _helpCenterFaqItems[index],
                showDivider: index > 0,
              ),
          ],
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: onContactSupport,
          icon: const Icon(Icons.support_agent_rounded),
          label: const Text('Nous contacter'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Votre compte ChezMoi sera joint automatiquement à la demande.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.item, required this.showDivider});

  final _FaqItem item;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final colors = context.chezMoiColors;
    return Column(
      children: [
        if (showDivider) Divider(height: 1, color: colors.border),
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 14),
            childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            iconColor: colors.textSecondary,
            collapsedIconColor: colors.textSecondary,
            title: Text(
              item.question,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  item.answer,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 13,
                    height: 1.38,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FaqItem {
  const _FaqItem({required this.question, required this.answer});

  final String question;
  final String answer;
}

const _helpCenterFaqItems = [
  _FaqItem(
    question: 'Comment trouver un établissement ?',
    answer:
        "Utilisez l'accueil, la carte ou les nouveautés pour parcourir les établissements disponibles. La recherche accepte les quartiers, villes et mots-clés.",
  ),
  _FaqItem(
    question: 'Comment filtrer les établissements ?',
    answer:
        "Les filtres permettent de préciser le type d'établissement, le budget par nuit, les équipements et la disponibilité.",
  ),
  _FaqItem(
    question: 'Comment enregistrer un établissement en favori ?',
    answer:
        "Touchez le cœur sur un établissement. Les favoris sont regroupés dans l'onglet Favoris quand vous êtes connecté.",
  ),
  _FaqItem(
    question: 'Comment réserver ou contacter un établissement ?',
    answer:
        "Ouvrez une fiche puis utilisez les actions de contact. Vous devez être connecté pour envoyer une demande fiable.",
  ),
  _FaqItem(
    question: 'Que faire si un établissement semble suspect ?',
    answer:
        "Contactez le support depuis ce centre d'aide avec le nom ou le lien de l'établissement. L'équipe pourra vérifier.",
  ),
  _FaqItem(
    question: 'Comment supprimer mon compte ?',
    answer:
        "Allez dans Paramètres de compte puis choisissez Désactiver mon compte. Une demande sera envoyée à l'équipe.",
  ),
  _FaqItem(
    question: 'Comment signaler un bug ou proposer un partenariat ?',
    answer:
        "Utilisez le bouton Nous contacter et choisissez le motif adapté. Votre compte sera joint automatiquement au message.",
  ),
];

class SupportRequestSheet extends StatefulWidget {
  const SupportRequestSheet({super.key, required this.profile});

  final ChezMoiProfile? profile;

  @override
  State<SupportRequestSheet> createState() => _SupportRequestSheetState();
}

class _SupportRequestSheetState extends State<SupportRequestSheet> {
  final _placeService = PlaceService();
  final _messageController = TextEditingController();
  String? _selectedReason;
  bool _submitting = false;
  bool _sent = false;
  String? _errorMessage;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.chezMoiColors;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        top: false,
        bottom: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.88,
          ),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              18,
              10,
              18,
              bottomInset + MediaQuery.viewInsetsOf(context).bottom + 18,
            ),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              border: Border(top: BorderSide(color: colors.border)),
              boxShadow: [
                BoxShadow(
                  color: colors.navy.withValues(alpha: 0.10),
                  blurRadius: 20,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _SheetHandle(),
                  const _SheetHeader(title: 'Contacter le support'),
                  const SizedBox(height: 8),
                  if (_sent)
                    _SupportSuccessState(onClose: () => Navigator.pop(context))
                  else ...[
                    _SupportIdentityNotice(profile: widget.profile),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedReason,
                      items: [
                        for (final reason in _supportReasons)
                          DropdownMenuItem(value: reason, child: Text(reason)),
                      ],
                      onChanged: _submitting
                          ? null
                          : (value) {
                              setState(() {
                                _selectedReason = value;
                                _errorMessage = null;
                              });
                            },
                      decoration: const InputDecoration(
                        labelText: 'Motif',
                        prefixIcon: Icon(Icons.help_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _messageController,
                      minLines: 5,
                      maxLines: 8,
                      enabled: !_submitting,
                      textInputAction: TextInputAction.newline,
                      onChanged: (_) {
                        if (_errorMessage != null) {
                          setState(() => _errorMessage = null);
                        }
                      },
                      decoration: const InputDecoration(
                        labelText: 'Message',
                        hintText: 'Décrivez votre demande en quelques lignes.',
                        alignLabelWithHint: true,
                        prefixIcon: Icon(Icons.message_outlined),
                      ),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 10),
                      _SupportInlineMessage(
                        message: _errorMessage!,
                        icon: Icons.error_outline_rounded,
                        color: colors.danger,
                      ),
                    ],
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: _submitting ? null : _submit,
                      icon: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded),
                      label: Text(
                        _submitting ? 'Envoi en cours...' : 'Envoyer',
                      ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Destination: chezmoi@dataplay.online',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final reason = _selectedReason?.trim() ?? '';
    final message = _messageController.text.trim();
    if (reason.isEmpty) {
      setState(() => _errorMessage = 'Sélectionnez un motif.');
      return;
    }
    if (message.isEmpty) {
      setState(() => _errorMessage = 'Ajoutez un message.');
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    try {
      await _placeService.submitSupportRequest(
        reason: reason,
        message: message,
      );
      if (!mounted) return;
      _messageController.clear();
      setState(() {
        _selectedReason = null;
        _sent = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _errorMessage =
            'Impossible d\'envoyer le message. Réessayez dans un instant.',
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

class _SupportIdentityNotice extends StatelessWidget {
  const _SupportIdentityNotice({required this.profile});

  final ChezMoiProfile? profile;

  @override
  Widget build(BuildContext context) {
    final colors = context.chezMoiColors;
    final user = BackendMode.useSupabase
        ? Supabase.instance.client.auth.currentUser
        : null;
    final name = profile?.fullName.trim().isNotEmpty == true
        ? profile!.fullName.trim()
        : 'Compte ChezMoi';
    final email = profile?.email.isNotEmpty == true
        ? profile!.email
        : user?.email ?? 'Email du compte';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.account_circle_outlined, color: colors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportInlineMessage extends StatelessWidget {
  const _SupportInlineMessage({
    required this.message,
    required this.icon,
    required this.color,
  });

  final String message;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _SupportSuccessState extends StatelessWidget {
  const _SupportSuccessState({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colors = context.chezMoiColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.primaryBlue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: colors.primaryBlue.withValues(alpha: 0.18),
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.mark_email_read_outlined,
                color: colors.primaryBlue,
                size: 34,
              ),
              const SizedBox(height: 10),
              Text(
                'Merci, votre message a bien été envoyé. Notre équipe vous répondra dans les meilleurs délais.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 14,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        FilledButton(onPressed: onClose, child: const Text('Fermer')),
      ],
    );
  }
}

const _supportReasons = [
  'Question sur un établissement',
  'Problème de recherche ou de filtres',
  'Favoris ou compte',
  'Réserver ou contacter un établissement',
  'Établissement suspect',
  'Suppression de compte',
  'Bug dans l\'application',
  'Partenariat',
  'Autre demande',
];

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = context.chezMoiColors;
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Fermer',
        ),
      ],
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    final colors = context.chezMoiColors;
    return Center(
      child: Container(
        width: 42,
        height: 4,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: colors.border,
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }
}

class _SettingsInfoRow extends StatelessWidget {
  const _SettingsInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.chezMoiColors;
    return ListTile(
      minVerticalPadding: 10,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
      leading: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.border),
        ),
        child: Icon(icon, color: colors.textSecondary, size: 18),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: colors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: colors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}

class _PreferenceSection extends StatelessWidget {
  const _PreferenceSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.chezMoiColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 0, 2, 8),
          child: Text(
            title,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ),
        _SettingsGroup(children: children),
      ],
    );
  }
}

class _PreferenceSwitchTile extends StatelessWidget {
  const _PreferenceSwitchTile({
    required this.icon,
    required this.label,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.chezMoiColors;
    return SwitchListTile.adaptive(
      contentPadding: const EdgeInsets.fromLTRB(16, 3, 12, 3),
      secondary: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: value
              ? colors.primaryBlue.withValues(alpha: 0.08)
              : colors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.border),
        ),
        child: Icon(
          icon,
          color: value ? colors.primaryBlue : colors.textSecondary,
          size: 18,
        ),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: colors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        description,
        style: TextStyle(
          color: colors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),
      activeThumbColor: colors.primaryBlue,
      value: value,
      onChanged: onChanged,
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.chezMoiColors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: colors.surface,
        child: Column(children: children),
      ),
    );
  }
}

class _SettingsSectionLabel extends StatelessWidget {
  const _SettingsSectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.chezMoiColors;
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: colors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final colors = context.chezMoiColors;
    final color = danger ? colors.danger : colors.textPrimary;
    return ListTile(
      minVerticalPadding: 10,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
      leading: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: danger
              ? colors.danger.withValues(alpha: 0.08)
              : colors.background,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: danger
                ? colors.danger.withValues(alpha: 0.18)
                : colors.border,
          ),
        ),
        child: Icon(
          icon,
          color: danger ? colors.danger : colors.textSecondary,
          size: 18,
        ),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: colors.textSecondary.withValues(alpha: 0.65),
        size: 20,
      ),
      onTap: onTap,
    );
  }
}
