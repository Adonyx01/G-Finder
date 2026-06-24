-- =====================================================================
-- ChezMoi — Côté ANNONCEUR
-- Les annonceurs (profiles.account_type = 'annonceur') publient et gèrent
-- leurs propres établissements, avec photos hébergées sur Supabase Storage.
-- Publication immédiate (status 'active'). Localisation par coordonnées GPS.
-- Script idempotent : réexécutable sans risque.
-- =====================================================================

-- ---- 1. Le trigger récupère le type de compte choisi à l'inscription ----
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, email, prenom, nom, display_name, account_type)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'prenom', ''),
    coalesce(new.raw_user_meta_data->>'nom', ''),
    coalesce(
      new.raw_user_meta_data->>'display_name',
      new.raw_user_meta_data->>'full_name',
      ''
    ),
    -- 'traveler' par défaut ; 'annonceur' si choisi à l'inscription
    case
      when new.raw_user_meta_data->>'account_type' = 'annonceur' then 'annonceur'
      else 'traveler'
    end
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

-- ---- 2. Propriétaire d'un établissement ----
-- null = donnée de simulation (seed), sans propriétaire.
alter table public.places
  add column if not exists owner_id uuid references auth.users(id) on delete set null;

create index if not exists places_owner_idx on public.places (owner_id);

-- ---- 3. RLS : un annonceur gère SES établissements ----
-- (la policy places_public_read de 0001 laisse déjà tout le monde lire les
--  établissements 'active'.)

-- L'annonceur voit ses propres établissements quel que soit leur statut.
drop policy if exists places_owner_read on public.places;
create policy places_owner_read on public.places
  for select using (auth.uid() = owner_id);

-- Créer : il faut être annonceur ET se déclarer propriétaire du lieu.
drop policy if exists places_owner_insert on public.places;
create policy places_owner_insert on public.places
  for insert with check (
    auth.uid() = owner_id
    and exists (
      select 1 from public.profiles p
      where p.id = auth.uid() and p.account_type = 'annonceur'
    )
  );

-- Modifier / supprimer : uniquement ses propres établissements.
drop policy if exists places_owner_update on public.places;
create policy places_owner_update on public.places
  for update using (auth.uid() = owner_id) with check (auth.uid() = owner_id);

drop policy if exists places_owner_delete on public.places;
create policy places_owner_delete on public.places
  for delete using (auth.uid() = owner_id);

-- ---- 4. Stockage des photos (bucket public en lecture) ----
insert into storage.buckets (id, name, public)
values ('place-photos', 'place-photos', true)
on conflict (id) do update set public = true;

-- Lecture publique des photos.
drop policy if exists place_photos_public_read on storage.objects;
create policy place_photos_public_read on storage.objects
  for select using (bucket_id = 'place-photos');

-- Upload réservé aux utilisateurs connectés, dans ce bucket.
drop policy if exists place_photos_insert on storage.objects;
create policy place_photos_insert on storage.objects
  for insert to authenticated
  with check (bucket_id = 'place-photos');

-- Mise à jour / suppression : uniquement ses propres fichiers.
drop policy if exists place_photos_update on storage.objects;
create policy place_photos_update on storage.objects
  for update to authenticated
  using (bucket_id = 'place-photos' and owner = auth.uid());

drop policy if exists place_photos_delete on storage.objects;
create policy place_photos_delete on storage.objects
  for delete to authenticated
  using (bucket_id = 'place-photos' and owner = auth.uid());
