// HU-08: analiza hasta 4 fotos importadas por llamada. Para cada una Gemini escribe título,
// categoría, etiquetas y descripción en español, y se guardan con sus embeddings.
//
// Cuerpo: { "foto_ids": ["uuid", ...] }
// Respuesta 200: { "resultados": [{ "foto_id": "...", "estado": "listo" | "error" }] }
// Respuesta 429: { "error": "ocupado", "reintentar_en": 30 }  (límite del plan gratuito)
// Respuesta 503: { "error": "no_disponible" }                  (reintentar más tarde)
//
// Usa el token de quien llama, así que la RLS impide leer o escribir fotos ajenas.

import { createClient, type SupabaseClient } from "npm:@supabase/supabase-js@2";
import { encodeBase64 } from "jsr:@std/encoding@1/base64";
import {
  type Descripcion,
  describir,
  embeddings,
  type FotoParaAnalizar,
  GeminiBloqueado,
  GeminiFallo,
  GeminiOcupado,
  textoParaBuscar,
} from "./gemini.ts";

const MAX_FOTOS = 4;

/** Gemini acepta hasta 20 MB por pedido y el base64 suma un tercio. */
const MAX_BYTES_POR_PEDIDO = 14 * 1024 * 1024;

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

type Estado = "listo" | "error";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  if (req.method !== "POST") return json({ error: "metodo" }, 405);

  const auth = req.headers.get("Authorization");
  if (!auth) return json({ error: "sin_sesion" }, 401);

  let ids: string[];
  try {
    ids = leerIds(await req.json());
  } catch (e) {
    return json({ error: "pedido_invalido", detalle: String(e) }, 400);
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: auth } } },
  );

  try {
    const resultados = await analizar(supabase, ids);
    return json({
      resultados: [...resultados].map(([foto_id, estado]) => ({ foto_id, estado })),
    });
  } catch (e) {
    if (e instanceof GeminiOcupado) {
      return json({ error: "ocupado", reintentar_en: e.reintentarEnSegundos }, 429);
    }
    if (e instanceof GeminiFallo) {
      console.error(e);
      return json({ error: "no_disponible" }, 503);
    }
    console.error(e);
    return json({ error: "interno" }, 500);
  }
});

async function analizar(supabase: SupabaseClient, ids: string[]) {
  const resultados = new Map<string, Estado>();

  const { data: filas, error } = await supabase
    .from("foto")
    .select("id, url_imagen, estado_analisis")
    .in("id", ids);
  if (error) throw error;

  const pendientes: { id: string; ruta: string }[] = [];
  for (const fila of filas ?? []) {
    if (fila.estado_analisis === "pendiente") {
      pendientes.push({ id: fila.id, ruta: fila.url_imagen });
    } else {
      // Otra corrida ya la analizó: no se gasta cuota en repetirla.
      resultados.set(fila.id, fila.estado_analisis);
    }
  }
  // Una foto que no existe o es de otra persona no se ve por la RLS.
  for (const id of ids) {
    if (!resultados.has(id) && !pendientes.some((p) => p.id === id)) {
      resultados.set(id, "error");
    }
  }

  const fotos: FotoParaAnalizar[] = [];
  const tamanos = new Map<string, number>();
  for (const p of pendientes) {
    const { data, error } = await supabase.storage.from("fotos").download(p.ruta);
    if (error || !data) {
      if (esNoEncontrado(error)) {
        await marcarError(supabase, p.id, resultados);
        continue;
      }
      throw error;
    }
    const bytes = new Uint8Array(await data.arrayBuffer());
    tamanos.set(p.id, bytes.length);
    fotos.push({ id: p.id, imagen: encodeBase64(bytes) });
  }

  for (const grupo of agrupar(fotos, tamanos)) {
    const descritas = await describirConRespaldo(grupo);
    const porId = new Map(grupo.map((f) => [f.id, f]));

    const vectores = descritas.length === 0 ? [] : await embeddings(
      descritas.map((d) => ({ imagen: porId.get(d.id)!.imagen, texto: textoParaBuscar(d) })),
    );

    for (const [i, d] of descritas.entries()) {
      const { error } = await supabase.rpc("guardar_analisis_foto", {
        p_foto_id: d.id,
        p_titulo: d.titulo,
        p_categoria: d.categoria,
        p_descripcion: d.descripcion,
        p_etiquetas: d.etiquetas,
        p_embedding_imagen: vector(vectores[i].imagen),
        p_embedding_texto: vector(vectores[i].texto),
      });
      if (error) throw error;
      resultados.set(d.id, "listo");
    }
    for (const f of grupo) {
      if (!resultados.has(f.id)) await marcarError(supabase, f.id, resultados);
    }
  }

  return resultados;
}

/**
 * Si Gemini bloquea o se salta alguna foto de un grupo, las que faltan se piden de a una:
 * así una sola foto problemática no deja sin análisis a las demás.
 */
async function describirConRespaldo(grupo: FotoParaAnalizar[]): Promise<Descripcion[]> {
  let descritas: Descripcion[] = [];
  try {
    descritas = await describir(grupo);
  } catch (e) {
    if (!(e instanceof GeminiBloqueado)) throw e;
    if (grupo.length === 1) return [];
  }
  if (grupo.length === 1 || descritas.length === grupo.length) return descritas;

  const hechas = new Set(descritas.map((d) => d.id));
  for (const foto of grupo.filter((f) => !hechas.has(f.id))) {
    try {
      descritas.push(...await describir([foto]));
    } catch (e) {
      if (!(e instanceof GeminiBloqueado)) throw e;
    }
  }
  return descritas;
}

/** Junta las fotos en pedidos que no pasen el límite de tamaño de Gemini. */
function agrupar(fotos: FotoParaAnalizar[], tamanos: Map<string, number>) {
  const grupos: FotoParaAnalizar[][] = [];
  let actual: FotoParaAnalizar[] = [];
  let bytes = 0;
  for (const f of fotos) {
    const tamano = tamanos.get(f.id) ?? 0;
    if (actual.length > 0 && bytes + tamano > MAX_BYTES_POR_PEDIDO) {
      grupos.push(actual);
      actual = [];
      bytes = 0;
    }
    actual.push(f);
    bytes += tamano;
  }
  if (actual.length > 0) grupos.push(actual);
  return grupos;
}

async function marcarError(
  supabase: SupabaseClient,
  id: string,
  resultados: Map<string, Estado>,
) {
  const { error } = await supabase.rpc("marcar_error_analisis_foto", { p_foto_id: id });
  if (error) throw error;
  resultados.set(id, "error");
}

function leerIds(cuerpo: unknown): string[] {
  const ids = (cuerpo as { foto_ids?: unknown })?.foto_ids;
  if (!Array.isArray(ids) || ids.length === 0 || ids.length > MAX_FOTOS) {
    throw new Error(`foto_ids debe tener entre 1 y ${MAX_FOTOS} ids`);
  }
  if (!ids.every((id) => typeof id === "string" && UUID.test(id))) {
    throw new Error("foto_ids debe tener uuids");
  }
  return [...new Set(ids as string[])];
}

// deno-lint-ignore no-explicit-any
function esNoEncontrado(error: any): boolean {
  const estado = Number(error?.statusCode ?? error?.status ?? error?.originalError?.status);
  return estado === 400 || estado === 404 || /not.?found/i.test(String(error?.message));
}

/** pgvector lee el vector como texto "[0.1,0.2,...]". */
function vector(valores: number[]): string {
  return `[${valores.join(",")}]`;
}

function json(cuerpo: unknown, status = 200): Response {
  return new Response(JSON.stringify(cuerpo), {
    status,
    headers: { ...CORS, "Content-Type": "application/json" },
  });
}
