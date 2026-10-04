// Manipule : la lecture à voix haute de l'énoncé.
//
// Rien d'autre ne nécessite de JavaScript ici — les réponses sont des
// formulaires. Pas de Stimulus, pas de dépendance : ce bundle doit rester
// minuscule et tourner sur un navigateur dont on ignore l'âge.

const FEMININES = /(am[ée]lie|audrey|aur[ée]lie|marie|hortense|julie|denise|[ée]lo[ïi]se|sylvie|google fran[çc]ais|femme|female)/i
const MASCULINES = /(thomas|paul|henri|claude|nicolas|guillaume|r[ée]mi|jean|homme|male)/i
// Les voix « Natural », « Online », Google ou Siri sont neuronales : à genre
// égal, elles sont nettement plus compréhensibles qu'une voix système.
const QUALITE = /(natural|online|enhanced|premium|neural|siri|google)/i

let voix = null
let enCours = false
let relance = null

function choisir() {
  if (!window.speechSynthesis) return
  const francaises = speechSynthesis.getVoices().filter((v) => /^fr/i.test(v.lang))
  francaises.sort((a, b) => note(a) - note(b))
  voix = francaises[0] || null
  afficher(francaises)
}

function note(v) {
  let n = 0
  if (FEMININES.test(v.name)) n -= 8
  else if (MASCULINES.test(v.name)) n += 8
  if (QUALITE.test(v.name)) n -= 3
  if (v.localService) n += 1
  return n
}

function afficher(francaises) {
  const zone = document.querySelector("[data-m-voix]")
  if (!zone) return
  if (!window.speechSynthesis) zone.textContent = "Cet ordinateur ne sait pas lire à voix haute."
  else if (!francaises.length && speechSynthesis.getVoices().length) zone.textContent = "Aucune voix française sur cet ordinateur."
  else zone.textContent = ""
}

function arreter() {
  enCours = false
  if (relance) { clearInterval(relance); relance = null }
  if (window.speechSynthesis) speechSynthesis.cancel()
  document.querySelectorAll(".m-lu").forEach((element) => element.classList.remove("m-lu"))
}

// Une phrase à la fois, avec un silence entre chacune : c'est ce que
// l'enseignante demande, et ça ne s'obtient pas en baissant le débit.
function lireTexte(texte, fini) {
  if (!window.speechSynthesis) { fini(); return }
  const phrases = (texte.match(/[^.!?…]+[.!?…]*/g) || []).map((p) => p.trim()).filter(Boolean)
  if (!phrases.length) { fini(); return }

  let i = 0
  const suivante = () => {
    if (!enCours || i >= phrases.length) { fini(); return }
    const u = new SpeechSynthesisUtterance(phrases[i])
    u.lang = "fr-FR"
    if (voix) u.voice = voix
    u.rate = 0.9
    u.onend = () => { i += 1; setTimeout(suivante, 650) }
    u.onerror = () => { arreter(); fini() }
    speechSynthesis.speak(u)
  }
  suivante()
}

// Chaque élément est surligné pendant qu'il est lu : un élève qui ne déchiffre
// pas doit au moins voir OÙ on en est.
function lireElements(elements, fini) {
  if (!window.speechSynthesis || !elements.length) { fini(); return }
  arreter()
  enCours = true
  // Chrome coupe la lecture au bout d'une quinzaine de secondes sans ce rappel.
  relance = setInterval(() => {
    if (enCours) { speechSynthesis.pause(); speechSynthesis.resume() }
  }, 9000)

  let i = 0
  const suivant = () => {
    if (!enCours || i >= elements.length) { arreter(); fini(); return }
    const element = elements[i]
    element.classList.add("m-lu")
    lireTexte(element.textContent.trim(), () => {
      element.classList.remove("m-lu")
      i += 1
      setTimeout(suivant, 250)
    })
  }
  suivant()
}

function signalerEcoute(bouton) {
  const url = bouton.dataset.url
  const attempt = bouton.dataset.attempt
  if (!url || !attempt) return
  const jeton = document.querySelector('meta[name="csrf-token"]')
  fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded", "X-CSRF-Token": jeton ? jeton.content : "" },
    body: `attempt_id=${encodeURIComponent(attempt)}`
  }).catch(() => {})
}

function tousLesBoutons() {
  return Array.from(document.querySelectorAll("[data-m-ecouter], [data-m-ecouter-un]"))
}

function verrouiller(verrou) {
  tousLesBoutons().forEach((bouton) => { bouton.disabled = verrou })
}

function brancher() {
  const principal = document.querySelector("[data-m-ecouter]")
  const aLire = Array.from(document.querySelectorAll("[data-m-lire]"))
  if (!principal || !aLire.length) return

  const demarrer = (elements) => {
    verrouiller(true)
    principal.textContent = "⏸ Lecture…"
    signalerEcoute(principal)
    lireElements(elements, () => {
      verrouiller(false)
      principal.textContent = "🔊 Tout écouter"
    })
  }

  principal.addEventListener("click", () => demarrer(aLire))

  // Le haut-parleur d'une réponse ne relit que celle-là, autant de fois que
  // l'élève veut : mémoriser trois options entendues d'affilée est hors de
  // portée de l'enfant à qui la voix s'adresse.
  document.querySelectorAll("[data-m-ecouter-un]").forEach((bouton) => {
    bouton.addEventListener("click", () => {
      const cible = bouton.parentElement.querySelector("[data-m-lire]")
      if (cible) demarrer([cible])
    })
  })
}

document.addEventListener("DOMContentLoaded", brancher)
document.addEventListener("turbo:load", brancher)
document.addEventListener("turbo:before-cache", arreter)
