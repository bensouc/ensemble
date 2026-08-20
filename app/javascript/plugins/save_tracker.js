// Suivi des enregistrements en cours, pour que l'export PDF ne parte jamais sur un
// état que la base n'a pas encore reçu.
//
// Deux sources, car elles n'empruntent pas le même canal :
//   - les soumissions Turbo : énoncé, domaine, compétence, suppressions. Suivies par
//     identité de `formSubmission` et non par un compteur, pour qu'un événement
//     dupliqué ne puisse pas décompter deux fois.
//   - les sauvegardes de tableau, qui partent par `request.js` : elles s'annoncent
//     elles-mêmes via `hold()`.
//
// Chaque prise est doublée d'une minuterie de sécurité : un enregistrement qui ne
// se terminerait jamais (onglet en veille, réseau coupé) ne doit pas laisser
// l'export définitivement indisponible.
const SAFETY_RELEASE = 15000

const submissions = new Set()
const holds = new Map()
const listeners = new Set()

// Formulaires modifiés mais jamais soumis. L'éditeur d'énoncé n'a AUCUN
// enregistrement automatique : sans ce suivi, taper un énoncé puis exporter donne un
// PDF sans le texte — et rien ne le signale, puisque du point de vue du serveur tout
// est normal. Contrairement aux prises ci-dessus, ça ne se résout pas en attendant :
// d'où une confirmation plutôt qu'un blocage.
const dirtyForms = new Set()
// Un éditeur Trix émet `trix-change` à l'analyse du contenu existant, donc avant
// toute frappe : on ne considère « modifié » qu'un éditeur qui a reçu le focus.
const focusedEditors = new WeakSet()

function notify() {
  const busy = isBusy()
  listeners.forEach((listener) => listener(busy))
}

export function isBusy() {
  return submissions.size > 0 || holds.size > 0
}

export function hasUnsavedChanges() {
  // Un formulaire remplacé par Turbo après enregistrement n'est plus dans le
  // document : on ne le compte plus.
  dirtyForms.forEach((form) => {
    if (!form.isConnected) dirtyForms.delete(form)
  })

  return dirtyForms.size > 0
}

function markDirty(form) {
  if (!form || dirtyForms.has(form)) return

  dirtyForms.add(form)
  notify()
}

export function onChange(listener) {
  listeners.add(listener)
  return () => listeners.delete(listener)
}

// Annonce un enregistrement hors Turbo. Renvoie la fonction de relâche.
export function hold(key) {
  const timer = setTimeout(() => release(key), SAFETY_RELEASE)
  clearTimeout(holds.get(key))
  holds.set(key, timer)
  notify()
  return () => release(key)
}

export function release(key) {
  if (!holds.has(key)) return

  clearTimeout(holds.get(key))
  holds.delete(key)
  notify()
}

document.addEventListener("turbo:submit-start", (event) => {
  const submission = event.detail?.formSubmission
  if (!submission) return

  submissions.add(submission)
  setTimeout(() => {
    if (submissions.delete(submission)) notify()
  }, SAFETY_RELEASE)
  notify()
})

document.addEventListener("turbo:submit-end", (event) => {
  const submission = event.detail?.formSubmission
  if (submission && submissions.delete(submission)) notify()

  const form = submission?.formElement
  if (form && dirtyForms.delete(form)) notify()
})

document.addEventListener("trix-focus", (event) => focusedEditors.add(event.target))

document.addEventListener("trix-change", (event) => {
  if (focusedEditors.has(event.target)) markDirty(event.target.closest("form"))
})

// Ciblé sur le champ de titre d'un énoncé : un écouteur `input` général
// marquerait le formulaire à chaque frappe dans une cellule de tableau, alors que
// celles-ci s'enregistrent seules et sont déjà couvertes par les prises.
document.addEventListener("input", (event) => {
  if (event.target.matches?.("input.challenge-title")) markDirty(event.target.closest("form"))
})
