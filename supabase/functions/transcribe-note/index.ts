// supabase/functions/transcribe-note/index.ts
// Pipeline : audio → Whisper → reformulation IA → note clinique
// Multi-pratique : podologie, soins infirmiers, plaies, réadaptation, etc.
//
// Entrée : { audio_path, type_pratique?, champs_structures? }
// Sortie : { transcription, note_reformulee }

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// ─── Config ──────────────────────────────────────────────────────────────────

const MAX_AUDIO_SIZE = 20 * 1024 * 1024;
const FETCH_TIMEOUT_MS = 55_000;

const ALLOWED_AUDIO: Record<string, string> = {
  m4a:  "audio/mp4",
  mp3:  "audio/mpeg",
  mp4:  "audio/mp4",
  wav:  "audio/wav",
  webm: "audio/webm",
  ogg:  "audio/ogg",
  flac: "audio/flac",
};

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

// ─── Vocabulaire Whisper par pratique ─────────────────────────────────────────

const WHISPER_LEXICON: Record<string, string> = {
  podologie:
    "podologie, soins podologiques, ongles incarnés, callosités, hyperkératose, " +
    "débrider, fraise, excavateur, orthèse plantaire, hallux valgus, onychomycose, " +
    "cors, durillons, kératolyse, matricectomie",

  "soins infirmiers":
    "soins infirmiers, pansement, plaie, évaluation, signes vitaux, glycémie, " +
    "injection, insuline, cathéter, stomie, perfusion, prélèvement, saturométrie, " +
    "tension artérielle, auscultation, drain",

  "soins de plaies":
    "plaie chronique, plaie aiguë, débridement, granulation, épithélialisation, " +
    "exsudat, biofilm, pansement hydrocellulaire, hydrofibre, Aquacel, Mepilex, " +
    "thérapie par pression négative, mesure de la plaie, bords de plaie",

  réadaptation:
    "réadaptation, physiothérapie, ergothérapie, amplitude articulaire, " +
    "mobilisation, transfert, aide technique, marchette, canne, équilibre, " +
    "renforcement musculaire, programme d'exercices, autonomie fonctionnelle",

  "soins de soutien":
    "soins de soutien, aide à domicile, AVQ, AVD, hygiène, bain, habillage, " +
    "alimentation, mobilité, surveillance, accompagnement, plan d'intervention",

  "soins dentaires":
    "soins dentaires, hygiène buccale, prothèse dentaire, gingivite, " +
    "détartrage, examen buccal, carie, fluorure, parodontite",
};

const WHISPER_BASE =
  "Transcription en français québécois. Vocabulaire de santé à domicile : " +
  "visite à domicile, patient, patiente, évaluation clinique, note clinique, " +
  "observation, plan de traitement, suivi, référence, CLSC, CISSS, stérilisation.";

// ─── Helpers ─────────────────────────────────────────────────────────────────

function json(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function fetchWithTimeout(url: string, init: RequestInit): Promise<Response> {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), FETCH_TIMEOUT_MS);
  return fetch(url, { ...init, signal: controller.signal })
    .finally(() => clearTimeout(timer));
}

function whisperPrompt(typePratique: string): string {
  const key = typePratique.toLowerCase();
  const specific = WHISPER_LEXICON[key];
  return specific ? `${WHISPER_BASE} ${specific}` : WHISPER_BASE;
}

function fileExt(path: string): string | null {
  const dot = path.lastIndexOf(".");
  return dot === -1 ? null : path.substring(dot + 1).toLowerCase();
}

function sanitizeTypePratique(raw: unknown): string {
  if (typeof raw === "string" && raw.trim().length > 0 && raw.trim().length < 100) {
    return raw.trim();
  }
  return "soins à domicile";
}

// ─── Handler ─────────────────────────────────────────────────────────────────

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return json({ error: "Méthode non autorisée" }, 405);
  }

  const startMs = Date.now();
  let userId: string | null = null;

  const serviceClient = createClient(
    Deno.env.get("SUPABASE_URL") ?? "",
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
  );

  async function log(statut: "success" | "error", extra: Record<string, unknown> = {}) {
    if (!userId) return;
    try {
      await serviceClient.from("ia_logs").insert({
        user_id: userId,
        fonction: "transcribe-note",
        statut,
        duree_ms: Date.now() - startMs,
        ...extra,
      });
    } catch (_) { /* never block */ }
  }

  try {
    // ── Auth ────────────────────────────────────────────────────────────────
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return json({ error: "Non autorisé : Authorization manquant" }, 401);
    }

    const userClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      { global: { headers: { Authorization: authHeader } } }
    );

    const { data: { user }, error: authError } = await userClient.auth.getUser();
    if (authError || !user) {
      return json({ error: "Non autorisé : token invalide" }, 401);
    }
    userId = user.id;

    // ── Input ───────────────────────────────────────────────────────────────
    const body = await req.json();
    const { audio_path, type_pratique, champs_structures } = body;

    if (!audio_path || typeof audio_path !== "string") {
      return json({ error: "audio_path manquant ou invalide" }, 400);
    }

    if (!audio_path.startsWith(user.id + "/")) {
      return json({ error: "Accès refusé : ce fichier ne vous appartient pas" }, 403);
    }

    const ext = fileExt(audio_path);
    if (!ext || !(ext in ALLOWED_AUDIO)) {
      return json({
        error: `Format non supporté (${ext ?? "inconnu"}). Acceptés : ${Object.keys(ALLOWED_AUDIO).join(", ")}`,
      }, 400);
    }

    const openaiApiKey = Deno.env.get("OPENAI_API_KEY");
    if (!openaiApiKey) {
      return json({ error: "Configuration serveur manquante" }, 500);
    }

    // ── Download ────────────────────────────────────────────────────────────
    const { data: audioBlob, error: storageError } = await serviceClient
      .storage.from("audio-notes")
      .download(audio_path);

    if (storageError || !audioBlob) {
      console.error("Storage:", storageError);
      await log("error", { erreur_message: `Storage: ${storageError?.message ?? "introuvable"}` });
      return json({ error: "Impossible de télécharger le fichier audio" }, 502);
    }

    if (audioBlob.size === 0) {
      await log("error", { erreur_message: "Fichier vide (0 bytes)" });
      return json({ error: "Fichier audio vide" }, 400);
    }

    if (audioBlob.size > MAX_AUDIO_SIZE) {
      await log("error", { erreur_message: `Taille: ${(audioBlob.size / 1024 / 1024).toFixed(1)} MB` });
      return json({ error: `Fichier trop volumineux (max ${MAX_AUDIO_SIZE / 1024 / 1024} MB)` }, 413);
    }

    // MIME validation: Supabase Storage returns a Blob with a type property.
    // If present and not generic, verify it matches an audio type.
    const blobType = audioBlob.type;
    if (blobType && blobType !== "application/octet-stream" && !blobType.startsWith("audio/")) {
      await log("error", { erreur_message: `MIME invalide: ${blobType}` });
      return json({ error: `Type de fichier invalide (${blobType}). Un fichier audio est requis.` }, 400);
    }

    // ── Whisper ─────────────────────────────────────────────────────────────
    const typePratique = sanitizeTypePratique(type_pratique);
    const expectedMime = ALLOWED_AUDIO[ext];

    // Re-wrap blob with correct MIME so Whisper detects the codec properly
    const audioFile = new File([audioBlob], `audio.${ext}`, { type: expectedMime });

    const formData = new FormData();
    formData.append("file", audioFile);
    formData.append("model", "whisper-1");
    formData.append("language", "fr");
    formData.append("prompt", whisperPrompt(typePratique));

    const whisperRes = await fetchWithTimeout(
      "https://api.openai.com/v1/audio/transcriptions",
      {
        method: "POST",
        headers: { "Authorization": `Bearer ${openaiApiKey}` },
        body: formData,
      }
    );

    if (!whisperRes.ok) {
      const errBody = await whisperRes.text();
      console.error("Whisper:", whisperRes.status, errBody);
      await log("error", { erreur_message: `Whisper ${whisperRes.status}: ${errBody.substring(0, 300)}` });
      return json({ error: "Erreur lors de la transcription audio" }, 502);
    }

    const transcription = (await whisperRes.json()).text?.trim();

    if (!transcription) {
      await log("error", { erreur_message: "Transcription vide" });
      return json({ error: "Transcription vide — vérifier le fichier audio" }, 422);
    }

    // ── Reformulation ───────────────────────────────────────────────────────
    const systemPrompt = `Tu es un assistant clinique pour professionnels de santé au Québec.
Domaine de pratique : ${typePratique}.
Tu reformules des observations dictées à voix haute en notes cliniques professionnelles.

Règles absolues :
- Tu utilises UNIQUEMENT ce qui a été dicté. Tu n'inventes rien.
- Si une information n'est pas dans la dictée, tu ne l'inclus pas.
- Tu corriges les déformations phonétiques évidentes des termes cliniques.
- Tu adaptes le vocabulaire au domaine de pratique indiqué.
- Français professionnel québécois, concis, sans listes à puces.
- Longueur cible : 100-200 mots.`;

    let userPrompt = `Voici la dictée brute transcrite :\n"${transcription}"\n`;

    if (
      champs_structures &&
      typeof champs_structures === "object" &&
      !Array.isArray(champs_structures) &&
      Object.keys(champs_structures).length > 0
    ) {
      userPrompt += `\nContexte clinique complémentaire (ne répéter que si pertinent) :\n${JSON.stringify(champs_structures, null, 2)}\n`;
    }

    userPrompt += `\nReformule en note clinique professionnelle.`;

    const gptRes = await fetchWithTimeout(
      "https://api.openai.com/v1/chat/completions",
      {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${openaiApiKey}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          model: "gpt-4o-mini",
          temperature: 0.2,
          max_tokens: 400,
          messages: [
            { role: "system", content: systemPrompt },
            { role: "user", content: userPrompt },
          ],
        }),
      }
    );

    if (!gptRes.ok) {
      const errBody = await gptRes.text();
      console.error("GPT:", gptRes.status, errBody);
      await log("error", { erreur_message: `GPT ${gptRes.status}: ${errBody.substring(0, 300)}` });
      return json({ error: "Erreur lors de la reformulation" }, 502);
    }

    const gptData = await gptRes.json();
    const noteReformulee = gptData.choices?.[0]?.message?.content?.trim();

    // ── Log ─────────────────────────────────────────────────────────────────
    await log("success", {
      tokens_input: gptData.usage?.prompt_tokens ?? 0,
      tokens_output: gptData.usage?.completion_tokens ?? 0,
      type_pratique: typePratique,
      mode_ia_note: "dictée vocale",
    });

    // ── Response ─────────────────────────────────────────────────────────────
    return json({
      transcription,
      note_reformulee: noteReformulee ?? transcription,
    }, 200);

  } catch (error) {
    console.error("Erreur inattendue:", error);
    const msg = error instanceof Error ? error.message : "Erreur inconnue";

    if (msg.includes("aborted")) {
      await log("error", { erreur_message: "Timeout dépassé" });
      return json({ error: "Délai dépassé — fichier audio trop long ou serveur lent" }, 504);
    }

    await log("error", { erreur_message: msg.substring(0, 500) });
    return json({ error: "Erreur interne du serveur" }, 500);
  }
});
