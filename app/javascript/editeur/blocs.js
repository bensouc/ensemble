// Les blocs d'un énoncé, tels que le navigateur les affiche.
//
// ProseMirror ne lit pas un bloc comme le navigateur l'affiche, sur deux points :
//
// - un navigateur ignore le dernier <br> d'un bloc : `<div>texte<br></div>`
//   tient sur une ligne, `<div><br></div>` fait UNE ligne vide. ProseMirror
//   montre ce retour à la ligne, puis en ajoute un pour y poser le curseur
//   (`ProseMirror-trailingBreak`) : chaque bloc d'un énoncé Trix qui finissait
//   par un <br> — à commencer par ses lignes vides — prenait une ligne de plus
//   dans l'éditeur. À l'inverse, un retour à la ligne tapé en fin de paragraphe
//   se voyait dans l'éditeur et disparaissait à l'affichage ;
// - un tableau (ou une liste, un titre…) posé dans un <div> coupe ce bloc en
//   deux. Le navigateur n'affiche que ce qui l'entoure ; ProseMirror, qui ne
//   peut pas mettre un tableau dans un paragraphe, laissait un paragraphe vide
//   devant lui — c'est ainsi que l'éditeur reçoit un ancien tableau maison.
//
// À l'ouverture, on découpe donc ces <div> et on retire le <br> final de chaque
// bloc ; à l'enregistrement, on remet un <br> derrière un retour à la ligne
// final, et dans un paragraphe vide, pour que la ligne que l'éditeur montre
// existe aussi à l'affichage.

const BLOCS = "div, p, li, h1, h2, h3, h4, h5, h6, blockquote, td, th"
// Les blocs de texte de l'éditeur, tels que getHTML() les écrit.
const BLOCS_DE_TEXTE = "div.rt-p, h1, h2, h3"
// Ce qui coupe un paragraphe en deux. Une image ne coupe rien : l'éditeur la
// place dans la ligne.
const COUPENT = new Set(["TABLE", "DIV", "P", "UL", "OL", "H1", "H2", "H3", "H4", "H5", "H6", "BLOCKQUOTE", "PRE", "HR"])
const SELECTEUR_COUPENT = [...COUPENT].join(", ").toLowerCase()
// Des <div> qui ne sont pas des paragraphes : l'éditeur les lit à part.
const CONTENEURS = ".rt-colonnes, .rt-colonne, .trix-content"
const EN_LIGNE = new Set(["SPAN", "STRONG", "EM", "B", "I", "U", "S", "DEL", "A", "MARK", "SUB", "SUP", "CODE"])
// Seuls ces blancs-là s'effacent ; une espace insécable est du contenu.
const BLANC = /^[ \t\n\r\f]*$/

const blanc = (n) => n.nodeType === Node.TEXT_NODE && BLANC.test(n.textContent)
const enLigne = (n) => EN_LIGNE.has(n.nodeName)
// Rien à afficher : des blancs, ou du gras qui n'entoure que des blancs.
const vide = (n) => blanc(n) || (enLigne(n) && [...n.childNodes].every(vide))

// Le dernier nœud d'un bloc, en descendant dans le gras, l'italique, un lien…
function dernierNoeud(parent) {
  for (let n = parent.lastChild; n; n = n.previousSibling) {
    if (blanc(n)) continue
    if (!enLigne(n)) return n
    const dedans = dernierNoeud(n)
    if (dedans) return dedans
  }
  return null
}

function retirerRetourFinal(bloc) {
  const n = dernierNoeud(bloc)
  if (n?.nodeName === "BR") n.remove()
}

// Ce qui contient un bloc : le bloc lui-même, ou le gras, le lien… qui
// l'entoure. Le gras reste autour du tableau : il en met les cases en gras.
const porteUnBloc = (n) => COUPENT.has(n.nodeName) || (enLigne(n) && !!n.querySelector(SELECTEUR_COUPENT))

// `<div>avant<table/>après</div>` -> `<div>avant</div><table/><div>après</div>`.
// Un morceau vide disparaît ; un morceau fait d'un <br> reste, c'est une ligne
// vide.
function decouper(div) {
  if (div.matches(CONTENEURS) || !div.querySelector(SELECTEUR_COUPENT)) return

  const morceaux = []
  let courant = []
  const fermer = () => {
    if (!courant.every(vide)) {
      const morceau = div.cloneNode(false)
      morceau.append(...courant)
      morceaux.push(morceau)
    }
    courant = []
  }
  for (const n of [...div.childNodes]) {
    if (porteUnBloc(n)) {
      fermer()
      morceaux.push(n)
    } else {
      courant.push(n)
    }
  }
  fermer()
  div.replaceWith(...morceaux)
}

// Le nœud affiché juste avant un bloc, dans la même ligne de texte : en
// remontant le gras qui l'entoure, et en descendant dans celui qui le précède.
function precedent(bloc) {
  for (let n = bloc; n; n = enLigne(n.parentNode) ? n.parentNode : null) {
    for (let p = n.previousSibling; p; p = p.previousSibling) {
      if (blanc(p)) continue
      if (!enLigne(p)) return p
      const dedans = dernierNoeud(p)
      if (dedans) return dedans
    }
  }
  return null
}

// Un bloc finit la ligne qui le précède : un <br> juste avant lui ne compte pas.
function retirerRetourAvantBloc(bloc) {
  const n = precedent(bloc)
  if (n?.nodeName === "BR") n.remove()
}

function transformer(html, traitement) {
  const modele = document.createElement("template")
  modele.innerHTML = html
  traitement(modele.content)
  return modele.innerHTML
}

// Ce que l'éditeur reçoit.
export function pourLEditeur(html) {
  return transformer(html, (racine) => {
    racine.querySelectorAll("div").forEach(decouper)
    racine.querySelectorAll(BLOCS).forEach(retirerRetourFinal)
    // Après le découpage : le <br> qui finit un morceau découpé est déjà parti,
    // il ne reste que celui qu'un gras enferme avec le bloc.
    racine.querySelectorAll(SELECTEUR_COUPENT).forEach(retirerRetourAvantBloc)
  })
}

// Ce que l'éditeur enregistre.
export function pourLEnregistrement(html) {
  return transformer(html, (racine) => {
    // La ligne que l'éditeur garde sous un tableau ou des colonnes finaux
    // (`LigneSousLeBloc`) : restée vide, elle n'existe pas.
    const derniere = racine.lastElementChild
    if (derniere?.matches("div.rt-p") && !dernierNoeud(derniere) &&
        derniere.previousElementSibling?.matches("table, div.rt-colonnes")) derniere.remove()

    // Un énoncé vide reste vide, sans ligne blanche.
    if ([...racine.childNodes].every((n) => vide(n) || (n.nodeType === Node.ELEMENT_NODE && n.matches("div.rt-p") && !dernierNoeud(n)))) {
      racine.replaceChildren()
      return
    }
    racine.querySelectorAll(BLOCS_DE_TEXTE).forEach((bloc) => {
      const n = dernierNoeud(bloc)
      if (!n) bloc.append(document.createElement("br"))
      else if (n.nodeName === "BR") n.after(document.createElement("br"))
    })
  })
}
