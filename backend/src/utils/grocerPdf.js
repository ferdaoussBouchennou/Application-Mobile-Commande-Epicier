const PDFDocument = require("pdfkit");

/** Palette sobre (alignée sur l’app MyHanut / espace épicier) */
const C = {
  primary: "#2D5016",
  /** Plus foncé que `primary` pour titres sur fond clair (lisibilité) */
  primaryDark: "#1B300F",
  primaryLight: "#E8F0E6",
  headerBg: "#2D5016",
  text: "#1A1A1A",
  /** Libellés sur fond blanc : lisibles sans être noirs purs */
  muted: "#444444",
  label: "#333333",
  border: "#D4D4D4",
  rowAlt: "#F7F9F7",
  tableHead: "#E3EDE0",
  white: "#FFFFFF",
  danger: "#B71C1C",
  ok: "#2E7D32",
  warn: "#E65100",
  info: "#1565C0",
};

/**
 * @param {(doc: import('pdfkit').PDFDocument) => void} draw
 * @returns {Promise<Buffer>}
 */
function renderPdf(draw) {
  return new Promise((resolve, reject) => {
    const doc = new PDFDocument({
      size: "A4",
      margin: 50,
      info: { Author: "MyHanut", Creator: "MyHanut" },
    });
    const chunks = [];
    doc.on("data", (c) => chunks.push(c));
    doc.on("end", () => resolve(Buffer.concat(chunks)));
    doc.on("error", reject);
    try {
      draw(doc);
      doc.end();
    } catch (e) {
      reject(e);
    }
  });
}

function esc(s) {
  if (s == null) return "";
  return String(s).replace(/\r?\n/g, " ");
}

function pageInnerWidth(doc) {
  const m = doc.page.margins;
  return doc.page.width - m.left - m.right;
}

/** PDFKit déplace `doc.x` après `text(..., { align: 'right' })` — sans reset, les blocs suivants se dessinent à droite / hors page */
function cursorResetX(doc) {
  doc.x = doc.page.margins.left;
}

function ensureSpace(doc, neededHeight) {
  const bottom = doc.page.height - doc.page.margins.bottom;
  if (doc.y + neededHeight > bottom) {
    doc.addPage();
    cursorResetX(doc);
  }
}

function drawKeyValueRow(doc, label, value, options = {}) {
  const { valueColor = C.text, valueFont = "Helvetica-Bold" } = options;
  const w = pageInnerWidth(doc);
  const labelW = Math.floor(w * 0.45);
  const valueW = w - labelW;
  cursorResetX(doc);
  const y = doc.y;
  doc
    .fontSize(10)
    .fillColor(C.muted)
    .font("Helvetica")
    .text(esc(label), doc.x, y, {
      width: labelW,
    });
  doc
    .fontSize(10)
    .fillColor(valueColor)
    .font(valueFont)
    .text(esc(String(value)), doc.x + labelW, y, {
      width: valueW,
      align: "right",
    });
  doc.font("Helvetica");
  doc.y = y + 14;
  cursorResetX(doc);
}

function colorStatutCommande(statut) {
  const s = String(statut || "").toLowerCase();
  if (s.includes("refus")) return C.danger;
  if (s.includes("livr")) return C.ok;
  if (s.includes("prêt") || s.includes("prête")) return C.warn;
  if (s.includes("reçu")) return C.info;
  return C.muted;
}

function colorStatutReclamation(statut) {
  const s = String(statut || "");
  if (s.includes("Résolu")) return C.ok;
  if (s.includes("attente")) return C.warn;
  if (s.includes("médiation") || s.includes("Litige")) return C.danger;
  return C.muted;
}

/**
 * Bandeau d’en-tête pleine largeur (sous la marge PDFKit, on dessine en coordonnées absolues)
 */
function drawHeader(doc, { storeName, reportTitle, periode, dateEmission }) {
  const margin = doc.page.margins?.left ?? 40;
  const pageW = doc.page.width;
  const y0 = doc.y;
  const h = 78;

  doc.save();
  doc.rect(0, y0, pageW, h).fill(C.headerBg);
  doc.fillColor(C.white);
  doc
    .fontSize(16)
    .font("Helvetica-Bold")
    .text(esc(storeName), margin, y0 + 14, {
      width: pageW - margin * 2,
    });
  doc
    .fontSize(11)
    .font("Helvetica")
    .text(esc(reportTitle), margin, y0 + 36, {
      width: pageW - margin * 2,
    });
  doc
    .fontSize(8.5)
    .fillColor("#E8F0E6")
    .text(`${esc(periode)}`, margin, y0 + 54);
  doc
    .fontSize(8)
    .text(`Document émis le ${esc(dateEmission)}`, margin, y0 + 66);
  doc.restore();

  cursorResetX(doc);
  doc.fillColor(C.text);
  doc.font("Helvetica");
  doc.y = y0 + h + 14;
}

function drawSectionTitle(doc, title) {
  cursorResetX(doc);
  const w = pageInnerWidth(doc);
  const y0 = doc.y;
  const bandH = 24;
  doc.save();
  doc.rect(doc.x, y0, w, bandH).fill(C.primaryLight);
  doc.fillColor(C.primaryDark).fontSize(10).font("Helvetica-Bold");
  doc.text(`  ${esc(title)}`, doc.x + 4, y0 + 7, { width: w - 8 });
  doc.restore();
  doc.fillColor(C.text).font("Helvetica");
  doc.y = y0 + bandH + 10;
}

function drawTableHeader(doc, { headers, col, fontSize = 8, rowHeight = 16 }) {
  cursorResetX(doc);
  const w = pageInnerWidth(doc);
  const headY = doc.y;
  doc.save();
  doc.rect(doc.x, headY, w, rowHeight).fill(C.tableHead);
  let x = doc.x + 6;
  headers.forEach((h, i) => {
    doc
      .fontSize(fontSize)
      .fillColor(C.primary)
      .font("Helvetica-Bold")
      .text(String(h), x, headY + 4, {
        width: w * col[i] - 4,
        lineBreak: false,
      });
    x += w * col[i];
  });
  doc.restore();
  cursorResetX(doc);
  doc.y = headY + rowHeight + 2;
}

function drawKpiRow(doc, label, value, options = {}) {
  const { boldValue = true } = options;
  const w = pageInnerWidth(doc);
  const labelW = Math.floor(w * 0.55);
  const valueW = w - labelW;
  cursorResetX(doc);
  const y = doc.y;
  doc
    .fontSize(10)
    .fillColor(C.muted)
    .text(esc(label), doc.x, y, { width: labelW });
  doc
    .font(boldValue ? "Helvetica-Bold" : "Helvetica")
    .fillColor(C.text)
    .text(esc(String(value)), doc.x + labelW, y, {
      width: valueW,
      align: "right",
    });
  doc.font("Helvetica");
  doc.y = y + 14;
  cursorResetX(doc);
}

function drawSummaryBox(doc, items) {
  cursorResetX(doc);
  const w = pageInnerWidth(doc);
  const baseX = doc.page.margins.left;
  const yStart = doc.y;
  const boxH = 16 + items.length * 18;
  const padX = 12;
  const labelW = Math.floor((w - padX * 2) * 0.62);
  const valueW = w - padX * 2 - labelW;
  doc.save();
  doc.rect(doc.x, yStart, w, boxH).stroke(C.border);
  let yy = yStart + 8;
  items.forEach((it) => {
    const rowY = yy;
    cursorResetX(doc);
    doc
      .fontSize(9)
      .fillColor(C.muted)
      .font("Helvetica")
      .text(String(it.label), baseX + padX, rowY, {
        width: labelW,
        lineBreak: false,
      });
    doc
      .fontSize(11)
      .font("Helvetica-Bold")
      .fillColor(C.primary)
      .text(String(it.value), baseX + padX + labelW, rowY, {
        width: valueW,
        align: "right",
        lineBreak: false,
      });
    doc.font("Helvetica");
    yy += 18;
  });
  doc.restore();
  doc.y = yStart + boxH + 12;
  cursorResetX(doc);
  doc.fillColor(C.text);
}

/**
 * Barres horizontales simples (CA ou volumes)
 */
function drawSimpleBars(
  doc,
  rows,
  { valueKey = "value", labelKey = "label", unit = "" },
) {
  cursorResetX(doc);
  const vals = rows.map((r) => Number(r[valueKey]) || 0);
  const maxVal = Math.max(...vals, 1);
  const w = pageInnerWidth(doc);
  const labelW = 108;
  const valueColW = 72;
  const gap = 8;
  /** Laisser de la place pour la colonne de droite (évite texte hors page) */
  const barMaxW = Math.max(48, w - labelW - valueColW - gap - 4);
  const left = doc.x;
  const barLeft = left + labelW + gap;

  rows.forEach((r) => {
    if (doc.y > 720) {
      doc.addPage();
      cursorResetX(doc);
    }
    const v = Number(r[valueKey]) || 0;
    const ratio = maxVal > 0 ? v / maxVal : 0;
    const lab = esc(String(r[labelKey]));
    const y = doc.y;
    doc
      .fontSize(8)
      .fillColor(C.label)
      .text(lab, left, y + 2, { width: labelW });
    doc.save();
    doc.rect(barLeft, y + 1, barMaxW, 7).fill("#EEEEEE");
    doc.rect(barLeft, y + 1, barMaxW * ratio, 7).fill(C.primary);
    doc.restore();
    const valStr =
      typeof v === "number" && !Number.isInteger(v) ? v.toFixed(2) : String(v);
    doc
      .fontSize(8)
      .fillColor(C.text)
      .text(`${valStr}${unit}`, barLeft + barMaxW + 4, y + 2, {
        width: valueColW,
        align: "right",
      });
    doc.y = y + 14;
    cursorResetX(doc);
  });
}

/**
 * Ticket commande — une commande
 */
async function pdfCommandeTicket({
  storeName,
  commandeId,
  clientLabel,
  dateStr,
  statut,
  lignes,
  montantTotal,
  creneau,
}) {
  const dateEmission = new Date().toLocaleString("fr-FR");
  return renderPdf((doc) => {
    drawHeader(doc, {
      storeName,
      reportTitle: "Ticket de commande",
      periode: `Commande n° ${commandeId}`,
      dateEmission,
    });

    drawSectionTitle(doc, "Résumé");
    const stColor = colorStatutCommande(statut);
    drawKeyValueRow(doc, "Client", clientLabel, { valueColor: C.text });
    drawKeyValueRow(doc, "Date de commande", dateStr, {
      valueColor: C.text,
      valueFont: "Helvetica",
    });
    if (creneau) {
      drawKeyValueRow(doc, "Créneau de retrait", creneau, {
        valueColor: C.text,
        valueFont: "Helvetica",
      });
    }
    drawKeyValueRow(doc, "Statut", statut, { valueColor: stColor });
    doc.moveDown(0.6);

    drawSectionTitle(doc, "Lignes");
    const w = pageInnerWidth(doc);
    const col = [0.52, 0.14, 0.17, 0.17];
    const headers = ["Produit", "Qté", "P.U.", "Total"];
    drawTableHeader(doc, { headers, col, fontSize: 8, rowHeight: 16 });

    lignes.forEach((l, i) => {
      cursorResetX(doc);
      const bg = i % 2 === 0 ? C.rowAlt : "#FFFFFF";
      const productLabel = l.rupture ? `${esc(l.nom)} (Rupture)` : esc(l.nom);
      const productH = doc.heightOfString(productLabel, {
        width: w * col[0] - 8,
      });
      const rowH = Math.max(18, Math.ceil(productH) + 8);
      ensureSpace(doc, rowH + 8);
      if (doc.y <= doc.page.margins.top + 6) {
        drawTableHeader(doc, { headers, col, fontSize: 8, rowHeight: 16 });
      }
      const rowY = doc.y;

      doc.save();
      doc.rect(doc.x, rowY, w, rowH).fill(bg);
      let x = doc.x + 6;
      doc
        .fontSize(8)
        .fillColor(l.rupture ? C.danger : C.text)
        .font(l.rupture ? "Helvetica-Bold" : "Helvetica");
      doc.text(productLabel, x, rowY + 4, { width: w * col[0] - 8 });
      x += w * col[0];

      doc
        .fillColor(C.text)
        .font("Helvetica")
        .text(String(l.quantite), x, rowY + 4, {
          width: w * col[1] - 4,
          align: "right",
        });
      x += w * col[1];
      doc.text(`${Number(l.prix_unitaire).toFixed(2)}`, x, rowY + 4, {
        width: w * col[2] - 4,
        align: "right",
      });
      x += w * col[2];
      doc.text(`${Number(l.total_ligne).toFixed(2)}`, x, rowY + 4, {
        width: w * col[3] - 4,
        align: "right",
      });
      doc.restore();
      doc.y = rowY + rowH;
    });

    doc.moveDown(0.8);
    const totalArticles = lignes.reduce(
      (a, l) => a + Number(l.quantite || 0),
      0,
    );
    drawSummaryBox(doc, [
      { label: "Nombre d'articles", value: totalArticles },
      { label: "Total général (MAD)", value: Number(montantTotal).toFixed(2) },
    ]);

    doc
      .fontSize(7)
      .fillColor(C.muted)
      .text("MyHanut — document généré automatiquement.", {
        align: "center",
      });
  });
}

/**
 * Liste commandes avec tableau principal + détails
 */
async function pdfCommandesListe({ storeName, title, periode, rows, totaux }) {
  const dateEmission = new Date().toLocaleString("fr-FR");
  const totalMontant =
    totaux?.montant ?? rows.reduce((a, r) => a + Number(r.montant || 0), 0);
  const totalCount = totaux?.count ?? rows.length;

  return renderPdf((doc) => {
    drawHeader(doc, {
      storeName,
      reportTitle: title,
      periode,
      dateEmission,
    });

    drawSectionTitle(doc, "Synthèse");
    drawSummaryBox(doc, [
      { label: "Nombre de commandes", value: totalCount },
      { label: "Montant total (MAD)", value: totalMontant.toFixed(2) },
    ]);

    drawSectionTitle(doc, "Détail des commandes");
    const w = pageInnerWidth(doc);
    const col = [0.1, 0.22, 0.2, 0.28, 0.08, 0.12];
    const headers = ["Cmd", "Client", "Date", "Produit", "Qté", "Total"];

    drawTableHeader(doc, { headers, col, fontSize: 8, rowHeight: 16 });

    rows.forEach((r, idx) => {
      const lignes =
        Array.isArray(r.lignes) && r.lignes.length
          ? r.lignes
          : [{ nom: "", quantite: "", total_ligne: r.montant }];
      lignes.forEach((l, li) => {
        cursorResetX(doc);
        if (doc.y > 720) {
          doc.addPage();
          cursorResetX(doc);
          drawTableHeader(doc, { headers, col, fontSize: 8, rowHeight: 16 });
        }
        const bg = (idx + li) % 2 === 0 ? C.rowAlt : "#FFFFFF";
        const productLabel = esc(l.nom || "");
        const productH = doc.heightOfString(productLabel, {
          width: w * col[3] - 8,
        });
        const rowH = Math.max(18, Math.ceil(productH) + 8);
        ensureSpace(doc, rowH + 6);
        if (doc.y <= doc.page.margins.top + 6) {
          drawTableHeader(doc, { headers, col, fontSize: 8, rowHeight: 16 });
        }
        const rowY = doc.y;

        doc.save();
        doc.rect(doc.x, rowY, w, rowH).fill(bg);
        let x = doc.x + 6;
        doc
          .fontSize(7.5)
          .fillColor(C.text)
          .font("Helvetica-Bold")
          .text(`#${r.id}`, x, rowY + 4, { width: w * col[0] - 4 });
        x += w * col[0];
        doc
          .font("Helvetica")
          .text(esc(r.client), x, rowY + 4, { width: w * col[1] - 4 });
        x += w * col[1];
        doc.text(esc(r.date), x, rowY + 4, { width: w * col[2] - 4 });
        x += w * col[2];
        doc.text(productLabel, x, rowY + 4, { width: w * col[3] - 8 });
        x += w * col[3];
        doc.text(String(l.quantite ?? ""), x, rowY + 4, {
          width: w * col[4] - 4,
          align: "right",
        });
        x += w * col[4];
        doc.text(`${Number(l.total_ligne ?? 0).toFixed(2)}`, x, rowY + 4, {
          width: w * col[5] - 4,
          align: "right",
        });
        doc.restore();
        doc.y = rowY + rowH;
      });

      if (idx < rows.length - 1) {
        cursorResetX(doc);
        doc.save();
        doc
          .moveTo(doc.x, doc.y)
          .lineTo(doc.x + w, doc.y)
          .strokeColor(C.border)
          .lineWidth(0.3)
          .stroke();
        doc.restore();
        doc.moveDown(0.25);
      }
    });

    cursorResetX(doc);
    doc.moveDown(0.5);
    doc
      .fontSize(7)
      .fillColor(C.muted)
      .text("MyHanut — espace épicier.", { align: "center" });
  });
}

/**
 * Rapport ventes (résumé + barres par jour)
 */
async function pdfSalesReport({
  storeName,
  periode,
  dateEmission,
  totalCa,
  totalCmd,
  jourRows,
}) {
  return renderPdf((doc) => {
    drawHeader(doc, {
      storeName,
      reportTitle: "Rapport des ventes",
      periode,
      dateEmission,
    });

    drawSectionTitle(doc, "Indicateurs clés");
    drawSummaryBox(doc, [
      { label: "Chiffre d'affaires total (MAD)", value: totalCa.toFixed(2) },
      { label: "Nombre de commandes", value: String(totalCmd) },
      {
        label: "Jours avec au moins une vente",
        value: String(jourRows.length),
      },
    ]);

    if (jourRows.length) {
      drawSectionTitle(doc, "Répartition par jour (aperçu)");
      const forBars = jourRows.slice(0, 25).map((r) => ({
        label: String(r.jour).slice(0, 10),
        value: Number(r.ca) || 0,
      }));
      drawSimpleBars(doc, forBars, {
        valueKey: "value",
        labelKey: "label",
        unit: " MAD",
      });
    }

    cursorResetX(doc);
    doc.moveDown(0.5);
    doc
      .fontSize(7)
      .fillColor(C.muted)
      .text("Les montants excluent les commandes refusées.", {
        align: "center",
      });
    doc.moveDown(0.3);
    doc
      .fillColor(C.muted)
      .text("MyHanut — espace épicier.", { align: "center" });
  });
}

/**
 * Résumé commandes (période + par statut)
 */
async function pdfSummaryOrders({
  storeName,
  periode,
  dateEmission,
  nbCommandes,
  ca,
  parStatut,
}) {
  return renderPdf((doc) => {
    drawHeader(doc, {
      storeName,
      reportTitle: "Résumé des commandes",
      periode,
      dateEmission,
    });

    drawSectionTitle(doc, "Synthèse");
    drawSummaryBox(doc, [
      { label: "Commandes (hors refus)", value: String(nbCommandes) },
      { label: "Chiffre d'affaires (MAD)", value: Number(ca).toFixed(2) },
    ]);

    if (parStatut && parStatut.length) {
      drawSectionTitle(doc, "Répartition par statut");
      const rows = parStatut.map((s) => ({
        label: s.statut,
        value: Number(s.n) || 0,
      }));
      drawSimpleBars(doc, rows, {
        valueKey: "value",
        labelKey: "label",
        unit: "",
      });
    }

    cursorResetX(doc);
    doc.moveDown(0.5);
    doc
      .fontSize(7)
      .fillColor(C.muted)
      .text("MyHanut — espace épicier.", { align: "center" });
  });
}

/**
 * Réclamations — tableau lisible
 */
async function pdfReclamationsReport({
  storeName,
  periode,
  dateEmission,
  parStatut,
  rows,
}) {
  return renderPdf((doc) => {
    drawHeader(doc, {
      storeName,
      reportTitle: "Réclamations clients",
      periode,
      dateEmission,
    });

    if (parStatut && parStatut.length) {
      drawSectionTitle(doc, "Synthèse par statut");
      const forBars = parStatut.map((x) => ({
        label: x.statut,
        value: Number(x.nombre ?? x.n) || 0,
      }));
      drawSimpleBars(doc, forBars, {
        valueKey: "value",
        labelKey: "label",
        unit: "",
      });
    }

    if (rows && rows.length) {
      drawSectionTitle(doc, "Liste des réclamations");
      cursorResetX(doc);
      const w = pageInnerWidth(doc);
      const col = [0.08, 0.16, 0.18, 0.2, 0.38];
      const headers = ["ID", "Statut", "Commande", "Client", "Motif"];
      drawTableHeader(doc, { headers, col, fontSize: 7.5, rowHeight: 16 });

      rows.forEach((r, i) => {
        cursorResetX(doc);
        if (doc.y > 720) {
          doc.addPage();
          cursorResetX(doc);
          drawTableHeader(doc, { headers, col, fontSize: 7.5, rowHeight: 16 });
        }
        const bg = i % 2 === 0 ? C.rowAlt : "#FFFFFF";
        const motif = esc(String(r.motif || ""));
        const stCol = colorStatutReclamation(r.statut);
        const motifH = doc.heightOfString(motif, { width: w * col[4] - 8 });
        const rowH = Math.max(18, Math.ceil(motifH) + 8);
        ensureSpace(doc, rowH + 6);
        if (doc.y <= doc.page.margins.top + 6) {
          drawTableHeader(doc, { headers, col, fontSize: 7.5, rowHeight: 16 });
        }
        const yy = doc.y;
        doc.save();
        doc.rect(doc.x, yy, w, rowH).fill(bg);
        let x2 = doc.x + 6;
        doc
          .fontSize(7.5)
          .fillColor(C.text)
          .font("Helvetica-Bold")
          .text(`#${r.id}`, x2, yy + 4, { width: w * col[0] - 4 });
        x2 += w * col[0];
        doc
          .fillColor(stCol)
          .font("Helvetica-Bold")
          .text(esc(r.statut), x2, yy + 4, { width: w * col[1] - 4 });
        x2 += w * col[1];
        doc
          .fillColor(C.text)
          .font("Helvetica")
          .text(String(r.commande_id ?? "—"), x2, yy + 4, {
            width: w * col[2] - 4,
          });
        x2 += w * col[2];
        doc.text(esc(r.client || ""), x2, yy + 4, { width: w * col[3] - 4 });
        x2 += w * col[3];
        doc
          .fillColor(C.label)
          .fontSize(7.5)
          .text(motif, x2, yy + 4, { width: w * col[4] - 8 });
        doc.restore();
        doc.y = yy + rowH;
      });
    } else {
      drawSectionTitle(doc, "Liste");
      doc
        .fontSize(10)
        .fillColor(C.muted)
        .text("Aucune réclamation sur cette période.");
    }

    cursorResetX(doc);
    doc.moveDown(1);
    doc
      .fontSize(7)
      .fillColor(C.muted)
      .text("MyHanut — espace épicier.", { align: "center" });
  });
}

module.exports = {
  renderPdf,
  pdfCommandeTicket,
  pdfCommandesListe,
  pdfSalesReport,
  pdfSummaryOrders,
  pdfReclamationsReport,
};
