-- =====================================================================
-- ChezMoi — App voyages Gabon (hôtels / restaurants / activités)
-- Schéma initial : auth, catalogue unifié (places), favoris, réservations.
-- Mode simulation : on ajoute les établissements nous-mêmes (voir seed).
-- À exécuter dans l'éditeur SQL de Supabase.
-- =====================================================================

create extension if not exists "pgcrypto";

-- =====================================================================
-- RÉINITIALISATION (script ré-exécutable)
-- Repart d'un schéma propre à chaque exécution.
-- N'efface PAS les comptes auth.users : le profil est recréé à la
-- prochaine connexion (AuthService.ensureProfile + trigger).
-- ⚠️ Efface les données applicatives (places, réservations, favoris…).
-- =====================================================================
drop table if exists public.reservations              cascade;
drop table if exists public.saved_places              cascade;
drop table if exists public.place_reports             cascade;
drop table if exists public.support_requests          cascade;
drop table if exists public.account_deletion_requests cascade;
drop table if exists public.amenities                 cascade;
drop table if exists public.places                    cascade;
drop table if exists public.profiles                  cascade;

-- =====================================================================
-- PROFILES (1 ligne par utilisateur auth)
-- =====================================================================
create table if not exists public.profiles (
  id            uuid primary key references auth.users(id) on delete cascade,
  email         text,
  prenom        text,
  nom           text,
  display_name  text,
  phone         text,
  avatar_url    text,
  location      text,
  country_code  text not null default 'GA',
  country_name  text not null default 'Gabon',
  location_lat  double precision,
  location_lng  double precision,
  account_type  text not null default 'traveler',
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

-- Création automatique du profil dès l'inscription (email/mot de passe ou OAuth)
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, email, prenom, nom, display_name)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'prenom', ''),
    coalesce(new.raw_user_meta_data->>'nom', ''),
    coalesce(
      new.raw_user_meta_data->>'display_name',
      new.raw_user_meta_data->>'full_name',
      ''
    )
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- =====================================================================
-- PLACES — catalogue unifié hôtels / restaurants / activités
-- =====================================================================
create table if not exists public.places (
  id             uuid primary key default gen_random_uuid(),
  category       text not null check (category in ('hotel','restaurant','activity')),
  title          text not null,
  public_code    text,
  description    text,
  subtype        text,                       -- sous-type : hotel/hostel/... | cuisine | type d'activité
  price          numeric,
  currency       text not null default 'XAF',
  price_unit     text not null default 'night'  -- night | person | table | session
                 check (price_unit in ('night','person','table','session')),
  star_rating    int check (star_rating between 0 and 5),
  guest_rating   numeric check (guest_rating >= 0 and guest_rating <= 10),
  review_count   int not null default 0,
  max_guests     int,
  address        text,
  neighborhood   text,
  city           text,
  country_code   text not null default 'GA',
  latitude       double precision,
  longitude      double precision,
  cover_image_url text,
  image_urls     text[] not null default '{}',
  amenities      text[] not null default '{}',   -- libellés (ex : 'Wi-Fi','Piscine')
  details        jsonb  not null default '{}'::jsonb, -- specs par catégorie
  is_featured    boolean not null default false,
  view_count     int not null default 0,
  status         text not null default 'active' check (status in ('active','hidden','draft')),
  created_at     timestamptz not null default now()
);

create index if not exists places_category_idx on public.places (category);
create index if not exists places_status_idx   on public.places (status);
create index if not exists places_city_idx     on public.places (city);

-- =====================================================================
-- AMENITIES — options de filtre (équipements / services)
-- =====================================================================
create table if not exists public.amenities (
  key        text primary key,
  label      text not null,
  applies_to text[] not null default '{hotel,restaurant,activity}',
  sort_order int not null default 0
);

-- =====================================================================
-- SAVED_PLACES — favoris
-- =====================================================================
create table if not exists public.saved_places (
  user_id    uuid not null references auth.users(id) on delete cascade,
  place_id   uuid not null references public.places(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, place_id)
);

-- =====================================================================
-- RESERVATIONS
-- =====================================================================
create table if not exists public.reservations (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references auth.users(id) on delete cascade,
  place_id      uuid not null references public.places(id) on delete cascade,
  category      text not null,
  status        text not null default 'pending'
                check (status in ('pending','confirmed','cancelled','completed')),
  start_date    date,            -- hôtel : arrivée ; resto/activité : date
  end_date      date,            -- hôtel : départ
  time_slot     text,            -- resto/activité : créneau horaire
  guests        int not null default 1,
  total_price   numeric,
  currency      text not null default 'XAF',
  contact_phone text,
  note          text,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

create index if not exists reservations_user_idx  on public.reservations (user_id, created_at desc);
create index if not exists reservations_place_idx on public.reservations (place_id);

-- =====================================================================
-- SUPPORT / SIGNALEMENTS / SUPPRESSION DE COMPTE
-- =====================================================================
create table if not exists public.support_requests (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid references auth.users(id) on delete set null,
  email      text,
  subject    text,
  reason     text,
  message    text,
  status     text not null default 'new',
  created_at timestamptz not null default now()
);

create table if not exists public.place_reports (
  id          uuid primary key default gen_random_uuid(),
  place_id    uuid references public.places(id) on delete cascade,
  reporter_id uuid references auth.users(id) on delete set null,
  reason      text not null,
  message     text,
  status      text not null default 'new',
  created_at  timestamptz not null default now()
);

create table if not exists public.account_deletion_requests (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references auth.users(id) on delete cascade,
  email      text,
  reason     text,
  status     text not null default 'pending',
  created_at timestamptz not null default now()
);

-- =====================================================================
-- ROW LEVEL SECURITY
-- =====================================================================
alter table public.profiles                  enable row level security;
alter table public.places                    enable row level security;
alter table public.amenities                 enable row level security;
alter table public.saved_places              enable row level security;
alter table public.reservations              enable row level security;
alter table public.support_requests          enable row level security;
alter table public.place_reports             enable row level security;
alter table public.account_deletion_requests enable row level security;

-- profiles : chacun ne voit/modifie que le sien
drop policy if exists profiles_select_own on public.profiles;
create policy profiles_select_own on public.profiles
  for select using (auth.uid() = id);
drop policy if exists profiles_insert_own on public.profiles;
create policy profiles_insert_own on public.profiles
  for insert with check (auth.uid() = id);
drop policy if exists profiles_update_own on public.profiles;
create policy profiles_update_own on public.profiles
  for update using (auth.uid() = id) with check (auth.uid() = id);

-- places / amenities : catalogue public en lecture (même non connecté)
drop policy if exists places_public_read on public.places;
create policy places_public_read on public.places
  for select using (status = 'active');
drop policy if exists amenities_public_read on public.amenities;
create policy amenities_public_read on public.amenities
  for select using (true);

-- favoris : chacun les siens
drop policy if exists saved_select_own on public.saved_places;
create policy saved_select_own on public.saved_places
  for select using (auth.uid() = user_id);
drop policy if exists saved_insert_own on public.saved_places;
create policy saved_insert_own on public.saved_places
  for insert with check (auth.uid() = user_id);
drop policy if exists saved_delete_own on public.saved_places;
create policy saved_delete_own on public.saved_places
  for delete using (auth.uid() = user_id);

-- réservations : chacun les siennes
drop policy if exists res_select_own on public.reservations;
create policy res_select_own on public.reservations
  for select using (auth.uid() = user_id);
drop policy if exists res_insert_own on public.reservations;
create policy res_insert_own on public.reservations
  for insert with check (auth.uid() = user_id);
drop policy if exists res_update_own on public.reservations;
create policy res_update_own on public.reservations
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
drop policy if exists res_delete_own on public.reservations;
create policy res_delete_own on public.reservations
  for delete using (auth.uid() = user_id);

-- support / signalements / suppression
drop policy if exists support_insert on public.support_requests;
create policy support_insert on public.support_requests
  for insert with check (auth.uid() = user_id or user_id is null);
drop policy if exists reports_insert on public.place_reports;
create policy reports_insert on public.place_reports
  for insert with check (auth.uid() = reporter_id);
drop policy if exists deletion_insert_own on public.account_deletion_requests;
create policy deletion_insert_own on public.account_deletion_requests
  for insert with check (auth.uid() = user_id);
drop policy if exists deletion_select_own on public.account_deletion_requests;
create policy deletion_select_own on public.account_deletion_requests
  for select using (auth.uid() = user_id);
