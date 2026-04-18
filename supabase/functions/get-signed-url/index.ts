// supabase/functions/get-signed-url/index.ts
// Génère une URL signée temporaire pour afficher un fichier d'un bucket privé.
//
// Sécurité :
//   - Requiert un JWT Supabase valide (utilisateur connecté)
//   - Vérifie que le chemin demandé appartient à l'utilisateur connecté
//     (le premier segment du chemin DOIT être l'uid de l'utilisateur)
//   - Seuls les buckets privés listés dans ALLOWED_BUCKETS sont accessibles
//   - L'URL signée expire après 1 heure (3600 secondes)
//
// Utilisation depuis FlutterFlow :
//   POST /functions/v1/get-signed-url
//   Headers: Authorization: Bearer <userJWT>
//   Body: { "bucket": "signatures", "path": "<uid>/signature_pro.png" }
//   Réponse: { "signedUrl": "https://..." }

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// ─── Config ──────────────────────────────────────────────────────────────────

const ALLOWED_BUCKETS = ["signatures", "soins_photos", "patient-photos"] as const;
type AllowedBucket = typeof ALLOWED_BUCKETS[number];

const SIGNED_URL_EXPIRY_SECONDS = 3600; // 1 heure

// ─── CORS ────────────────────────────────────────────────────────────────────

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

// ─── Handler ─────────────────────────────────────────────────────────────────

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return json({ error: "Méthode non autorisée" }, 405);
  }

  try {
    // 1. Vérifier l'authentification
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return json({ error: "Non autorisé : en-tête Authorization manquant" }, 401);
    }

    const userClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      { global: { headers: { Authorization: authHeader } } }
    );

    const { data: { user }, error: authError } = await userClient.auth.getUser();
    if (authError || !user) {
      return json({ error: "Non autorisé : token invalide ou expiré" }, 401);
    }

    // 2. Parser le corps
    let body: { bucket?: string; path?: string };
    try {
      body = await req.json();
    } catch {
      return json({ error: "Corps de requête JSON invalide" }, 400);
    }

    const { bucket, path } = body;

    if (!bucket || !path) {
      return json({ error: "Paramètres manquants : bucket et path sont requis" }, 400);
    }

    // 3. Vérifier que le bucket est autorisé (pas clinic-assets qui est public)
    if (!ALLOWED_BUCKETS.includes(bucket as AllowedBucket)) {
      return json(
        { error: `Bucket non autorisé. Buckets acceptés : ${ALLOWED_BUCKETS.join(", ")}` },
        403
      );
    }

    // 4. Vérifier l'ownership : le chemin DOIT commencer par l'uid de l'utilisateur
    //    Exemple valide : "5523ea42-8b58-448d-a2a4-520308c63bd4/signature_pro.png"
    const expectedPrefix = user.id + "/";
    if (!path.startsWith(expectedPrefix)) {
      return json({ error: "Accès refusé : ce fichier ne vous appartient pas" }, 403);
    }

    // 5. Générer l'URL signée avec la service role key (contourne RLS pour la lecture)
    const serviceClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    const { data, error: signError } = await serviceClient.storage
      .from(bucket)
      .createSignedUrl(path, SIGNED_URL_EXPIRY_SECONDS);

    if (signError || !data?.signedUrl) {
      console.error("Erreur génération URL signée:", signError);
      return json({ error: "Impossible de générer l'URL signée" }, 500);
    }

    // 6. Retourner l'URL signée
    return json({
      signedUrl: data.signedUrl,
      expiresIn: SIGNED_URL_EXPIRY_SECONDS,
    }, 200);

  } catch (error) {
    console.error("Erreur inattendue:", error);
    return json({ error: "Erreur interne du serveur" }, 500);
  }
});

// ─── Utilitaire ──────────────────────────────────────────────────────────────

function json(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
