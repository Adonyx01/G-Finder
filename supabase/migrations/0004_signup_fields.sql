-- =====================================================================
-- ChezMoi — Champs d'inscription
-- Voyageur : e-mail seul. Annonceur : + nom d'entreprise + téléphone.
-- Ajoute company_name et fait enregistrer entreprise/téléphone par le trigger.
-- Idempotent : réexécutable sans risque.
-- =====================================================================

alter table public.profiles
  add column if not exists company_name text;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (
    id, email, prenom, nom, display_name, phone, company_name, account_type
  )
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'prenom', ''),
    coalesce(new.raw_user_meta_data->>'nom', ''),
    coalesce(
      new.raw_user_meta_data->>'display_name',
      new.raw_user_meta_data->>'company_name',
      new.raw_user_meta_data->>'full_name',
      ''
    ),
    nullif(new.raw_user_meta_data->>'phone', ''),
    nullif(new.raw_user_meta_data->>'company_name', ''),
    case
      when new.raw_user_meta_data->>'account_type' = 'annonceur' then 'annonceur'
      else 'traveler'
    end
  )
  on conflict (id) do nothing;
  return new;
end;
$$;
