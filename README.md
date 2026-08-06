# Maison Liora

Application de décoration d'intérieur — espace client (dossier projet, questionnaire, upload, rendez-vous, suivi) + espace administrateur (décoratrice).

Stack : **HTML/CSS/JS vanilla** + **fonctions serverless Vercel** (Node/CommonJS) + **Supabase** (Auth, Postgres, Storage).

---

## 1. Arborescence du projet

```
maison-liora/
├── index.html                     # Landing page
├── login.html                     # Connexion
├── register.html                  # Inscription
├── forgot-password.html           # Mot de passe oublié
├── dashboard.html                 # Tableau de bord client
├── nouveau-projet.html            # Assistant de création de dossier (7 étapes)
├── suivi.html                     # Suivi d'un dossier (statut, notes)
├── profil.html                    # Profil utilisateur
├── pages/
│   └── admin/
│       ├── dashboard.html         # Liste de tous les dossiers, filtre par statut
│       ├── clients.html           # Liste de tous les clients
│       └── projet-detail.html     # Détail dossier : statut, questionnaire, fichiers, notes, RDV
├── config/
│   └── brand.config.js            # Identité de marque centralisée (nom, couleurs, polices, listes)
├── css/
│   └── style.css                  # Système de design (miroir CSS de brand.config.js)
├── js/
│   └── supabase-client.js         # Initialisation du client Supabase + aides de session
├── api/
│   └── config.js                  # Fonction serverless exposant SUPABASE_URL / ANON_KEY au navigateur
├── assets/
│   ├── favicon.svg
│   ├── logo-icon-light.svg / logo-icon-dark.svg
│   └── logo-horizontal-light.svg / logo-horizontal-dark.svg
├── supabase/
│   └── schema.sql                 # Tables, RLS, triggers, policies Storage
├── .env.example
├── package.json
└── vercel.json
```

---

## 2. Base de données Supabase

Tables créées par `supabase/schema.sql` : `profiles`, `admins`, `projects`, `questionnaires`, `appointments`, `files`, `project_notes`, `statuses`.

- Row Level Security activée partout : un client ne voit/modifie que ses propres lignes (via `client_id` / relation à `project_id`) ; l'admin (présent dans la table `admins`) voit tout.
- Un trigger crée automatiquement une ligne `profiles` à chaque inscription.
- Deux **buckets Storage privés** sont nécessaires, à créer manuellement dans Supabase Studio (Storage → New bucket) :
  - `photos-projets`
  - `documents-projets`
  Les policies de ces buckets sont incluses en fin de `schema.sql`.

### Créer le premier compte admin
1. Inscrivez-vous normalement sur `/register.html` avec l'e-mail qui doit être admin.
2. Dans Supabase Studio → Authentication → Users, copiez son UUID.
3. Dans le SQL editor : `insert into public.admins (user_id) values ('UUID_ICI');`

---

## 3. Variables d'environnement

À définir dans **Vercel → Project Settings → Environment Variables** (voir aussi `.env.example`) :

| Variable | Où la trouver | Utilisée par |
|---|---|---|
| `SUPABASE_URL` | Supabase → Project Settings → API | `api/config.js` (exposée au navigateur) |
| `SUPABASE_ANON_KEY` | Supabase → Project Settings → API | `api/config.js` (exposée au navigateur) |
| `SUPABASE_SERVICE_KEY` | Supabase → Project Settings → API → service_role | réservée à de futures fonctions admin côté serveur — **ne jamais exposer au navigateur** |

Le navigateur ne reçoit jamais directement ces variables : `js/supabase-client.js` les récupère via l'appel à `/api/config`, qui ne renvoie que les valeurs publiques (`SUPABASE_URL`, `SUPABASE_ANON_KEY`).

---

## 4. Déploiement — GitHub + Vercel + Supabase

**Supabase**
1. Créer un nouveau projet sur [supabase.com](https://supabase.com).
2. Ouvrir le SQL editor → coller le contenu de `supabase/schema.sql` → exécuter.
3. Storage → créer les buckets `photos-projets` et `documents-projets` (privés).
4. Noter `Project URL` et `anon public key` (Project Settings → API).

**GitHub**
1. Créer un nouveau dépôt et y pousser l'ensemble de ce dossier.

**Vercel**
1. Importer le dépôt GitHub dans Vercel (New Project).
2. Aucune commande de build n'est nécessaire (site statique + fonctions `api/`) — laisser les réglages par défaut.
3. Renseigner les variables d'environnement de la section 3.
4. Déployer.
5. Tester : inscription (`/register.html`), création d'un dossier (`/nouveau-projet.html`), puis passer ce compte en admin (section 2) et vérifier `/pages/admin/dashboard.html`.

---

## 5. État de ce livrable — ce qui est fonctionnel, ce qui reste à faire

**Fonctionnel de bout en bout** : inscription/connexion/mot de passe oublié, création de dossier en 7 étapes (type, style, questionnaire, mesures, upload photos, upload documents, demande de RDV), tableau de bord client, suivi de dossier avec timeline de statut, profil, tableau de bord admin avec filtre par statut, liste des clients, détail de dossier admin avec changement de statut et ajout de notes (internes ou visibles côté client), consultation sécurisée des fichiers via URLs signées.

**Volontairement simplifié, à enrichir selon vos retours** :
- La « messagerie » est pour l'instant portée par les notes de suivi (`project_notes`), plus simple qu'un vrai fil de discussion en temps réel — suffisant pour démarrer, extensible ensuite (ex. Supabase Realtime).
- La gestion des rendez-vous côté admin est en lecture seule dans le détail dossier (pas encore de confirmation/replanification en un clic) : à ajouter selon votre façon de gérer votre agenda (Calendly, Google Calendar, ou un vrai calendrier interne).
- Suppression/archivage de dossier pas encore implémenté (RLS empêche déjà la suppression côté client ; à ajouter côté admin si besoin).
- Le logo fourni est un monogramme SVG simple (arche + colonne, cercle olive/doré) pensé comme base solide et modifiable — à affiner ou remplacer par une version dessinée par un graphiste si vous le souhaitez.
- Les polices sont chargées depuis Google Fonts (Fraunces + Inter) : à héberger en local si vous voulez éviter toute dépendance externe.

Aucune valeur de contact, SIRET ou domaine n'a été inventée : les champs correspondants sont vides dans `config/brand.config.js`, à compléter quand vous les aurez.
