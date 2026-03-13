/**
 * In-memory cart (session-style). One cart per client_id.
 * Structure: Map<clientId, Array<{ produit_id, quantite, epicier_id }>>
 * Cart is lost on server restart. No DB tables paniers / panier_produits.
 */

const carts = new Map();

function getItems(clientId) {
  const id = Number(clientId);
  if (!carts.has(id)) carts.set(id, []);
  return [...carts.get(id)];
}

function setItems(clientId, items) {
  carts.set(Number(clientId), items.filter(Boolean));
}

function addItem(clientId, produit_id, quantite = 1, epicier_id = null) {
  const id = Number(clientId);
  if (!carts.has(id)) carts.set(id, []);
  const list = carts.get(id);
  const existing = list.find((i) => Number(i.produit_id) === Number(produit_id));
  const qty = Math.max(1, parseInt(quantite, 10) || 1);
  if (existing) {
    existing.quantite += qty;
    if (epicier_id != null) existing.epicier_id = epicier_id;
  } else {
    list.push({
      produit_id: Number(produit_id),
      quantite: qty,
      epicier_id: epicier_id != null ? Number(epicier_id) : null,
    });
  }
  const item = list.find((i) => Number(i.produit_id) === Number(produit_id));
  return item.quantite;
}

function updateQuantity(clientId, produitId, quantite) {
  const items = getItems(clientId);
  const idx = items.findIndex((i) => Number(i.produit_id) === Number(produitId));
  if (idx < 0) return null;
  const qty = parseInt(quantite, 10);
  if (isNaN(qty) || qty < 0) return null;
  if (qty === 0) {
    items.splice(idx, 1);
    setItems(clientId, items);
    return 0;
  }
  items[idx].quantite = qty;
  setItems(clientId, items);
  return qty;
}

function removeItem(clientId, produitId) {
  const items = getItems(clientId).filter((i) => Number(i.produit_id) !== Number(produitId));
  setItems(clientId, items);
}

function removeItemsByProduitIds(clientId, produitIds) {
  const ids = new Set(produitIds.map(Number));
  const items = getItems(clientId).filter((i) => !ids.has(Number(i.produit_id)));
  setItems(clientId, items);
}

module.exports = {
  getItems,
  setItems,
  addItem,
  updateQuantity,
  removeItem,
  removeItemsByProduitIds,
};
