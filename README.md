# G-Finder

> Application mobile de réservation de voyages au Gabon — hôtels, restaurants et activités.
> Construite avec **Flutter** et **Supabase**.

G-Finder est une application façon Booking/Trivago, dédiée au Gabon. Les voyageurs
parcourent et réservent des **hôtels**, **restaurants** et **activités** ; les
**annonceurs** (professionnels) publient et gèrent leurs propres établissements,
géolocalisés pour la fonction « à proximité ».

---

## ✨ Fonctionnalités

### Côté voyageur
- 🔎 Recherche par ville/quartier, filtres (catégorie, budget, équipements, distance).
- 🗂️ Onglets par catégorie : Tous · Hôtels · Restaurants · Activités.
- 🗺️ Carte interactive (OpenStreetMap via `flutter_map`) avec les établissements.
- 📍 « Lieux à proximité » calculés localement (distance de Haversine).
- ❤️ Favoris.
- 📅 Réservations (hôtel : dates ; restaurant/activité : créneau).
- 🔐 Connexion **sans mot de passe** : code à usage unique reçu par e-mail (OTP).

### Côté annonceur
- 🏪 Compte annonceur (nom d'entreprise + téléphone à l'inscription).
- ➕ Publication d'un établissement : catégorie, prix, photos, équipements, et
  **position sur la carte** (pointage GPS).
- 🖼️ Upload de vraies photos sur **Supabase Storage**.
- 🛠️ Gestion (liste / suppression) de ses propres établissements.
- 🔐 Connexion par **e-mail + mot de passe**.

---

## 🧱 Stack technique

| Domaine | Technologie |
|---|---|
| Framework | Flutter (Dart SDK `^3.12.0`), Material 3 |
| Navigation | `go_router` |
| Backend | **Supabase** (Auth, PostgreSQL, RLS, Storage) |
| Cartographie | `flutter_map` + `latlong2` (tuiles OpenStreetMap) |
| Recherche d'adresses | API Geoapify (autocomplétion) |
| Stockage local | `shared_preferences` |
| Photos | `image_picker` |
| E-mails (OTP) | SMTP personnalisé **Brevo** |

---

## 🗂️ Architecture

Organisation **feature-first** (un dossier par fonctionnalité), avec trois couches :
**UI** (écrans/widgets) → **Services** (logique + appels Supabase) → **Models**
(formes des données). Le dossier `core/` regroupe les fondations transverses.

```
lib/
├── main.dart                 # Point d'entrée : init Supabase + lance l'app
├── core/                     # Fondations (router, thème, config, mode backend…)
├── services/                 # Services transverses (recherche d'adresses)
├── shared/widgets/           # Widgets partagés (footer…)
└── features/
    ├── auth/                 # Connexion / inscription / vérification code
    ├── splash/               # Écran de démarrage + loader
    ├── account/              # État du compte / profil
    ├── places/               # Cœur métier : modèles, services, écrans, widgets
    ├── dashboard/            # Écran principal voyageur (recherche, carte, onglets)
    ├── reservations/         # Réservations
    └── legal/                # CGU / Confidentialité

supabase/migrations/          # Schéma de la base en SQL (à exécuter dans Supabase)
```

> 💡 Pour comprendre une fonctionnalité, lire toujours dans l'ordre
> **model → service → screen**.

### Fichiers clés
| Fichier | Rôle |
|---|---|
| `core/app_router.dart` | Toutes les routes de l'app |
| `core/backend_mode.dart` | Bascule entre mode `supabase` et `template` (démo) |
| `core/supabase_config.dart` | URL + clé publique Supabase |
| `features/places/models/place.dart` | Modèle `Place`, `ChezMoiProfile`, `PlaceFilter` |
| `features/places/services/place_service.dart` | Requêtes places (lire/chercher/publier/favoris) |
| `features/auth/auth_service.dart` | Logique d'authentification |
| `features/dashboard/dashboard_screen.dart` | Écran principal (le plus gros) |

---

## 🚀 Démarrage rapide

### Prérequis
- [Flutter](https://docs.flutter.dev/get-started/install) (canal stable, Dart `^3.12.0`)
- Un émulateur Android/iOS ou un appareil physique

### Installation
```bash
git clone https://github.com/Adonyx01/G-Finder.git
cd G-Finder        # (ou le dossier du projet : projetmobile/chezmoi)
flutter pub get
flutter run
```

Par défaut, l'app se connecte directement au projet Supabase configuré dans
`lib/core/supabase_config.dart` — un simple `flutter run` suffit.

### Surcharger la configuration (optionnel)
```bash
flutter run \
  --dart-define=SUPABASE_URL=https://VOTRE-PROJET.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=sb_publishable_xxx
```

### Mode démo (sans backend)
Pour faire tourner l'UI avec des données factices, sans toucher à Supabase :
```bash
flutter run --dart-define=CHEZMOI_BACKEND=template
```

---

## 🗄️ Base de données (Supabase)

Le schéma vit dans `supabase/migrations/`. À exécuter **dans l'ordre** depuis le
**SQL Editor** de Supabase :

| Migration | Contenu |
|---|---|
| `0001_chezmoi_init.sql` | Tables (`places`, `profiles`, `reservations`, favoris…), RLS, trigger `handle_new_user` |
| `0002_seed_places.sql` | Données de démonstration (Gabon) |
| `0003_annonceur.sql` | Colonne `places.owner_id`, RLS annonceur, bucket Storage `place-photos` |
| `0004_signup_fields.sql` | Champs d'inscription (`company_name`…) |

**Table centrale `places`** : une seule table pour les 3 catégories, avec une
colonne `category` (`hotel` / `restaurant` / `activity`), un `subtype`, des
tableaux `image_urls[]` / `amenities[]` et un `details jsonb` pour les specs
propres à chaque catégorie.

**Sécurité (RLS)** : tout passe par les *Row Level Security policies* —
publication réservée aux annonceurs (`account_type = 'annonceur'`), modification/
suppression réservées au propriétaire (`owner_id = auth.uid()`), réservations
visibles uniquement par leur auteur.

---

## 🔐 Authentification

Deux types de comptes, choisis via un bouton segmenté à l'inscription :

| Type | Méthode de connexion |
|---|---|
| **Voyageur** | E-mail uniquement → **code à usage unique (OTP)** reçu par e-mail |
| **Annonceur** | E-mail + **mot de passe** (+ nom d'entreprise & téléphone) |

> Les e-mails de code utilisent un **SMTP personnalisé (Brevo)**. Les templates
> Supabase « Confirm signup » et « Magic Link » doivent contenir `{{ .Token }}`
> pour afficher le code à 6 chiffres.

---

## 📦 Dépendances principales
`supabase_flutter` · `go_router` · `flutter_map` · `latlong2` ·
`image_picker` · `shared_preferences` · `http`

---

## 🗺️ Pistes d'évolution
- [ ] Côté annonceur : voir et **confirmer/refuser** les réservations reçues
      (nécessite une policy RLS sur `reservations` pour le propriétaire du lieu).
- [ ] Interface annonceur dédiée (espace séparé de l'interface voyageur).
- [ ] Avis & notes voyageurs.

---

## 👥 Équipe
Projet mobile académique. Backend & structure : Giselle. Front-end : binôme dédié.

> ⚠️ Projet pédagogique — la clé Supabase publique embarquée est protégée par les
> règles RLS ; ne pas y stocker de données sensibles réelles.
