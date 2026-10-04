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
}

// Une phrase à la fois, avec un silence entre chacune : c'est ce que
// l'enseignante demande, et ça ne s'obtient pas en baissant le débit.
function lire(texte, fini) {
  if (!window.speechSynthesis) { fini(); return }
  arreter()
  const phrases = (texte.match(/[^.!?…]+[.!?…]*/g) || []).map((p) => p.trim()).filter(Boolean)
  if (!phrases.length) { fini(); return }

  enCours = true
  // Chrome coupe la lecture au bout d'une quinzaine de secondes sans ce rappel.
  relance = setInterval(() => {
    if (enCours) { speechSynthesis.pause(); speechSynthesis.resume() }
  }, 9000)

  let i = 0
  const suivante = () => {
    if (!enCours || i >= phrases.length) { arreter(); fini(); return }
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

// L'énoncé ET la question. Les séparer n'aurait aucun sens : un élève qui ne
// déchiffre pas entendrait l'histoire sans jamais savoir ce qu'on lui demande.
function texteALire() {
  return ["[data-m-enonce]", "[data-m-question]"]
    .map((selecteur) => document.querySelector(selecteur))
    .filter(Boolean)
    .map((element) => element.textContent.trim())
    .filter((texte) => texte.length)
    .join(" ")
}

function brancher() {
  const bouton = document.querySelector("[data-m-ecouter]")
  if (!bouton || !texteALire()) return

  bouton.addEventListener("click", () => {
    bouton.disabled = true
    bouton.textContent = "⏸ Lecture…"
    signalerEcoute(bouton)
    lire(texteALire(), () => {
      bouton.disabled = false
      bouton.textContent = "🔊 Écouter"
    })
  })
}

if (window.speechSynthesis) {
  choisir()
  speechSynthesis.onvoiceschanged = choisir
  setTimeout(choisir, 400)
}

document.addEventListener("DOMContentLoaded", brancher)
document.addEventListener("turbo:load", brancher)
document.addEventListener("turbo:before-cache", arreter)
