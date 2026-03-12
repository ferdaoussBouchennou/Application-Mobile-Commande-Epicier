const Commande = require('../models/Commande');
const DetailCommande = require('../models/DetailCommande');
const Panier = require('../models/Panier');
const PanierProduit = require('../models/PanierProduit');
const Product = require('../models/Product');

const getOrCreatePanier = async (clientId) => {
  const [panier] = await Panier.findOrCreate({
    where: { client_id: clientId },
    defaults: { date_creation: new Date().toISOString().slice(0, 10) },
  });
  return panier;
};

const commandeController = {
  createFromPanier: async (req, res) => {
    try {
      const clientId = req.user.id;
      const { epicier_id, date_recuperation } = req.body;

      if (!epicier_id || !date_recuperation) {
        return res.status(400).json({ message: 'epicier_id et date_recuperation requis' });
      }

      const panier = await getOrCreatePanier(clientId);
      const panierItems = await PanierProduit.findAll({
        where: { panier_id: panier.id },
        include: [{ model: Product, as: 'Product', attributes: ['id', 'nom', 'prix', 'epicier_id'] }],
      });

      const itemsForEpicier = panierItems.filter(
        (row) => row.Product && Number(row.Product.epicier_id) === Number(epicier_id)
      );
      if (itemsForEpicier.length === 0) {
        return res.status(400).json({ message: 'Aucun article de cet épicier dans le panier' });
      }

      let montantTotal = 0;
      const details = itemsForEpicier.map((row) => {
        const prix = parseFloat(row.Product.prix ?? 0);
        const qty = row.quantite || 0;
        const totalLigne = Math.round(prix * qty * 100) / 100;
        montantTotal += totalLigne;
        return {
          produit_id: row.produit_id,
          quantite: qty,
          prix_unitaire: prix,
          total_ligne: totalLigne,
        };
      });
      montantTotal = Math.round(montantTotal * 100) / 100;

      const dateRecup = new Date(date_recuperation);
      const commande = await Commande.create({
        client_id: clientId,
        epicier_id: Number(epicier_id),
        date_recuperation: dateRecup,
        montant_total: montantTotal,
      });

      await DetailCommande.bulkCreate(
        details.map((d) => ({
          commande_id: commande.id,
          produit_id: d.produit_id,
          quantite: d.quantite,
          prix_unitaire: d.prix_unitaire,
          total_ligne: d.total_ligne,
        }))
      );

      for (const row of itemsForEpicier) {
        await PanierProduit.destroy({
          where: { panier_id: panier.id, produit_id: row.produit_id },
        });
      }

      res.status(201).json({
        message: 'Commande créée avec succès',
        commande_id: commande.id,
        montant_total: montantTotal,
      });
    } catch (error) {
      console.error('Erreur createFromPanier:', error);
      res.status(500).json({ message: 'Erreur lors de la création de la commande', error: error.message });
    }
  },
};

module.exports = commandeController;
