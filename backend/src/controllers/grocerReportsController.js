const sequelize = require("../config/db");
const { QueryTypes } = require("sequelize");
const Commande = require("../models/Commande");
const DetailCommande = require("../models/DetailCommande");
const User = require("../models/User");
const Product = require("../models/Product");
const Store = require("../models/Store");
const {
  pdfCommandeTicket,
  pdfCommandesListe,
  pdfSalesReport,
  pdfSummaryOrders,
  pdfReclamationsReport,
} = require("../utils/grocerPdf");

function epicierIdOr403(req, res) {
  const id = req.user.storeId;
  if (!id) {
    res.status(403).json({ message: "Store ID manquant" });
    return null;
  }
  return id;
}

function parseRange(req) {
  const to = req.query.to ? String(req.query.to).slice(0, 10) : null;
  const from = req.query.from ? String(req.query.from).slice(0, 10) : null;
  const today = new Date();
  const toD = to || today.toISOString().slice(0, 10);
  const fromD =
    from ||
    new Date(today.getTime() - 29 * 24 * 60 * 60 * 1000).toISOString().slice(0, 10);
  return { from: fromD, to: toD };
}

function sendPdf(res, buffer, filename) {
  res.setHeader("Content-Type", "application/pdf");
  res.setHeader(
    "Content-Disposition",
    `attachment; filename="${filename.replace(/[^a-zA-Z0-9._-]/g, "_")}"`,
  );
  res.send(buffer);
}

/** Ventes par jour sur une période */
exports.getReportSales = async (req, res) => {
  try {
    const epicierId = epicierIdOr403(req, res);
    if (!epicierId) return;
    const { from, to } = parseRange(req);
    const rows = await sequelize.query(
      `SELECT DATE(c.date_commande) AS jour,
              COALESCE(SUM(c.montant_total), 0) AS ca,
              COUNT(*) AS nb_commandes
       FROM commandes c
       WHERE c.epicier_id = :epicierId
         AND DATE(c.date_commande) BETWEEN :from AND :to
         AND c.statut != 'refusee'
       GROUP BY DATE(c.date_commande)
       ORDER BY jour`,
      { replacements: { epicierId, from, to }, type: QueryTypes.SELECT },
    );
    const totalCa = rows.reduce((a, r) => a + Number(r.ca || 0), 0);
    const totalCmd = rows.reduce((a, r) => a + Number(r.nb_commandes || 0), 0);
    res.json({
      periode: { from, to },
      parJour: rows.map((r) => ({
        jour: String(r.jour).slice(0, 10),
        ca: Number(r.ca),
        nbCommandes: Number(r.nb_commandes),
      })),
      totaux: { ca: totalCa, nbCommandes: totalCmd },
    });
  } catch (e) {
    console.error("getReportSales:", e);
    res.status(500).json({ message: e.message });
  }
};

/** Liste commandes (JSON) pour rapports */
exports.getReportOrders = async (req, res) => {
  try {
    const epicierId = epicierIdOr403(req, res);
    if (!epicierId) return;
    const { from, to } = parseRange(req);
    const statut = req.query.statut ? String(req.query.statut) : null;
    let statutClause = "";
    const rep = { epicierId, from, to };
    if (statut && ["reçue", "prête", "livrée", "refusee"].includes(statut)) {
      statutClause = " AND c.statut = :statut ";
      rep.statut = statut;
    }
    const rows = await sequelize.query(
      `SELECT c.id, c.date_commande, c.statut, c.montant_total,
              u.nom AS client_nom, u.prenom AS client_prenom
       FROM commandes c
       INNER JOIN utilisateurs u ON u.id = c.client_id
       WHERE c.epicier_id = :epicierId
         AND DATE(c.date_commande) BETWEEN :from AND :to
         ${statutClause}
       ORDER BY c.date_commande DESC
       LIMIT 500`,
      { replacements: rep, type: QueryTypes.SELECT },
    );
    res.json({
      periode: { from, to },
      statut: statut || "tous",
      commandes: rows.map((r) => ({
        id: r.id,
        date_commande: r.date_commande,
        statut: r.statut,
        montant_total: parseFloat(r.montant_total ?? 0),
        client_nom: `${r.client_prenom || ""} ${r.client_nom || ""}`.trim(),
      })),
    });
  } catch (e) {
    console.error("getReportOrders:", e);
    res.status(500).json({ message: e.message });
  }
};

/** Top produits + ruptures */
exports.getReportProducts = async (req, res) => {
  try {
    const epicierId = epicierIdOr403(req, res);
    if (!epicierId) return;
    const { from, to } = parseRange(req);
    const top = await sequelize.query(
      `SELECT p.id, p.nom, SUM(d.quantite) AS total_qte,
              SUM(d.total_ligne) AS ca_lignes
       FROM detailscommande d
       INNER JOIN commandes c ON c.id = d.commande_id AND c.epicier_id = :epicierId
       INNER JOIN produits p ON p.id = d.produit_id
       WHERE DATE(c.date_commande) BETWEEN :from AND :to
         AND c.statut != 'refusee'
       GROUP BY p.id, p.nom
       ORDER BY total_qte DESC
       LIMIT 15`,
      { replacements: { epicierId, from, to }, type: QueryTypes.SELECT },
    );
    const ruptures = await sequelize.query(
      `SELECT COUNT(*) AS n FROM epicier_produits
       WHERE epicier_id = :epicierId AND rupture_stock = 1 AND is_active = 1`,
      { replacements: { epicierId }, type: QueryTypes.SELECT },
    );
    const catalogue = await sequelize.query(
      `SELECT COUNT(*) AS n FROM epicier_produits
       WHERE epicier_id = :epicierId AND is_active = 1`,
      { replacements: { epicierId }, type: QueryTypes.SELECT },
    );
    res.json({
      periode: { from, to },
      nbProduitsCatalogue: Number(catalogue[0]?.n ?? 0),
      produitsEnRupture: Number(ruptures[0]?.n ?? 0),
      topProduits: top.map((r) => ({
        id: r.id,
        nom: r.nom,
        quantiteVendue: Number(r.total_qte),
        caLignes: Number(r.ca_lignes),
      })),
    });
  } catch (e) {
    console.error("getReportProducts:", e);
    res.status(500).json({ message: e.message });
  }
};

/** Réclamations liées aux commandes du magasin */
exports.getReportReclamations = async (req, res) => {
  try {
    const epicierId = epicierIdOr403(req, res);
    if (!epicierId) return;
    const { from, to } = parseRange(req);
    const statut = req.query.statut ? String(req.query.statut) : null;
    let stClause = "";
    const rep = { epicierId, from, to };
    const valid = [
      "En attente",
      "Résolu",
      "En médiation",
      "Remboursé",
      "Litige ouvert",
    ];
    if (statut && valid.includes(statut)) {
      stClause = " AND r.statut = :statut ";
      rep.statut = statut;
    }
    const rows = await sequelize.query(
      `SELECT r.id, r.statut, r.motif, r.date_creation, r.commande_id,
              u.nom AS client_nom, u.prenom AS client_prenom
       FROM reclamations r
       INNER JOIN commandes c ON c.id = r.commande_id AND c.epicier_id = :epicierId
       INNER JOIN utilisateurs u ON u.id = r.client_id
       WHERE DATE(r.date_creation) BETWEEN :from AND :to
       ${stClause}
       ORDER BY r.date_creation DESC
       LIMIT 300`,
      { replacements: rep, type: QueryTypes.SELECT },
    );
    const parStatut = await sequelize.query(
      `SELECT r.statut, COUNT(*) AS n
       FROM reclamations r
       INNER JOIN commandes c ON c.id = r.commande_id AND c.epicier_id = :epicierId
       WHERE DATE(r.date_creation) BETWEEN :from AND :to
       GROUP BY r.statut`,
      { replacements: { epicierId, from, to }, type: QueryTypes.SELECT },
    );
    res.json({
      periode: { from, to },
      parStatut: parStatut.map((x) => ({ statut: x.statut, nombre: Number(x.n) })),
      reclamations: rows.map((r) => ({
        id: r.id,
        statut: r.statut,
        motif: r.motif,
        commande_id: r.commande_id,
        date_creation: r.date_creation,
        client: `${r.client_prenom || ""} ${r.client_nom || ""}`.trim(),
      })),
    });
  } catch (e) {
    console.error("getReportReclamations:", e);
    res.status(500).json({ message: e.message });
  }
};

exports.exportCommandePdf = async (req, res) => {
  try {
    const epicierId = epicierIdOr403(req, res);
    if (!epicierId) return;
    const { id } = req.params;
    const store = await Store.findByPk(epicierId, {
      attributes: ["nom_boutique"],
    });
    const commande = await Commande.findOne({
      where: { id, epicier_id: epicierId },
      include: [
        { model: User, as: "client", attributes: ["nom", "prenom"] },
        {
          model: DetailCommande,
          include: [{ model: Product, attributes: ["nom"] }],
        },
      ],
    });
    if (!commande) {
      return res.status(404).json({ message: "Commande introuvable" });
    }
    const detailList = commande.DetailCommandes || [];
    let creneau = "";
    if (commande.date_recuperation) {
      const d = new Date(commande.date_recuperation);
      const h = d.getHours();
      const m = d.getMinutes();
      creneau = `${String(h).padStart(2, "0")}:${String(m).padStart(2, "0")} – ${String(h + 1).padStart(2, "0")}:${String(m).padStart(2, "0")}`;
    }
    const lignes = detailList.map((d) => ({
      nom: d.Product?.nom ?? "",
      quantite: d.quantite,
      prix_unitaire: parseFloat(d.prix_unitaire ?? 0),
      total_ligne: parseFloat(d.total_ligne ?? 0),
      rupture: !!d.rupture,
    }));
    const clientLabel = `${commande.client?.prenom || ""} ${commande.client?.nom || ""}`.trim();
    const dateStr = commande.date_commande
      ? new Date(commande.date_commande).toLocaleString("fr-FR")
      : "";
    const buf = await pdfCommandeTicket({
      storeName: store?.nom_boutique || "Boutique",
      commandeId: commande.id,
      clientLabel,
      dateStr,
      statut: commande.statut,
      lignes,
      montantTotal: parseFloat(commande.montant_total ?? 0),
      creneau,
    });
    sendPdf(res, buf, `commande_${id}.pdf`);
  } catch (e) {
    console.error("exportCommandePdf:", e);
    res.status(500).json({ message: e.message });
  }
};

exports.exportCommandesPdf = async (req, res) => {
  try {
    const epicierId = epicierIdOr403(req, res);
    if (!epicierId) return;
    const { from, to } = parseRange(req);
    const statut = req.query.statut ? String(req.query.statut) : null;
    let statutClause = "";
    const rep = { epicierId, from, to };
    if (statut && ["reçue", "prête", "livrée", "refusee"].includes(statut)) {
      statutClause = " AND c.statut = :statut ";
      rep.statut = statut;
    }
    const store = await Store.findByPk(epicierId, {
      attributes: ["nom_boutique"],
    });
    const rows = await sequelize.query(
      `SELECT c.id, c.date_commande, c.statut, c.montant_total,
              u.nom AS client_nom, u.prenom AS client_prenom
       FROM commandes c
       INNER JOIN utilisateurs u ON u.id = c.client_id
       WHERE c.epicier_id = :epicierId
         AND DATE(c.date_commande) BETWEEN :from AND :to
         ${statutClause}
       ORDER BY c.date_commande DESC
       LIMIT 80`,
      { replacements: rep, type: QueryTypes.SELECT },
    );
    const pdfRows = [];
    for (const r of rows) {
      const details = await DetailCommande.findAll({
        where: { commande_id: r.id },
        include: [{ model: Product, attributes: ["nom"] }],
      });
      pdfRows.push({
        id: r.id,
        client: `${r.client_prenom || ""} ${r.client_nom || ""}`.trim(),
        date: r.date_commande
          ? new Date(r.date_commande).toLocaleString("fr-FR")
          : "",
        statut: r.statut,
        montant: parseFloat(r.montant_total ?? 0),
        lignes: details.map((d) => ({
          nom: d.Product?.nom ?? "",
          quantite: d.quantite,
          total_ligne: parseFloat(d.total_ligne ?? 0),
        })),
      });
    }
    const totalMontant = pdfRows.reduce((a, r) => a + Number(r.montant || 0), 0);
    const buf = await pdfCommandesListe({
      storeName: store?.nom_boutique || "Boutique",
      title: "Liste des commandes (détail)",
      periode: `Du ${from} au ${to}${statut ? ` — statut : ${statut}` : ""}`,
      rows: pdfRows,
      totaux: { count: pdfRows.length, montant: totalMontant },
    });
    sendPdf(res, buf, `commandes_${from}_${to}.pdf`);
  } catch (e) {
    console.error("exportCommandesPdf:", e);
    res.status(500).json({ message: e.message });
  }
};

exports.exportSummaryPdf = async (req, res) => {
  try {
    const epicierId = epicierIdOr403(req, res);
    if (!epicierId) return;
    const { from, to } = parseRange(req);
    const store = await Store.findByPk(epicierId, {
      attributes: ["nom_boutique"],
    });
    const [tot] = await sequelize.query(
      `SELECT
         COUNT(*) AS nb,
         COALESCE(SUM(montant_total), 0) AS ca
       FROM commandes
       WHERE epicier_id = :epicierId
         AND DATE(date_commande) BETWEEN :from AND :to
         AND statut != 'refusee'`,
      { replacements: { epicierId, from, to }, type: QueryTypes.SELECT },
    );
    const parStatut = await sequelize.query(
      `SELECT statut, COUNT(*) AS n
       FROM commandes
       WHERE epicier_id = :epicierId
         AND DATE(date_commande) BETWEEN :from AND :to
       GROUP BY statut`,
      { replacements: { epicierId, from, to }, type: QueryTypes.SELECT },
    );
    const dateEmission = new Date().toLocaleString("fr-FR");
    const buf = await pdfSummaryOrders({
      storeName: store?.nom_boutique || "Boutique",
      periode: `Du ${from} au ${to}`,
      dateEmission,
      nbCommandes: Number(tot?.nb ?? 0),
      ca: Number(tot?.ca ?? 0),
      parStatut: parStatut.map((s) => ({ statut: s.statut, n: Number(s.n) })),
    });
    sendPdf(res, buf, `resume_commandes_${from}_${to}.pdf`);
  } catch (e) {
    console.error("exportSummaryPdf:", e);
    res.status(500).json({ message: e.message });
  }
};

exports.exportSalesPdf = async (req, res) => {
  try {
    const epicierId = epicierIdOr403(req, res);
    if (!epicierId) return;
    const { from, to } = parseRange(req);
    const store = await Store.findByPk(epicierId, {
      attributes: ["nom_boutique"],
    });
    const rows = await sequelize.query(
      `SELECT DATE(c.date_commande) AS jour,
              COALESCE(SUM(c.montant_total), 0) AS ca,
              COUNT(*) AS nb_commandes
       FROM commandes c
       WHERE c.epicier_id = :epicierId
         AND DATE(c.date_commande) BETWEEN :from AND :to
         AND c.statut != 'refusee'
       GROUP BY DATE(c.date_commande)
       ORDER BY jour`,
      { replacements: { epicierId, from, to }, type: QueryTypes.SELECT },
    );
    const totalCa = rows.reduce((a, r) => a + Number(r.ca || 0), 0);
    const totalCmd = rows.reduce((a, r) => a + Number(r.nb_commandes || 0), 0);
    const jourRows = rows.map((r) => ({
      jour: String(r.jour).slice(0, 10),
      ca: Number(r.ca),
      nb_commandes: Number(r.nb_commandes),
    }));
    const dateEmission = new Date().toLocaleString("fr-FR");
    const buf = await pdfSalesReport({
      storeName: store?.nom_boutique || "Boutique",
      periode: `Du ${from} au ${to}`,
      dateEmission,
      totalCa,
      totalCmd,
      jourRows,
    });
    sendPdf(res, buf, `ventes_${from}_${to}.pdf`);
  } catch (e) {
    console.error("exportSalesPdf:", e);
    res.status(500).json({ message: e.message });
  }
};

exports.exportReclamationsPdf = async (req, res) => {
  try {
    const epicierId = epicierIdOr403(req, res);
    if (!epicierId) return;
    const { from, to } = parseRange(req);
    const store = await Store.findByPk(epicierId, {
      attributes: ["nom_boutique"],
    });
    const rows = await sequelize.query(
      `SELECT r.id, r.statut, r.motif, r.date_creation, r.commande_id,
              u.nom AS client_nom, u.prenom AS client_prenom
       FROM reclamations r
       INNER JOIN commandes c ON c.id = r.commande_id AND c.epicier_id = :epicierId
       INNER JOIN utilisateurs u ON u.id = r.client_id
       WHERE DATE(r.date_creation) BETWEEN :from AND :to
       ORDER BY r.date_creation DESC
       LIMIT 100`,
      { replacements: { epicierId, from, to }, type: QueryTypes.SELECT },
    );
    const parStatut = await sequelize.query(
      `SELECT r.statut, COUNT(*) AS n
       FROM reclamations r
       INNER JOIN commandes c ON c.id = r.commande_id AND c.epicier_id = :epicierId
       WHERE DATE(r.date_creation) BETWEEN :from AND :to
       GROUP BY r.statut`,
      { replacements: { epicierId, from, to }, type: QueryTypes.SELECT },
    );
    const pdfRows = rows.map((r) => ({
      id: r.id,
      statut: r.statut,
      motif: r.motif,
      commande_id: r.commande_id,
      client: `${r.client_prenom || ""} ${r.client_nom || ""}`.trim(),
    }));
    const dateEmission = new Date().toLocaleString("fr-FR");
    const buf = await pdfReclamationsReport({
      storeName: store?.nom_boutique || "Boutique",
      periode: `Du ${from} au ${to}`,
      dateEmission,
      parStatut: parStatut.map((x) => ({ statut: x.statut, nombre: Number(x.n) })),
      rows: pdfRows,
    });
    sendPdf(res, buf, `reclamations_${from}_${to}.pdf`);
  } catch (e) {
    console.error("exportReclamationsPdf:", e);
    res.status(500).json({ message: e.message });
  }
};
