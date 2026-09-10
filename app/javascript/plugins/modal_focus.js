// Rendre le focus AVANT que Bootstrap ne masque une modale.
//
// Bootstrap pose `aria-hidden="true"` sur la modale qu'il ferme. Si le focus est
// encore dedans à ce moment-là — et il l'est presque toujours, puisqu'on ferme
// en cliquant la croix ou un choix, ce qui donne le focus à l'élément cliqué —,
// le navigateur refuse l'attribut et journalise :
//
//   Blocked aria-hidden on an element because its descendant retained focus.
//
// Ce n'est pas qu'un message : tant que le focus reste dans un sous-arbre que
// l'application déclare caché, un lecteur d'écran lit un contenu que rien
// n'annonce plus, et la touche Tab continue d'y circuler.
//
// `hide.bs.modal` part AVANT la pose de l'attribut : c'est le seul moment où
// sortir le focus règle la chose. Un seul écouteur au niveau du document les
// couvre toutes — la modale d'évaluation du mobile, celles des tableaux, celle
// du layout — plutôt qu'un contrôleur à poser sur chacune.
document.addEventListener("hide.bs.modal", (event) => {
  const actif = document.activeElement;
  if (actif && event.target.contains(actif)) actif.blur();
});
