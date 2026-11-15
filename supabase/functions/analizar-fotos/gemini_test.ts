// deno test --allow-env supabase/functions/analizar-fotos
import { assertEquals, assertStringIncludes } from "jsr:@std/assert@1";
import { type Descripcion, limpiarFactura, textoParaBuscar } from "./gemini.ts";

Deno.test("una factura legible guarda tipo, monto y moneda", () => {
  assertEquals(
    limpiarFactura({ tipo_compra: " cafetería ", monto: 23.104, moneda: "USD" }),
    { tipoCompra: "Cafetería", monto: 23.1, moneda: "USD" },
  );
});

Deno.test("un monto sin moneda conocida no se guarda (CA3)", () => {
  assertEquals(limpiarFactura({ tipo_compra: "Farmacia", monto: 12 }), {
    tipoCompra: "Farmacia",
  });
  assertEquals(limpiarFactura({ monto: 12, moneda: "XXX" }), undefined);
});

Deno.test("montos sin sentido quedan vacíos", () => {
  assertEquals(limpiarFactura({ monto: 0, moneda: "COP" }), undefined);
  assertEquals(limpiarFactura({ monto: -5, moneda: "COP" }), undefined);
  assertEquals(limpiarFactura({ monto: "23.100", moneda: "COP" }), undefined);
  assertEquals(limpiarFactura({ monto: 1e12, moneda: "COP" }), undefined);
});

Deno.test("sin datos legibles no hay factura", () => {
  assertEquals(limpiarFactura(undefined), undefined);
  assertEquals(limpiarFactura({}), undefined);
  assertEquals(limpiarFactura({ tipo_compra: "  " }), undefined);
});

Deno.test("el texto de búsqueda incluye la compra y el total (CA4)", () => {
  const factura: Descripcion = {
    id: "1",
    titulo: "Recibo de café",
    categoria: "Factura",
    etiquetas: ["recibo", "café"],
    descripcion: "Recibo de una cafetería.",
    factura: { tipoCompra: "Cafetería", monto: 23.1, moneda: "USD" },
  };
  const texto = textoParaBuscar(factura);

  assertStringIncludes(texto, "Tipo de compra: Cafetería.");
  assertStringIncludes(texto, "Total: 23.1 USD.");
});

Deno.test("las fotos que no son facturas no hablan de compras (CA5)", () => {
  const comida: Descripcion = {
    id: "2",
    titulo: "Almuerzo",
    categoria: "Comida",
    etiquetas: ["arepa"],
    descripcion: "Un plato de arepas.",
  };

  assertEquals(textoParaBuscar(comida).includes("Total"), false);
});
