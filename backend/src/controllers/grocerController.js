const sequelize = require('../config/db');
const { QueryTypes } = require('sequelize');

const grocerController = {
  getDashboard: async (req, res) => {
    try {
      const epicierId = req.user.storeId;
      if (!epicierId) {
        return res.status(403).json({ message: 'Store ID manquant' });
      }

      const periodDays = 30;

      const kpiRows = await sequelize.query(
        `SELECT
          (SELECT COUNT(*) FROM commandes WHERE epicier_id = :epicierId AND date_commande >= DATE_SUB(CURDATE(), INTERVAL :periodDays DAY)) AS total_commandes,
          (SELECT COALESCE(SUM(montant_total), 0) FROM commandes WHERE epicier_id = :epicierId AND date_commande >= DATE_SUB(CURDATE(), INTERVAL :periodDays DAY)) AS ca_total,
          (SELECT COALESCE(AVG(note), 0) FROM avis WHERE epicier_id = :epicierId) AS note_moyenne`,
        { replacements: { epicierId, periodDays }, type: QueryTypes.SELECT }
      );
      const kpis = Array.isArray(kpiRows) && kpiRows.length > 0 ? kpiRows[0] : {};

      const commandesParJour = await sequelize.query(
        `SELECT DATE(date_commande) AS jour, COUNT(*) AS nb
         FROM commandes
         WHERE epicier_id = :epicierId AND date_commande >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
         GROUP BY DATE(date_commande)
         ORDER BY jour`,
        { replacements: { epicierId }, type: QueryTypes.SELECT }
      );

      const topProduits = await sequelize.query(
        `SELECT p.id, p.nom, SUM(d.quantite) AS total_quantite
         FROM detailscommande d
         INNER JOIN commandes c ON c.id = d.commande_id AND c.epicier_id = :epicierId
         INNER JOIN produits p ON p.id = d.produit_id
         WHERE c.date_commande >= DATE_SUB(CURDATE(), INTERVAL :periodDays DAY)
         GROUP BY p.id, p.nom
         ORDER BY total_quantite DESC
         LIMIT 5`,
        { replacements: { epicierId, periodDays }, type: QueryTypes.SELECT }
      );

      const totalQuantite = topProduits.reduce((acc, row) => acc + Number(row.total_quantite), 0);

      const topProductsWithPct = topProduits.map((row) => ({
        id: row.id,
        nom: row.nom,
        quantite: Number(row.total_quantite),
        percentage: totalQuantite > 0 ? Math.round((Number(row.total_quantite) / totalQuantite) * 100) : 0,
      }));

      const joursLabels = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
      const last7Days = [];
      for (let i = 6; i >= 0; i--) {
        const d = new Date();
        d.setDate(d.getDate() - i);
        const dateStr = d.toISOString().slice(0, 10);
        const found = commandesParJour.find((r) => r.jour && String(r.jour).slice(0, 10) === dateStr);
        last7Days.push({
          jour: dateStr,
          label: joursLabels[6 - i],
          nb: found ? Number(found.nb) : 0,
        });
      }

      res.status(200).json({
        kpis: {
          totalCommandes: Number(kpis?.total_commandes ?? 0),
          caTotal: Number(kpis?.ca_total ?? 0),
          noteMoyenne: Number(Number(kpis?.note_moyenne ?? 0).toFixed(1)),
          annulations: 0,
        },
        chartData: last7Days,
        topProducts: topProductsWithPct,
      });
    } catch (error) {
      console.error('Erreur getDashboard:', error);
      res.status(500).json({ message: 'Erreur lors de la récupération du tableau de bord', error: error.message });
    }
  },
};

module.exports = grocerController;
