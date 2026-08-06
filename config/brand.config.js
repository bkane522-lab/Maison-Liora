/**
 * ============================================================
 *  MAISON LIORA — CONFIGURATION DE MARQUE CENTRALISÉE
 * ============================================================
 * Toute référence au nom, slogan, couleurs, polices, domaine
 * doit passer par cet objet. Ne JAMAIS écrire ces valeurs en
 * dur dans les pages HTML/CSS/JS.
 *
 * Utilisation côté navigateur : ce fichier s'expose sur
 * `window.BRAND` (voir le bloc IIFE en bas de fichier).
 * Utilisation côté serverless (api/*.js) : `require('../config/brand.config.js')`.
 * ============================================================
 */

const BRAND = {
  // Identité
  name: "Maison Liora",
  shortName: "Liora",
  tagline: "Votre intérieur, pensé avec sens et élégance.",
  legalName: "", // SIRET / raison sociale — à compléter, ne jamais inventer
  contactEmail: "", // à compléter
  domain: "", // ex: maison-liora.fr — à compléter, configurable en un seul endroit

  // Palette — luxe doux, éditorial, organique
  colors: {
    ivoire: "#FDFBF6",
    creme: "#F6F1E7",
    sable: "#E7DAC3",
    olive: "#3E4A34",
    oliveClair: "#5C6B4C",
    dore: "#B08D57",
    doreClair: "#D4B483",
    texte: "#2B2820",
    texteDoux: "#6B6355",
    bordure: "#E3D9C6",
    blanc: "#FFFFFF",
    erreur: "#A34A3A",
    succes: "#4A5D3A",
  },

  // Typographie
  fonts: {
    display: "'Fraunces', 'Georgia', serif",
    body: "'Inter', system-ui, sans-serif",
    displayGoogleFont: "Fraunces:opsz,wght@9..144,300..600&display=swap",
    bodyGoogleFont: "Inter:wght@400;500;600&display=swap",
  },

  // Logo (texte de repli tant que les fichiers SVG définitifs ne sont pas fournis)
  logo: {
    wordmark: "Maison Liora",
    monogramLetter: "L",
    iconLight: "/assets/logo-icon-light.svg",
    iconDark: "/assets/logo-icon-dark.svg",
    horizontalLight: "/assets/logo-horizontal-light.svg",
    horizontalDark: "/assets/logo-horizontal-dark.svg",
    favicon: "/assets/favicon.svg",
  },

  // Types de projet proposés
  projectTypes: [
    { id: "coaching", label: "Coaching déco" },
    { id: "amenagement", label: "Aménagement" },
    { id: "renovation-legere", label: "Rénovation légère" },
    { id: "conseil-couleur", label: "Conseil couleur" },
    { id: "optimisation-espace", label: "Optimisation d'espace" },
  ],

  // Styles proposés
  styles: [
    { id: "minimaliste", label: "Minimaliste" },
    { id: "contemporain", label: "Contemporain" },
    { id: "chaleureux", label: "Chaleureux" },
    { id: "naturel", label: "Naturel" },
    { id: "luxe-doux", label: "Luxe doux" },
    { id: "boheme-chic", label: "Bohème chic" },
  ],

  // Statuts de dossier (ordre d'affichage)
  statuses: [
    { id: "recu", label: "Dossier reçu" },
    { id: "en-analyse", label: "En analyse" },
    { id: "attente-infos", label: "En attente d'informations" },
    { id: "rdv-programme", label: "Rendez-vous programmé" },
    { id: "proposition", label: "Proposition en cours" },
    { id: "termine", label: "Terminé" },
  ],
};

// Export universel : Node (require) + navigateur (window.BRAND)
if (typeof module !== "undefined" && module.exports) {
  module.exports = BRAND;
}
if (typeof window !== "undefined") {
  window.BRAND = BRAND;
}
