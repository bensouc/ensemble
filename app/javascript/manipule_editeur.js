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

  try {
    const reponse = await fetch(formulaire.dataset.apercu, {
      method: "POST",
      body: new FormData(formulaire),
      headers: { Accept: "text/html" },
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

function brancherEditeur() {
  const formulaire = document.querySelector("[data-m-editeur]")
  if (!formulaire) return

  basculer(formulaire)
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
