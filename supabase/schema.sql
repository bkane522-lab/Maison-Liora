-- ============================================================
--  MAISON LIORA — SCHÉMA SUPABASE
--  À exécuter dans l'éditeur SQL du projet Supabase (une seule fois).
-- ============================================================

-- Extension nécessaire pour gen_random_uuid()
create extension if not exists "pgcrypto";

-- ------------------------------------------------------------
-- TABLE : profiles (1 ligne par utilisateur, miroir de auth.users)
-- ------------------------------------------------------------
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  nom_complet text,
  email text,
  telephone text,
  created_at timestamptz not null default now()
);

-- ------------------------------------------------------------
-- TABLE : admins (liste blanche des comptes admin)
-- Un utilisateur devient admin uniquement si son id apparaît ici.
-- Insertion manuelle depuis le SQL editor Supabase, jamais depuis le client.
-- ------------------------------------------------------------
create table if not exists public.admins (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

-- ------------------------------------------------------------
-- TABLE : projects
-- ------------------------------------------------------------
create table if not exists public.projects (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null references auth.users(id) on delete cascade,
  titre text,
  type_projet text not null,
  style text,
  statut text not null default 'recu',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ------------------------------------------------------------
-- TABLE : questionnaires (1-1 avec projects)
-- ------------------------------------------------------------
create table if not exists public.questionnaires (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects(id) on delete cascade,
  pieces text,
  budget text,
  delai text,
  description text,
  longueur_m numeric,
  largeur_m numeric,
  hauteur_m numeric,
  notes_mesures text,
  created_at timestamptz not null default now()
);

-- ------------------------------------------------------------
-- TABLE : appointments
-- ------------------------------------------------------------
create table if not exists public.appointments (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects(id) on delete cascade,
  date_souhaitee date,
  creneau text,
  statut text not null default 'demandee', -- demandee | confirmee | annulee
  created_at timestamptz not null default now()
);

-- ------------------------------------------------------------
-- TABLE : files (photos + documents, métadonnées seulement —
-- les fichiers eux-mêmes vivent dans Supabase Storage)
-- ------------------------------------------------------------
create table if not exists public.files (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects(id) on delete cascade,
  bucket text not null,
  chemin text not null,
  nom_original text,
  categorie text not null, -- photo | document
  created_at timestamptz not null default now()
);

-- ------------------------------------------------------------
-- TABLE : project_notes (notes de suivi, internes ou visibles client)
-- ------------------------------------------------------------
create table if not exists public.project_notes (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects(id) on delete cascade,
  auteur_id uuid references auth.users(id),
  contenu text not null,
  visible_client boolean not null default false,
  created_at timestamptz not null default now()
);

-- ------------------------------------------------------------
-- TABLE : statuses (référentiel — optionnel, la liste vit surtout
-- dans config/brand.config.js ; cette table permet une évolution
-- future côté back-office sans redéploiement)
-- ------------------------------------------------------------
create table if not exists public.statuses (
  id text primary key,
  label text not null,
  ordre integer not null
);
insert into public.statuses (id, label, ordre) values
  ('recu', 'Dossier reçu', 1),
  ('en-analyse', 'En analyse', 2),
  ('attente-infos', 'En attente d''informations', 3),
  ('rdv-programme', 'Rendez-vous programmé', 4),
  ('proposition', 'Proposition en cours', 5),
  ('termine', 'Terminé', 6)
on conflict (id) do nothing;

-- ------------------------------------------------------------
-- TRIGGER : création automatique du profil à l'inscription
-- ------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email, nom_complet)
  values (new.id, new.email, new.raw_user_meta_data->>'nom_complet')
  on conflict (id) do nothing;
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ------------------------------------------------------------
-- FONCTION UTILITAIRE : est-ce l'utilisateur courant un admin ?
-- ------------------------------------------------------------
create or replace function public.est_admin()
returns boolean as $$
  select exists (select 1 from public.admins where user_id = auth.uid());
$$ language sql security definer stable;

-- ============================================================
-- ROW LEVEL SECURITY
-- Chaque client ne voit que ses propres données. L'admin voit tout.
-- ============================================================

alter table public.profiles enable row level security;
alter table public.admins enable row level security;
alter table public.projects enable row level security;
alter table public.questionnaires enable row level security;
alter table public.appointments enable row level security;
alter table public.files enable row level security;
alter table public.project_notes enable row level security;
alter table public.statuses enable row level security;

-- profiles
create policy "profil visible par son propriétaire ou l'admin"
  on public.profiles for select
  using (auth.uid() = id or public.est_admin());
create policy "profil modifiable par son propriétaire"
  on public.profiles for update
  using (auth.uid() = id);

-- admins (lecture seule pour vérifier son propre statut ; aucune écriture côté client)
create policy "un utilisateur peut vérifier s'il est admin"
  on public.admins for select
  using (auth.uid() = user_id or public.est_admin());

-- projects
create policy "un client voit ses projets, l'admin voit tout"
  on public.projects for select
  using (auth.uid() = client_id or public.est_admin());
create policy "un client crée ses propres projets"
  on public.projects for insert
  with check (auth.uid() = client_id);
create policy "seul l'admin modifie un projet (statut, etc.)"
  on public.projects for update
  using (public.est_admin());

-- questionnaires
create policy "lecture questionnaire par le propriétaire du projet ou l'admin"
  on public.questionnaires for select
  using (
    public.est_admin() or
    exists (select 1 from public.projects p where p.id = project_id and p.client_id = auth.uid())
  );
create policy "création questionnaire par le propriétaire du projet"
  on public.questionnaires for insert
  with check (
    exists (select 1 from public.projects p where p.id = project_id and p.client_id = auth.uid())
  );

-- appointments
create policy "lecture rdv par le propriétaire du projet ou l'admin"
  on public.appointments for select
  using (
    public.est_admin() or
    exists (select 1 from public.projects p where p.id = project_id and p.client_id = auth.uid())
  );
create policy "création rdv par le propriétaire du projet"
  on public.appointments for insert
  with check (
    exists (select 1 from public.projects p where p.id = project_id and p.client_id = auth.uid())
  );
create policy "modification rdv par l'admin"
  on public.appointments for update
  using (public.est_admin());

-- files
create policy "lecture fichiers par le propriétaire du projet ou l'admin"
  on public.files for select
  using (
    public.est_admin() or
    exists (select 1 from public.projects p where p.id = project_id and p.client_id = auth.uid())
  );
create policy "ajout fichiers par le propriétaire du projet"
  on public.files for insert
  with check (
    exists (select 1 from public.projects p where p.id = project_id and p.client_id = auth.uid())
  );

-- project_notes
create policy "lecture notes : admin voit tout, client voit les notes visibles"
  on public.project_notes for select
  using (
    public.est_admin() or
    (visible_client = true and exists (select 1 from public.projects p where p.id = project_id and p.client_id = auth.uid()))
  );
create policy "ajout de notes réservé à l'admin"
  on public.project_notes for insert
  with check (public.est_admin());

-- statuses (référentiel public en lecture)
create policy "statuts lisibles par tout utilisateur connecté"
  on public.statuses for select
  using (auth.role() = 'authenticated');

-- ============================================================
-- STORAGE — buckets à créer manuellement dans Supabase Studio
-- (Storage > New bucket), en PRIVÉ (pas de public access) :
--   - photos-projets
--   - documents-projets
-- Puis appliquer les policies ci-dessous (Storage > Policies).
-- ============================================================

-- Lecture/écriture par le propriétaire du dossier (chemin = {user_id}/{project_id}/...)
create policy "upload photos par le propriétaire"
  on storage.objects for insert
  with check (
    bucket_id = 'photos-projets'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
create policy "lecture photos par le propriétaire ou l'admin"
  on storage.objects for select
  using (
    bucket_id = 'photos-projets'
    and ((storage.foldername(name))[1] = auth.uid()::text or public.est_admin())
  );

create policy "upload documents par le propriétaire"
  on storage.objects for insert
  with check (
    bucket_id = 'documents-projets'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
create policy "lecture documents par le propriétaire ou l'admin"
  on storage.objects for select
  using (
    bucket_id = 'documents-projets'
    and ((storage.foldername(name))[1] = auth.uid()::text or public.est_admin())
  );

-- ============================================================
-- POUR CRÉER LE PREMIER COMPTE ADMIN :
-- 1. Inscrivez-vous normalement via /register.html avec l'e-mail admin.
-- 2. Récupérez son id dans Authentication > Users.
-- 3. Exécutez :
--    insert into public.admins (user_id) values ('UUID_DE_L_UTILISATEUR');
-- ============================================================
