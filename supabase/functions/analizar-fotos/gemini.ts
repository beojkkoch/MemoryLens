// Las dos llamadas a Gemini: describir fotos (generateContent) y generar embeddings
// (gemini-embedding-2). Es el único archivo que conoce la API de Google.

const API = "https://generativelanguage.googleapis.com/v1beta/models";

/** Modelo de visión. Se puede cambiar sin tocar código con el secret GEMINI_MODEL. */
const MODEL = Deno.env.get("GEMINI_MODEL") ?? "gemini-3.8-flash";
const EMBEDDING_MODEL = "gemini-embedding-2";

/** Debe coincidir con vector(768) en la migración. */
export const EMBEDDING_DIMENSIONS = 768;

/** Los nombres exactos de la tabla categoria. */
export const CATEGORIAS = [
  "Factura",
  "Comida",
  "Lugar",
  "Viaje",
  "Mascotas",
  "Personas",
  "Arte",
  "Trabajo",
] as const;

export type Categoria = (typeof CATEGORIAS)[number];

/** Monedas que la IA puede elegir (ISO 4217). Una que no esté aquí deja el monto vacío. */
export const MONEDAS = [
  "COP", "USD", "EUR", "MXN", "PEN", "CLP", "ARS", "BRL", "UYU", "BOB", "PYG", "VES",
  "CRC", "GTQ", "DOP", "PAB", "CAD", "GBP",
] as const;

export type Moneda = (typeof MONEDAS)[number];

/** Datos de una factura (HU-09). Un campo que no se lee con claridad no viene. */
export interface DatosFactura {
  tipoCompra?: string;
  monto?: number;
  moneda?: Moneda;
}

export interface FotoParaAnalizar {
  id: string;
  /** JPEG en base64. */
  imagen: string;
}

export interface Descripcion {
  id: string;
  titulo: string;
  categoria: Categoria;
  etiquetas: string[];
  descripcion: string;
  /** Solo en la categoría Factura. */
  factura?: DatosFactura;
}

/** Lo que se sabe de la persona y ayuda a leer mejor sus fotos. */
export interface Contexto {
  /** Para saber de qué país es un "$" sin más pistas. */
  ciudad?: string;
}

/** Google pidió esperar (límite del plan gratuito). */
export class GeminiOcupado extends Error {
  constructor(readonly reintentarEnSegundos: number) {
    super(`Gemini pidió esperar ${reintentarEnSegundos} s`);
  }
}

/** Gemini se negó a describir lo que se le mandó (filtros de seguridad). */
export class GeminiBloqueado extends Error {}

/** Cualquier otra falla de Google: conviene reintentar más tarde. */
export class GeminiFallo extends Error {}

const INSTRUCCIONES = `Eres el asistente de Memory Lens, una app que organiza la galería de fotos de una persona.
Para cada foto que recibas escribe, siempre en español:
- titulo: un título corto y concreto (máximo 60 caracteres), sin comillas ni emojis. Ejemplos: "Almuerzo de arepas en casa", "Factura de energía de octubre".
- categoria: exactamente una de: ${CATEGORIAS.join(", ")}. Elige la que mejor sirva para encontrar la foto después. Una foto de un recibo o una cuenta es Factura aunque salga comida; una mascota con su dueño es Mascotas; capturas de pantalla, documentos o reuniones son Trabajo.
- etiquetas: de 3 a 8 palabras o frases cortas en minúsculas y en singular (por ejemplo "perro", "playa", "cumpleaños", "recibo"). Incluye objetos, lugares, actividades y, si se leen con claridad, marcas o comercios.
- descripcion: una o dos frases que describan lo que se ve, incluyendo texto importante legible (montos, fechas, nombres de lugares).
Solo si la categoría es Factura (facturas, recibos, tiquetes de compra, cuentas de restaurante), agrega "factura" con lo que se lea con claridad en el documento:
- tipo_compra: qué se compró, en una o dos palabras en español y con mayúscula inicial: "Cafetería", "Supermercado", "Restaurante", "Farmacia", "Gasolina", "Transporte", "Ropa", "Tecnología", "Servicios públicos"...
- monto: el TOTAL a pagar (no un subtotal ni el IVA), como número con punto decimal y sin separadores de miles. Ejemplos: "$ 23.100" en pesos colombianos es 23100; "US$23.10" es 23.10; "1.234,50 €" es 1234.50.
- moneda: el código ISO 4217 (COP, USD, EUR...). Usa el símbolo, el país del comercio, el NIT o el formato de los números. Si el símbolo es solo "$" y nada más lo aclara, usa la moneda del país donde vive la persona.
Si un dato no se lee con claridad, está cortado o tendrías que adivinarlo, omítelo: es mejor dejarlo vacío que inventarlo. Si no hay monto, tampoco pongas moneda. En las demás categorías no incluyas "factura".
No inventes lo que no se ve. No identifiques a personas por su nombre ni adivines datos sensibles de ellas.
Devuelve un elemento por cada foto, usando como id el que aparece antes de cada imagen.`;

/** Describe las fotos en una sola llamada. Devuelve un resultado por foto que Gemini sí describió. */
export async function describir(
  fotos: FotoParaAnalizar[],
  contexto: Contexto = {},
): Promise<Descripcion[]> {
  const ids = fotos.map((f) => f.id);
  const parts = fotos.flatMap((f) => [
    { text: `Foto id ${f.id}:` },
    { inlineData: { mimeType: "image/jpeg", data: f.imagen } },
  ]);
  const ciudad = contexto.ciudad?.trim();
  parts.push({
    text: `Describe las ${fotos.length} fotos anteriores.` +
      (ciudad ? ` La persona vive en ${ciudad.slice(0, 80)}.` : ""),
  });

  const respuesta = await llamar(`${API}/${MODEL}:generateContent`, {
    systemInstruction: { parts: [{ text: INSTRUCCIONES }] },
    contents: [{ role: "user", parts }],
    generationConfig: {
      responseMimeType: "application/json",
      responseJsonSchema: esquema(ids),
      thinkingConfig: { thinkingLevel: "LOW" },
    },
  });

  if (respuesta.promptFeedback?.blockReason) {
    throw new GeminiBloqueado(respuesta.promptFeedback.blockReason);
  }
  const candidato = respuesta.candidates?.[0];
  const texto: string = (candidato?.content?.parts ?? [])
    .filter((p: { text?: string; thought?: boolean }) => p.text && !p.thought)
    .map((p: { text: string }) => p.text)
    .join("");
  if (!texto) {
    // SAFETY, PROHIBITED_CONTENT, IMAGE_SAFETY...: no tiene sentido reintentar igual.
    throw new GeminiBloqueado(candidato?.finishReason ?? "sin respuesta");
  }

  let datos: { fotos?: unknown };
  try {
    datos = JSON.parse(texto);
  } catch {
    throw new GeminiFallo(`Respuesta que no es JSON (${candidato?.finishReason})`);
  }
  return limpiar(datos.fotos, ids);
}

/**
 * Embeddings de cada foto: uno de la imagen y uno de su texto, en el mismo espacio vectorial,
 * así una búsqueda en texto (HU-21) se puede comparar con los dos.
 */
export async function embeddings(
  items: { imagen: string; texto: string }[],
): Promise<{ imagen: number[]; texto: number[] }[]> {
  const pedido = (parts: unknown[]) => ({
    model: `models/${EMBEDDING_MODEL}`,
    content: { parts },
    outputDimensionality: EMBEDDING_DIMENSIONS,
  });
  const requests = items.flatMap((item) => [
    pedido([{ inlineData: { mimeType: "image/jpeg", data: item.imagen } }]),
    pedido([{ text: item.texto }]),
  ]);

  const respuesta = await llamar(`${API}/${EMBEDDING_MODEL}:batchEmbedContents`, { requests });
  const vectores: number[][] = (respuesta.embeddings ?? []).map(
    (e: { values: number[] }) => e.values,
  );
  if (
    vectores.length !== requests.length ||
    vectores.some((v) => v?.length !== EMBEDDING_DIMENSIONS)
  ) {
    throw new GeminiFallo("Los embeddings no llegaron completos");
  }
  return items.map((_, i) => ({ imagen: vectores[2 * i], texto: vectores[2 * i + 1] }));
}

/** El texto que representa a la foto en la búsqueda, con el formato que recomienda Google. */
export function textoParaBuscar(d: Descripcion): string {
  const f = d.factura;
  const compra = !f ? "" : [
    f.tipoCompra ? ` Tipo de compra: ${f.tipoCompra}.` : "",
    f.monto !== undefined && f.moneda ? ` Total: ${f.monto} ${f.moneda}.` : "",
  ].join("");
  return `title: ${d.titulo} | text: ${d.descripcion} Categoría: ${d.categoria}.` +
    `${compra} Etiquetas: ${d.etiquetas.join(", ")}.`;
}

function esquema(ids: string[]) {
  return {
    type: "object",
    properties: {
      fotos: {
        type: "array",
        items: {
          type: "object",
          properties: {
            id: { type: "string", enum: ids },
            titulo: { type: "string", description: "Título en español, máximo 60 caracteres." },
            categoria: { type: "string", enum: [...CATEGORIAS] },
            etiquetas: {
              type: "array",
              items: { type: "string" },
              minItems: 3,
              maxItems: 8,
              description: "Etiquetas en español, en minúsculas y en singular.",
            },
            descripcion: { type: "string", description: "Una o dos frases en español." },
            factura: {
              type: "object",
              description: "Solo si la categoría es Factura. Omite los campos que no se lean.",
              properties: {
                tipo_compra: { type: "string", description: "Por ejemplo Cafetería." },
                monto: { type: "number", description: "Total a pagar, sin separadores de miles." },
                moneda: { type: "string", enum: [...MONEDAS] },
              },
            },
          },
          required: ["id", "titulo", "categoria", "etiquetas", "descripcion"],
        },
      },
    },
    required: ["fotos"],
  };
}

/** Se queda solo con resultados válidos, uno por id pedido. */
function limpiar(fotos: unknown, ids: string[]): Descripcion[] {
  if (!Array.isArray(fotos)) return [];
  const vistos = new Set<string>();
  const validos: Descripcion[] = [];
  for (const f of fotos) {
    if (
      typeof f?.id !== "string" || !ids.includes(f.id) || vistos.has(f.id) ||
      typeof f.titulo !== "string" || !f.titulo.trim() ||
      !CATEGORIAS.includes(f.categoria) ||
      !Array.isArray(f.etiquetas) ||
      typeof f.descripcion !== "string"
    ) {
      continue;
    }
    vistos.add(f.id);
    validos.push({
      id: f.id,
      titulo: f.titulo.trim().slice(0, 60),
      categoria: f.categoria,
      etiquetas: f.etiquetas.filter((e: unknown) => typeof e === "string" && e.trim()),
      descripcion: f.descripcion.trim(),
      factura: f.categoria === "Factura" ? limpiarFactura(f.factura) : undefined,
    });
  }
  return validos;
}

/**
 * Deja solo lo que tiene sentido: un tipo de compra corto, un monto positivo con dos
 * decimales y una moneda conocida. Monto y moneda van juntos o no van.
 */
// deno-lint-ignore no-explicit-any
export function limpiarFactura(f: any): DatosFactura | undefined {
  if (!f || typeof f !== "object") return undefined;
  const datos: DatosFactura = {};

  if (typeof f.tipo_compra === "string") {
    const tipo = f.tipo_compra.trim().slice(0, 40);
    if (tipo) datos.tipoCompra = tipo.charAt(0).toUpperCase() + tipo.slice(1);
  }

  const monto = typeof f.monto === "number" ? Math.round(f.monto * 100) / 100 : NaN;
  if (Number.isFinite(monto) && monto > 0 && monto < 1e10 && MONEDAS.includes(f.moneda)) {
    datos.monto = monto;
    datos.moneda = f.moneda;
  }

  return Object.keys(datos).length > 0 ? datos : undefined;
}

// deno-lint-ignore no-explicit-any
async function llamar(url: string, body: unknown): Promise<any> {
  const apiKey = Deno.env.get("GEMINI_API_KEY");
  if (!apiKey) throw new Error("Falta el secret GEMINI_API_KEY");

  let res: Response;
  try {
    res = await fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json", "x-goog-api-key": apiKey },
      body: JSON.stringify(body),
      signal: AbortSignal.timeout(90_000),
    });
  } catch (e) {
    throw new GeminiFallo(`No se pudo llamar a Gemini: ${e}`);
  }

  if (res.status === 429) {
    throw new GeminiOcupado(reintentarEn(await res.text()));
  }
  if (!res.ok) {
    const detalle = (await res.text()).slice(0, 500);
    if (res.status >= 500) throw new GeminiFallo(`Gemini ${res.status}: ${detalle}`);
    // Un 400 es un error nuestro (modelo, esquema, clave): no se arregla reintentando.
    throw new Error(`Gemini ${res.status}: ${detalle}`);
  }
  return await res.json();
}

/** Google dice cuánto esperar en RetryInfo.retryDelay ("30s"). Si no, un minuto. */
function reintentarEn(cuerpo: string): number {
  const coincidencia = cuerpo.match(/"retryDelay"\s*:\s*"(\d+(?:\.\d+)?)s"/);
  const segundos = coincidencia ? Math.ceil(Number(coincidencia[1])) : 60;
  return Math.min(Math.max(segundos, 1), 120);
}
