/**
 * GET /api/config
 * Expose au navigateur uniquement les valeurs publiques nécessaires
 * (URL Supabase + clé anon). La clé service_role ne sort JAMAIS d'ici.
 */
module.exports = (req, res) => {
  res.setHeader("Cache-Control", "public, max-age=300");
  res.status(200).json({
    supabaseUrl: process.env.SUPABASE_URL || "",
    supabaseAnonKey: process.env.SUPABASE_ANON_KEY || "",
  });
};
