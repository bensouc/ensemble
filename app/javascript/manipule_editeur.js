// L'éditeur d'un problème : montrer/cacher ce qui dépend du mode, et tenir
// l'aperçu à jour pendant qu'on écrit.
//
// Chargé par la seule page de l'éditeur, pas par le bundle commun d'Ensemble.

const ATTENTE = 400 // ms après la dernière frappe

let minuteur = null

function basculer(formulaire) {
  const choix = formulaire.querySelector("[name='probleme[answer_mode]']:checked")?.value === "choix"
  const outil = formulaire.querySelector("[data-m-outil]")?.value

  formulaire.querySelectorAll("[data-m-si-choix]").forEach((bloc) => { bloc.hidden = !choix })
  formulaire.querySelectorAll("[data-m-si-saisie]").forEach((bloc) => { bloc.hidden = choix })
  formulaire.querySelectorAll("[data-m-si-jetons]").forEach((bloc) => { bloc.hidden = outil !== "jetons" })
}

async function rafraichir(formulaire) {
  const cadre = document.querySelector("[data-m-apercu]")
  if (!cadre) return

  // On réutilise les champs du formulaire, mais pas ce qui appartient à SON
  // action. Deux pièges, tous deux rencontrés :
  //
  //   — `authenticity_token` est lié à l'action du formulaire, celle qui
  //     enregistre. Envoyé ailleurs, il est invalide et Rails répond 422.
  //     On présente à la place le jeton global de la page.
  //   — `_method` vaut « patch » sur le formulaire de modification. Laissé
  //     là, Rails lit un PATCH sur une adresse qui n'accepte que POST, et
  //     répond 404 — l'aperçu restait blanc à l'édition, jamais à la création.
  const champs = new FormData(formulaire)
  champs.delete("authenticity_token")
  champs.delete("_method")
  const jeton = document.querySelector("meta[name='csrf-token']")?.content

  try {
    const reponse = await fetch(formulaire.dataset.apercu, {
      method: "POST",
      body: champs,
      headers: { Accept: "text/html", "X-CSRF-Token": jeton || "" },
      credentials: "same-origin",
    })
    if (!reponse.ok) return

    // `srcdoc` plutôt qu'une adresse : la réponse est déjà la page entière, et
    // on évite un second aller-retour. Les adresses d'assets y sont absolues.
    cadre.srcdoc = await reponse.text()
  } catch {
    // Un aperçu qui ne se rafraîchit pas ne doit jamais empêcher d'enregistrer.
  }
}

// Les cases de l'outil s'ajoutent et se retirent. Trois fentes figées était
// arbitraire : deux suffisent souvent, et un problème de partage en demande
// parfois quatre. Le plafond vient du modèle, qui le fait respecter de son
// côté — une adresse forgée ne doit pas pouvoir en poser cinquante.
function brancherLesCases(formulaire) {
  const liste = formulaire.querySelector("[data-m-cases]")
  const ajouter = formulaire.querySelector("[data-m-ajouter-case]")
  if (!liste || !ajouter) return

  const plafond = Number(ajouter.dataset.max) || 6

  const compter = () => {
    const cases = liste.querySelectorAll("[data-m-case]")
    ajouter.hidden = cases.length >= plafond
    // On ne retire jamais la dernière : sans case, l'outil n'a plus de sens.
    cases.forEach((bloc) => {
      bloc.querySelector("[data-m-retirer-case]").hidden = cases.length <= 1
    })
  }

  ajouter.addEventListener("click", () => {
    const cases = liste.querySelectorAll("[data-m-case]")
    if (cases.length >= plafond) return

    const copie = cases[cases.length - 1].cloneNode(true)
    const champ = copie.querySelector("input")
    champ.value = ""
    champ.placeholder = "Une autre case"
    champ.setAttribute("aria-label", `Nom de la case ${cases.length + 1}`)
    copie.querySelector("[data-m-retirer-case]").addEventListener("click", () => {
      copie.remove()
      compter()
      formulaire.dispatchEvent(new Event("change", { bubbles: true }))
    })
    liste.appendChild(copie)
    compter()
    champ.focus()
  })

  liste.querySelectorAll("[data-m-retirer-case]").forEach((bouton) => {
    bouton.addEventListener("click", () => {
      bouton.closest("[data-m-case]").remove()
      compter()
      formulaire.dispatchEvent(new Event("change", { bubbles: true }))
    })
  })

  compter()
}

// `DOMContentLoaded` et `turbo:load` se déclenchent TOUS LES DEUX au premier
// chargement d'une page. Sans ce garde, chaque écouteur était posé deux fois :
// un clic en valait deux, et l'aperçu partait en double à chaque frappe.
function uneSeuleFois(element, marque, poser) {
  if (!element || element.dataset[marque]) return false

  element.dataset[marque] = "1"
  poser()
  return true
}

function brancherEditeur() {
  const formulaire = document.querySelector("[data-m-editeur]")
  if (!uneSeuleFois(formulaire, "mBranche", () => {})) return

  basculer(formulaire)
  brancherLesCases(formulaire)
  rafraichir(formulaire)

  formulaire.addEventListener("input", () => {
    basculer(formulaire)
    clearTimeout(minuteur)
    minuteur = setTimeout(() => rafraichir(formulaire), ATTENTE)
  })

  // Un changement de liste ou de bouton radio n'émet pas toujours « input »
  // sur les vieux navigateurs : « change » rattrape.
  formulaire.addEventListener("change", () => {
    basculer(formulaire)
    clearTimeout(minuteur)
    minuteur = setTimeout(() => rafraichir(formulaire), ATTENTE)
  })
}

document.addEventListener("DOMContentLoaded", brancherEditeur)
document.addEventListener("turbo:load", brancherEditeur)
