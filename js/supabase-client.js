/**
 * Client Supabase côté navigateur.
 * Utilise uniquement la clé publique (anon) — jamais la clé service_role ici.
 * SUPABASE_URL / SUPABASE_ANON_KEY sont injectées au build via
 * l'endpoint /api/config (voir api/config.js) pour éviter de les
 * écrire en dur dans le HTML statique.
 */

let supabaseClientInstance = null;

async function obtenirClientSupabase() {
  if (supabaseClientInstance) return supabaseClientInstance;

  const reponse = await fetch("/api/config");
  if (!reponse.ok) {
    throw new Error("Impossible de charger la configuration Supabase");
  }
  const { supabaseUrl, supabaseAnonKey } = await reponse.json();

  if (!supabaseUrl || !supabaseAnonKey) {
    throw new Error("Configuration Supabase manquante côté serveur");
  }

  supabaseClientInstance = window.supabase.createClient(supabaseUrl, supabaseAnonKey, {
    auth: { persistSession: true, autoRefreshToken: true },
  });
  return supabaseClientInstance;
}

// Petites aides de session partagées entre les pages
async function utilisateurCourant() {
  const client = await obtenirClientSupabase();
  const { data } = await client.auth.getSession();
  return data.session?.user || null;
}

async function exigerSession(redirectionVers = "/login.html") {
  const utilisateur = await utilisateurCourant();
  if (!utilisateur) {
    window.location.href = redirectionVers;
    return null;
  }
  return utilisateur;
}

async function estAdmin(userId) {
  const client = await obtenirClientSupabase();
  const { data } = await client.from("admins").select("user_id").eq("user_id", userId).maybeSingle();
  return !!data;
}

function afficherToast(message, estUneErreur = false) {
  let toast = document.querySelector(".toast");
  if (!toast) {
    toast = document.createElement("div");
    toast.className = "toast";
    document.body.appendChild(toast);
  }
  toast.textContent = message;
  toast.classList.toggle("toast-erreur", estUneErreur);
  toast.classList.add("visible");
  clearTimeout(toast._timer);
  toast._timer = setTimeout(() => toast.classList.remove("visible"), 3200);
}
